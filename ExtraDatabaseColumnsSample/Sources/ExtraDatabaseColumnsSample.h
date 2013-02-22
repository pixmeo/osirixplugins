//
//  ExtraDatabaseColumnsSample.h
//  ExtraDatabaseColumnsSample
//
//  Copyright (c) 2013 Alessandro Volz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>

@interface ExtraDatabaseColumnsSample : PluginFilter {
    NSTableColumn* _tc;
}

@property(retain) NSTableColumn* tc;

@end