//
//  BaseNetworking.m
//
//  Created by Sardorbek on 12/13/15.
//  Copyright © 2015 Sardorbek. All rights reserved.
//

#import "BaseNetworking.h"

#define BASE_NETWORKING @"BASE_NETWORKING"

@implementation BaseNetworking

-(void)fetchDataAtURLString:(NSString *)urlString withBlock:(BaseNetworkingResponse)block
{
   NSURL *url = [NSURL URLWithString:urlString];
   NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
   NSURLSession *session = [NSURLSession sharedSession];
   NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
      if (error)
      {
         NSLog(@"%@, error: %@", BASE_NETWORKING, [error localizedDescription]);
         block(nil, response, error);
         return;
      }
      
      //NSString *contentType = [resp]
      // "Content-Type" = "application/json";
      
      // www.google.com ->
      // "Content-Type" = "text/html; charset=ISO-8859-1";
      
      // if flask response is configured as "text/xml",
      // response content type is
      // "Content-Type" = "text/xml; charset=utf-8";
      
      // if flask response is configured as "text/html",
      // response content type is
      // "Content-Type" = "text/html; charset=utf-8";
      
      //NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      
      //NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
      //NSArray *finite = [self parseDictIntoPosts:json];
      //MALog(@"__count (fresh): %i", [finite count]);
      
      
      NSLog(@"%@, response: ...", BASE_NETWORKING);
      block(data, response, nil);
   }];
   
   [postDataTask resume];
   
}
-(void)fetchContentAtURLString:(NSString *)urlString withBlock:(BaseNetworkingResponse)block
{
   [self fetchDataAtURLString:urlString withBlock:^(id responseData, NSURLResponse *responseObject, NSError *error) {
      if (responseData)
      {
         NSHTTPURLResponse *httpResonse = (NSHTTPURLResponse*)responseObject;
         NSDictionary *headers = [httpResonse allHeaderFields];
 
         // categorize response objects based on http header
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
         NSLog(@"%@, post-error: %@", BASE_NETWORKING, [error localizedDescription]);
         block(nil, response, error);
         return;
      }
      // NSLog(@"%@, post-response: %@", BASE_NETWORKING, response);
      /*
       NSHTTPURLResponse *httpResonse = (NSHTTPURLResponse*)response;
       NSDictionary *headers = [httpResonse allHeaderFields];
       NSLog(@"headers: %@", headers);
       
       // categorize response objects based on http header
       NSString *contentType = headers[@"Content-Type"];
       */
      
      //NSString *serialized = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      //NSLog(@"%@: serialized string: %@", BASE_NETWORKING, serialized);
      
      block([NSJSONSerialization JSONObjectWithData:data options:0 error:nil], nil, nil);
      
   }];
   [postDataTask resume];
}
@end
