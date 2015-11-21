//
//  DKClient.m
//  DropletKit
//
//  Created by Victor Gama on 5/6/15.
//  Copyright (c) 2015 Victor Gama. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import "Thirdparty/PromiseKit/PromiseKit.h"

#import <DropletKit/DropletKit.h>

@implementation DKClient {
    __block AFHTTPSessionManager *manager;
    __block AFHTTPRequestSerializer *serializer;
}

#pragma mark Properties
+ (void)setAuthenticationToken:(NSString *)token {
    DKClient *instance = [self sharedInstance];
    instance.authenticationToken = token;
}

- (AFHTTPSessionManager*)sharedSessionManager {
    return manager;
}


#pragma mark Life cycle
- (instancetype)init {
    self = [super init];
    manager = [[AFHTTPSessionManager alloc] initWithBaseURL:nil];
    serializer = [[AFJSONRequestSerializer alloc] init];
    [serializer setValue:@"DropletKit" forHTTPHeaderField:@"User-Agent"];
    manager.requestSerializer = serializer;
    [self addObserver:self forKeyPath:@"self.authenticationToken" options:NSKeyValueObservingOptionNew context:nil];
    return self;
}


#pragma mark Singletons
+ (instancetype)sharedInstance {
    static DKClient *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DKClient alloc] init];
    });
    return instance;
}


#pragma mark NSObject
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"self.authenticationToken"]) {
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", self.authenticationToken] forHTTPHeaderField:@"Authorization"];
    }
}


#pragma mark URL Builders
- (NSString*)apiURLForEndpoint:(NSString*)endpoint {
    return [NSString stringWithFormat:@"%@%@", kDOBASEAPIURL, endpoint];
}

- (NSString *)apiURLForEndpointWithComponents:(NSString *)firstComponent, ... NS_REQUIRES_NIL_TERMINATION {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    if(firstComponent) {
        NSLog(@"FirstComponent: %@", firstComponent);
        [array addObject:firstComponent];
        va_list args;
        va_start(args, firstComponent);

        id arg = nil;
        while((arg = va_arg(args, id))) {
            NSLog(@"Component: %@", arg);
            [array addObject:arg];
        }
        va_end(args);
    }

    return [self apiURLForEndpoint:[array componentsJoinedByString:@"/"]];
}


#pragma mark Dynamic item request
- (PMKPromise *)requestForItemWithType:(Class)type andFullURL:(NSString *)url {
    __weak __typeof__(self) weakSelf = self;
    return [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        __strong __typeof__(self) strongSelf = weakSelf;
        [[strongSelf sharedSessionManager] GET:url parameters:nil success:^(NSURLSessionTask *operation, id responseObject) {
            if(![responseObject isKindOfClass:[NSDictionary class]]) {
                reject([DKErrorDomain inconsistentDataReceivedFromEndpoint]);
                return;
            }
            id item = [[type alloc] initWithDictionary:responseObject];
            if(item == nil) {
                reject([DKErrorDomain inconsistentDataReceivedFromEndpoint]);
            } else {
                fulfill(item);
            }
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            reject(error);
        }];
    }];
}


#pragma mark Dynamic collection request
- (PMKPromise *)requestForSpecializedCollectionWithType:(Class)type andFullURL:(NSString *)url andParent:(id)parent {
    __weak __typeof__(self) weakSelf = self;
    return [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        __strong __typeof__(self) strongSelf = weakSelf;
        [[strongSelf sharedSessionManager] GET:url parameters:nil success:^(NSURLSessionTask *operation, id responseObject) {
            if(![responseObject isKindOfClass:[NSDictionary class]]) {
                reject([DKErrorDomain inconsistentDataReceivedFromEndpoint]);
                return;
            }
            id collection = [[type alloc] initWithDictionary:responseObject];
            if(collection == nil) {
                reject([DKErrorDomain inconsistentDataReceivedFromEndpoint]);
            } else {
                if(parent) {
                    for(id item in [collection objects]) {
                        SEL selector = @selector(setParent:);
                        if([item respondsToSelector:selector]) {
                            [item performSelector:@selector(setParent:) withObject:parent];
                        }
                    }
                }
                fulfill(collection);
            }
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            reject(error);
        }];
    }];
}

- (PMKPromise *)requestForSpecializedCollectionWithType:(Class)type andFullURL:(NSString *)url {
    return [self requestForSpecializedCollectionWithType:type andFullURL:url andParent:nil];
}

- (PMKPromise *)requestForCollectionOf:(NSString *)collectionName andType:(Class)type {
    return [self requestForSpecializedCollectionWithType:type andFullURL:[self apiURLForEndpoint:collectionName]];
}


#pragma mark Item deletion request
- (PMKPromise *)requestDeleteForURL:(NSString *)url {
    __weak __typeof__(self) weakSelf = self;
    return [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        __strong __typeof__(self) strongSelf = weakSelf;
        [[strongSelf sharedSessionManager] DELETE:url parameters:nil success:^(NSURLSessionTask *operation, id responseObject) {
            if(((NSHTTPURLResponse*)operation.response).statusCode == 204) {
                fulfill([NSNull null]);
            } else {
                reject([DKErrorDomain inconsistentDataReceivedFromEndpoint]);
            }
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            reject(error);
        }];
    }];
}


#pragma mark Create item request
- (PMKPromise *)requestCreateForURL:(NSString *)url withData:(NSDictionary *)data {
    __weak __typeof__(self) weakSelf = self;
    return [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        __strong __typeof__(self) strongSelf = weakSelf;
        [[strongSelf sharedSessionManager] POST:url parameters:data success:^(NSURLSessionTask *operation, id responseObject) {
            fulfill(responseObject);
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            reject(error);
        }];
    }];
}


#pragma mark Update item request
- (PMKPromise *)requestUpdateForURL:(NSString *)url withData:(NSDictionary *)data {
    __weak __typeof__(self) weakSelf = self;
    return [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        __strong __typeof__(self) strongSelf = weakSelf;
        [[strongSelf sharedSessionManager] PUT:url parameters:data success:^(NSURLSessionTask *operation, id responseObject) {
            fulfill(responseObject);
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            reject(error);
        }];
    }];
}


#pragma Dynamic action request
- (PMKPromise *)requestAction:(NSString *)action forUrl:(NSString *)url {
    return [self requestAction:action forUrl:url andData:@{}];
}

- (PMKPromise *)requestAction:(NSString *)action forUrl:(NSString *)url andData:(NSDictionary *)data {
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary:data];
    [dict setObject:action forKey:@"type"];
    __weak __typeof__(self) weakSelf = self;
    return [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        __strong __typeof__(self) strongSelf = weakSelf;
        [[strongSelf sharedSessionManager] POST:url parameters:dict success:^(NSURLSessionTask *operation, id responseObject) {
            if(![responseObject isKindOfClass:[NSDictionary class]]) {
                reject([DKErrorDomain inconsistentDataReceivedFromEndpoint]);
                return;
            }
            DKAction* action = [[DKAction alloc] initWithDictionary:responseObject];
            if(!action) {
                reject([DKErrorDomain inconsistentDataReceivedFromEndpoint]);
            } else {
                fulfill(action);
            }
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            reject(error);
        }];
    }];
}


#pragma mark Simple items
- (PMKPromise *)getAccountInfo {
    return [self requestForItemWithType:[DKUser class] andFullURL:[self apiURLForEndpoint:@"account"]];
}


#pragma mark Collections
- (PMKPromise *)getDroplets {
    return [self requestForCollectionOf:@"droplets" andType:[DKDropletCollection class]];
}

- (PMKPromise *)getActions {
    return [self requestForCollectionOf:@"actions" andType:[DKActionCollection class]];
}

- (PMKPromise *)getActionWithId:(NSNumber *)actionId {
    return [self requestForItemWithType:[DKAction class] andFullURL:[self apiURLForEndpointWithComponents:@"actions", actionId, nil]];
}

- (PMKPromise *)getDomains {
    return [self requestForCollectionOf:@"domains" andType:[DKDomainCollection class]];
}

- (PMKPromise *)getSSHKeys {
    return [self requestForCollectionOf:@"account/keys" andType:[DKSSHKeyCollection class]];
}

- (PMKPromise *)getImages {
    return [self requestForCollectionOf:@"images" andType:[DKImageCollection class]];
}

- (PMKPromise *)getDistributionImages {
    return [self requestForCollectionOf:@"images?type=distribution" andType:[DKImageCollection class]];
}

- (PMKPromise *)getApplicationImages {
    return [self requestForCollectionOf:@"images?type=application" andType:[DKImageCollection class]];
}

- (PMKPromise *)getUserImages {
    return [self requestForCollectionOf:@"images?private=true" andType:[DKImageCollection class]];
}

- (PMKPromise *)getRegions {
    return [self requestForCollectionOf:@"regions" andType:[DKRegionCollection class]];
}

- (PMKPromise *)getSizes {
    return [self requestForCollectionOf:@"sizes" andType:[DKSizeCollection class]];
}

@end