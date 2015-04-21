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


static BOOL (^verifyBlock)(NSData* data) = ^BOOL(NSData* data){
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
    [super viewDidLoad];

    NSString *remoteURL = @"http://www.baidu.com";
    self.remoteHostLabel.text = [NSString stringWithFormat:@"Host:%@", remoteURL];
	self.hostReachability = [[RLReachability alloc] initWithGetURL:remoteURL verificationHandler:nil];
    [self addObserver:self forKeyPath:@"hostReachability.hostStatus" options:(NSKeyValueObservingOptions)(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:nil];
    
    [self updateInterfaceWithReachability];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"hostReachability.hostStatus"]) {
        [self updateInterfaceWithReachability];
    }
}

- (void)updateInterfaceWithReachability
{
    RLHostReachabilityInfo* info = [self.hostReachability currentReachabilityStatus];
    
    switch (info.hostStatus) {
        case RLHostNotReachable:
            self.remoteHostImageView.image = [UIImage imageNamed:@"stop-32.png"] ;
            break;
        case RLHostReachabilityPending:
            self.remoteHostImageView.image = [UIImage imageNamed:@"Pending.png"] ;
            break;
            
        case RLHostReachable:{
            switch (info.interfaceType) {
                case RLTypeWWAN:
                    self.remoteHostImageView.image = [UIImage imageNamed:@"WWAN5.png"];
                    break;
                case RLTypeWIFI:
                    self.remoteHostImageView.image = [UIImage imageNamed:@"Airport.png"];
                    break;
                case RLTypeNone:
                    break;
            }
        }
            break;
    }
    
    self.remoteHostStatusField.text = [RLReachability hostStatusString:info.hostStatus];
    [self.summaryLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.summaryLabel.text = [RLReachability hostReachabilityInfoString:info];
}

- (void)dealloc{
    [self removeObserver:self forKeyPath:@"hostReachability.hostStatus"];
}


@end
