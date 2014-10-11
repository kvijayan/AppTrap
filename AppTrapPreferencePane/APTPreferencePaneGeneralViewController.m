//
//  APTPreferencePaneGeneralViewController.m
//  AppTrapPreferencePane
//
//  Created by Kumaran Vijayan on 2014-10-11.
//
//

#import "APTPreferencePaneGeneralViewController.h"

@import AppKit.NSButton;
@import AppKit.NSColor;
@import AppKit.NSTextField;

@import QuartzCore.CALayer;

@interface APTPreferencePaneGeneralViewController ()
@property (nonatomic, weak) IBOutlet NSTextField *appTrapIsLabel;
@property (nonatomic, weak) IBOutlet NSTextField *appTrapStatusLabel;
@property (nonatomic, weak) IBOutlet NSTextField *restartingLabel;
@property (nonatomic, weak) IBOutlet NSButton *startOnLoginCheckbox;
@end

@implementation APTPreferencePaneGeneralViewController

- (void)setUpLocalizationStrings
{
    NSLog(@"AppTrap is: = %@", NSLocalizedString(@"AppTrap is:", @""));
    [self.appTrapIsLabel setStringValue:NSLocalizedString(@"AppTrap is:", nil)];
    [self.restartingLabel setStringValue:NSLocalizedString(@"Restarting AppTrap", nil)];
    [self.startOnLoginCheckbox setStringValue:NSLocalizedString(@"Start automatically on login", nil)];
}

- (void)setUpAppTrapStatus
{
    
}

- (void)viewDidLoad
{
//    [[self view] layer].backgroundColor = [[NSColor blackColor] CGColor];
//    self.appTrapIsLabel.backgroundColor = [NSColor blackColor];
    [self setUpLocalizationStrings];
    [self setUpAppTrapStatus];
}

#pragma mark - NSViewController

- (void)loadView
{
    [super loadView];
// TODO: Remember to support 10.10's viewDidLoad method implementation
    [self viewDidLoad];
}

@end
