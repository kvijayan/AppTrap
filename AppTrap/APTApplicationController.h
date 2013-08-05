//
//  APTApplicationController.h
//  AppTrap
//
//  Created by Kumaran Vijayan on 2013-05-15.
//
//

#import <AppKit/AppKit.h>

@class APTApplicationController;

@protocol APTApplicationControllerDelegate <NSObject>
@required
- (void)applicationController:(APTApplicationController*)applicationController didFindFiles:(NSArray*)files;
@end

@interface APTApplicationController : NSObject

@end
