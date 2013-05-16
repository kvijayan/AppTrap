//
//  APTFSEventsWatcher.m
//  AppTrap
//
//  Created by Kumaran Vijayan on 2013-05-08.
//
//

#import "APTFSEventsWatcher.h"

static CFTimeInterval kEventStreamLatency = 3.0;

@interface APTFSEventsWatcher ()
{
    BOOL _watching;
}

@property (nonatomic) FSEventStreamRef eventStream;

void eventStreamCallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]);

@end



@implementation APTFSEventsWatcher

#pragma mark - Creation

- (id)initWithDirectoryPath:(NSString *)directoryPath
{
    self = [super init];
    if (self)
    {
        _watching = NO;

        FSEventStreamContext eventStreamContext;
        eventStreamContext.info = (__bridge void*)self;
        eventStreamContext.version = 0;
        eventStreamContext.release = NULL;
        eventStreamContext.retain = NULL;
        eventStreamContext.copyDescription = NULL;
        
        
        FSEventStreamRef eventStream = FSEventStreamCreate(kCFAllocatorDefault,
                                                           &eventStreamCallback,
                                                           &eventStreamContext,
                                                           (CFArrayRef)CFBridgingRetain(@[directoryPath]),
                                                           kFSEventStreamEventIdSinceNow,
                                                           kEventStreamLatency,
                                                           kFSEventStreamCreateFlagUseCFTypes);
        [self setEventStream:eventStream];
    }
    return self;
}

#pragma mark - Public APIs

- (BOOL)isWatching
{
    return _watching;
}

- (void)startWatching
{
    FSEventStreamScheduleWithRunLoop(self.eventStream,
                                     CFRunLoopGetCurrent(),
                                     kCFRunLoopDefaultMode);
    FSEventStreamStart(self.eventStream);
    _watching = YES;
}

- (void)stopWatching
{
    FSEventStreamStop(self.eventStream);
    _watching = NO;
}

#pragma mark - FSEventStream Callback

void eventStreamCallback(ConstFSEventStreamRef streamRef,
                         void *clientCallBackInfo,
                         size_t numEvents,
                         void *eventPaths,
                         const FSEventStreamEventFlags eventFlags[],
                         const FSEventStreamEventId eventIds[])
{
    APTFSEventsWatcher *watcher = (__bridge APTFSEventsWatcher*)clientCallBackInfo;
    NSArray *paths = (__bridge NSArray*)eventPaths;
    [watcher.delegate eventsWatcher:watcher observedChangesInDirectoryPath:paths[0]];
}

- (NSString *)description
{
    return @"Hey there";
}

#pragma mark - Memory Management

- (void)dealloc
{
    FSEventStreamUnscheduleFromRunLoop(self.eventStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamInvalidate(self.eventStream);
    FSEventStreamRelease(self.eventStream);
}

@end
