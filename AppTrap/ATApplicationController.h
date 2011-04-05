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

#import <Cocoa/Cocoa.h>

@class ATArrayController;

/**
 * The main controller for the AppTrap background process. Handles applications
 * that are trashed and the user input regarding the removal of the associated
 * preference files.
 */
@interface ATApplicationController : NSObject
{
    IBOutlet NSWindow *mainWindow;
    IBOutlet ATArrayController *listController;
    NSCellStateValue isExpanded;
    
    NSMutableSet *whitelist;
    NSString *pathToTrash;
    NSSet *applicationsPaths;
    NSSet *libraryPaths;
    
    IBOutlet NSTextField *dialogueText1;
    IBOutlet NSTextField *dialogueText2;
	IBOutlet NSTextField *dialogueText3;
    IBOutlet NSButton *leaveButton;
    IBOutlet NSButton *moveButton;
    IBOutlet NSButton *disclosureTriangle;
    IBOutlet NSScrollView *filelistView;
}

/**
 * Initialize this ATApplicationController's trash path string for later use.
 */
- (void)setupTrashFolderPath;

/**
 * Add a path to UKKQueue to be watched and register ourself to handle
 * UKFileWatcherWriteNotification notifications.
 */
- (void)registerForWriteNotifications;

/**
 * Unregister this controller from handling any notifications.
 */
- (void)unregisterForWriteNotifications;

/**
 * Called by the NSNotificationCenter when file(s) are moved to the trash.
 * Finds associated preference files for any applications that were part of the
 * move and presents the main window.
 *
 * @param[in] notification The NSNotification that invoked this method.
 */
- (void)handleWriteNotification:(NSNotification *)notification;

/**
 * Return all applications currently in the trash, as an NSArray.
 *
 * @return an NSArray containing the directory locations of each application in
 * the trash
 */
- (NSArray *)applicationsInTrash;

/**
 * Find the number of user-visible items in the trash.
 */
- (int)numberOfVisibleItemsInTrash;

/**
 * Find all the files that match filename in a given directory.
 *
 * @param[in] filename The name of the file you want to find.
 * @param[in] path The directory that will be searched for filename.
 * @return an NSArray for all the matches that are found.
 */
- (NSArray *)matchesForFilename:(NSString *)filename atPath:(NSString *)path;

/**
 * Called by the NSNotificationCenter when the preference pane's "Stop AppTrap"
 * button is clicked.
 *
 * @param[in] aNotification The NSNotification that invoked this method.
 */
- (void)terminateAppTrap:(NSNotification *)aNotification;

#pragma mark -
#pragma mark Interface Actions

/**
 * Move the selected items to the trash.
 *
 * @param[in] sender The button that was clicked.
 */
- (IBAction)moveCurrentItemsToTrash:(id)sender;

/**
 * Close the pop-up dialog and don't move any files.
 *
 * @param[in] sender The cancel button that was clicked.
 */
- (IBAction)cancel:(id)sender;

/**
 * Show or hide the list of files to be moved by enlarging the main window.
 *
 * @param[in] sender The disclosure triangle that was clicked.
 * @deprecated This method is no longer useful. Use expandOrShrink: instead.
 */
- (IBAction)toggleFilelist:(id)sender;

/**
 * Show or hide the list of files to be moved by enlarging the main window.
 *
 * @param[in] sender The disclosure triangle that was clicked.
 */
- (IBAction)expandOrShrink:(id)sender;

- (IBAction)tempExpandOrShrink:(id)sender;

#pragma mark -
#pragma mark Window resizing

/**
 * Extends the main window vertically by amount (which can be negative).
 *
 * @param[in] amount The amount by which you want to enlarge the main window.
 * Can be negative in order to shrink the window.
 */
- (void)extendMainWindowBy:(int)amount;

/**
 * Expand or contract the main window.
 *
 * @param[in] flag The BOOL specifying whether the main window should expand
 * (YES) or contract (NO).
 */
- (void)setExpanded:(BOOL)flag;
@end
