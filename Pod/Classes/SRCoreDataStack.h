//
//  SRCoreDataStack.h
//  CoreDataStack
//
//  Created by Sardorbek on 3/13/16.
//  Copyright © 2016 Sardorbek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NSManagedObject+SRCoreDataStack.h"

typedef NSManagedObject*(^ParseBlock)(NSDictionary *obj, NSManagedObject *mo, NSManagedObjectContext *currentCtx);

@interface SRCoreDataStack : NSObject

// public context
@property (readonly, strong) NSManagedObjectContext *managedObjectContext;

-(void)saveInBackground:(NSArray*)wireObjects ofType:(NSString*)type ofCommonProperty:(NSString*)property usingTemplate:(ParseBlock)aTemplate;

-(void)saveInBackground:(NSArray *)wireObjects ofType:(NSString *)type ofWireProperty:(NSString *)wire ofLocalProperty:(NSString *)local usingTemplate:(ParseBlock)aTemplate;


-(instancetype)initWithModelName:(NSString*)modelName;

@end
