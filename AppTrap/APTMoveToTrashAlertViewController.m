//
//  APTMoveToTrashAlertViewController.m
//  AppTrap
//
//  Created by Kumaran Vijayan on 2013-07-31.
//
//

#import "APTMoveToTrashAlertViewController.h"

#import "APTApplicationController.h"
#import "ATArrayController.h"

static CGFloat LargeHeight = 402.0;
static CGFloat SmallHeight = 177.0;

@interface APTMoveToTrashAlertViewController () <APTApplicationControllerDelegate>

@property (weak) IBOutlet NSWindow *mainWindow;

@property (weak) IBOutlet NSTextField *instructionLabel;
@property (weak) IBOutlet NSTextField *explanationLabel;
@property (weak) IBOutlet NSTextField *warningLabel;
@property (weak) IBOutlet NSButton *leaveFilesButton;
@property (weak) IBOutlet NSButton *moveFilesButton;
@property (weak) IBOutlet NSButton *showFileListButton;
@property (weak) IBOutlet NSTableView *tableView;

@property (weak) IBOutlet APTApplicationController *applicationController;
@property (weak) IBOutlet ATArrayController *arrayController;

- (void)viewDidLoad;
- (void)setUpLabelsAndButtons;
- (void)resizeWindowForState:(NSCellStateValue)state;

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

- (void)resizeWindowForState:(NSCellStateValue)state
{
	NSRect rect = self.mainWindow.frame;
	
	if (state == NSOnState)
	{
		CGFloat heightDifference = LargeHeight - self.mainWindow.frame.size.height;
		rect.origin.y -= heightDifference;
		rect.size.height = LargeHeight;
	}
	else
	{
		CGFloat heightDifference = self.mainWindow.frame.size.height - SmallHeight;
		rect.origin.y += heightDifference;
		rect.size.height = SmallHeight;
	}
	
	[self.mainWindow setFrame:rect display:YES animate:YES];
}

#pragma mark - Interface Actions

- (IBAction)moveFiles:(id)sender
{
	NSLog(@"%s", __func__);
	NSMutableArray *paths = [NSMutableArray new];
	NSMutableArray *entries = [NSMutableArray new];
	for (NSDictionary *entry in self.arrayController.arrangedObjects)
	{
		BOOL shouldBeRemoved = ((NSNumber*)entry[@"shouldBeRemoved"]).boolValue;
		if (shouldBeRemoved)
		{
			[paths addObject:entry[@"fullPath"]];
			[entries addObject:entry];
		}
	}
	
	[self.applicationController moveFilesToTrash:paths];
	[self.arrayController removeObjects:entries];
	
	[NSApp stopModal];
	[self.mainWindow orderOut:self];
}

- (IBAction)leaveFiles:(id)sender
{
	NSArray *entries = self.arrayController.arrangedObjects;
	[self.arrayController removeObjects:entries];
	
	[NSApp stopModal];
	[self.mainWindow orderOut:self];
}

- (IBAction)showFileList:(NSButton*)sender
{
	[self resizeWindowForState:sender.state];
}

#pragma mark - APTApplicationControllerDelegate Method

- (void)applicationController:(APTApplicationController *)applicationController didFindFiles:(NSArray *)files
{
	if (files.count > 0)
	{
		[self.arrayController addPathsForDeletion:files];
		[NSApp activateIgnoringOtherApps:YES];
		[NSApp runModalForWindow:self.mainWindow];
	}
}

@end
