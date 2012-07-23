//
//  ViewerController+AuditTrailOverride.m
//  AuditTrailDemo
//
//  Created by Joël Spaltenstein on 7/9/12.
//  Copyright (c) 2012 Spaltenstein Natural Image. All rights reserved.
//

#import "ViewerController+AuditTrailOverride.h"
#import "AuditTrailDemoPlugin.h"

@implementation ViewerController (AuditTrailOverride)

- (id)auditTrailInitWithPix:(NSMutableArray*)f withFiles:(NSMutableArray*)d withVolume:(NSData*) v
{
    id returnValue = [self auditTrailInitWithPix:f withFiles:d withVolume:v];
    
    NSString *patientName = [[[[self imageView] dcmFilesList] objectAtIndex: 0] valueForKeyPath:@"series.study.name"];
    NSString *studyName = [[[[self imageView] dcmFilesList] objectAtIndex: 0] valueForKeyPath:@"series.study.studyName"];
    NSString *note = [NSString stringWithFormat:@"study name: %@", studyName];
    
    [[AuditTrailDemoPlugin sharedAuditTrailDemoPlugin] postAuditItemWithAction:@"Opened 2D Viewer" patientName:patientName note:note];
    
    return returnValue;
}

@end
