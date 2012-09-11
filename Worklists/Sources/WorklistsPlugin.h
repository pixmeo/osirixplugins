//
//  HelloWorldFilter.h
//  HelloWorld
//
//  Copyright (c) 2008 Joris Heuberger. All rights reserved.
//

#import <OsiriXAPI/PluginFilter.h>

@class WorklistsPlugin;

@interface WorklistsPlugin : PluginFilter {
    NSArrayController* _worklists;
}

@property(readonly,retain) NSArrayController* worklists;

+ (WorklistsPlugin*)instance;

@end
