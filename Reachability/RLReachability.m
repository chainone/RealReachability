//
//  RLReachability.m
//  Reachability
//
//  Created by ChenYong on 9/18/14.
//  Copyright (c) 2014 Apple Inc. All rights reserved.
//

#import "RLReachability.h"

static NSString * const hostStatusKeyPath = @"hostStatus";

@interface RLReachability()

@property (nonatomic, readwrite) Reachability* applReachability;
@property (nonatomic, readwrite) RLHostStatus hostStatus;
@property (nonatomic, readwrite) CTTelephonyNetworkInfo *celluarNetworkInfo;

@end

@implementation RLHostReachabilityInfo
@end

@interface RLReachability()
{
    NSIndexSet *_acceptableStatusCodes;
    NSURL *_url;
    BOOL (^_verifyBlock)(NSData *data);
}

@end


@implementation RLReachability

-(instancetype)initWithGetURL:(NSString*)urlString verificationHandler:(BOOL (^)(NSData *data))handler
{
    self = [super init];
    if(self)
    {
        NSCParameterAssert(urlString);
        _acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
        _verifyBlock = handler;
        self.celluarNetworkInfo = [CTTelephonyNetworkInfo new];
        _url= [NSURL URLWithString:urlString];
        if (_url) {
            self.applReachability = [Reachability reachabilityForInternetConnection];
            [self _reachabilityStatusChanged];
            [_applReachability startNotifier];
            [self _setupBindings];
        }
    }

    return self;
}

- (void)_setupBindings{
    
    //1. Create Signals that would trigger host reachability change
    //   following events could potentially impact the reachability status:
    //
    //  a. reachability change
    //
    @weakify(self)
    RACSignal *reachabilityChangeSig = [[[self.applReachability rac_signalForSelector:@selector(reachabilityChanged:)] deliverOnMainThread] doNext:^(id __unused _) {
        @strongify(self)
        NSLog(@"%@: Interface reachability status changed to %@ ",[NSDate date], @(self.applReachability.currentReachabilityStatus != NotReachable));
    }];
    
    //
    //  b. celluar change
    //
    RACSignal *celluarTypeChangeSig = [[[NSNotificationCenter.defaultCenter rac_addObserverForName:CTRadioAccessTechnologyDidChangeNotification object:nil] takeUntil:[self rac_willDeallocSignal]] doNext:^(id __unused _) {
        @strongify(self)
        NSLog(@"%@: Celluar type changed to %@ ",[NSDate date], self.celluarNetworkInfo.currentRadioAccessTechnology);
    }];
    
    //
    //  c. timer based check
    //
    RACSignal *timerCheckSig = [[RACSignal interval:2*60 onScheduler:[RACScheduler mainThreadScheduler]] doNext:^(id __unused _) {
        NSLog(@"%@: timer check initiated",[NSDate date]);
    }];
    
    [[RACSignal merge:@[reachabilityChangeSig, celluarTypeChangeSig, timerCheckSig]] subscribeNext:^(id __unused _) {
        @strongify(self)
        [self _reachabilityStatusChanged];
    }];
}


- (void)_reachabilityStatusChanged{
    NSCParameterAssert(self->_url);
    
    if ([self.applReachability currentReachabilityStatus] == NotReachable) {
        [self _setHostStatusOnMainThread:RLHostNotReachable];
    }else{
        [self _setHostStatusOnMainThread:RLHostReachabilityPending];
        NSLog(@"Start to send the request to check the internet status, pending...");
        
        @weakify(self)
        [[[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:_url] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
            @strongify(self)
            RLHostStatus retStatus = RLHostNotReachable;
            if(!error){
                if([self->_acceptableStatusCodes containsIndex:((NSHTTPURLResponse*)response).statusCode]){
                    if(_verifyBlock){
                        retStatus = self->_verifyBlock(data) ? RLHostReachable: RLHostNotReachable;
                    }else
                        retStatus = RLHostReachable;
                }
            }
            
            NSLog(@"Check finished, host reachability:%@", @(retStatus));
            [self _setHostStatusOnMainThread:retStatus];
        }] resume];
    }
}



-(void)_setHostStatusOnMainThread:(RLHostStatus)hostStatus{
    dispatch_async(dispatch_get_main_queue(),^{
        self.hostStatus = hostStatus;
    });
}

-(RLHostReachabilityInfo*)currentReachabilityStatus{
    NetworkStatus interfaceStatus = [_applReachability currentReachabilityStatus];
    RLHostReachabilityInfo* info = [RLHostReachabilityInfo new];
    if(interfaceStatus != NotReachable)
    {
        info.interfaceType = (interfaceStatus == ReachableViaWiFi) ? RLTypeWIFI : RLTypeWWAN;
        info.hostStatus = self.hostStatus;
        if(self.hostStatus == RLHostNotReachable)
            info.hostStatusReason = RLHostNotReachableReasonInterfaceConnectedHostNotReachable;
        else
            info.hostStatusReason = RLHostNotReachableReasonNone;
        
        if (info.interfaceType == RLTypeWIFI)
            info.celluarType = @"";
        else
            info.celluarType = self.celluarNetworkInfo.currentRadioAccessTechnology;
    }else{
        NSCAssert(info.hostStatus == RLHostNotReachable, @"reachable status should match", @"");
        info.interfaceType = RLTypeNone;
        info.hostStatus = RLHostNotReachable;
        info.hostStatusReason = RLHostNotReachableReasonInterfaceNotConnected;
        info.celluarType = @"";
    }
    
    return info;
}


-(void)dealloc{
    [_applReachability stopNotifier];
}


+ (NSString*)hostStatusString:(RLHostStatus)hostStatus{
    switch (hostStatus) {
        case RLHostNotReachable:
            return @"Host Not Reachable";
        
        case RLHostReachabilityPending:
            return @"Checking host...";
            
        case RLHostReachable:
            return @"Host Reachable";
    }
}

+ (NSString*)_hostStatusReasonString:(RLHostNotReachableReason)reason{
    switch (reason) {
        case RLHostNotReachableReasonInterfaceConnectedHostNotReachable:
            return @"Interface Connected but host not reachable";
        case RLHostNotReachableReasonInterfaceNotConnected:
            return @"Interface not connected";
        case RLHostNotReachableReasonNone:
            return @"None";
    }
}


+ (NSString*)_interfaceTypeString:(RLInterfaceType)type{
    switch (type) {
        case RLTypeWIFI:
            return @"WIFI";
        case RLTypeWWAN:
            return @"Celluar";
        case RLTypeNone:
            return @"None";
    }
}

+ (NSString*)hostReachabilityInfoString:(RLHostReachabilityInfo*)info{
    NSCParameterAssert(info);
    if (!info)
        return nil;
    
    return [NSString stringWithFormat:@"%@, reason: %@ interface:%@, celluar:%@", [RLReachability hostStatusString:info.hostStatus], [RLReachability _hostStatusReasonString:info.hostStatusReason], [RLReachability _interfaceTypeString:info.interfaceType], info.celluarType];
}

@end
