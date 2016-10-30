//
//  TesterStack.m
//  SRCoreDataStack
//
//  Created by Sardorbek on 30/10/2016.
//  Copyright © 2016 Sardorbek Ruzmatov. All rights reserved.
//

#import "TesterStack.h"

@interface TesterStack()
{
    NSString *_model;
}

@end
@implementation TesterStack


-(instancetype)initStackWithDataModel:(NSString *)dataModelName andStoreType:(NSString *)storeType
{
    _model = dataModelName;
    return [super initStackWithDataModel:dataModelName andStoreType:storeType];
}

// Override the bundle object for the data model,
// system loads a dedicated bundle for test targets, and as such doesn't use the main bundle
- (NSManagedObjectModel *)managedObjectModel
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *modelURL = [bundle URLForResource:_model withExtension:@"momd"];
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return mom;
}

-(NSPersistentStoreCoordinator*)theStore
{
    return [super valueForKey:@"persistentStoreCoordinator"];
}
-(NSManagedObjectModel*)theModel
{
    return [super valueForKey:@"managedObjectModel"];
}
@end
