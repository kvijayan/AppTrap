//
//  APTFSEventsWatcher.h
//  AppTrap
//
//  Created by Kumaran Vijayan on 2013-05-08.
//
//

#import <Foundation/Foundation.h>

@class APTFSEventsWatcher;

@protocol APTFSEventsWatcherDelegate <NSObject>
@required
- (void)eventsWatcher:(APTFSEventsWatcher*)eventsWatcher observedChangesInDirectoryPath:(NSString*)directory;
@end



@interface APTFSEventsWatcher : NSObject

@property (nonatomic, weak) id <APTFSEventsWatcherDelegate> delegate;

@property (nonatomic, readonly, getter=isWatching) BOOL watching;

- (id)initWithDirectoryPath:(NSString*)directoryPath;

- (void)startWatching;

- (void)stopWatching;

@end
