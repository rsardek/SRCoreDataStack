//
//  MovieViewController.m
//  SRCoreDataStack
//
//  Created by Sardorbek on 3/29/16.
//  Copyright © 2016 Sardorbek Ruzmatov. All rights reserved.
//

#import "MovieViewController.h"
#import "SRCoreDataStack.h"
#import "BaseNetworking.h"
#import "FetchedResultsDelegate.h"
#import "Movie.h"
#import "MovieGenre.h"

static NSString *kFetchMoviesURL = @"http://localhost:5000/movies/api/v1.0/movies";
static NSString *kEditMovieURL = @"http://localhost:5000/movies/api/v1.0/edit";

@interface MovieViewController ()
{
   FetchedResultsDelegate *fetchedResultsDelegate;
}

@property (nonatomic, strong) SRCoreDataStack *dataStack;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResults;
@property (nonatomic, strong) BaseNetworking *networking;

@end

@implementation MovieViewController

@synthesize dataStack = _dataStack;
@synthesize fetchedResults = _fetchedResults;
@synthesize networking = _networking;

-(BaseNetworking*)networking
{
   if (!_networking)
   {
      _networking = [BaseNetworking new];
   }
   return _networking;
}
-(NSFetchedResultsController*)fetchedResults
{
   if (!_fetchedResults)
   {
      NSManagedObjectContext *mainMoc = [self.dataStack managedObjectContext];
      NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Movie"];
      request.predicate = nil;
      request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"movie_id"
                                                                ascending:YES
                                                                 selector:@selector(localizedStandardCompare:)]];
      _fetchedResults = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                            managedObjectContext:mainMoc
                                                              sectionNameKeyPath:nil
                                                                       cacheName:nil];
      fetchedResultsDelegate = [[FetchedResultsDelegate alloc] initWithTableView:self.tableView];
      _fetchedResults.delegate = fetchedResultsDelegate;
      
   }
   return _fetchedResults;
}

-(SRCoreDataStack*)dataStack
{
   if (!_dataStack)
   {
      _dataStack = [SRCoreDataStack defaultStackForDataModel:@"Example"];
   }
   return _dataStack;
}
- (IBAction)reloadButtonTapped:(id)sender
{
   [self importDataAtURL:kFetchMoviesURL];
}

-(NSArray*)validGenresFromText:(NSString*)text
{
   NSMutableArray *values = [NSMutableArray array];
   NSArray *components = [text componentsSeparatedByString:@","];
   [components enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      NSString *genre = (NSString*)obj;
      genre = [genre stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
      [values addObject:genre];
   }];
   
   return [NSArray arrayWithArray:values];
}

- (IBAction)addNewItemTapped:(id)sender
{
   UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add movie" message:@"Add another movie" preferredStyle:UIAlertControllerStyleAlert];
   [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
      textField.placeholder = @"Movie title";
   }];
   [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
      textField.placeholder = @"Movie year";
   }];
   [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
      textField.placeholder = @"Movie description";
   }];
   [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
      textField.placeholder = @"Movie genres separated by comma";
   }];
   
   UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
      
      NSArray *lengths = [[alert textFields] valueForKeyPath:@"text.length"];
      if ([lengths containsObject:[NSNumber numberWithInteger:0]])
      {
         // There is an empty field
         UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No movie added" message:@"Some fields were missing" preferredStyle:UIAlertControllerStyleAlert];
         UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            // nothing to do
         }];
         [alert addAction:cancelAction];
         [self presentViewController:alert animated:YES completion:nil];
         return;
      }
      
      NSArray *inputTexts = [[alert textFields] valueForKeyPath:@"text"];
      NSDictionary *content = @{
                                @"title":[inputTexts firstObject],
                                @"year":[inputTexts objectAtIndex:1],
                                @"description": [inputTexts objectAtIndex:2],
                                @"genres": [self validGenresFromText:[inputTexts objectAtIndex:3]],
                                @"id": @""
                                };
      
      
      [self.networking postContent:content atURLString:kEditMovieURL
                         withBlock:^(id responseData, NSURLResponse *responseObject, NSError *error) {
                            
                            if (responseData)
                            {
                               NSLog(@"'Add' response: %@", responseData);
                               [self persistArray:@[responseData[@"movie"]]];
                            }
                            
                         }];
      
   }];
   [alert addAction:okAction];
   UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
      // nothing to do
   }];
   [alert addAction:cancelAction];
   
   [self presentViewController:alert animated:YES completion:nil];
   
}

-(void)importDataAtURL:(NSString*)URL
{
   [self.networking fetchContentAtURLString:kFetchMoviesURL withBlock:^(id responseData, NSURLResponse *responseObject, NSError *error) {
      NSArray *wireObjects = responseData[@"movies"];
      [self persistArray:wireObjects];
      
   }];
}

-(void)persistArray:(NSArray*)wireObjects
{
   [self.dataStack saveObjects:wireObjects inEntity:@"Movie" withWireAttribute:@"id" andLocalAttribute:@"movie_id" andConfiguration:^NSManagedObject *(NSDictionary *obj, NSManagedObject *mo, NSManagedObjectContext *currentCtx) {
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
   
}
- (void)viewDidLoad
{
   [super viewDidLoad];
   
   /**
    *  Import persisted data from disk
    */
   [self.fetchedResults performFetch:nil];
   
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   NSInteger rows = 0;
   if ([[self.fetchedResults sections] count])
   {
      id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResults sections] objectAtIndex:section];
      rows = [sectionInfo numberOfObjects];
   }
   return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"MOVIE_CELL"];
   Movie *movie = [self.fetchedResults objectAtIndexPath:indexPath];
   cell.textLabel.text = [NSString stringWithFormat:@"%@: %@ - %@", movie.movie_id, movie.movie_title, movie.movie_description];
   NSString *genresText = [NSString stringWithFormat:@"%@",[[[movie.movie_genres allObjects] valueForKeyPath:@"genre_name"] componentsJoinedByString:@", "]];
   cell.detailTextLabel.text = genresText;
   return cell;
}

@end
