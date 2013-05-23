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
@property (nonatomic) NSArray *whitelist;

@property (nonatomic, readonly) NSString *pathToTrash;

- (void)setUpAndStartEventsWatcher;
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

#pragma mark - Core

- (BOOL)currentDirectoryContentsMatchesNewDirectoryContents:(NSArray*)newDirectoryContents
{
    if (!newDirectoryContents)
    {
        [NSException raise:NSInvalidArgumentException format:@"newDirectoryContents must not be nil"];
    }
    
    if (self.currentDirectoryContents && self.currentDirectoryContents.count == newDirectoryContents.count)
    {
        for (NSUInteger i = 0; i < self.currentDirectoryContents.count; i++)
        {
            NSString *currentName = self.currentDirectoryContents[i];
            NSString *newName = newDirectoryContents[i];
            if (![currentName isEqualToString:newName])
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

- (void)checkForNewApplicationBundlesInDirectory:(NSString *)directoryPath
{
    NSMutableArray *newApplicationsArray = [NSMutableArray new];
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:directoryPath];
    for (NSString *filename in enumerator)
    {
        if ([[filename pathExtension] isEqualToString:@"app"])
        {
            [newApplicationsArray addObject:filename];
        }
    }
    
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
    if (newApplicationsArray.count > 0)
    {
        [self presentMainWindowForApplicationsArray:newApplicationsArray];
    }
}

- (void)presentMainWindowForApplicationsArray:(NSArray *)applicationsArray
{
    NSLog(@"%s", __func__);
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
