
#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#import <OsiriXAPI/PluginFilter.h>


@interface AuditTrailDemoPlugin : PluginFilter <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
{
    NSNetServiceBrowser *netServiceBrowser;
    NSNetService *serverNetService;
    
    NSMutableArray *storedAuditItems;
}

+ (AuditTrailDemoPlugin *)sharedAuditTrailDemoPlugin;

- (void)postAuditItemWithAction:(NSString *)action patientName:(NSString *)patientName note:(NSString *)note;

@end
    