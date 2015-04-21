//
//  RLReachability.h
//  Reachability
//
//  Created by ChenYong on 9/18/14.
//  Copyright (c) 2014 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "Reachability.h"

typedef NS_ENUM(NSUInteger, RLHostStatus) {
    RLHostNotReachable = 0,
    RLHostReachabilityPending = 1,
    RLHostReachable = 2
};

typedef NS_ENUM(NSUInteger, RLHostNotReachableReason) {
    RLHostNotReachableReasonNone = 0,
    RLHostNotReachableReasonInterfaceNotConnected = 1,
    RLHostNotReachableReasonInterfaceConnectedHostNotReachable = 2
};

typedef NS_ENUM(NSUInteger, RLInterfaceType) {
    RLTypeNone = 0,
    RLTypeWIFI = 1, //WIFI
    RLTypeWWAN = 2  //Celluar
};

@interface RLHostReachabilityInfo : NSObject
@property (nonatomic) RLHostStatus hostStatus;
@property (nonatomic) RLHostNotReachableReason hostStatusReason;
@property (nonatomic) RLInterfaceType interfaceType;
@property (nonatomic) NSString *celluarType;
@end

@interface RLReachability : NSObject
@property (nonatomic, readonly) RLHostStatus hostStatus;

- (instancetype)initWithGetURL:(NSString*)urlString verificationHandler:(BOOL (^)(NSData *data))handler;
- (RLHostReachabilityInfo*)currentReachabilityStatus;
+ (NSString*)hostReachabilityInfoString:(RLHostReachabilityInfo*)info;
+ (NSString*)hostStatusString:(RLHostStatus)hostStatus;

@end
