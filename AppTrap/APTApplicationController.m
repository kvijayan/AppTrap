//
//  APTApplicationController.m
//  AppTrap
//
//  Created by Kumaran Vijayan on 2013-05-15.
//
//

#import "APTApplicationController.h"

#import "APTFSEventsWatcher.h"

@interface APTApplicationController () <APTFSEventsWatcherDelegate>
{
    NSString *_pathToTrash;
}

@property (nonatomic) APTFSEventsWatcher *eventsWatcher;

@property (nonatomic) NSArray *currentDirectoryContents;
@property (nonatomic) NSMutableArray *whitelist;

@property (nonatomic, readonly) NSString *pathToTrash;

- (void)setUpAndStartEventsWatcher;
- (void)setUpWhitelist;

- (NSArray*)arrayOfApplicationsInDirectory:(NSString*)path;
- (BOOL)arrayOfStrings:(NSArray*)firstArray isEqualToArrayOfStrings:(NSArray*)secondArray;
- (BOOL)currentDirectoryContentsMatchesNewDirectoryContents:(NSArray*)newDirectoryContents;
- (void)checkForNewApplicationBundlesInDirectory:(NSString*)directoryPath;
- (void)presentMainWindowForApplicationsArray:(NSArray*)applicationsArray;

@end



@implementation APTApplicationController

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
    NSMutableArray *newApplicationsArray = [NSMutableArray arrayWithArray:array];
    
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
    
    // Present the window
    if (newApplicationsArray.count > 0)
    {
        [self presentMainWindowForApplicationsArray:newApplicationsArray];
        
        // Now that we've dealt with the applications, we'll put them in the whitelist
        [self.whitelist addObjectsFromArray:newApplicationsArray];
    }
}

- (void)presentMainWindowForApplicationsArray:(NSArray *)applicationsArray
{
    NSLog(@"%s", __func__);
    NSLog(@"current directory contents: %@", self.currentDirectoryContents);
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
