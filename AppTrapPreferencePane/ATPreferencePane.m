/*
-----------------------------------------------
  APPTRAP LICENSE

  "Do what you want to do,
  and go where you're going to
  Think for yourself,
  'cause I won't be there with you"

  You are completely free to do anything with
  this source code, but if you try to make
  money on it you will be beaten up with a
  large stick. I take no responsibility for
  anything, and this license text must
  always be included.

  Markus Amalthea Magnuson <markus.magnuson@gmail.com>
-----------------------------------------------
*/

#import "ATPreferencePane.h"
#import "ATNotifications.h"
#import "ATVariables.h"
//#import "UKLoginItemRegistry.h"

static NSString *AppTrapBackgroundBundleIdentifier = @"com.KumaranVijayan.AppTrap";
static NSString *AppTrapBackgroundBundleIdentifierOld = @"se.konstochvanligasaker.AppTrap";

@implementation ATPreferencePane

- (void)mainViewDidLoad
{
	[[ATSUUpdater sharedUpdater] resetUpdateCycle];
	[[ATSUUpdater sharedUpdater] setDelegate:self];
		
    // Setup the application path
    appPath = [[[self bundle] pathForResource:@"AppTrap" ofType:@"app"] retain];
	NSLog(@"appPath: %@", appPath);
	
	[automaticallyCheckForUpdate setState:[[ATSUUpdater sharedUpdater] automaticallyChecksForUpdates]];

    // Restart AppTrap in case the user just updated to a new version
    // TODO: Check AppTrap's version against the prefpane version and only restart if they differ
    // TODO: Leave this off for now, something goes haywire on startup
    /*if ([self appTrapIsRunning])
        [self launchAppTrap];*/
	CFURLRef appPathURL = (CFURLRef)[appPath copy];

    // Check if application is in login items
    if ([self inLoginItems:LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL) forPath:appPathURL]) {
		[startOnLoginButton setState:NSOnState];
	} else {
		[startOnLoginButton setState:NSOffState];
	}
	
	CFRelease(appPathURL);
    
    // Display read me file
    [aboutView readRTFDFromFile:[[self bundle] pathForResource:@"Read Me" ofType:@"rtf"]];
    // Replace the {APPTRAP_VERSION} symbol with the version number
    NSRange versionSymbolRange = [[aboutView string] rangeOfString:@"{APPTRAP_VERSION}"];
    if (versionSymbolRange.location != NSNotFound){
        [[aboutView textStorage] replaceCharactersInRange:versionSymbolRange withString:[[self bundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
	}

    // Register for notifications from AppTrap
    NSDistributedNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
    
    [nc addObserver:self
           selector:@selector(updateStatus)
               name:ATApplicationFinishedLaunchingNotification
             object:nil
 suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
    
    [nc addObserver:self
           selector:@selector(updateStatus)
               name:ATApplicationTerminatedNotification
             object:nil
 suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
	
	[nc addObserver:self
		   selector:@selector(checkBackgroundProcessVersion:) 
			   name:ATApplicationGetVersionData 
			 object:nil 
 suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
	
	[nc postNotificationName:ATApplicationSendVersionData 
					  object:nil 
					userInfo:nil 
		  deliverImmediately:YES];	
}

- (void)checkBackgroundProcessVersion:(NSNotification*)notification {
	NSLog(@"checkBackgroundProcessVersion");
	NSLog(@"notification: %@", [notification description]);
	NSLog(@"notification userInfo class: %@", [[notification userInfo] className]);
	NSLog(@"notification userInfo: %@", [[notification userInfo] description]);
	
	NSString *backgroundProcessVersion = [notification userInfo][ATBackgroundProcessVersion];
	int backgroundProcessVersionInt = [backgroundProcessVersion intValue];
	NSString *prefpaneVersion = [[self bundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	int prefpaneVersionInt = [prefpaneVersion intValue];
	
	if (prefpaneVersionInt != backgroundProcessVersionInt) {
		NSBeginAlertSheet(@"AppTrap", 
						  NSLocalizedStringFromTableInBundle(@"Restart AppTrap", nil, [self bundle], @""), 
						  NSLocalizedStringFromTableInBundle(@"Don't restart AppTrap", nil, [self bundle], @""), 
						  nil, 
						  [startStopButton window], 
						  self, 
						  @selector(sheetDidEnd:returnCode:contextInfo:), 
						  nil, 
						  nil, 
						  NSLocalizedStringFromTableInBundle(@"The background process is an older version. Would you like to restart it with the newer version?", nil, [self bundle], @""));
	}
}

- (void)checkBackgroundProcessVersion {
	NSDistributedNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
	
	[nc postNotificationName:ATApplicationSendVersionData 
					  object:nil 
					userInfo:nil 
		  deliverImmediately:YES];	
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
	if (returnCode == NSAlertDefaultReturn) {
		[startStopButton setEnabled:NO];
		[restartingAppTrapIndicator startAnimation:nil];
		[restartingAppTrapTextField setHidden:NO];
		[self terminateAppTrap];
		[self performSelector:@selector(restartWithNewVersion) withObject:nil afterDelay:5];
	}
}

- (void)restartWithNewVersion {
	[self launchAppTrap];
	[restartingAppTrapIndicator stopAnimation:nil];
	[restartingAppTrapTextField setHidden:YES];
	[startStopButton setEnabled:YES];
}

- (void)didSelect
{
	CFURLRef appPathURL = (CFURLRef)[appPath copy];
	
	if ([self inLoginItems:LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL) 
				   forPath:appPathURL]) {
		[startOnLoginButton setState:NSOnState];
	} else {
		[startOnLoginButton setState:NSOffState];
	}
	CFRelease(appPathURL);
	
    [self updateStatus];
	[self checkBackgroundProcessVersion];
}

- (void)updateStatus
{
    if ([self appTrapIsRunning]) {
        // Need to specify bundle because we're a prefpane
        [statusText setStringValue:NSLocalizedStringFromTableInBundle(@"Active", nil, [self bundle], @"")];
        [statusText setTextColor:[NSColor blackColor]];
        [startStopButton setTitle:NSLocalizedStringFromTableInBundle(@"Stop AppTrap", nil, [self bundle], @"")];
    }
    else {
        // Need to specify bundle because we're a prefpane
        [statusText setStringValue:NSLocalizedStringFromTableInBundle(@"Inactive", nil, [self bundle], @"")];
        [statusText setTextColor:[NSColor grayColor]];
        [startStopButton setTitle:NSLocalizedStringFromTableInBundle(@"Start AppTrap", nil, [self bundle], @"")];
    }
    
    // Extra check after five seconds in case the launch/termination was delayed
    [self performSelector:@selector(updateStatus)
			   withObject:nil
			   afterDelay:5.0];
}

- (void)launchAppTrap
{    
    // Try to launch AppTrap
	NSLog(@"launching AppTrap");
	NSURL *appURL = [NSURL fileURLWithPath:appPath];
	unsigned options = NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchWithoutActivation | NSWorkspaceLaunchAsync;
    
	BOOL launched = [[NSWorkspace sharedWorkspace] openURLs:@[appURL]
                                    withAppBundleIdentifier:nil
                                                    options:options
                             additionalEventParamDescriptor:nil
                                          launchIdentifiers:NULL];
    
    if (!launched)
        NSLog(@"Couldn't launch AppTrap!");
}

- (void)terminateAppTrap
{
	NSLog(@"terminating Apptrap");
    NSDistributedNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
    [nc postNotificationName:ATApplicationShouldTerminateNotification
                      object:nil
                    userInfo:nil
          deliverImmediately:YES];
}

- (BOOL)appTrapIsRunning
{
	id <NSFastEnumeration> applications = [NSRunningApplication runningApplicationsWithBundleIdentifier:AppTrapBackgroundBundleIdentifier];
	for (NSRunningApplication *application in applications)
	{
		NSString *bundleIdentifier = application.bundleIdentifier;
		if ([bundleIdentifier isEqualToString:AppTrapBackgroundBundleIdentifier])
		{
			return YES;
		}
	}
	return NO;
}

#pragma mark -
#pragma mark Update check

- (SUUpdater*)updater {
	return [SUUpdater updaterForBundle:[NSBundle bundleForClass:[self class]]];
}

- (IBAction)automaticallyCheckForUpdate:(id)sender {
	[[ATSUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:[sender state]];
}

- (IBAction)checkForUpdate:(id)sender {
	[[ATSUUpdater sharedUpdater] checkForUpdates:sender];
}

#pragma mark -
#pragma mark Login items
- (BOOL)inLoginItems:(LSSharedFileListRef)theLoginItemsRefs forPath:(CFURLRef)thePath
{
	UInt32 seedValue;
	
	// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
	// and pop it in an array so we can iterate through it to find our item.
	NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
	for (id item in loginItemsArray) {		
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
			if ([[(NSURL *)thePath path] hasPrefix:appPath]) {
				return YES;
			}
		}
	}
	
	return NO;
}

- (void)addToLoginItems:(LSSharedFileListRef )theLoginItemsRefs forPath:(CFURLRef)thePath
{
	LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(theLoginItemsRefs, kLSSharedFileListItemLast, NULL, NULL, thePath, NULL, NULL);		
	if (item) {
		CFRelease(item);
	}
}

- (void)removeFromLoginItems:(LSSharedFileListRef )theLoginItemsRefs forPath:(CFURLRef)thePath
{
	UInt32 seedValue;
	
	// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
	// and pop it in an array so we can iterate through it to find our item.
	NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
	for (id item in loginItemsArray) {		
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &thePath, NULL) == noErr) {
			if ([[(NSURL *)thePath path] hasPrefix:appPath])
				LSSharedFileListItemRemove(theLoginItemsRefs, itemRef); // Deleting the item
		}
	}
	
	[loginItemsArray release];
}

#pragma mark -
#pragma mark Interface actions

- (IBAction)startStopAppTrap:(id)sender
{
	
    if ([self appTrapIsRunning]) {
        [self terminateAppTrap];
    } else {
        [self launchAppTrap];
	}
}

- (IBAction)startOnLogin:(id)sender
{
	CFURLRef appPathURL = (CFURLRef)[NSURL fileURLWithPath:appPath];
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);

    if ([sender state] == NSOnState) {
        [self addToLoginItems:loginItems forPath:appPathURL];
	} else {
        [self removeFromLoginItems:loginItems forPath:appPathURL];
	}
	
    CFRelease(loginItems);
}

- (IBAction)visitWebsite:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"http://onnati.net/apptrap/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
