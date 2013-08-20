//
//  APTPreferencePaneDelegate.h
//  AppTrapPreferencePane
//
//  Created by Kumaran Vijayan on 2013-08-17.
//
//

#import <Foundation/Foundation.h>

@protocol APTPreferencePaneDelegate <NSObject>
/**
 * The preference pane is requesting the version number from the background process. Send
 * a distributed notification with this information.
 */
- (void)preferencePaneRequestsVersion:(id)sender;

/**
 * The preference pane is requesting that the background process be terminated.
 */
- (void)preferencePaneRequestsTermination:(id)sender;
@end
