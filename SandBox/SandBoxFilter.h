//
//  SandBoxFilter.h
//  SandBox
//
//  Copyright (c) 2013 Thomas. All rights reserved.
//

#import <SandboxWindowController.h>

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>




@interface SandBoxFilter : PluginFilter
{
	SandboxWindowController *m_window;
}

- (long) filterImage:(NSString*) menuName;

@end








