//
//  TestStack.m
//  SRCoreDataStack
//
//  Created by Sardorbek on 3/27/16.
//  Copyright © 2016 Sardorbek Ruzmatov. All rights reserved.
//

#import "TestStack.h"

@implementation TestStack

-(instancetype)init
{
   return [[super class] defaultStackForDataModel:@"Example"];
   //[super initStackWithModel:@"Example" andStoreType:NSInMemoryStoreType];
}

@end
