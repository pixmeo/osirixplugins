/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import <Cocoa/Cocoa.h>
#import "ViewerController.h"

@interface KeyImagesWindowController : NSWindowController
{
    IBOutlet NSScrollView *scrollView;
    IBOutlet NSMatrix *matrix;
    NSArray *previousThumbnails;
    ViewerController *viewer;
    int previousIndex;
}

@property (retain) ViewerController *viewer;

- (id) initForViewer:(ViewerController*) v;
- (BOOL) buildThumbnailMatrix;

@end
