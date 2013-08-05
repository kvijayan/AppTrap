//
//  APTMoveToTrashAlertViewController.m
//  AppTrap
//
//  Created by Kumaran Vijayan on 2013-07-31.
//
//

#import "APTMoveToTrashAlertViewController.h"

#import "APTApplicationController.h"

static CGFloat LargeHeight = 402.0;
static CGFloat SmallHeight = 177.0;

@interface APTMoveToTrashAlertViewController ()

@property (weak) IBOutlet NSTextField *instructionLabel;
@property (weak) IBOutlet NSTextField *explanationLabel;
@property (weak) IBOutlet NSTextField *warningLabel;
@property (weak) IBOutlet NSButton *leaveFilesButton;
@property (weak) IBOutlet NSButton *moveFilesButton;

@property (nonatomic) APTApplicationController *applicationController;

- (void)viewDidLoad;
- (void)setUpLabelsAndButtons;

- (IBAction)moveFiles:(id)sender;
- (IBAction)leaveFiles:(id)sender;
- (IBAction)showFileList:(id)sender;

@end



@implementation APTMoveToTrashAlertViewController

- (void)loadView
{
	[super loadView];
	[self viewDidLoad];
}

- (void)viewDidLoad
{
	[self setUpLabelsAndButtons];
}

- (void)setUpLabelsAndButtons
{
	[self.instructionLabel setStringValue:NSLocalizedString(@"You are moving an application to the trash, do you want to move its associated system files too?", nil)];
	[self.explanationLabel setStringValue:NSLocalizedString(@"No files will be deleted until you empty the trash.", nil)];
	[self.warningLabel setStringValue:NSLocalizedString(@"WARNING: The application may only be updating itself.", nil)];
	
	[self.leaveFilesButton setStringValue:NSLocalizedString(@"Leave files", nil)];
	[self.moveFilesButton setStringValue:NSLocalizedString(@"Move files", nil)];
}

#pragma mark - Interface Actions

- (IBAction)moveFiles:(id)sender
{
}

- (IBAction)leaveFiles:(id)sender
{
}

- (IBAction)showFileList:(NSButton*)sender
{
	NSRect rect = self.view.window.frame;
	
	if (sender.state == NSOnState)
	{
		CGFloat heightDifference = LargeHeight - self.view.window.frame.size.height;
		rect.origin.y -= heightDifference;
		rect.size.height = LargeHeight;
	}
	else
	{
		CGFloat heightDifference = self.view.window.frame.size.height - SmallHeight;
		rect.origin.y += heightDifference;
		rect.size.height = SmallHeight;
	}

	[self.view.window setFrame:rect display:YES animate:YES];
}

@end
