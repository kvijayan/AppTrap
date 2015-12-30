//
//  main.m
//  RelaunchObjC
//
//  Created by Kumaran Vijayan on 2015-12-28.
//
//

#import <AppKit/AppKit.h>

@interface Observer: NSObject
@property (nonatomic, copy) void (^callback)();
- (instancetype)initWithCallback:(void (^)())callback;
@end
@implementation Observer
- (instancetype)initWithCallback:(void (^)())callback {
    self = [super init];
    if (self) {
        _callback = callback;
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context {
    self.callback();
}
@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        int parentPid = atoi(argv[1]);
        NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:parentPid];
        NSURL *bundleURL = app.bundleURL;
        Observer *listener = [[Observer alloc] initWithCallback:^{
            CFRunLoopStop(CFRunLoopGetCurrent());
        }];
        [app addObserver:listener forKeyPath:@"isTerminated" options:0 context:nil];
        [app terminate];
        CFRunLoopRun();
        [app removeObserver:listener forKeyPath:@"isTerminated"];
        
        [[NSWorkspace sharedWorkspace] launchApplicationAtURL:bundleURL
                                                      options:NSWorkspaceLaunchDefault
                                                configuration:[NSDictionary new]
                                                        error:nil];
    }
    return 0;
}
