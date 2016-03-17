//
//  SRCoreDataStack.m
//  CoreDataStack
//
//  Created by Sardorbek on 3/13/16.
//  Copyright © 2016 Sardorbek. All rights reserved.
//

#import "SRCoreDataStack.h"
#import "NSManagedObject+SRCoreDataStack.h"
#import "Constants.h"

#warning improve code later
// preferably, create singleton initializer with this name passed as param
NSString *modelName = @"<GIVE NAME OF MODEL LATER>";

@interface SRCoreDataStack()

@property (readonly, strong) NSManagedObjectContext *masterManagedObjectContext;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;

-(NSManagedObjectContext*)workerContext;
-(void)saveContext:(NSManagedObjectContext *)moc;


// helpers
-(NSUInteger)numberOfRecordsIn:(NSString*)entityName withPredicate:(NSPredicate*)predicate;
-(NSArray*)fetchObjectsFrom:(NSString*)entityName withPredicate:(NSPredicate*)predicate atContext:(NSManagedObjectContext*)moc;
-(NSArray*)fetchObjectsFrom:(NSString*)entityName withObjectIDs:(NSArray*)objectsIDs atContext:(NSManagedObjectContext*)moc;


@end
@implementation SRCoreDataStack

@synthesize masterManagedObjectContext = _masterManagedObjectContext;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

-(void)saveInBackground:(NSArray *)wireObjects ofType:(NSString *)type ofCommonProperty:(NSString *)property usingTemplate:(ParseBlock)aTemplate
{
   [self saveInBackground:wireObjects ofType:type ofWireProperty:property ofLocalProperty:property usingTemplate:aTemplate];
}
-(void)saveInBackground:(NSArray *)wireObjects ofType:(NSString *)type ofWireProperty:(NSString *)wire ofLocalProperty:(NSString *)local usingTemplate:(ParseBlock)aTemplate
{
   if (![wireObjects count]) return;
   
   NSAssert(type, @"Model type cannot be nil");
   
   // in future, use same property on both sides
   NSString *wireKey = wire;
   NSString *localKey = local;
   
   /**
    *  Maybe it is best to use 'id' value for all managed objects
    */
   NSAssert(wireKey, @"Cannot be nil");
   NSAssert(localKey, @"Cannot be nil");
   
   NSManagedObjectContext *aWorkerContext = [self workerContext];
   
   ///
   ///
   // array of models
   NSArray *localObjects = [self fetchObjectsFrom:type withPredicate:nil atContext:aWorkerContext];
   NSSortDescriptor *IDs = [[NSSortDescriptor alloc] initWithKey:localKey ascending:YES];
   localObjects = [localObjects sortedArrayUsingDescriptors:@[IDs]];
   
   // array of dictionaries
   wireObjects = [wireObjects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
      return [obj1[wireKey] compare:obj2[wireKey]];
   }];
   
   
   NSArray *l, *w;
   l = localObjects;
   w = wireObjects;
   
   NSLog(@"string_type: %@: class: %@; LOCALLY: %i, WIRELY: %i", type, [[l lastObject] class], [l count], [w count]);
   
   // just to be able to keep the inserted objects in the heap for a while, until CoreData sync comes along
   NSMutableArray *inserts = [NSMutableArray array];
   NSMutableArray *updates = [NSMutableArray array];
   NSUInteger ll = [l count];
   
   [w enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      
      NSUInteger lc = 0;
      NSDictionary *wo = (NSDictionary*)obj;
      //BaseManagedObject *lo = [l firstObject];
      NSManagedObject *lo = [l firstObject];
      
      // look for the first match, if any
      NSInteger newLcIndex = -1;
      while (lc < ll) {
         lo = [l objectAtIndex:lc];
         if ([wo[wireKey] isEqualToString:[lo valueForKey:localKey]])
         {
            newLcIndex = lc;
            break;
         }
         lc ++;
      }
      
      if (newLcIndex > -1)
      {
         //MALog(@"UPDATE: [%@] on local obj at index: %i", wo[wireKey], newLcIndex);
         NSLog(@"= UPDATE: [%@]", wo[wireKey]);
         aTemplate(wo, lo, aWorkerContext);
         [updates addObject:lo];
      }
      else
      {
         NSLog(@"= INSERT: [%@]", wo[wireKey]);
         NSManagedObject *newMO = [NSClassFromString(type) insertNewObjectIntoContext:aWorkerContext];
         NSAssert(newMO, @"Check for existance of your model class");
         aTemplate(wo, newMO, aWorkerContext);
         [inserts addObject:newMO];
      }
   }];
   
   MALog(@"---outside '%@' loop---", type);
   
   [self saveContext:aWorkerContext];
}

#pragma mark -
-(NSManagedObjectContext*)masterManagedObjectContext
{
   if (_masterManagedObjectContext)
   {
      return _masterManagedObjectContext;
   }
   NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
   if (!coordinator)
   {
      return nil;
   }
   _masterManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
   [_masterManagedObjectContext setPersistentStoreCoordinator:coordinator];
   _masterManagedObjectContext.name = @"This is Master Context";
   return _masterManagedObjectContext;
}
-(NSManagedObjectContext *)managedObjectContext
{
   if (_managedObjectContext)
   {
      return _managedObjectContext;
   }
   
   NSManagedObjectContext *masterMoc = self.masterManagedObjectContext;
   
   _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
   _managedObjectContext.parentContext = masterMoc;
   _managedObjectContext.name = @"This is Main Context";
   return _managedObjectContext;
}
-(NSManagedObjectContext*)workerContext
{
   NSManagedObjectContext *worker = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
   worker.parentContext = self.managedObjectContext;
   worker.name = @"This is Worker Context";
   // worker.undoManager = nil; // makes the context "lighter"
   NSLog(@"Creating worker context: %@", worker);
   return worker;
}
- (NSManagedObjectModel *)managedObjectModel
{
   // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
   if (_managedObjectModel)
   {
      return _managedObjectModel;
   }
   NSURL *modelURL = [[NSBundle mainBundle] URLForResource:modelName withExtension:@"momd"];
   _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
   return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
   // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
   if (_persistentStoreCoordinator)
   {
      return _persistentStoreCoordinator;
   }
   
   // Create the coordinator and store
   _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
   
   NSString *fileName = [NSString stringWithFormat:@"%@.sqlite", modelName];
   NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:fileName];
   
   // Check if we already have a persistent store (handles Apple Store core data model incompatibility)
   NSError *metaDataError = nil;
   if ( [[NSFileManager defaultManager] fileExistsAtPath: [storeURL path]] )
   {
      NSDictionary *existingPersistentStoreMetadata = [NSPersistentStoreCoordinator
                                                       metadataForPersistentStoreOfType: NSSQLiteStoreType
                                                       URL: storeURL
                                                       error: &metaDataError];
      if ( !existingPersistentStoreMetadata )
      {
         // Something *really* bad has happened to the persistent store
         [NSException raise: NSInternalInconsistencyException format: @"Failed to read metadata for persistent store %@: %@", storeURL, metaDataError];
      }
      
      // if 2 sqlite models are different, remove the old one
      if ( ![self.managedObjectModel isConfiguration: nil compatibleWithStoreMetadata: existingPersistentStoreMetadata] )
      {
         // NSLog(@"%@: model stores dont match", kCoreDataStoreLog);
         
         if ( ![[NSFileManager defaultManager] removeItemAtURL: storeURL error: &metaDataError] )
         {
            //NSLog(@"%@: Could not delete persistent store, error: %@", kCoreDataStoreLog, [metaDataError description]);
         }
         else
         {
            //NSLog(@"%@: Deleted persistent store", kCoreDataStoreLog);
         }
         // else the existing persistent store is compatible with the current model - nice!
      }
      
   } // else no database file yet
   
   NSError *addPersistentStoreError = nil;
   NSString *failureReason = @"There was an error creating or loading the application's saved data.";
   if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                  configuration:nil
                                                            URL:storeURL
                                                        options:nil /*options*/
                                                          error:&addPersistentStoreError])
   {
      // Report any error we got.
      NSMutableDictionary *dict = [NSMutableDictionary dictionary];
      dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
      dict[NSLocalizedFailureReasonErrorKey] = failureReason;
      dict[NSUnderlyingErrorKey] = addPersistentStoreError;
      addPersistentStoreError = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
      // Replace this with code to handle the error appropriately.
      // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
      NSLog(@"Unresolved error %@, %@", addPersistentStoreError, [addPersistentStoreError userInfo]);
      abort();
   }
   
   return _persistentStoreCoordinator;
}


-(NSURL *)applicationDocumentsDirectory
{
   // The directory the application uses to store the Core Data store file. This code uses a directory named "eu.youco.tdca" in the application's documents directory.
   return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


#pragma mark - Interact with data
-(void)saveContext:(NSManagedObjectContext *)moc
{
   if (moc.parentContext == self.managedObjectContext) // it is a worker context
   {
      if (![moc hasChanges]) { MALog(@"Why moc has no changes???!!!"); return; }
      
      // 3->
      [moc performBlock:^{
         NSError *privateError = nil;
         NSAssert([moc save:&privateError], @"Error saving private context: %@\n%@",
                  [privateError localizedDescription], [privateError userInfo]);
         
         
         
         MALog(@"worker OK");
         
         if (![[self managedObjectContext] hasChanges]) return;
         
         // 2
         [[self managedObjectContext] performBlock:^{
            NSError *privateError = nil;
            NSAssert([[self managedObjectContext] save:&privateError], @"Error saving private context: %@\n%@",
                     [privateError localizedDescription], [privateError userInfo]);
            
            
            MALog(@"main OK");
            
         
            if (![[self masterManagedObjectContext] hasChanges]) return;
            // 1-> prova!
            [[self masterManagedObjectContext] performBlock:^{
               NSError *privateError = nil;
               NSAssert([[self masterManagedObjectContext] save:&privateError], @"Error saving private context: %@\n%@",
                        [privateError localizedDescription], [privateError userInfo]);
               
               MALog(@"Master OK");
          
            }];
            
         }];
       
      }];
   }
   else if (moc == self.managedObjectContext) // it is the main context
   {}
   else if (moc == self.masterManagedObjectContext) // it is the master context
   {}
}



NSString *updatedKey = @"updated";
NSString *insertedKey = @"inserted";
-(NSDictionary*)fetchObjectBasedOnUserInfo:(NSDictionary *)info atContext:(NSManagedObjectContext *)moc
{
   NSArray *updatedValues = [info[updatedKey] allObjects];
   NSMutableArray *ma = [NSMutableArray array];
   for (NSManagedObject *mo in updatedValues)
   {
      NSLog(@"UPD_id: %@", [mo objectID]);
      [ma addObject:[mo objectID]];
   }
   updatedValues = [self fetchObjectsFrom:nil withObjectIDs:[NSArray arrayWithArray:ma] atContext:nil];
   
   NSArray *insertedValues = [info[insertedKey] allObjects];
   ma = [NSMutableArray array];
   for (NSManagedObject *mo in insertedValues)
   {
      NSLog(@"INS_id: %@", [mo objectID]);
      [ma addObject:[mo objectID]];
   }
   insertedValues = [self fetchObjectsFrom:nil withObjectIDs:[NSArray arrayWithArray:ma]  atContext:nil];
   
   NSDictionary *d = @{
                       updatedKey : [updatedValues count] ? updatedValues : [NSArray array],
                       insertedKey : [insertedValues count] ? insertedValues : [NSArray array]
                       };
   return d;
}
-(NSArray*)fetchObjectsFrom:(NSString *)entityName withPredicate:(NSPredicate *)predicate atContext:(NSManagedObjectContext*)moc
{
   NSAssert(entityName, @"There must be a valid entity name");
   NSManagedObjectContext *context = moc ? moc : self.managedObjectContext;
   
   NSFetchRequest *request = [[NSFetchRequest alloc] init];
   NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
   [request setEntity:entity];
   if (predicate != nil)
   {
      [request setPredicate:predicate];
   }
   NSError *fetchError;
   NSArray *results = [[context executeFetchRequest:request error:&fetchError] mutableCopy];
   return results;
}
-(NSArray*)fetchObjectsFrom:(NSString *)entityName withObjectIDs:(NSArray *)objectsIDs atContext:(NSManagedObjectContext *)moc
{
   //NSAssert(entityName, @"There must be a valid entity name");
   NSManagedObjectContext *context = moc ? moc : self.managedObjectContext;
   NSMutableArray *ma = [NSMutableArray array];
   for (NSManagedObjectID *moID in objectsIDs)
   {
      NSManagedObject *mo = [context existingObjectWithID:moID error:nil];
      [ma addObject:mo];
   }
   // MALog(@"_fetching_: %i, %@", [ma count], [[ma lastObject] class]);
   return [NSArray arrayWithArray:ma];
}
-(NSUInteger)numberOfRecordsIn:(NSString *)entityName withPredicate:(NSPredicate *)predicate
{
   NSAssert([entityName length], @"Entity name cannot be empty");
   NSFetchRequest *request = [[NSFetchRequest alloc] init];
   NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
   request.entity = entity;
   if (predicate)
   {
      [request setPredicate:predicate];
   }
   NSError *error;
   NSUInteger count = [self.managedObjectContext countForFetchRequest:request error:&error];
   
   if (!error)
      return count;
   else
      return 0;
}
@end
