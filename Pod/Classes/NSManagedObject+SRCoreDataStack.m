//
//  NSManagedObject+SRCoreDataStack.m
//  CoreDataStack
//
//  Created by Sardorbek on 3/13/16.
//  Copyright © 2016 Sardorbek. All rights reserved.
//

#import "NSManagedObject+SRCoreDataStack.h"

@implementation NSManagedObject (SRCoreDataStack)

+(instancetype)insertNewObjectIntoContext:(NSManagedObjectContext *)context
{
   return [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([self class]) inManagedObjectContext:context];
}
@end
