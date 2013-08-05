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

#import "ATArrayController.h"

@implementation ATArrayController

- (void)addPathsForDeletion:(NSArray*)paths
{
    for (NSString *path in paths)
    {
        [self addPathForDeletion:path];
    }
}

- (void)addPathForDeletion:(NSString *)path
{
    // Expand any tildes in the path
    NSString *fullPath = [path stringByExpandingTildeInPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath])
	{
		NSString *name = [[NSFileManager defaultManager] displayNameAtPath:fullPath];
		NSString *path = fullPath.stringByAbbreviatingWithTildeInPath.stringByDeletingLastPathComponent;
		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:fullPath];
		[icon setSize:NSMakeSize(32.0, 32.0)];
		NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithObjectsAndKeys:path, @"path", name, @"name", icon, @"icon", @YES, @"shouldBeRemoved", nil];
		[self addObject:entry];
    }
}

@end
