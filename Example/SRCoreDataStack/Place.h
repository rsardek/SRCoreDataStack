//
//  Place.h
//  SRCoreDataStack
//
//  Created by Sardorbek on 3/20/16.
//  Copyright © 2016 Sardorbek Ruzmatov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Place : NSManagedObject

@property (nonatomic, strong) NSString *place_name;

@end
