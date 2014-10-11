//
//  AppTrapTests.m
//  AppTrapTests
//
//  Created by Kumaran Vijayan on 2014-10-10.
//
//

@import Foundation.NSString;

#import <XCTest/XCTest.h>

#import "APTApplicationController.h"

@interface APTApplicationController ()
@property (nonatomic, readonly) NSString *pathToTrash;
@property (nonatomic, readonly) NSArray *libraryPaths;
@end

@interface AppTrapTests : XCTestCase
@property (nonatomic, readonly) NSString *pathToTrash;
@property (nonatomic, readonly) NSArray *libraryPaths;
@property (nonatomic) APTApplicationController *controller;
@end

@implementation AppTrapTests

- (void)setUp {
    [super setUp];
    APTApplicationController *controller = [APTApplicationController new];
    [self setController:controller];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPathToTrash
{
    NSString *pathToTrash = self.controller.pathToTrash;
    XCTAssertNotNil(pathToTrash, @"");
    NSString *trash = pathToTrash.lastPathComponent;
    XCTAssertEqualObjects(trash, @".Trash", @"");
}

- (void)testLibraryPaths
{
    NSArray *libraryPaths = self.controller.libraryPaths;
    XCTAssertNotNil(libraryPaths, @"");
    XCTAssertTrue([libraryPaths count] > 0, @"");
}

@end
