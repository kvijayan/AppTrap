//
//  APTApplicationController.m
//  AppTrap
//
//  Created by Kumaran Vijayan on 2013-05-15.
//
//

#import "APTApplicationController.h"

#import "APTFSEventsWatcher.h"
#import "ATArrayController.h"

static NSString *PreferencesFolderName = @"Preferences";
static NSString *StartupItemsFolderName = @"StartupItems";
static NSString *SandboxContainersFolderName = @"Containers";

@interface APTApplicationController () <APTFSEventsWatcherDelegate>

@property (nonatomic, weak) IBOutlet id <APTApplicationControllerDelegate> delegate;

@property (nonatomic) IBOutlet NSWindow *window;

@property (nonatomic) APTFSEventsWatcher *eventsWatcher;

@property (nonatomic) NSArray *currentDirectoryContents;
@property (nonatomic) NSMutableArray *whitelist;

@property (nonatomic, readonly) NSString *pathToTrash;
@property (nonatomic, readonly) NSSet *libraryPaths;

- (void)setUpAndStartEventsWatcher;
- (void)setUpWhitelist;

- (NSUInteger)visibleItemsCountAtPath:(NSString*)path;
- (NSArray*)arrayOfApplicationsInDirectory:(NSString*)path;
- (BOOL)currentDirectoryContentsMatchesNewDirectoryContents:(NSArray*)newDirectoryContents;
- (void)checkForNewApplicationBundlesInDirectory:(NSString*)directoryPath;
- (NSSet*)matchesForApplication:(NSString*)application;
- (NSSet*)matchesForFilename:(NSString*)filename atPath:(NSString*)path;
- (void)presentMainWindow;

@end



@implementation APTApplicationController

@synthesize pathToTrash = _pathToTrash;
@synthesize libraryPaths = _libraryPaths;

#pragma mark - Creation

- (NSString *)pathToTrash
{
    if (!_pathToTrash)
    {
        // Find the path to the user's trash folder
        OSErr err;
        FSRef trashFolderRef;
        
        err = FSFindFolder(kUserDomain, kTrashFolderType, kDontCreateFolder, &trashFolderRef);
        if (err == noErr) {
            CFURLRef trashURL = CFURLCreateFromFSRef(kCFAllocatorSystemDefault, &trashFolderRef);
            if (trashURL) {
                _pathToTrash = (NSString *)CFBridgingRelease(CFURLCopyFileSystemPath(trashURL, kCFURLPOSIXPathStyle));
                CFRelease(trashURL);
            }
        }
    }
    
    return _pathToTrash;
}

- (NSSet*)libraryPaths
{
    if (!_libraryPaths)
    {
        NSMutableSet *set = [NSMutableSet new];
        NSSearchPathDomainMask domainMask = NSUserDomainMask | NSLocalDomainMask;
        NSArray *searchArray = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                                   domainMask,
                                                                   YES);
        NSString *directoryString;
        for (directoryString in searchArray)
        {
            NSString *preferencesDirectory = [directoryString stringByAppendingPathComponent:PreferencesFolderName];
            NSString *startupItemsDirectory = [directoryString stringByAppendingPathComponent:StartupItemsFolderName];
			NSString *sandboxContainersDirectory = [directoryString stringByAppendingPathComponent:SandboxContainersFolderName];
            [set addObject:preferencesDirectory];
            [set addObject:startupItemsDirectory];
			[set addObject:sandboxContainersDirectory];
        }
        
        NSArray *directories = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                                   domainMask,
                                                                   YES);
        [set addObjectsFromArray:directories];
        directories = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                          domainMask,
                                                          YES);
        [set addObjectsFromArray:directories];
        _libraryPaths = [NSSet setWithSet:set];
    }
    return _libraryPaths;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self setUpWhitelist];
        [self setUpAndStartEventsWatcher];
    }
    return self;
}

- (void)setUpAndStartEventsWatcher
{
    APTFSEventsWatcher *eventsWatcher = [[APTFSEventsWatcher alloc] initWithDirectoryPath:self.pathToTrash];
    [self setEventsWatcher:eventsWatcher];
    [eventsWatcher setDelegate:self];
    [eventsWatcher startWatching];
}

- (void)setUpWhitelist
{
    NSArray *applications = [self arrayOfApplicationsInDirectory:self.pathToTrash];
    NSMutableArray *whitelist = [NSMutableArray arrayWithArray:applications];
    [self setWhitelist:whitelist];
}

- (void)moveFilesToTrash:(NSArray *)paths
{
	// Kill the events watcher before we move stuff to the trash
	[self.eventsWatcher stopWatching];
	[self setEventsWatcher:nil];
	
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSString *emptyString = @"";
	for (NSString *path in paths)
	{
		NSString *source = path.stringByDeletingLastPathComponent;
		NSString *fileName = path.lastPathComponent;
		NSInteger tag;
		BOOL success = [workspace performFileOperation:NSWorkspaceRecycleOperation
												source:source
										   destination:emptyString
												 files:@[fileName]
												   tag:&tag];
		if (success)
		{
			NSLog(@"Successfully moved %@ to trash", path);
		}
		else
		{
			NSLog(@"Couldn't move %@ to trash (tag = %d)", path, (int)tag);
		}
	}
	
	// Create a new events watcher to monitor the trash
	APTFSEventsWatcher *watcher = [[APTFSEventsWatcher alloc] initWithDirectoryPath:self.pathToTrash];
	[self setEventsWatcher:watcher];
	[watcher setDelegate:self];
	[watcher startWatching];
}

#pragma mark - Core

- (NSUInteger)visibleItemsCountAtPath:(NSString*)path
{
	NSUInteger count = 0;
	NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
	for (NSString *filePath in directoryEnumerator)
	{
		if ([filePath hasPrefix:@"."])
		{
			[directoryEnumerator skipDescendants];
		}
		else
		{
			count++;
		}
	}
	return count;
}

- (NSArray*)arrayOfApplicationsInDirectory:(NSString*)path
{
    NSMutableArray *applications = [NSMutableArray new];
    NSEnumerator *files = [[NSFileManager defaultManager] enumeratorAtPath:path];
    for (NSString *file in files)
    {
        if ([file.pathExtension isEqualToString:@"app"])
        {
            [applications addObject:file];
        }
    }
    
    return [NSArray arrayWithArray:applications];
}

- (BOOL)currentDirectoryContentsMatchesNewDirectoryContents:(NSArray*)newDirectoryContents
{
	BOOL same = [self.currentDirectoryContents isEqualToArray:newDirectoryContents];
	return same;
}

- (void)checkForNewApplicationBundlesInDirectory:(NSString *)directoryPath
{
    // Enumerate through everything in the folder and get just the applications
    NSArray *array = [self arrayOfApplicationsInDirectory:directoryPath];
    NSMutableArray *newApplicationsArray = array.mutableCopy;
    
    // Sift out the applications that are in the whitelist
    NSMutableArray *oldApplicationsArray = [NSMutableArray new];
    for (NSString *filename in newApplicationsArray)
    {
        for (NSString *whitelistFilename in self.whitelist)
        {
            if ([filename isEqualToString:whitelistFilename])
            {
                [oldApplicationsArray addObject:filename];
                break;
            }
        }
    }
    [newApplicationsArray removeObjectsInArray:oldApplicationsArray];
    
	if ([self visibleItemsCountAtPath:self.pathToTrash] <= 0)
	{
		[self.whitelist removeAllObjects];
	}
	else
	{
		NSMutableArray *files = [NSMutableArray new];
		for (NSString *application in newApplicationsArray)
		{
			NSSet *matches = [self matchesForApplication:application];
			[files addObjectsFromArray:matches.allObjects];
		}
		   
		if (files.count > 0)
		{
			NSArray *returnFiles = [NSArray arrayWithArray:files];
			[self.delegate applicationController:self didFindFiles:returnFiles];
		}
		   
		// Now that we've dealt with the applications, we'll put them in the whitelist
		[self.whitelist addObjectsFromArray:newApplicationsArray];
	}
}

- (NSSet*)matchesForApplication:(NSString*)application
{
    // Get the full path of the trapped application
    NSString *fullPath = [self.pathToTrash stringByAppendingPathComponent:application];

    // Get the applications's bundle and its identifier
    NSBundle *appBundle = [NSBundle bundleWithPath:fullPath];
	NSString *bundleIdentifier = appBundle.bundleIdentifier;
    NSString *preferenceFileName = [bundleIdentifier stringByAppendingPathExtension:@"plist"];
    NSString *preflockFileName = [preferenceFileName stringByAppendingPathExtension:@"lockfile"];
    NSString *lssflprefFileName = [bundleIdentifier stringByAppendingPathExtension:@"LSSharedFileList.plist"];
    NSString *lssflpreflocklFileName = [lssflprefFileName stringByAppendingPathExtension:@"lockfile"];
	
    
    // Get the application's true name (i.e. not the filename)
    // TODO: replace @"CFBundle" with kCFBundle
    NSString *appName = [appBundle objectForInfoDictionaryKey:@"CFBundleName"];
    
    // Let's find some system files
    NSMutableSet *matches = [NSMutableSet new];
    for (NSString *libraryPath in self.libraryPaths)
    {
        NSSet *set = [self matchesForFilename:preferenceFileName atPath:libraryPath];
        [matches unionSet:set];
        set = [self matchesForFilename:preflockFileName atPath:libraryPath];
        [matches unionSet:set];
        set = [self matchesForFilename:preflockFileName atPath:libraryPath];
        [matches unionSet:set];
        set = [self matchesForFilename:lssflprefFileName atPath:libraryPath];
        [matches unionSet:set];
        set = [self matchesForFilename:lssflpreflocklFileName atPath:libraryPath];
        [matches unionSet:set];
        set = [self matchesForFilename:appName atPath:libraryPath];
        [matches unionSet:set];
		set = [self matchesForFilename:bundleIdentifier atPath:libraryPath];
		[matches unionSet:set];
    }
    
    NSSet *returnSet = [NSSet setWithSet:matches];
    return returnSet;
}

- (NSSet*)matchesForFilename:(NSString *)filename atPath:(NSString *)path
{
    if (!filename || !path)
    {
        return [NSSet new];
    }
    
    // Do not ever allow empty strings
    if ([filename isEqualToString:@""] || [path isEqualToString:@""])
    {
        return [NSSet set];
    }
	
	NSMutableSet *set = [NSMutableSet new];
	NSURL *url = [NSURL fileURLWithPath:path];
	NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:url
															 includingPropertiesForKeys:@[NSURLNameKey]
																				options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants
																		   errorHandler:nil];
	for (NSURL *searchFile in enumerator)
	{
		NSString *searchFileName = searchFile.path.lastPathComponent;
		if ([searchFileName hasPrefix:@"."])
		{
			[enumerator skipDescendants];
		}
		else if ([searchFileName isEqualToString:filename])
		{
			NSString *match = [path stringByAppendingPathComponent:searchFileName];
			[set addObject:match];
		}
	}
	NSSet *returnSet = [NSSet setWithSet:set];
	return returnSet;
}

- (void)presentMainWindow
{
    NSLog(@"%s", __func__);
    NSLog(@"current directory contents: %@", self.currentDirectoryContents);
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp runModalForWindow:self.window];
}

#pragma mark - APTFSEventsWatcherDelegate Method

- (void)eventsWatcher:(APTFSEventsWatcher *)eventsWatcher observedChangesInDirectoryPath:(NSString *)directory
{
    NSError *error;
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:&error];
    
    if (error)
    {
        NSLog(@"error: %@", error);
    }
    
    if (![self currentDirectoryContentsMatchesNewDirectoryContents:contents])
    {
        [self setCurrentDirectoryContents:contents];
        [self checkForNewApplicationBundlesInDirectory:directory];
    }
}

@end
