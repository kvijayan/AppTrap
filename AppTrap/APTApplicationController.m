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

@interface APTApplicationController () <APTFSEventsWatcherDelegate>

@property (nonatomic) IBOutlet NSWindow *window;
@property (nonatomic) IBOutlet ATArrayController *listController;

@property (nonatomic) APTFSEventsWatcher *eventsWatcher;

@property (nonatomic) NSArray *currentDirectoryContents;
@property (nonatomic) NSMutableArray *whitelist;

@property (nonatomic, readonly) NSString *pathToTrash;
@property (nonatomic, readonly) NSSet *libraryPaths;

- (void)setUpAndStartEventsWatcher;
- (void)setUpWhitelist;

- (NSUInteger)visibleItemsCountAtPath:(NSString*)path;
- (NSArray*)arrayOfApplicationsInDirectory:(NSString*)path;
- (BOOL)arrayOfStrings:(NSArray*)firstArray isEqualToArrayOfStrings:(NSArray*)secondArray;
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
            [set addObject:preferencesDirectory];
            [set addObject:startupItemsDirectory];
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

- (BOOL)arrayOfStrings:(NSArray *)firstArray isEqualToArrayOfStrings:(NSArray *)secondArray
{
    if (firstArray.count == secondArray.count)
    {
        for (NSUInteger i = 0; i < firstArray.count; i++)
        {
            NSString *firstString = firstArray[i];
            NSString *secondString = secondArray[i];
            if (![firstString isEqualToString:secondString])
            {
                return NO;
            }
        }
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL)currentDirectoryContentsMatchesNewDirectoryContents:(NSArray*)newDirectoryContents
{
    if (!newDirectoryContents)
    {
        [NSException raise:NSInvalidArgumentException format:@"newDirectoryContents must not be nil"];
    }
    
    if (self.currentDirectoryContents)
    {
        return [self arrayOfStrings:self.currentDirectoryContents isEqualToArrayOfStrings:newDirectoryContents];
    }
    else
    {
        return NO;
    }
    
}

- (void)checkForNewApplicationBundlesInDirectory:(NSString *)directoryPath
{
    // Enumerate through everything in the trash folder and get just the applications
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
		for (NSString *application in newApplicationsArray)
		{
			NSSet *matches = [self matchesForApplication:application];
			[self.listController addPathsForDeletion:matches];
		}
		   
		if (((NSArray*)self.listController.arrangedObjects).count > 0)
		{
			[self presentMainWindow];
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
    NSString *preferenceFileName = [[appBundle bundleIdentifier] stringByAppendingPathExtension:@"plist"];
    NSString *preflockFileName = [preferenceFileName stringByAppendingPathExtension:@"lockfile"];
    NSString *lssflprefFileName = [[appBundle bundleIdentifier] stringByAppendingPathExtension:@"LSSharedFileList.plist"];
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
    }
    
    NSSet *returnSet = [NSSet setWithSet:matches];
    return returnSet;
}

// Part of code from http://www.borkware.com/quickies/single?id=130
// TODO: Seems like were leaking NSConcreteTask and NSConcretePipe here, needs to be investigated
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
    
    // Find all the matching files at the given path
    NSString *command = [NSString stringWithFormat:@"find '%@' -name '%@' -maxdepth 1", path.stringByExpandingTildeInPath, filename];
    
    NSTask *task = [NSTask new];
    [task setLaunchPath: @"/bin/sh"];
    [task setArguments: @[@"-c", command]];
    
    NSPipe *pipe  = [NSPipe new];
    [task setStandardOutput:pipe];
    NSFileHandle *file = pipe.fileHandleForReading;

    [task launch];
    
    NSData *data = file.readDataToEndOfFile;
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *matches = [string componentsSeparatedByString:@"\n"];
    
    [task waitUntilExit];
    
    NSSet *setToReturn = [NSSet setWithArray:matches];
    return setToReturn;
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
