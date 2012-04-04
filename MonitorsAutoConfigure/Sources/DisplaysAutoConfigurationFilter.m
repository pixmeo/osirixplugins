//
//  MonitorsAutoConfigureFilter.m
//  MonitorsAutoConfigure
//
//  Copyright (c) 2012 OsiriX. All rights reserved.
//

#import "DisplaysAutoConfigurationFilter.h"
#import <OsiriXAPI/NSScreen+N2.h>
#import <OsiriXAPI/NSUserDefaults+OsiriX.h>
#import <objc/runtime.h>
#import <IOKit/graphics/IOGraphicsLib.h>

@implementation DisplaysAutoConfigurationFilter

- (void)initPlugin {
    Class nsScreenClass = [NSScreen class];
    if (!class_getInstanceMethod(nsScreenClass, @selector(screenNumber)))
        [NSException raise:NSGenericException format:@"this plugin requires a more recent version of OsiriX"];
    
    NSDictionary* vendorsDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Displays" ofType:@"plist"]];
    // reformat plist data for easier search
    NSMutableDictionary* dd = [NSMutableDictionary dictionary];
    for (NSString* key in vendorsDict) {
        NSDictionary* vendorDict = [vendorsDict objectForKey:key];
        NSNumber* vendorID = [vendorDict objectForKey:@kDisplayVendorID];
        if (!vendorID) continue;
        
        NSMutableDictionary* vd = [NSMutableDictionary dictionary];
        [dd setObject:vd forKey:vendorID];
        
        NSDictionary* productsDict = [vendorDict objectForKey:@"Products"];
        for (NSString* key in productsDict) {
            NSDictionary* productDict = [productsDict objectForKey:key];
            NSNumber* productID = [productDict objectForKey:@kDisplayProductID];
            if (!productID) continue;
            
            NSArray* a = [productDict objectForKey:@"Excluded Serial Numbers"];
            if (!a) a = [NSArray array];
            [vd setObject:a forKey:productID];
        }
    }
    
    NSArray* screens = [NSScreen screens];
    NSMutableArray* matchedScreens = [NSMutableArray array];
    for (NSScreen* screen in screens) {
        NSDictionary* screenInfo = [(NSDictionary*)IODisplayCreateInfoDictionary(CGDisplayIOServicePort([screen screenNumber]), kIODisplayOnlyPreferredName) autorelease];
        // NSLog(@"Screen: %@\n%@", screen, screenInfo);
        
        NSNumber* vendorID = [screenInfo objectForKey:@kDisplayVendorID];
        NSNumber* productID = [screenInfo objectForKey:@kDisplayProductID];
        NSNumber* serialNumber = [screenInfo objectForKey:@kDisplaySerialNumber];
        
        NSArray* e = [[dd objectForKey:vendorID] objectForKey:productID];
        if (e && ![e containsObject:serialNumber])
            [matchedScreens addObject:screen];
        
        NSLog(@"Display %@, %@, %@, %@: %@", vendorID, productID, serialNumber, [screen displayName], ([matchedScreens containsObject:screen]? @"matched" : @"NOT matched"));
    }
    
    if (matchedScreens.count) // we found at least one eligible display
        for (NSScreen* screen in screens)
            [[NSUserDefaults standardUserDefaults] screen:screen setIsUsedForViewers:[matchedScreens containsObject:screen]];
}

- (long)filterImage:(NSString*)menuName {
    return 0;
}

@end
