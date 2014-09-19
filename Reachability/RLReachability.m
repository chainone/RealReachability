//
//  RLReachability.m
//  Reachability
//
//  Created by ChenYong on 9/18/14.
//  Copyright (c) 2014 Apple Inc. All rights reserved.
//

#import "RLReachability.h"

NSString *kInternetStatusChangedNotification = @"kInternetStatusChangedNotification";

@implementation RLInternetReachabilityInfo
@end

@interface RLReachability()
{
    NSURL* _url;
    RLInternetStatus _intenetStatus;
    NSIndexSet* _acceptableStatusCodes;
    BOOL (^_verifyBlock)(NSData *data);
    dispatch_semaphore_t _sema;
}

@end


@implementation RLReachability

-(instancetype)initWithGetURL:(NSString*)urlString VerificationHandler:(BOOL (^)(NSData *data))handler
{
    self = [super init];
    if(self)
    {
        NSCParameterAssert(urlString);
        _intenetStatus = RLInternetNotReachable;
        _acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
        _verifyBlock = handler;
        _url= [NSURL URLWithString:urlString];
        if (_url) {
            NSString* host = [_url host];
            _applReachability = [Reachability reachabilityWithHostName:host];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_interfaceStatusChanged:) name:kReachabilityChangedNotification object:nil];
            [_applReachability startNotifier];
        }
    }

    return self;
}


-(void)_interfaceStatusChanged:(NSNotification*)notification
{
    NetworkStatus interfaceStatus = [_applReachability currentReachabilityStatus];
    if(interfaceStatus != NotReachable)
    {
        RLInternetStatus oldInternetStatus = _intenetStatus;
        _intenetStatus = RLInternetReachabilityPending;
        [[NSNotificationCenter defaultCenter] postNotificationName: kInternetStatusChangedNotification object: self];
        NSLog(@"Start to send the request to check the internet status, pending...");
        _sema = dispatch_semaphore_create(0);
        __weak typeof(self)weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [[[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:_url] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
              {
                  __strong typeof(weakSelf)strongSelf = weakSelf;
                  RLInternetStatus retStatus = RLInternetNotReachable;
                  if(!error)
                  {
                      if([_acceptableStatusCodes containsIndex:((NSHTTPURLResponse*)response).statusCode])
                      {
                          if(_verifyBlock){
                              retStatus = _verifyBlock(data) ? RLInternetReachable: RLInternetNotReachable;
                          }
                      }
                      
                  }
                  
                  strongSelf->_intenetStatus = retStatus;
                  
                  if(retStatus != oldInternetStatus/* || (retStatus == RLInternetReachable && oldInternetStatus == RLInternetReachable)*/)
                  {
                      // Post a notification to notify the client that the network reachability changed.
                    dispatch_async(dispatch_get_main_queue(),^{
                      [[NSNotificationCenter defaultCenter] postNotificationName: kInternetStatusChangedNotification object: strongSelf];
                    });
                  }
                  dispatch_semaphore_signal(_sema);
                 

                  
                  

              }] resume];
        });
        
        
    }
    else
    {
        _intenetStatus = RLInternetNotReachable;
        [[NSNotificationCenter defaultCenter] postNotificationName: kInternetStatusChangedNotification object: self];
    }

}

-(NetworkStatus)currentInterfaceStatus
{
    return [_applReachability currentReachabilityStatus];
}

-(RLInternetReachabilityInfo*)currentInternetStatus
{
    NetworkStatus interfaceStatus = [_applReachability currentReachabilityStatus];
    RLInternetReachabilityInfo* info = [RLInternetReachabilityInfo new];
    if(interfaceStatus != NotReachable)
    {
        info.interfaceType = (interfaceStatus == ReachableViaWiFi) ? RLTypeWIFI : RLTypeWWAN;
        info.internetStatus = _intenetStatus;
    }
    else
    {
        info.interfaceType = RLTypeNone;
        //NSCAssert(_intenetStatus == RLInternetNotReachable, @"Internal internet status should also be not reachable!");
        info.internetStatus = RLInternetNotReachable;
    }
    
    
    return info;
}

-(BOOL)isInterfaceConnected
{
    NetworkStatus interfaceStatus = [_applReachability currentReachabilityStatus];
    return interfaceStatus!=NotReachable;
}

-(BOOL)isInternetConnectedSync
{
    if(_intenetStatus == RLInternetReachabilityPending)
    {
        dispatch_semaphore_wait(_sema, DISPATCH_TIME_FOREVER);
    }
    
    return [self currentInternetStatus].internetStatus == RLInternetReachable;

}

-(void)dealloc
{
    [_applReachability stopNotifier];
}

@end
