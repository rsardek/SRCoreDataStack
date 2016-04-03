//
//  BaseNetworking.h
//
//  Created by Sardorbek on 12/13/15.
//  Copyright © 2015 Sardorbek Ruzmatov. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^BaseNetworkingResponse)(id responseData, NSURLResponse *responseObject, NSError *error);

/**
 *  A wrapper class for basic networking calls
 */
@interface BaseNetworking : NSObject

-(void)fetchDataAtURLString:(NSString*)urlString withBlock:(BaseNetworkingResponse)block;
-(void)fetchContentAtURLString:(NSString*)urlString withBlock:(BaseNetworkingResponse)block;
-(void)postContent:(id)content atURLString:(NSString*)urlString withBlock:(BaseNetworkingResponse)block;

@end
