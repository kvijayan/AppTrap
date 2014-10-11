//
//  APTPreferencePaneViewController.m
//  AppTrapPreferencePane
//
//  Created by Kumaran Vijayan on 2014-10-11.
//
//

#import "APTPreferencePaneViewController.h"

@import AppKit.NSTabViewItem;

@interface APTPreferencePaneViewController ()
@property (nonatomic) IBOutlet NSViewController *generalTabViewController;

@property (nonatomic, weak) IBOutlet NSTabViewItem *generalTabViewItem;
@property (nonatomic, weak) IBOutlet NSTabViewItem *aboutTabViewItem;
@end

@implementation APTPreferencePaneViewController

- (void)setUpLocalizationStrings
{
    [self.generalTabViewItem setLabel:NSLocalizedString(@"General", nil)];
    [self.aboutTabViewItem setLabel:NSLocalizedString(@"About", nil)];
}

- (void)setUpGeneralTab
{
    [self.generalTabViewItem setView:[self.generalTabViewController view]];
}

- (void)viewDidLoad
{
    [self setUpLocalizationStrings];
    [self setUpGeneralTab];
}

#pragma mark - NSViewController

- (void)loadView
{
    [super loadView];
    // TODO: Remember to support 10.10's viewDidLoad method implementation
    [self viewDidLoad];
}

@end
