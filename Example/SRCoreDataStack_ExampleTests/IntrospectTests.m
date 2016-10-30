//
//  IntrospectTests.m
//  SRCoreDataStack
//
//  Created by Sardorbek on 30/10/2016.
//  Copyright © 2016 Sardorbek Ruzmatov. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TesterStack.h"
#import "Movie.h"
#import "MovieGenre.h"

@interface IntrospectTests : XCTestCase
{
    TesterStack *stack;
}
@end

@implementation IntrospectTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    stack = [[TesterStack alloc] initStackWithDataModel:@"Tester" andStoreType:NSInMemoryStoreType];
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    stack = nil;
    [super tearDown];
}

-(void)testMocIsNotNil
{
    XCTAssertNotNil(stack.managedObjectContext);
}
-(void)testHasStore
{
    XCTAssertNotNil(stack.theStore);
}
-(void)testHasInMemoryTypeStore
{
    XCTAssertTrue([stack.theStore.persistentStores.lastObject.type isEqualToString:NSInMemoryStoreType]);
}
-(void)testHasModel
{
    XCTAssertNotNil(stack.theModel);
}
@end
