//
//  ExportROIsPlugin.h
//  ExportROIs
//
//  Copyright (c) 2005 Yuichi Matsuyama & Tatsuo Hiramatsu, Team Lampway.
//  All rights reserved.
//  Distributed under GNU - GPL

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

#define DQUOTE 0x22
#define LF 0x0a

typedef enum {
	FT_NONE		= -1,
	FT_XML		= 1,
	FT_CSV
} EXPORT_FILE_TYPE;

@interface ExportROIsPlugin : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;

- (long) exportROIs;
- (void) endSavePanel: (NSSavePanel *) sheet returnCode: (int) retCode contextInfo: (void *) contextInfo;

@end
