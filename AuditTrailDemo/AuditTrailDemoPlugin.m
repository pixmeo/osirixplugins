
#import "AuditTrailDemoPlugin.h"
#import <objc/runtime.h>
#import "ViewerController+AuditTrailOverride.h"
#import <CoreServices/CoreServices.h>

void AuditTrailInvocationCallback(WSMethodInvocationRef invocation, void *info, CFDictionaryRef outRef);

@interface AuditTrailDemoPlugin ()
@property (nonatomic, retain, readwrite) NSNetService *serverNetService;

- (void)processAuditItems;
- (void)setupSwizzles;

@end

// This plugin object is in practice a singleton created and initialized by OsiriX, and so we will treat it as such
static AuditTrailDemoPlugin *_sharedAuditTrailDemoPlugin = nil;

@implementation AuditTrailDemoPlugin
@synthesize serverNetService;

#pragma mark -
#pragma mark Class Methods

+ (AuditTrailDemoPlugin *)sharedAuditTrailDemoPlugin
{
    return _sharedAuditTrailDemoPlugin;
}

#pragma mark -
#pragma mark Public Methods

- (void)initPlugin
{
    _sharedAuditTrailDemoPlugin = [self retain];
    
    netServiceBrowser = [[NSNetServiceBrowser alloc] init];
    [netServiceBrowser setDelegate:self];
    [netServiceBrowser searchForServicesOfType:@"_http._tcp." inDomain:@""];
    
    storedAuditItems = [[NSMutableArray alloc] init];
    
    [self setupSwizzles];
    
    [[AuditTrailDemoPlugin sharedAuditTrailDemoPlugin] postAuditItemWithAction:@"Opened" patientName:nil note:@"It Started"];
}

- (void)postAuditItemWithAction:(NSString *)action patientName:(NSString *)patientName note:(NSString *)note
{
    if ([action length] == 0) {
        NSLog(@"postAuditItemWithAction:patientName:note: had got no action");
        return;
    }
    
    NSMutableDictionary *auditItemDictionary = [NSMutableDictionary dictionary];
    [auditItemDictionary setObject:action forKey:@"action"];
    if (patientName) {
        [auditItemDictionary setObject:patientName forKey:@"patientName"];
    }
    if (note) {
        [auditItemDictionary setObject:note forKey:@"note"];
    }
    
    [storedAuditItems addObject:auditItemDictionary];
    [self processAuditItems];
}


#pragma mark -
#pragma mark Private Methods

- (void)processAuditItems
{
    NSString *serverHostName = [serverNetService hostName];
    NSInteger serverPort = [serverNetService port];
    
    if (serverHostName) {
        for (NSDictionary *auditItemDictionary in storedAuditItems) {
            NSString *action = [auditItemDictionary objectForKey:@"action"];
            NSString *patientName = [auditItemDictionary objectForKey:@"patientName"];
            NSString *note = [auditItemDictionary objectForKey:@"note"];
            
            NSMutableDictionary *paramStruct = [NSMutableDictionary dictionaryWithObjectsAndKeys:NSUserName(), @"userName", nil];
            if (patientName) {
                [paramStruct setObject:patientName forKey:@"patientName"];
            }
            if (note) {
                [paramStruct setObject:note forKey:@"note"];
            }
            
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%lld/", serverHostName, (long long)serverPort]];
            WSMethodInvocationRef invocationRef = WSMethodInvocationCreate((CFURLRef)url, (CFStringRef)action, kWSXMLRPCProtocol);
            WSMethodInvocationSetParameters(invocationRef, (CFDictionaryRef)[NSDictionary dictionaryWithObject:paramStruct forKey:@"paramStruct"],
                                            (CFArrayRef)[NSArray arrayWithObject:@"paramStruct"]);
            WSMethodInvocationSetCallBack(invocationRef, AuditTrailInvocationCallback, NULL);
            WSMethodInvocationScheduleWithRunLoop(invocationRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        }
        [storedAuditItems removeAllObjects];
    }
}

- (void)setupSwizzles
{
    Method auditTrailInitWithPixMethod = class_getInstanceMethod([ViewerController class], @selector(auditTrailInitWithPix:withFiles:withVolume:));
    Method initWithPixMethod = class_getInstanceMethod([ViewerController class], @selector(initWithPix:withFiles:withVolume:));
    
    method_exchangeImplementations(auditTrailInitWithPixMethod, initWithPixMethod);
}

#pragma mark -
#pragma mark Delegate Methods

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing
{
    if ([[netService name] isEqualToString:@"OsiriX Audit Trail Server"]) {
        self.serverNetService = netService;
        [netService setDelegate:self];
        [netService resolveWithTimeout:10];
    }
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{    
    [self processAuditItems];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    NSLog(@"netService did not resolve, trying again: @%@", errorDict);
    [sender resolveWithTimeout:10];
}

@end

#pragma mark -
#pragma mark Web Services Callback


void AuditTrailInvocationCallback(WSMethodInvocationRef invocation, void *info, CFDictionaryRef outRef)
{
    CFRelease(invocation);
    NSLog(@"AuditTrailInvocationCallback did return");
}
                
                













