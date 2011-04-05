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

#import <PreferencePanes/PreferencePanes.h>
#import "ATSUUpdater.h"

/**
 * The main controller class for the preference pane. Handles all of the logic.
 */
@interface ATPreferencePane : NSPreferencePane 
{
    NSString *appPath;
    
    IBOutlet NSTextField *statusText;
    IBOutlet NSButton *startStopButton;
    IBOutlet NSButton *startOnLoginButton;
	IBOutlet NSButton *automaticallyCheckForUpdate;
    IBOutlet NSTextView *aboutView;
	IBOutlet NSProgressIndicator *restartingAppTrapIndicator;
	IBOutlet NSTextField *restartingAppTrapTextField;
	IBOutlet NSWindow *window;
	IBOutlet NSWindow *appTrapRestartWindow;
}

/**
 * Check to see if AppTrap is running and update the user interface accordingly.
 */
- (void)updateStatus;

/**
 * Launch the AppTrap background process.
 */
- (void)launchAppTrap;

/**
 * Terminate the AppTrap background process. Sends a notification that the
 * background process receives.
 */
- (void)terminateAppTrap;

/**
 * Returns a BOOL indicating whether AppTrap is running or not.
 *
 * @return the BOOL indicating whether AppTrap is running.
 */
- (BOOL)appTrapIsRunning;

/**
 * Method called by the NSDistributedNotificationCenter on behalf of the
 * background process. Checks the background process version in the userInfo
 * dictionary in notification and opens an appropriate alert sheet if the
 * background process version is different from the preference pane version.
 *
 * @param[in] notification The NSNotification that invoked this method.
 */
- (void)checkBackgroundProcessVersion:(NSNotification*)notification;

/**
 * Send a notification to the background process asking for its version number.
 */
- (void)checkBackgroundProcessVersion;

/**
 * Check to see if the application referenced by thePath is in the user's list
 * of login items.
 *
 * @param[in] theLoginItemsRefs The list of the user's login items.
 * @param[in] thePath The URL to the application in question.
 * @return a BOOL indicating whether the application referenced by thePath is in
 * the user's list of login items.
 * @todo Modify this method, or make a new one, that gets the login items on its
 * own (without a parameter).
 */
- (BOOL)inLoginItems:(LSSharedFileListRef)theLoginItemsRefs forPath:(CFURLRef)thePath;

/**
 * Add the application referenced by thePath to the list of user's login items.
 *
 * @param[in] theLginItemsRefs The list of user's login items.
 * @param[in] thePath The URL to the application to be added.
 */
- (void)addToLoginItems:(LSSharedFileListRef )theLoginItemsRefs forPath:(CFURLRef)thePath;

/**
 * Remove the application referenced by thePath from the list of user's login
 * items.
 *
 * @param[in] theLoginItemsRefs The list of user's login items.
 * @param[in] thePath The URL to the application to be added to the list of
 * login items.
 */
- (void)removeFromLoginItems:(LSSharedFileListRef )theLoginItemsRefs forPath:(CFURLRef)thePath;

- (IBAction)automaticallyCheckForUpdate:(id)sender;
- (IBAction)checkForUpdate:(id)sender;
- (IBAction)startStopAppTrap:(id)sender;
- (IBAction)startOnLogin:(id)sender;
- (IBAction)visitWebsite:(id)sender;

@end
