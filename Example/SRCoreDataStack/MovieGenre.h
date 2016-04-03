//
//  MovieGenre.h
//  SRCoreDataStack
//
//  Created by Sardorbek on 3/29/16.
//  Copyright © 2016 Sardorbek Ruzmatov. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Movie;
@interface MovieGenre : NSManagedObject

@property (nonatomic, strong) NSString *genre_name;
@property (nonatomic, strong) Movie *movie;
@end
