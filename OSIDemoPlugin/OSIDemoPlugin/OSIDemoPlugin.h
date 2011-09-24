//
//  OSIDemoPlugin.h
//  OSIDemo
//
//  Created by Joël Spaltenstein on 2/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OsiriXAPI/PluginFilter.h>

@interface OSIDemoPlugin : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;


@end
