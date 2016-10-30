//
//  TesterStack.h
//  SRCoreDataStack
//
//  Created by Sardorbek on 30/10/2016.
//  Copyright © 2016 Sardorbek Ruzmatov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRCoreDataStack.h"

@interface TesterStack : SRCoreDataStack

// inspect super class properties
-(NSPersistentStoreCoordinator*)theStore;
-(NSManagedObjectModel*)theModel;

@end
