//
//  ZoomMatrix.h
//  EjectionFraction
//
//  Created by joris on 4/4/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>
#import <WebKit/WebView.h>
#import <Cocoa/Cocoa.h>
#import "ROI.h"

@interface ZoomMatrix : NSMatrix {
	NSArray * cellsCopy;
	NSMutableArray * types; // store the type of each cell. type = 0 for images ; type = 1 for ROI .
	NSMutableArray * images; // store the images
	NSMutableArray * ROIrow0; // store the ROI of line 0
	NSMutableArray * ROIrow1; // store the ROI of line 1
	NSMutableArray * ROIrow2; // store the ROI of line 2
	float angle[3]; // rotation for each line (degres)
}
-(void) setType:(int)t atindex:(int)index;
-(void) setImage:(NSImage*)im atindex:(int)index;
-(int) getTypeAtindex:(int)index;
-(NSImage*) getImageAtindex:(int)index;
-(NSImage*) copyImage:(NSImage*)im;
-(void) setImage:(NSImage*)im cellAtRow:(int)r column:(int)c;
-(void) copyImages;
-(void) drawROI:(ROI*) roi: (NSImage*) image: (float) scale: (NSPoint) cmDias: (float) angle;
-(void) addROI:(ROI*)roi:(int)row;
-(void) setAngle:(float)a:(int)row;
@end
