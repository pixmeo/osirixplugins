//
//  DiscPublishing+Toolm.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 6/24/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishing.h"


@interface DiscPublishing (Tool)

+(NSAppleScript*)toolAS;

+(NSString*)PublishDisc:(NSString*)name root:(NSString*)root info:(NSDictionary*)info; // return taskId
+(NSArray*)ListTasks; // returns all current tasks' taskId
+(NSDictionary*)GetTaskInfo:(NSString*)taskId;
+(void)SetQuitWhenDone:(BOOL)flag;
+(NSString*)GetStatusXML;
+(void)SetBinSelection:(BOOL)enabled leftBinMediaType:(NSUInteger)leftBinMediaType rightBinMediaType:(NSUInteger)rightBinMediaType defaultBin:(NSUInteger)defaultBin;

@end
