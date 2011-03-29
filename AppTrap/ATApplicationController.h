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

- (void)registerForWriteNotifications;
- (void)unregisterForWriteNotifications;
- (NSArray *)applicationsInTrash;
- (void)handleWriteNotification:(NSNotification *)notification;
- (int)numberOfVisibleItemsInTrash;
- (NSArray *)matchesForFilename:(NSString *)filename atPath:(NSString *)path;
- (IBAction)moveCurrentItemsToTrash:(id)sender;
- (IBAction)cancel:(id)sender;
- (void)terminateAppTrap:(NSNotification *)aNotification;

#pragma mark -
#pragma mark Window resizing

- (IBAction)toggleFilelist:(id)sender;
- (void)extendMainWindowBy:(int)amount;
- (void)setExpanded:(BOOL)flag;
- (IBAction)expandOrShrink:(id)sender;
- (IBAction)tempExpandOrShrink:(id)sender;
@end
