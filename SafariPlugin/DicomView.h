//
//  DicomView.h
//  DICOMPlugIn
//
//  Created by Lance Pysher on 4/5/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import <QuickTime/QuickTime.h>


//@interface DicomView : NSImageView {
@interface DicomView : QTMovieView {
	DataHandler mDataHandlerRef;
    NSDictionary *_arguments;
	 BOOL _loadedImage;
}

- (void)setArguments:(NSDictionary *)arguments;
-(Movie)quicktimeMovieFromTempFile:(DataHandler *)outDataHandler error:(OSErr *)outErr;


@end
