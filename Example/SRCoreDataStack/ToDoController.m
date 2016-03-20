//
//  ToDoController.m
//  SRCoreDataStack
//
//  Created by Sardorbek on 03/17/2016.
//  Copyright (c) 2016 Sardorbek. All rights reserved.
//

#import "ToDoController.h"
#import "SRCoreDataStack.h"
#import "ToDo.h"
#import "Place.h"
#import "Constants.h"
#import "BaseNetworking.h"


// Python app directory:
// /Users/sardorbek/Desktop/python_dir/todo_app/


static NSString *serverURL = @"http://localhost:5000/todo/api/v1.0/tasks";


@interface ToDoController () <NSFetchedResultsControllerDelegate>
{
   
}

@property (nonatomic, strong) SRCoreDataStack *dataStack;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResults;
@property (nonatomic, strong) BaseNetworking *networking;

@end

@implementation ToDoController

/**
 *  Lazy setups
 */

/**
 *  Not using AFNetworking, because:
 -the wire objects are returned by default on main thread; I prefer to remain still in background thread for data persistance
 (ie, GET:parameters:)
 -POST: method is so many lines of code
 
 Thus using my own, thin, networking class!
 
 */

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
      NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ToDo"];
      request.predicate = nil;
      request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"todo_id"
                                                                ascending:YES
                                                                 selector:@selector(localizedStandardCompare:)]];
      _fetchedResults = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                            managedObjectContext:mainMoc
                                                              sectionNameKeyPath:nil
                                                                       cacheName:nil];
      _fetchedResults.delegate = self;
   }
   return _fetchedResults;
}

-(SRCoreDataStack*)dataStack
{
   if (!_dataStack)
   {
      _dataStack = [[SRCoreDataStack alloc] initWithModelName:@"Example"];
   }
   return _dataStack;
}

-(void)importSoccerFeeds
{
   NSString *url = @"http://www.flickr.com/services/feeds/photos_public.gne?tags=soccer&format=json";
   [self.networking fetchContentAtURLString:url withBlock:^(id responseData, NSURLResponse *responseObject, NSError *error) {
      MALog(@"");
   }];
}

- (IBAction)handleReloadButtonTap:(id)sender
{
   [self importDataAtURL:serverURL];
   
   //[self importSoccerFeeds];
}
- (IBAction)handleAddNewItemTap:(id)sender
{
   UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add new" message:@"Add a new item" preferredStyle:UIAlertControllerStyleAlert];
   [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
      textField.placeholder = @"Task title";
   }];
   [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
      textField.placeholder = @"Task description";
   }];
   
   UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
      
      NSArray *texts = [[alert textFields] valueForKeyPath:@"text"];
      NSDictionary *dict = @{
                             @"title":[texts firstObject],
                             @"description": [texts lastObject]
                             };
      
      [self.networking postContent:dict atURLString:serverURL
                         withBlock:^(id responseData, NSURLResponse *responseObject, NSError *error) {
                            NSLog(@"'Add' response: %@", responseData);
                            
                            [self persistArray:@[responseData[@"task"]]];
                         }];
      
   }];
   [alert addAction:okAction];
   UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
      // nothing to do…
   }];
   [alert addAction:cancelAction];
   [self presentViewController:alert animated:YES completion:nil];
   
   
}

-(void)importDataAtURL:(NSString*)URL
{
   [self.networking fetchContentAtURLString:serverURL withBlock:^(id responseData, NSURLResponse *responseObject, NSError *error) {
      
      NSArray *wireObjects = responseData[@"tasks"];
      [self persistArray:wireObjects];
      
   }];
}

-(void)persistArray:(NSArray*)wireObjects
{
   [self.dataStack saveInBackground:wireObjects ofType:@"ToDo" ofWireProperty:@"id" ofLocalProperty:@"todo_id" usingTemplate:^NSManagedObject *(NSDictionary *obj, NSManagedObject *mo, NSManagedObjectContext *currentCtx) {
      
      ToDo *todo = (ToDo*)mo;
      todo.todo_description = obj[@"description"];
      todo.todo_title = obj[@"title"];
      todo.todo_id = obj[@"id"];
      todo.todo_done = obj[@"done"];
      
      NSMutableArray *ma = [NSMutableArray array];
      for (NSString *placeString in obj[@"place"])
      {
         Place *place = [Place insertNewObjectIntoContext:currentCtx];
         place.place_name = placeString;
         [ma addObject:place];
      }
      
      todo.places = [NSSet setWithArray:[NSArray arrayWithArray:ma]];
      return todo;
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
   UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"TODO_CELL"];
   ToDo *todo = [self.fetchedResults objectAtIndexPath:indexPath];
   cell.textLabel.text = [NSString stringWithFormat:@"%@: %@ at places: %i", todo.todo_id, todo.todo_title, todo.places.count];
   cell.detailTextLabel.text = todo.todo_description;
   return cell;
}


#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
   [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
   switch(type)
   {
      case NSFetchedResultsChangeInsert:
         [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
         break;
         
      case NSFetchedResultsChangeUpdate:
         break;
         
      case NSFetchedResultsChangeDelete:
         [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
         break;
         
      default:
         break;
   }
}
- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
   switch(type)
   {
      case NSFetchedResultsChangeInsert:
         [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
         break;
         
      case NSFetchedResultsChangeDelete:
         [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
         break;
         
      case NSFetchedResultsChangeUpdate:
         [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationMiddle];
         break;
         
      case NSFetchedResultsChangeMove:
         [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
         [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
         break;
   }
}
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
   [self.tableView endUpdates];
}
@end
