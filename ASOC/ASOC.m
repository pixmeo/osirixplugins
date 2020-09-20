#import "ASOC.h"

#import <AppleScriptObjC/AppleScriptObjC.h>
@protocol ASOCprotocol
- (void)sayHello;//simple call
- (NSString *)getFinderVersion;//return value
- (void)say:(NSString*)phrase;//call with direct parameter. (the applescript handler with direct parameter is ended by underscore, which shouldn´t be copied into the protocol definition)
@end

@implementation ASOC

static Class ASOCclass;
static id<ASOCprotocol> ASOCinstance;

- (void) initPlugin
{
    [[NSBundle bundleForClass:[self class]] loadAppleScriptObjectiveCScripts];
    ASOCclass = NSClassFromString(@"ASOCscript");
    if (!ASOCclass) NSLog(@"INFO [ASOC] ASOCclass not found");
    else
    {
        [ASOCclass retain];
        ASOCinstance = [[ASOCclass alloc] init];
        if (!ASOCinstance) NSLog(@"INFO [ASOC] ASOCinstance not initialized");
        else  NSLog(@"INFO [ASOC] ASOCinstance initialized");
    }
}

- (long) filterImage:(NSString*) menuName
{
    //calls to the class based in the Applescript
    
    if      ([menuName hasPrefix:@"[a]"]) [ASOCinstance sayHello];
    else if ([menuName hasPrefix:@"[b]"]) NSLog(@"Finder version = %@", [ASOCinstance getFinderVersion]);
    else if ([menuName hasPrefix:@"[c]"]) [ASOCinstance say:@"you are a genius"];
    
	return 0;   // No Errors
}

@end
