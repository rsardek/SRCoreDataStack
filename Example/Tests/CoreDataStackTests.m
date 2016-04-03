//
//  CoreDataStackTests.m
//  SRCoreDataStack
//
//  Created by Sardorbek on 3/27/16.
//  Copyright © 2016 Sardorbek Ruzmatov. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TestStack.h"

@interface CoreDataStackTests : XCTestCase
{
   TestStack *stack;
}
@end

@implementation CoreDataStackTests

- (void)setUp {
   [super setUp];
   stack = [TestStack new];
   NSLog(@"test stack is: %@", stack);
   
   // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
   // Put teardown code here. This method is called after the invocation of each test method in the class.
   [super tearDown];
   stack = nil;
}

- (void)testExample {
   // This is an example of a functional test case.
   // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
   // This is an example of a performance test case.
   [self measureBlock:^{
      // Put the code you want to measure the time of here.
   }];
}


@end
