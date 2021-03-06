//
//  DKErrorDomain.m
//  DropletKit
//
//  Created by Victor Gama on 5/6/15.
//  Copyright (c) 2015 Victor Gama. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DKErrorDomain.h"
#import "Constants.h"

@implementation DKErrorDomain

#pragma mark Properties
+ (NSString *)domain {
    return kAPIERRDOMAIN;
}
- (NSString *)domain {
    return kAPIERRDOMAIN;
}

#pragma mark Errors
+ (NSError *)errorWithErrorCode:(NSInteger)errorCode {
    return [DKErrorDomain errorWithErrorCode:errorCode userInfo:nil];
}

+ (NSError *)errorWithErrorCode:(NSInteger)errorCode userInfo:(NSDictionary *)userInfo {
    return [NSError errorWithDomain:kAPIERRDOMAIN code:errorCode userInfo:userInfo];
}

+ (NSError *)undefinedError {
    return [DKErrorDomain errorWithErrorCode:DKErrorCode_Undefined];
}

+ (NSError *)inconsistentDataReceivedFromEndpoint {
    return [DKErrorDomain errorWithErrorCode:DKErrorCode_InconsistentDataReceivedFromEndpoint];
}

+ (NSError *)unexpectedResponse {
    return [DKErrorDomain errorWithErrorCode:DKErrorCode_UnexpectedResponse];
}

+ (NSError *)inconsistentArgumentsWithReason:(NSString *)reason {
    NSDictionary *info = @{
                           @"reason": reason
                           };
    return [DKErrorDomain errorWithErrorCode:DKErrorCode_InconsistentArguments userInfo:info];
}

+ (NSError *)dropletLocked {
    return [DKErrorDomain errorWithErrorCode:DKErrorCode_DropletLocked];
}

+ (NSError *)tokenExpired {
    return [DKErrorDomain errorWithErrorCode:DKErrorCode_TokenExpired];
}

+ (NSError *)tryTranslateAFError:(NSError *)error {
    if([error.domain hasPrefix:@"com.alamofire.error.serialization.response"] && error.userInfo) {
        id info = error.userInfo[@"com.alamofire.serialization.response.error.response"];
        if(info && [info isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *resp = (NSHTTPURLResponse *)info;
            if(resp.statusCode == 401) {
                return [DKErrorDomain tokenExpired];
            }
        }
    }
    return error;
}
@end
