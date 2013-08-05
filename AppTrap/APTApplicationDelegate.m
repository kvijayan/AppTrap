//
//  APTApplicationDelegate.m
//  AppTrap
//
//  Created by Kumaran Vijayan on 2013-07-31.
//
//

#import "APTApplicationDelegate.h"

@interface APTApplicationDelegate () <NSApplicationDelegate>

@property (nonatomic) IBOutlet NSWindow *window;
@property (nonatomic) IBOutlet NSViewController *mainViewController;

@end



@implementation APTApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	[self.window setContentView:self.mainViewController.view];
}

@end
