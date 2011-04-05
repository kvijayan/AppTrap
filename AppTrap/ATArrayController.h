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

/**
 * A subclass of NSArrayController whose purpose is to populate the table view
 * in the main window.
 */
@interface ATArrayController : NSArrayController
{
}

/**
 * Add a path to delete from the disk.
 *
 * @param[in] path The string representing the path to the file that should be
 * deleted.
 */
- (void)addPathForDeletion:(NSString *)path;

@end
