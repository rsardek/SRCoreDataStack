//
//  SRCoreDataStack.m
//
//  Created by Sardorbek on 3/13/16.
//  Copyright © 2016 Sardorbek. All rights reserved.
//

#import "SRCoreDataStack.h"

@interface SRCoreDataStack()
{
   NSString *_modelName;
   //NSString *_storeType;
}

@property (readonly, strong) NSManagedObjectContext *masterManagedObjectContext;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;

-(NSManagedObjectContext*)workerContext;
-(void)saveContext:(NSManagedObjectContext *)moc;

@end
@implementation SRCoreDataStack

@synthesize masterManagedObjectContext = _masterManagedObjectContext;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+(instancetype)defaultStackForDataModel:(NSString *)dataModelName
{
   static SRCoreDataStack *sharedStack = nil;
   static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
      sharedStack = [[self alloc] initWithModelName:dataModelName];
   });
   return sharedStack;
}
-(instancetype)initStackWithModel:(NSString *)modelName andStoreType:(NSString *)storeType
{
   if (self = [super init])
   {
      _modelName = modelName;
      //_storeType = storeType;
   }
   return self;
}

-(instancetype)initWithModelName:(NSString *)modelName
{
   if (self = [super init])
   {
      _modelName = modelName;
   }
   return self;
}

-(void)saveObjects:(NSArray *)objects inEntity:(NSString *)entityName withWireAttribute:(NSString *)wireAttributeName andLocalAttribute:(NSString *)localAttributeName andConfiguration:(SRCoreDataStackConfigurationBlock)configuration
{
   if (![objects count]) return;
   
   NSAssert(entityName, @"Model type cannot be nil");
   NSAssert(wireAttributeName, @"Attribute cannot be nil");
   NSAssert(localAttributeName, @"Attribute cannot be nil");
   
   NSManagedObjectContext *aWorkerContext = [self workerContext];
   
   // sorted array of already persisted objects
   NSArray *localObjects = [self fetchObjectsFromEntity:entityName withPredicate:nil atContext:aWorkerContext];
   NSSortDescriptor *IDs = [[NSSortDescriptor alloc] initWithKey:localAttributeName ascending:YES];
   localObjects = [localObjects sortedArrayUsingDescriptors:@[IDs]];
   
   // sorted wire objects
   objects = [objects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
      return [obj1[wireAttributeName] compare:obj2[wireAttributeName]];
   }];
   
   NSLog(@"INFO: %@: class: %@; LOCALLY: %i, WIRELY: %i", entityName, [[localObjects lastObject] class], [localObjects count], [objects count]);
   
   [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      
      NSUInteger lc = 0;
      NSDictionary *wireObj = (NSDictionary*)obj;
      NSManagedObject *localObj = [localObjects firstObject];
      
      // look for the first match, if any
      NSInteger newLcIndex = -1;
      while (lc < [localObjects count]) {
         localObj = [localObjects objectAtIndex:lc];
         if ([wireObj[wireAttributeName] isEqualToString:[localObj valueForKey:localAttributeName]])
         {
            newLcIndex = lc;
            break;
         }
         lc ++;
      }
      
      if (newLcIndex > -1)
      {
         NSLog(@"UPDATE: [%@=%@]", wireAttributeName, wireObj[wireAttributeName]);
         configuration(wireObj, localObj, aWorkerContext);
      }
      else
      {
         NSLog(@"INSERT: [%@=%@]", wireAttributeName, wireObj[wireAttributeName]);
         NSManagedObject *newMO = [NSClassFromString(entityName) insertNewObjectIntoContext:aWorkerContext];
         NSAssert(newMO, @"Check for existance of your model class");
         configuration(wireObj, newMO, aWorkerContext);
      }
   }];
   
   [self saveContext:aWorkerContext];
}
-(void)saveObjects:(NSArray *)objects inEntity:(NSString *)entityName withCommonAttribute:(NSString *)attribute andConfiguration:(SRCoreDataStackConfigurationBlock)configuration
{
   [self saveObjects:objects inEntity:entityName withWireAttribute:attribute andLocalAttribute:attribute andConfiguration:configuration];
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
   NSURL *modelURL = [[NSBundle mainBundle] URLForResource:_modelName withExtension:@"momd"];
   _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
   return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
   if (_persistentStoreCoordinator)
   {
      return _persistentStoreCoordinator;
   }
   
   // Create the coordinator and store
   _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
   
   NSString *fileName = [NSString stringWithFormat:@"%@.sqlite", _modelName];
   NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:fileName];
   
   NSError *metaDataError = nil;
   if ([[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]])
   {
      NSDictionary *existingPersistentStoreMetadata = [NSPersistentStoreCoordinator
                                                       metadataForPersistentStoreOfType: /*_storeType ? _storeType:*/NSSQLiteStoreType
                                                       URL: storeURL
                                                       error: &metaDataError];
      if (!existingPersistentStoreMetadata)
      {
         // Something *really* bad has happened to the persistent store
         [NSException raise: NSInternalInconsistencyException format: @"Failed to read metadata for persistent store %@: %@", storeURL, metaDataError];
      }
      
      if (![self.managedObjectModel isConfiguration:nil compatibleWithStoreMetadata: existingPersistentStoreMetadata] )
      {
         /**
          *  if existing and new sqlite models don't match, remove the old sqlite model
          */
         [[NSFileManager defaultManager] removeItemAtURL: storeURL error: &metaDataError];
      }
      
   }
   
   NSError *addPersistentStoreError = nil;
   NSString *failureReason = @"There was an error creating or loading the application's saved data.";
   if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                  configuration:nil
                                                            URL:storeURL
                                                        options:nil
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
/**
 *  Saves the context and propogates the changes all the way to the store
 *
 *  @param moc context object
 */
-(void)saveContext:(NSManagedObjectContext *)moc
{
   if (moc.parentContext == self.managedObjectContext) // it is a worker context
   {
      if (![moc hasChanges]) return;
      [moc performBlock:^{
         NSError *privateError = nil;
         NSAssert([moc save:&privateError], @"Error saving 'worker' context: %@\n%@",
                  [privateError localizedDescription], [privateError userInfo]);
         NSLog(@"'worker' context did save changes");
         
         if (![[self managedObjectContext] hasChanges]) return;
         [[self managedObjectContext] performBlock:^{
            NSError *privateError = nil;
            NSAssert([[self managedObjectContext] save:&privateError], @"Error saving 'main' context: %@\n%@",
                     [privateError localizedDescription], [privateError userInfo]);
            NSLog(@"'main' context did save changes");
            
            if (![[self masterManagedObjectContext] hasChanges]) return;
            [[self masterManagedObjectContext] performBlock:^{
               NSError *privateError = nil;
               NSAssert([[self masterManagedObjectContext] save:&privateError], @"Error saving 'master' context: %@\n%@",
                        [privateError localizedDescription], [privateError userInfo]);
               NSLog(@"'master' context did save changes");
               
            }];
            
         }];
         
      }];
   }
}

-(NSArray*)fetchObjectsFromEntity:(NSString *)entityName withPredicate:(NSPredicate *)predicate atContext:(NSManagedObjectContext*)moc
{
   NSAssert(entityName, @"There must be a valid entity name");
   NSManagedObjectContext *context = moc ? moc : self.managedObjectContext;
   
   NSFetchRequest *request = [[NSFetchRequest alloc] init];
   NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
   [request setEntity:entity];
   if (predicate)
   {
      [request setPredicate:predicate];
   }
   NSError *fetchError;
   NSArray *results = [[context executeFetchRequest:request error:&fetchError] mutableCopy];
   return results;
}
-(NSUInteger)numberOfRecordsInEntity:(NSString *)entityName withPredicate:(NSPredicate *)predicate
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
