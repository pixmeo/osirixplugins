//
//  SandBoxTestFilter.h
//  SandBoxTest
//
//  Copyright (c) 2013 Thomas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>
#import <OsiriXAPI/BrowserController.h>

#import <Cocoa/Cocoa.h>

#import <S_BurnerWindowController.h>

@class DRTrack;
@class DicomDatabase;



@interface SandBoxFilter : PluginFilter
{
	S_BurnerWindowController *m_window;
	
}

- (long) filterImage:(NSString*) menuName;


@end








