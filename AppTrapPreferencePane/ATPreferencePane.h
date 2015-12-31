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
 * Enable or disable automatic update checking, depending on the sender's state.
 * Called by a checkbox.
 *
 * @param[in] sender The control that invoked this method (likely a checkbox).
 */
- (IBAction)automaticallyCheckForUpdate:(id)sender;

/**
 * Check if there is an update. Called by a button.
 *
 * @param[in] sender The control that invoked this method (likely a button).
 */
- (IBAction)checkForUpdate:(id)sender;

/**
 * Start or stop the AppTrap background process. Called by a button.
 *
 * @param[in] sender The control that invoked this method (likely a button).
 */
- (IBAction)startStopAppTrap:(id)sender;

/**
 * Add or remove the AppTrap background process from the user's login items,
 * depending on the state of sender. Called by a checkbox.
 *
 * @param[in] sender The control that invoked this method (likely a checkbox).
 */
- (IBAction)startOnLogin:(id)sender;

/**
 * Open the AppTrap website in the user's default browser. Called by a button.
 *
 * @param[in] sender The control that invoked this method (likely a checkbox).
 */
- (IBAction)visitWebsite:(id)sender;

@end
