//
//  CloseThisStudyFilter.m
//  CloseThisStudy
//
//  Copyright (c) 2012 OsiriX. All rights reserved.
//

#import "CloseThisStudyFilter.h"

@implementation CloseThisStudyFilter

- (void) initPlugin {
}

-(long)filterImage:(NSString*)menuName {
    NSString* studyInstanceUID = [[[viewerController studyInstanceUID] retain] autorelease];
    
	for (ViewerController* vc in [ViewerController getDisplayed2DViewers])
        if ([[vc studyInstanceUID] isEqualToString:studyInstanceUID])
            [vc close];
    
    return 0;
}

@end
