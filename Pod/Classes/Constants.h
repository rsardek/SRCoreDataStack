//
//  Constants.h
//  CoreDataStack
//
//  Created by Sardorbek on 3/13/16.
//  Copyright © 2016 Sardorbek. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MALog(fmt, ...) NSLog((@"FUNC: %s, LINE: %d, " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

@interface Constants : NSObject

@end
