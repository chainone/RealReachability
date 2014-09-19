/*
     File: APLViewController.m
 Abstract: Application delegate class.
  Version: 3.5
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "APLViewController.h"
#import "RLReachability.h"


@interface APLViewController ()

@property (nonatomic, weak) IBOutlet UILabel* summaryLabel;

@property (nonatomic, weak) IBOutlet UITextField *remoteHostLabel;
@property (nonatomic, weak) IBOutlet UIImageView *remoteHostImageView;
@property (nonatomic, weak) IBOutlet UITextField *remoteHostStatusField;


@property (nonatomic) RLReachability *hostReachability;

@end


BOOL (^verifyBlock)(NSData* data) = ^BOOL(NSData* data){
    NSError* error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingMutableContainers) error:&error];
    if(error)
        return NO;
    else{
        NSLog(@"%@", [dict description]);
        NSString* status = [dict objectForKey:@"status"];
        if([status isEqualToString:@"GOOD"]){
            return YES;
        }else{
            return NO;
        }
    }
    
};



@implementation APLViewController

- (void)viewDidLoad
{
    self.summaryLabel.hidden = YES;

    /*
     Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the method reachabilityChanged will be called.
     */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kInternetStatusChangedNotification object:nil];

    NSString *remoteURL = @"https://b4.autodesk.com/api/system/v1/health.json?detailed=0";
    NSString *remoteURLFormatString = NSLocalizedString(@"Remote URL: %@", @"Remote host label format string");
    self.remoteHostLabel.text = [NSString stringWithFormat:remoteURLFormatString, remoteURL];
	self.hostReachability = [[RLReachability alloc] initWithGetURL:remoteURL VerificationHandler:verifyBlock];
    [self updateInterfaceWithReachability];
}


/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note
{
	RLReachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass:[RLReachability class]] && _hostReachability == curReach);
	[self updateInterfaceWithReachability];
}


- (void)updateInterfaceWithReachability
{
    NSString* statusString;
    RLInternetReachabilityInfo* info = [_hostReachability currentInternetStatus];
    switch (info.internetStatus) {
        case RLInternetNotReachable:
            statusString = NSLocalizedString(@"Access Not Available", @"Text field text for access is not available");
            self.remoteHostImageView.image = [UIImage imageNamed:@"stop-32.png"] ;
            break;
        case RLInternetReachabilityPending:
            statusString = NSLocalizedString(@"Checking Internet status", @"Text field text for checking status");
            self.remoteHostImageView.image = [UIImage imageNamed:@"stop-32.png"] ;
            break;
            
        case RLInternetReachable:
        {
            switch (info.interfaceType) {
                case RLTypeWIFI:
                    statusString = NSLocalizedString(@"Reachable WWAN", @"");
                    self.remoteHostImageView.image = [UIImage imageNamed:@"WWAN5.png"];
                    break;
                case RLTypeWWAN:
                    statusString= NSLocalizedString(@"Reachable WiFi", @"");
                    self.remoteHostImageView.image = [UIImage imageNamed:@"Airport.png"];
                    break;
                default:
                    break;
            }
        }
            
            break;
            
        default:
            break;
    }
    _remoteHostStatusField.text = statusString;
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kInternetStatusChangedNotification object:nil];
}


@end
