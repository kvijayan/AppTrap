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

- (void)addPathForDeletion:(NSString *)path
{
    // Expand any tildes in the path
    NSString *fullPath = [path stringByExpandingTildeInPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
        // Get the display name of the file or directory
        NSString *displayName = [[NSFileManager defaultManager] displayNameAtPath:fullPath];
        
        // Get the abbreviated path
        NSString *shortPath = [fullPath stringByAbbreviatingWithTildeInPath];
        
        // Construct a multiline attributed string for table display
        NSMutableString *nameString = [[NSMutableString alloc] initWithFormat:@"%@\n%@", displayName, shortPath];
        NSMutableAttributedString *name = [[NSMutableAttributedString alloc] initWithString:nameString];
        
        // First row (regular system font)
        NSDictionary *firstRowAttributes = [NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:13.0]
                                                                    forKey:NSFontAttributeName];
        
        // Second row (smaller, gray text)
        NSDictionary *secondRowAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSFont systemFontOfSize:11.0], NSFontAttributeName,
            [NSColor grayColor], NSForegroundColorAttributeName,
            nil];
        
        // Apply the attributes
        [name addAttributes:firstRowAttributes range:NSMakeRange(0,[displayName length])];
        [name addAttributes:secondRowAttributes range:NSMakeRange([displayName length] + 1,[shortPath length])];
        
        // Get the icon
        NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:fullPath];
        [icon setSize:NSMakeSize(32, 32)];
        
        // Throw this stuff into a new dict...
        NSMutableDictionary *newEntry = [NSMutableDictionary dictionary];
        [newEntry setValue:fullPath forKey:@"fullPath"];
        [newEntry setValue:name forKey:@"name"];
        [newEntry setValue:icon forKey:@"icon"];
        [newEntry setValue:[NSNumber numberWithBool:YES] forKey:@"shouldBeRemoved"];
        
        // ...and add it to the list
        [self addObject:newEntry];
        
        // Clear the temporary attributed strings
        [nameString release];
        [name release];
    }
}

@end
