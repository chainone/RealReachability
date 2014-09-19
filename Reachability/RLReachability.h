//
//  RLReachability.h
//  Reachability
//
//  Created by ChenYong on 9/18/14.
//  Copyright (c) 2014 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "Reachability.h"

extern NSString *kInternetStatusChangedNotification;

typedef NS_ENUM(NSUInteger, RLInternetStatus) {
    RLInternetNotReachable = 0,
    RLInternetReachabilityPending = 1,
    RLInternetReachable = 2
};

typedef NS_ENUM(NSUInteger, RLInterfaceType) {
    RLTypeNone = 0,
    RLTypeWIFI = 1, //WIFI
    RLTypeWWAN = 2  //3G
};


@interface RLInternetReachabilityInfo : NSObject
@property (nonatomic) RLInternetStatus internetStatus;
@property (nonatomic) RLInterfaceType interfaceType;
@end

@interface RLReachability : NSObject

@property (nonatomic, readonly) Reachability* applReachability;

-(instancetype)initWithGetURL:(NSString*)urlString VerificationHandler:(BOOL (^)(NSData *data))handler;

-(BOOL)isInterfaceConnected;

-(BOOL)isInternetConnectedSync;

-(NetworkStatus)currentInterfaceStatus;

-(RLInternetReachabilityInfo*)currentInternetStatus;


@end
