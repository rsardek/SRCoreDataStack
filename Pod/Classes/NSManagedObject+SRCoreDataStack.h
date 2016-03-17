//
//  NSManagedObject+SRCoreDataStack.h
//  CoreDataStack
//
//  Created by Sardorbek on 3/13/16.
//  Copyright © 2016 Sardorbek. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (SRCoreDataStack)

+(instancetype)insertNewObjectIntoContext:(NSManagedObjectContext*)context;

@end
