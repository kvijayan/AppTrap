/*
-----------------------------------------------
  APPTRAP LICENSE

  "Do what you want to do,
  and go where you're going to
  Think for yourself,
  'cause I won't be there with you"

  You are completely free to do anything with
  this source code, but if you try to make
  money on it you will be beaten up with a
  large stick. I take no responsibility for
  anything, and this license text must
  always be included.

  Markus Amalthea Magnuson <markus.magnuson@gmail.com>
-----------------------------------------------
*/

#import "ATApplicationController.h"
#import "ATArrayController.h"
#import "ATNotifications.h"
#import "ATVariables.h"
#import "UKKQueue.h"
#import "ATUserDefaultKeys.h"

// Amount to expand the window to show the filelist
const int kWindowExpansionAmount = 164;

@implementation ATApplicationController

- (id)init
{
    if ((self = [super init])) {
        // Setup the path to the trash folder
        pathToTrash = nil;
        CFURLRef trashURL;
        FSRef trashFolderRef;
        OSErr err;
		
		isExpanded = NO;
        
        err = FSFindFolder(kUserDomain, kTrashFolderType, kDontCreateFolder, &trashFolderRef);
        if (err == noErr) {
            trashURL = CFURLCreateFromFSRef(kCFAllocatorSystemDefault, &trashFolderRef);
            if (trashURL) {
                pathToTrash = (NSString *)CFURLCopyFileSystemPath(trashURL, kCFURLPOSIXPathStyle);
                CFRelease(trashURL);
            }
        }
        
        // Setup paths for application folders
        applicationsPaths = [[NSSet alloc] initWithArray:NSSearchPathForDirectoriesInDomains(NSAllApplicationsDirectory, NSLocalDomainMask | NSUserDomainMask, YES)];
        
        // Setup paths for library items, where we'll search for files
        NSMutableArray *tempArray = [[NSMutableArray alloc] init];
        NSArray *tempSearchArray = nil;
        NSEnumerator *e = nil;
        id currentObject = nil;
        
        // Preferences and StartupItems
        tempSearchArray = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                              NSUserDomainMask | NSLocalDomainMask,
                                                              YES);
        e = [tempSearchArray objectEnumerator];
        while ((currentObject = [e nextObject])) {
            [tempArray addObject:[currentObject stringByAppendingPathComponent:@"Preferences"]];
            [tempArray addObject:[currentObject stringByAppendingPathComponent:@"StartupItems"]];
        }
        
        // Application Support
        [tempArray addObjectsFromArray:NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask | NSLocalDomainMask, YES)];
        
        // Cache
        [tempArray addObjectsFromArray:NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask | NSLocalDomainMask, YES)];
        
        libraryPaths = [[NSSet alloc] initWithArray:tempArray];
        
        [tempArray release];
        
        // Create an empty whitelist
        whitelist = [[NSMutableSet alloc] init];
        
        // Register for changes to the trash
        [self registerForWriteNotifications];
        
        // Setup default preferences
        NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithBool:NO], ATPreferencesIsExpanded,
            nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
        
        // Register for notifications from the prefpane
        NSDistributedNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(terminateAppTrap:)
                   name:ATApplicationShouldTerminateNotification
                 object:nil
     suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
		
		[nc addObserver:self
			   selector:@selector(sendVersion) 
				   name:ATApplicationSendVersionData 
				 object:nil
	 suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
    }
    
    return self;
}

- (void)setupTrashFolderPath
{
    pathToTrash = nil;
    CFURLRef trashURL;
    FSRef trashFolderRef;
    OSErr err;
    
    isExpanded = NO;
    
    err = FSFindFolder(kUserDomain, kTrashFolderType, kDontCreateFolder, &trashFolderRef);
    if (err == noErr) {
        trashURL = CFURLCreateFromFSRef(kCFAllocatorSystemDefault, &trashFolderRef);
        if (trashURL) {
            pathToTrash = (NSString *)CFURLCopyFileSystemPath(trashURL, kCFURLPOSIXPathStyle);
            CFRelease(trashURL);
        }
    }
}

- (void)awakeFromNib
{
	NSLog(@"awakeFromNib");
    // Restore the expanded state of the window
	BOOL shouldExpand = [[NSUserDefaults standardUserDefaults] boolForKey:ATPreferencesIsExpanded];
	NSLog(@"shouldExpand: %d", shouldExpand);
	
	if (shouldExpand) {
		[self setExpanded:shouldExpand];
		[disclosureTriangle setState:NSOnState];
	}
}

- (void)sendVersion {
	NSDistributedNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
	NSDictionary *version = [NSDictionary dictionaryWithObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] 
														forKey:ATBackgroundProcessVersion];
	//NSLog(@"sendVersion");
	
	[nc postNotificationName:ATApplicationGetVersionData 
					  object:nil 
					userInfo:version 
		  deliverImmediately:YES];
}

// A dealloc method is not needed since our only instance of
// ATApplicationController will always be dealloced at the same time
// as the application is quit, which releases all memory anyway. In
// fact, a dealloc here wouldn't even be called.

- (void)registerForWriteNotifications
{
    static BOOL inited = NO;
    
    if (!inited) {
        // Register for changes to the trash
        [[UKKQueue sharedFileWatcher] addPathToQueue:pathToTrash];
    }
    
    NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace] notificationCenter];
    [nc addObserver:self
           selector:@selector(handleWriteNotification:)
               name:UKFileWatcherWriteNotification
             object:nil];
}

- (void)unregisterForWriteNotifications
{
    NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace] notificationCenter];
    [nc removeObserver:self];
}

// Return all applications currently in the trash, as an array
// TODO: Can this method be incorporated in handleWriteNotification: to speed things up?
- (NSArray *)applicationsInTrash
{
    NSMutableArray *applicationsInTrash = [NSMutableArray array];
    
    if (pathToTrash && ![pathToTrash isEqualToString:@""]) {
        NSFileManager *manager = [NSFileManager defaultManager];
        if ([manager fileExistsAtPath:pathToTrash]) {
            NSDirectoryEnumerator *e = [manager enumeratorAtPath:pathToTrash];
            NSString *currentFilename = nil;
            
            // Use a little trick found at: http://www.cocoadev.com/index.pl?NSDirectoryEnumerator
            // For more information: http://www.wodeveloper.com/omniLists/macosx-dev/2002/June/msg00353.html
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            while ((currentFilename = [e nextObject])) {
                if ([currentFilename hasSuffix:@".app"])
                    [applicationsInTrash addObject:currentFilename];
                
                [pool drain];
                pool = [[NSAutoreleasePool alloc] init];
            }
            
            [pool drain];
            pool = nil;
        }
    }
    
    return applicationsInTrash;
}

- (void)handleWriteNotification:(NSNotification *)notification
{
    NSEnumerator *e = [[self applicationsInTrash] objectEnumerator];
    NSString *currentFilename = nil;
    
    while ((currentFilename = [e nextObject])) {
        // Is it on the whitelist?
        if ([whitelist containsObject:currentFilename])
            continue;
        
        // If it's in the applications folder, it was probably auto-updated by Sparkle
        // XXX: Currently only works for applications in root (not apps in folders), we could of course recurse with an NSDirectoryEnumerator but that would be _reeeeally_ slow since this method is called very often
        NSFileManager *manager = [NSFileManager defaultManager];
        NSEnumerator *applicationPathsEnumerator = [applicationsPaths objectEnumerator];
        id currentApplicationPath = nil;
        
        while ((currentApplicationPath = [applicationPathsEnumerator nextObject])) {
            if ([manager fileExistsAtPath:[currentApplicationPath stringByAppendingPathComponent:currentFilename]]) {
                // Add it to the whitelist
                [whitelist addObject:currentFilename];
            }
        }
        
        // Now, check again for safety
        if ([whitelist containsObject:currentFilename])
            continue;
        
        NSLog(@"I just trapped the application %@!", currentFilename);
        
		NSLog(@"whitelist before: %@", whitelist);
        // Add it to the whitelist
        [whitelist addObject:currentFilename];
		NSLog(@"whitelist after: %@", whitelist);
        
        // Get the full path of the trapped application
        NSString *fullPath = [pathToTrash stringByAppendingPathComponent:currentFilename];
        
        // Get the applications's bundle and its identifier
        NSBundle *appBundle = [NSBundle bundleWithPath:fullPath];
        NSString *preferenceFileName = [[appBundle bundleIdentifier] stringByAppendingPathExtension:@"plist"];
        
        // Get the application's true name (i.e. not the filename)
        NSString *appName = [appBundle objectForInfoDictionaryKey:@"CFBundleName"];
        
        // Let's find some system files
        NSMutableSet *matches = [[NSMutableSet alloc] init];
        NSEnumerator *libraryEnumerator = [libraryPaths objectEnumerator];
        id currentLibraryPath = nil;
        
        while ((currentLibraryPath = [libraryEnumerator nextObject])) {
            [matches addObjectsFromArray:[self matchesForFilename:preferenceFileName atPath:currentLibraryPath]];
            [matches addObjectsFromArray:[self matchesForFilename:appName atPath:currentLibraryPath]];
        }
        
        // TODO: Test performance of this
        // Get a snapshot of our matches so that we can remove objects from matches while enumerating
        NSEnumerator *matchesEnumerator = [[matches allObjects] objectEnumerator];
        id currentObject = nil;
        while ((currentObject = [matchesEnumerator nextObject])) {
            [listController addPathForDeletion:currentObject];
            [matches removeObject:currentObject];
        }
        
        [matches release];
    }
    
    // Open up the window if we got any hits
    if ([[listController arrangedObjects] count] > 0) {
        [NSApp activateIgnoringOtherApps:YES];
        [NSApp runModalForWindow:mainWindow];
    }
    
    // Clear the whitelist if the trash is empty, i.e an "Empty trash"
    // operation was just finished
    if ([self numberOfVisibleItemsInTrash] == 0)
        [whitelist removeAllObjects];
}

- (int)numberOfVisibleItemsInTrash
{
    int count = 0;
    NSDirectoryEnumerator *e = [[NSFileManager defaultManager] enumeratorAtPath:pathToTrash];
    NSString *currentObject = nil;
    
    // See the method applicationsInTrash for an explanation of this technique
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    while ((currentObject = [e nextObject])) {
        if (![currentObject hasPrefix:@"."])
            count++;
        
        [pool drain];
        pool = [[NSAutoreleasePool alloc] init];
    }
    
    [pool drain];
    pool = nil;
    
    return count;
}

// Part of code from http://www.borkware.com/quickies/single?id=130
// TODO: Seems like were leaking NSConcreteTask and NSConcretePipe here, needs to be investigated
- (NSArray *)matchesForFilename:(NSString *)filename atPath:(NSString *)path
{
	NSLog(@"filename: %@", filename);
    if (!filename || !path)
        return [NSArray array];
    
    // Do not ever allow empty strings
    if ([filename isEqualToString:@""] || [path isEqualToString:@""])
        return [NSArray array];
    
    // Find all the matching files at the given path
    NSString *command = [NSString stringWithFormat:@"find '%@' -name '%@' -maxdepth 1", [path stringByExpandingTildeInPath], filename];
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
    [task setArguments: [NSArray arrayWithObjects:@"-c", command, nil]];
    
    NSPipe *pipe  = [NSPipe pipe];
    [task setStandardOutput: pipe];
    NSFileHandle *file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data = [file readDataToEndOfFile];
    NSString *string = [[NSString alloc] initWithData:data
                                             encoding:NSUTF8StringEncoding];
    NSArray *matches = [string componentsSeparatedByString:@"\n"];
    
    [task waitUntilExit];
    [task release];
    [string release];
    
    return matches;
}

- (IBAction)moveCurrentItemsToTrash:(id)sender
{
    // Close the window
    [NSApp stopModal];
    [mainWindow orderOut:self];
    
    // First, unregister for further notifications until done
    [self unregisterForWriteNotifications];
    
    id currentItem = nil;
    NSLog(@"listController before: %@ \n\n", [listController arrangedObjects]);
    while ([[listController arrangedObjects] count] > 0) {
        // Pick the first object in the list
        currentItem = [[listController arrangedObjects] objectAtIndex:0];
		NSLog(@"currentItem: %@", currentItem);
		NSLog(@"currentItem class: %@", [currentItem class]);
        
        // Check if this item should be removed
        if ([[currentItem valueForKey:@"shouldBeRemoved"] boolValue] == YES) {
            // Move the item to the trash
            NSString *sourcePath = [currentItem valueForKey:@"fullPath"];
            NSString *source = [sourcePath stringByDeletingLastPathComponent];
            NSArray *files = [NSArray arrayWithObject:[sourcePath lastPathComponent]];
			NSInteger tag;
            [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation
                                                         source:source
                                                    destination:pathToTrash
                                                          files:files
                                                            tag:&tag];
            
            if (tag >= 0)
                NSLog(@"Successfully moved %@ to trash", sourcePath);
            else
                NSLog(@"Couldn't move %@ to trash (tag = %d)", sourcePath, (int)tag);
        }
        
        // Remove the item from the list
        [listController removeObjectAtArrangedObjectIndex:0];
		
		NSLog(@"listController after: %@ \n\n", [listController arrangedObjects]);
    }
    
    // Now, register for notifications again
    [self registerForWriteNotifications];
}

- (IBAction)cancel:(id)sender
{
    // Empty the list of candidates
    [listController removeObjects:[listController arrangedObjects]];
    
    // Close the window
    [NSApp stopModal];
    [mainWindow orderOut:self];
}

#pragma mark -
#pragma mark Window resizing

// TODO: This stuff is just plain ugly and probably error prone

- (IBAction)toggleFilelist:(id)sender
{
    // Show/hide the filelist
    [self setExpanded:([sender state] == NSOnState)];
}

- (void)extendMainWindowBy:(int)amount
{
    // Extends the main window vertically by the amount (which can be negative)
    NSRect newFrame = [mainWindow frame];
    newFrame.size.height += amount;
    newFrame.origin.y -= amount;
    
    [mainWindow setFrame:newFrame display:YES animate:YES];
}

- (void)setExpanded:(BOOL)flag
{
    // Expand or contract the window
    if (isExpanded != flag) {
        isExpanded = flag;
		[[NSUserDefaults standardUserDefaults] setBool:isExpanded forKey:ATPreferencesIsExpanded];
        
        if (isExpanded) {
            [self extendMainWindowBy:kWindowExpansionAmount];
		} else {			
            [self extendMainWindowBy:-kWindowExpansionAmount];
		}
    }
}

- (IBAction)expandOrShrink:(id)sender {
    // Expand or contract the window
	if ([sender state] == NSOffState) {
		[self setExpanded:NO];
	} else if ([sender state] == NSOnState) {
		[self setExpanded:YES];
	}
}

#pragma mark -
#pragma mark Application delegate methods

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Add any applications already in the trash to the whitelist to avoid confusion
    [whitelist addObjectsFromArray:[self applicationsInTrash]];
    
    // Post distributed notification for the prefpane
    NSDistributedNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
    [nc postNotificationName:ATApplicationFinishedLaunchingNotification
                      object:nil
                    userInfo:nil
          deliverImmediately:YES];
}

- (void)terminateAppTrap:(NSNotification *)aNotification
{
    // The prefpane wants us to quit, so let's quit
    [[NSApplication sharedApplication] terminate:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Post distributed notification for the prefpane
    NSDistributedNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
    [nc postNotificationName:ATApplicationTerminatedNotification
                      object:nil
                    userInfo:nil
          deliverImmediately:YES];
}

@end
