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
@property (nonatomic) CFRunLoopRef runLoop;

void eventStreamCallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]);

@end



@implementation APTFSEventsWatcher

#pragma mark - Creation

- (id)initWithDirectoryPath:(NSString *)directoryPath
{
    self = [super init];
    if (self)
    {
        if (!directoryPath)
        {
            [NSException raise:NSInvalidArgumentException format:@"directoryPath must be a valid NSString."];
        }
        
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
                                                           (__bridge CFArrayRef)@[directoryPath],
                                                           kFSEventStreamEventIdSinceNow,
                                                           kEventStreamLatency,
                                                           kFSEventStreamCreateFlagUseCFTypes);
        [self setEventStream:eventStream];
		[self setRunLoop:CFRunLoopGetCurrent()];
		FSEventStreamScheduleWithRunLoop(self.eventStream,
										 CFRunLoopGetCurrent(),
										 kCFRunLoopDefaultMode);
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

#pragma mark - Memory Management

- (void)dealloc
{
	FSEventStreamStop(self.eventStream);
    FSEventStreamUnscheduleFromRunLoop(self.eventStream, self.runLoop, kCFRunLoopDefaultMode);
    FSEventStreamInvalidate(self.eventStream);
    FSEventStreamRelease(self.eventStream);
}

@end
