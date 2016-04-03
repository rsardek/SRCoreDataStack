//
//  FetchedResultsDelegate.h
//  SRCoreDataStack
//
//  Created by Sardorbek on 3/29/16.
//  Copyright © 2016 Sardorbek Ruzmatov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UITableView;
@protocol NSFetchedResultsControllerDelegate;
/**
  
   Wraps common boiler plate NSFetchResultsControllerDelegate methods
 */
@interface FetchedResultsDelegate : NSObject <NSFetchedResultsControllerDelegate>

-(instancetype)initWithTableView:(UITableView*)tableView;

@end
