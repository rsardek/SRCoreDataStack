//
//  FetchedResultsDelegate.m
//  SRCoreDataStack
//
//  Created by Sardorbek on 3/29/16.
//  Copyright © 2016 Sardorbek Ruzmatov. All rights reserved.
//

#import "FetchedResultsDelegate.h"
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface FetchedResultsDelegate()

@property (nonatomic, weak) UITableView *tableView;
@end
@implementation FetchedResultsDelegate

@synthesize tableView = _tableView;

-(instancetype)init
{
   [NSException raise:@"Incorrect initializer invocation" format:@"Incorrect initializer method has been called, use %@ instead", NSStringFromSelector(@selector(initWithTableView:))];
   return nil;
}

-(instancetype)initWithTableView:(UITableView *)tableView
{
   if (self = [super init])
   {
      _tableView = tableView;
   }
   return self;
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
