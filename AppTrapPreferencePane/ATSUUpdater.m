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
 Created by Kumaran Vijayan on 13/07/09.
 */

#import "ATSUUpdater.h"


@implementation ATSUUpdater
+(id)sharedUpdater {
	return [self updaterForBundle:[NSBundle bundleForClass:[self class]]];
}
@end
