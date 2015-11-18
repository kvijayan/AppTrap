//
//  PrefPaneTests.m
//  PrefPaneTests
//
//  Created by Kumaran Vijayan on 2013-08-18.
//
//

#import "PrefPaneTests.h"

@implementation PrefPaneTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testUserVersionNumber
{
	NSBundle *bundle = [NSBundle bundleForClass:[PrefPaneTests class]];
	NSString *path = bundle.bundlePath;
	path = path.stringByDeletingLastPathComponent;
	path = [path stringByAppendingPathComponent:@"AppTrap.prefPane"];
	bundle = [NSBundle bundleWithPath:path];
	NSString *shortVersionStringKey = @"CFBundleShortVersionString";
	NSString *prefpaneVersion = [bundle objectForInfoDictionaryKey:shortVersionStringKey];
	
	path = [bundle pathForResource:@"AppTrap" ofType:@"app"];
	bundle = [NSBundle bundleWithPath:path];
	NSString *backgroundVersion = [bundle objectForInfoDictionaryKey:shortVersionStringKey];
	
	XCTAssertEqualObjects(prefpaneVersion, backgroundVersion, @"");
}

- (void)testVersionNumber
{
	NSBundle *bundle = [NSBundle bundleForClass:[PrefPaneTests class]];
	NSString *path = bundle.bundlePath;
	path = path.stringByDeletingLastPathComponent;
	path = [path stringByAppendingPathComponent:@"AppTrap.prefPane"];
	bundle = [NSBundle bundleWithPath:path];
	NSString *prefpaneVersion = [bundle objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
	
	path = [bundle pathForResource:@"AppTrap" ofType:@"app"];
	bundle = [NSBundle bundleWithPath:path];
	NSString *backgroundVersion = [bundle objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
	
	XCTAssertEqualObjects(prefpaneVersion, backgroundVersion, @"");
}

@end
