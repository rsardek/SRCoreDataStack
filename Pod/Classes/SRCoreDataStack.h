//
//  SRCoreDataStack.h
//
//  Created by Sardorbek on 3/13/16.
//  Copyright © 2016 Sardorbek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NSManagedObject+SRCoreDataStack.h"


/**
 *  Block used to parse a json object into a custom NSManagedObject instance
 *
 *  @param obj        json value of element
 *  @param mo         NSManagedObject instance on which to fill in the attributes
 *  @param currentCtx current context object; needed when generating parent-child relationships for NSManagedObjects
 *
 *  @return modified NSManagedObject instance
 */
typedef NSManagedObject*(^SRCoreDataStackConfigurationBlock)(NSDictionary *obj, NSManagedObject *mo, NSManagedObjectContext *currentCtx);

@interface SRCoreDataStack : NSObject

/**
 *  Context which is used to interact with persisted data
 */
@property (readonly, strong) NSManagedObjectContext *managedObjectContext;


/**
 *  Persists remote objects in background context
 *
 *  @param objects            array of remote wire objects
 *  @param entityName         entity to save the objects into
 *  @param wireAttributeName  a main attribute of incoming data element
 *  @param localAttributeName a main attributes of local, entity attribute
 *  @param configuration      configuration block
 */
-(void)saveObjects:(NSArray*)objects inEntity:(NSString*)entityName withWireAttribute:(NSString*)wireAttributeName andLocalAttribute:(NSString*)localAttributeName andConfiguration:(SRCoreDataStackConfigurationBlock)configuration;


/**
 *  Persists remote objects in background context
 *
 *  @param objects       array of remote wire objects
 *  @param entityName    entity to save the objects into
 *  @param attribute     a property used to distinguish one element from another, ie, 'id'; incoming json element and the custom NSManagedObject both must have such attribute
 *  @param configuration configuration block
 */
-(void)saveObjects:(NSArray*)objects inEntity:(NSString*)entityName withCommonAttribute:(NSString*)attribute andConfiguration:(SRCoreDataStackConfigurationBlock)configuration;


/**
 *  Persists remote objects in background context; removes locals objects that don't match with the wire objects
 *
 *  @param objects       array of remote wire objects
 *  @param deleteLocals  flag whether to delete non-matching local objects
 *  @param entityName    entity to save the objects into
 *  @param attribute     a property used to distinguish one element from another, ie, 'id'; incoming json element and the custom NSManagedObject both must have such attribute
 *  @param configuration configuration block
 */
-(void)saveObjects:(NSArray*)objects deleteNonMatchingLocals:(BOOL)deleteLocals inEntity:(NSString*)entityName withWireAttribute:(NSString*)wireAttributeName andLocalAttribute:(NSString*)localAttributeName andConfiguration:(SRCoreDataStackConfigurationBlock)configuration;


/**
 *  Creates a stack with the provided model name with the default store type 'Sqlite'
 *
 *  @param dataModelName       Name of your model object
 @return stack
 */
+(instancetype)defaultStackForDataModel:(NSString*)dataModelName;

/**
 *  Creates a stack with the provided model name and store type
 *
 *  @param dataModelName       Name of your model object
 *  @param dataModelName       Store type
 @return stack
 */
-(instancetype)initStackWithDataModel:(NSString *)dataModelName andStoreType:(NSString *)storeType;



/**
 *  Fetches managed objects from the given entity, and predicate using default 'main thread' context
 *
 *  @param entityName       Name of the entity
 *  @param predicate       Predicate
 *  @param moc       Context on which to make the query
 
 @return array of found managed objects
 */
-(NSArray*)fetchObjectsFromEntity:(NSString*)entityName withPredicate:(NSPredicate*)predicate atContext:(NSManagedObjectContext*)moc;


/**
 *  Fetches the number of objects in the given entity and predicate using 'main thread' context
 *
 *  @param entityName       Name of the entity
 *  @param predicate       Predicate
 @return number of objects
 */
-(NSUInteger)numberOfRecordsInEntity:(NSString*)entityName withPredicate:(NSPredicate*)predicate;


@end
