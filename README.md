RealReachability
================
RealReachability is based on Apple's Reachability code

Apple's Reachability will not actually test if the host reachable or not. 
It only does the host name translation(if what is given is a host name ) and the package can leave NIC

RealReachability takes an URL for testing the actual reachability of the given host. It does async reachability check but it also privoe a method for you to do sync reachability check if the current status is pending.
Real reachability status change notifcation would be delivered to main thread.

Usage:
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kInternetStatusChangedNotification object:nil];
NSString *remoteURL = @"https://b4.autodesk.com/api/system/v1/health.json?detailed=0";
self.hostReachability = [[RLReachability alloc] initWithGetURL:remoteURL VerificationHandler:verifyBlock];


