//
//  Movie.h
//  SRCoreDataStack
//
//  Created by Sardorbek on 3/29/16.
//  Copyright © 2016 Sardorbek Ruzmatov. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface Movie : NSManagedObject

@property (nonatomic, strong) NSString *movie_description;
@property (nonatomic, strong) NSString *movie_title;
@property (nonatomic, strong) NSString *movie_id;
@property (nonatomic, strong) NSString *movie_year;
@property (nonatomic, strong) NSSet *movie_genres;
@end
