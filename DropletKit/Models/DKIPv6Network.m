//
//  DKIPv6Network.m
//  DropletKit
//
//  Created by Victor Gama on 5/5/15.
//  Copyright (c) 2015 Victor Gama. All rights reserved.
//

#import "DKIPv6Network.h"
#import "DropletKit.h"

@implementation DKIPv6Network
@synthesize ipAddress, netmask, gateway, type;

#pragma mark Life cycle
- (void)fillInstanceWithDictionary:(NSDictionary *)data {
    if(CHECK_DATA_CONTAINS(ip_address, netmask, gateway, type)) {
        CALL_MACRO_X_FOR_EACH(EXPAND_DATA, netmask, gateway, type)
        EXPAND_DATA_LOCAL(ip_address, ipAddress)
    }
}
@end
