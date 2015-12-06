//
//  DKAction.m
//  DropletKit
//
//  Created by Victor Gama on 5/2/15.
//  Copyright (c) 2015 Victor Gama. All rights reserved.
//

#import "DKAction.h"
#import "DropletKit.h"

@implementation DKAction

#pragma mark Life cycle
- (instancetype)initWithDictionary:(NSDictionary *)data {
    self = [super init];
    if([[data allKeys] containsObject:@"action"]) {
        data = [data objectForKey:@"action"];
    }
    if(!CHECK_DATA_CONTAINS(id, status, type, started_at, completed_at, resource_id, resource_type, region_slug)) {
        self = nil;
    } else {
        // Common Items
        CALL_MACRO_X_FOR_EACH(EXPAND_DATA, status, type)
        // Renamed items
        EXPAND_DATA_LOCAL(id, actionId);
        EXPAND_DATA_LOCAL(resource_id, resourceId)
        EXPAND_DATA_LOCAL(resource_type, resourceType)
        EXPAND_DATA_LOCAL(region_slug, regionSlug)
        // NSDate items
        EXPAND_DATA_DATE_LOCAL(started_at, startedAt);
        if([[data allKeys] containsObject:@"completed_at"]) {
            self.completed = YES;
            EXPAND_DATA_DATE_LOCAL(completed_at, completedAt);
        } else {
            self.completed = NO;
        }
    }
    return self;
}

- (void)reloadWithBlock:(void (^)(BOOL))block {
    [[DKClient sharedInstance] getActionWithId:self.actionId].then(^(DKAction *action) {
        NSArray *baseSelectors = @[
                                   @"Status",
                                   @"Type",
                                   @"ActionId",
                                   @"ResourceId",
                                   @"ResourceType",
                                   @"RegionSlug",
                                   @"StartedAt",
                                   @"Completed",
                                   @"CompletedAt"
                                   ];
        for(NSString *selectorBase in baseSelectors) {
            SEL getter = NSSelectorFromString([NSString stringWithFormat:@"get%@", selectorBase]);
            SEL setter = NSSelectorFromString([NSString stringWithFormat:@"set%@:", selectorBase]);
            if([self respondsToSelector:setter] && [action respondsToSelector:getter]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self performSelector:setter withObject:[action performSelector:getter]];
#pragma clang diagnostic pop
            } else {
                // We have a problem.
                NSLog(@"[DropletKit] DKAction reloadWithBlock: could not copy using selector tuple: %@ %@", NSStringFromSelector(getter), NSStringFromSelector(setter));
            }
        }
        block(YES);
    }).catch(^{
        block(NO);
    });
}

@end
