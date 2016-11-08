# SRCoreDataStack

[![Version](https://img.shields.io/cocoapods/v/SRCoreDataStack.svg?style=flat)](http://cocoapods.org/pods/SRCoreDataStack)
[![License](https://img.shields.io/cocoapods/l/SRCoreDataStack.svg?style=flat)](http://cocoapods.org/pods/SRCoreDataStack)
[![Platform](https://img.shields.io/cocoapods/p/SRCoreDataStack.svg?style=flat)](http://cocoapods.org/pods/SRCoreDataStack)


## Installation

SRCoreDataStack is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:


```ruby
pod "SRCoreDataStack"
```

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.


Get the default shared instance:
```  objective-c

self.dataStack = [SRCoreDataStack defaultStackForDataModel:@"Example"];

```

Save objects coming from network call into Core Data:
```  objective-c

[self.dataStack saveObjects:wireObjects deleteNonMatchingLocals:NO inEntity:@"Movie" withWireAttribute:@"id" andLocalAttribute:@"movie_id" andConfiguration:^NSManagedObject *(NSDictionary *obj, NSManagedObject *mo, NSManagedObjectContext *currentCtx) {
   Movie *movie = (Movie*)mo;
   movie.movie_id = obj[@"id"];
   movie.movie_title = obj[@"title"];
   movie.movie_description = obj[@"description"];

   // define its parent-child relationship
   NSMutableArray *ma = [NSMutableArray array];
   for (NSString *genreString in obj[@"genres"])
   {
      MovieGenre *movieGenre = [MovieGenre insertNewObjectIntoContext:currentCtx];
      movieGenre.genre_name = genreString;
      [ma addObject:movieGenre];
   }
   movie.movie_genres = [NSSet setWithArray:[NSArray arrayWithArray:ma]];
   return movie;
}];

```

## Example project
Example project uses [this backend project](https://github.com/rsardek/movies-list). The backend project, once downloaded and run on Terminal, can be viewed through browser. You can then make seamless live synching between the apps.



## Overview
- Saves wire objects in background managed object context
- Custom object serialization and relationship management between objects handled within a block
- Under the hood works with NSManagedObject instances, thus the stack doesn't need to know of your custom managed object type
- Uses nested managed object contexts for synching
- Implements "insert or update" algorithm discussed in WWDC 2013-211 video 



## License

SRCoreDataStack is available under the MIT license. See the LICENSE file for more info.
