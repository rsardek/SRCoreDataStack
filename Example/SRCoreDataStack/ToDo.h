//
//  ToDo.h
//  SRCoreDataStack
//
//  Created by Sardorbek on 3/14/16.
//  Copyright © 2016 Sardorbek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ToDo : NSManagedObject

@property (nonatomic, strong) NSString *todo_description;
@property (nonatomic, strong) NSString *todo_title;
@property (nonatomic, strong) NSNumber *todo_done;
@property (nonatomic, strong) NSString *todo_id;

@property (nonatomic, strong) NSSet *places;

@end
