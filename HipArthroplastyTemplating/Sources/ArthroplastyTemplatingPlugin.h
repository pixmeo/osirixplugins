//
//  ArthroplastyTemplatingPlugin.h
//  Arthroplasty Templating II
//  Created by Joris Heuberger on 04/04/07.
//  Modified by Alessandro Volz since 07/2009
//  Copyright (c) 2007-2009 OsiriX Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>
@class ArthroplastyTemplatingWindowController, ArthroplastyTemplatingStepsController;

@interface ArthroplastyTemplatingPlugin : PluginFilter {
	ArthroplastyTemplatingWindowController *_templatesWindowController;
	NSMutableArray* _windows;
	BOOL _initialized;
}

@property(readonly) ArthroplastyTemplatingWindowController* templatesWindowController;

-(ArthroplastyTemplatingStepsController*)windowControllerForViewer:(ViewerController*)viewer;

@end
