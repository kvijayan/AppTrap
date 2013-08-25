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
#import "ATUserDefaultKeys.h"
#import "APTPreferencePaneDelegate.h"
#import "ATNotifications.h"
#import "ATVariables.h"

static CGFloat LargeHeight = 402.0;
static CGFloat SmallHeight = 177.0;

@interface APTMoveToTrashAlertViewController () <APTApplicationControllerDelegate, APTPreferencePaneDelegate>

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
@property (nonatomic, readonly) NSArray *arrayControllerSortDescriptors;

@property (nonatomic) IBOutlet NSDistributedNotificationCenter *notificationCenter;

- (void)viewDidLoad;
- (void)setUpLabelsAndButtons;
- (void)setUpWindow;
- (void)sendApplicationDidFinishLaunchingNotification;
- (void)resizeWindowForState:(NSCellStateValue)state;

- (IBAction)moveFiles:(id)sender;
- (IBAction)leaveFiles:(id)sender;
- (IBAction)showFileList:(id)sender;

@end



@implementation APTMoveToTrashAlertViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (self)
	{
		NSDistributedNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
		[self setNotificationCenter:nc];
		[nc addObserver:self
			   selector:@selector(preferencePaneRequestsTermination:)
				   name:ATApplicationShouldTerminateNotification
				 object:nil
	 suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
		
		[nc addObserver:self
			   selector:@selector(preferencePaneRequestsVersion:)
				   name:ATApplicationSendVersionData
				 object:nil
	 suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
	}
	return self;
}

- (void)loadView
{
	[super loadView];
	[self viewDidLoad];
}

- (void)viewDidLoad
{
	[self setUpLabelsAndButtons];
	[self setUpWindow];
	[self sendApplicationDidFinishLaunchingNotification];
}

- (void)dealloc
{
	[self.notificationCenter removeObserver:self];
}

- (void)setUpLabelsAndButtons
{
	[self.instructionLabel setStringValue:NSLocalizedString(@"You are moving an application to the trash, do you want to move its associated system files too?", nil)];
	[self.explanationLabel setStringValue:NSLocalizedString(@"No files will be deleted until you empty the trash.", nil)];
	[self.warningLabel setStringValue:NSLocalizedString(@"WARNING: The application may only be updating itself.", nil)];
	
	[self.leaveFilesButton setStringValue:NSLocalizedString(@"Leave files", nil)];
	[self.moveFilesButton setStringValue:NSLocalizedString(@"Move files", nil)];
}

- (void)setUpWindow
{
	BOOL isExpanded = [[NSUserDefaults standardUserDefaults] boolForKey:ATPreferencesIsExpanded];
	NSCellStateValue state;
	if (isExpanded)
	{
		state = NSOnState;
	}
	else
	{
		state = NSOffState;
	}
	[self resizeWindowForState:state];
	[self.showFileListButton setState:state];
}

- (NSArray*)arrayControllerSortDescriptors
{
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"path"
																	 ascending:YES];
	return @[sortDescriptor];
}

- (void)sendApplicationDidFinishLaunchingNotification
{
	[self.notificationCenter postNotificationName:ATApplicationFinishedLaunchingNotification
										   object:nil];
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
	for (NSDictionary *entry in self.arrayController.arrangedObjects)
	{
		BOOL shouldBeRemoved = ((NSNumber*)entry[@"shouldBeRemoved"]).boolValue;
		if (shouldBeRemoved)
		{
			[paths addObject:entry[@"fullPath"]];
		}
	}
	
	[self.applicationController moveFilesToTrash:paths];
	NSArray *entries = self.arrayController.arrangedObjects;
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
	NSCellStateValue state = sender.state;
	[self resizeWindowForState:sender.state];
	BOOL isExpanded;
	if (state == NSOnState)
	{
		isExpanded = YES;
	}
	else
	{
		isExpanded = NO;
	}
	[[NSUserDefaults standardUserDefaults] setBool:isExpanded forKey:ATPreferencesIsExpanded];
	[[NSUserDefaults standardUserDefaults] synchronize];
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

#pragma mark - APTPreferencePaneDelegate methods

- (void)preferencePaneRequestsVersion:(id)sender
{
	NSString *bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
	NSDictionary *userInfo = @{ATBackgroundProcessVersion: bundleIdentifier};
	[self.notificationCenter postNotificationName:ATApplicationGetVersionData
										   object:nil
										 userInfo:userInfo
							   deliverImmediately:YES];
}

- (void)preferencePaneRequestsTermination:(id)sender
{
	[[NSApplication sharedApplication] terminate:self];
}

@end
