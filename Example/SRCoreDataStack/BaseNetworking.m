//
//  BaseNetworking.m
//
//  Created by Sardorbek on 12/13/15.
//  Copyright © 2015 Sardorbek Ruzmatov. All rights reserved.
//

#import "BaseNetworking.h"

@implementation BaseNetworking

-(void)fetchDataAtURLString:(NSString *)urlString withBlock:(BaseNetworkingResponse)block
{
   NSURL *url = [NSURL URLWithString:urlString];
   NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
   NSURLSession *session = [NSURLSession sharedSession];
   NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
      if (error)
      {
         NSLog(@"%@, error: %@", [self class], [error localizedDescription]);
         block(nil, response, error);
         return;
      }
      
      NSLog(@"%@, response ok", [self class]);
      block(data, response, nil);
   }];
   
   [postDataTask resume];
   
}
-(void)fetchContentAtURLString:(NSString *)urlString withBlock:(BaseNetworkingResponse)block
{
   [self fetchDataAtURLString:urlString withBlock:^(id responseData, NSURLResponse *responseObject, NSError *error) {
      
      NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)responseObject;
      NSDictionary *headers = [httpResponse allHeaderFields];
      if (httpResponse.statusCode == 404)
      {
         block(nil, responseObject, error);
         return;
      }
      
      if (responseData)
      {
         /**
          *  Filter response types on the basis of 'content-type' header
          */
         NSString *contentType = headers[@"Content-Type"];
         if ([contentType containsString:@"text/xml"])
         {
            block([[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding], nil, nil);
         }
         else if ([contentType containsString:@"text/html"])
         {
            block([[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding], nil, nil);
         }
         else if ([contentType containsString:@"application/json"])
         {
            block([NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil], nil, nil);
         }
         else if ([contentType containsString:@"image/jpeg"])
         {
            block(responseData, responseObject, nil);
         }
      }
      else
      {
         block(nil, responseObject, error);
      }
   }];
}

-(void)postContent:(id)content atURLString:(NSString *)urlString withBlock:(BaseNetworkingResponse)block
{
   NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
   [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
   [request setHTTPMethod:@"POST"];
   NSData *postData = [NSJSONSerialization dataWithJSONObject:content options:0 error:nil];
   request.HTTPBody = postData;
   NSURLSession *session = [NSURLSession sharedSession];
   NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
      if (error)
      {
         NSLog(@"%@, error: %@", [self class], [error localizedDescription]);
         block(nil, response, error);
         return;
      }
      NSLog(@"%@, response ok", [self class]);
      block([NSJSONSerialization JSONObjectWithData:data options:0 error:nil], nil, nil);
      
   }];
   [postDataTask resume];
}
@end
