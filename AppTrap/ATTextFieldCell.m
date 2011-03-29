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

#import "ATTextFieldCell.h"

@implementation ATTextFieldCell

// Alignment for the name column in the filelist
// TODO: Actually do a true vertical alignment
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    cellFrame.origin.y += 7.0;
    cellFrame.size.height -= 7.0;
    
    [super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
