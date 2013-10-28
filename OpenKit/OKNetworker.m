//  Created by Manuel Martinez-Almeida and Lou Zell
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "AFNetworking.h"
#import "AFOAuth1Client.h"
#import "OKNetworker.h"
#import "OKManager.h"
#import "OKUtils.h"
#import "OKMacros.h"
#import "OKError.h"
#import "OKPrivate.h"


typedef void (^OKNetworkerBlock)(id responseObject, NSError * error);


static AFOAuth1Client *__httpClient = nil;
static NSString *OK_SERVER_API_VERSION = @"v2";


@implementation OKNetworker

+ (AFOAuth1Client*)httpClient
{
    if(!__httpClient) {
        NSURL *baseEndpointURL = [NSURL URLWithString:[OKManager endpoint]];
        NSURL *endpointUrl = [NSURL URLWithString:OK_SERVER_API_VERSION relativeToURL:baseEndpointURL];
        NSString *endpointString = [endpointUrl absoluteString];
        
        OKLog(@"Initializing AFOauth1Client with endpoint: %@", endpointString);
        __httpClient = [[AFOAuth1Client alloc] initWithBaseURL:endpointUrl
                                                          key:[OKManager appKey]
                                                       secret:[OKManager secretKey]];
        
        [__httpClient setParameterEncoding:AFJSONParameterEncoding];
        [__httpClient setDefaultHeader:@"Accept" value:@"application/json"];
        [__httpClient setDefaultHeader:@"Accept-Encoding" value:@"gzip"];
    }
    return __httpClient;
}


+ (NSInteger)getStatusCodeFromAFNetworkingError:(NSError*)error
{
    return [[[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey] statusCode];
}




+ (void)requestWithMethod:(NSString *)method
                     path:(NSString *)path
               parameters:(NSDictionary *)params
                      tag:(NSInteger)tag
               completion:(void (^)(id responseObject, NSError * error))handler
{    
    // SUCCESS BLOCK
    void (^successBlock)(AFHTTPRequestOperation*, id) = ^(AFHTTPRequestOperation *op, id response)
    {
        NSError *err;
        id decodedObj = OKDecodeObj(response, &err);
        if(handler)
            handler(decodedObj, err);
    };

    
    // FAILURE BLOCK
    void (^failureBlock)(AFHTTPRequestOperation*, NSError*) = ^(AFHTTPRequestOperation *op, NSError *err)
    {
        NSInteger errorCode = [OKNetworker getStatusCodeFromAFNetworkingError:err];
        
        // If the user is unsubscribed to the app, log out the user.
        if(errorCode == OK_UNSUBSCRIBED_USER_ERROR_CODE) {
            OKLogErr(@"Logging out current user b/c user is unsubscribed to app");
            [[OKManager sharedManager] logoutCurrentUser];
        }
        
        if(handler)
            handler(nil, err);
    };

    
    // Perform HTTP request
    AFOAuth1Client *httpclient = [self httpClient];
    
    NSMutableURLRequest *request = [httpclient requestWithMethod:method
                                                            path:path
                                                      parameters:params];
    
    AFHTTPRequestOperation *operation = [httpclient HTTPRequestOperationWithRequest:request
                                                                            success:successBlock
                                                                            failure:failureBlock];
    
    [operation setUserInfo:@{@"tag": @(tag)}];
    [operation start];
}


+ (void)getFromPath:(NSString *)path
         parameters:(NSDictionary *)params
         completion:(void (^)(id responseObject, NSError *error))handler
{
    [self requestWithMethod:@"GET"
                       path:path
                 parameters:params
                        tag:kOKNetworkerRequest_other
                 completion:handler];
}


+ (void)postToPath:(NSString *)path
        parameters:(NSDictionary *)params
        completion:(void (^)(id responseObject, NSError *error))handler
{
    [self requestWithMethod:@"POST"
                       path:path
                 parameters:params
                        tag:kOKNetworkerRequest_other
                 completion:handler];
}


+ (void)putToPath:(NSString *)path
       parameters:(NSDictionary *)params
       completion:(void (^)(id responseObject, NSError *error))handler
{
    [self requestWithMethod:@"PUT"
                       path:path
                 parameters:params
                        tag:kOKNetworkerRequest_other
                 completion:handler];
}


+ (void)getFromPath:(NSString *)path
         parameters:(NSDictionary *)params
                tag:(NSInteger)tag
         completion:(void (^)(id responseObject, NSError *error))handler
{
    [self requestWithMethod:@"GET"
                       path:path
                 parameters:params
                        tag:tag
                 completion:handler];
}


+ (void)postToPath:(NSString *)path
        parameters:(NSDictionary *)params
               tag:(NSInteger)tag
        completion:(void (^)(id responseObject, NSError *error))handler
{
    [self requestWithMethod:@"POST"
                       path:path
                 parameters:params
                        tag:tag
                 completion:handler];
}


+ (void)putToPath:(NSString *)path
       parameters:(NSDictionary *)params
              tag:(NSInteger)tag
       completion:(void (^)(id responseObject, NSError *error))handler
{
    [self requestWithMethod:@"PUT"
                       path:path
                 parameters:params
                        tag:(NSInteger)tag
                 completion:handler];
}


@end
