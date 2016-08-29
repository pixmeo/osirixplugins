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

@class DicomSeries;

@interface ThumbnailCell : NSButtonCell {
	BOOL rightClick, isStudy;
    BOOL invertedSet, invertedColors;
    
    float animationHeightPercent;
}

@property(readonly) BOOL rightClick;
@property float animationHeightPercent;

+ (float) thumbnailCellWidth;
+ (void) resetThumbnailCellWidth;
+ (BOOL) drawAnnotationsForROIsAndKeyimages: (DicomSeries*) series inRect: (NSRect) imageRect;
+ (BOOL) drawAnnotationsForROIs: (BOOL) imagesWithROIs andKeyimages: (BOOL) imagesWithKeys inRect: (NSRect) imageRect;
@end
