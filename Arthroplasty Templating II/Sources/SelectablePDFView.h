//
//  SelectablePDFView.h
//  Arthroplasty Templating II
//
//  Created by Alessandro Volz on 6/8/09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
@class ArthroplastyTemplatingWindowController;

extern NSString* SelectablePDFViewDocumentDidChangeNotification;


@interface SelectablePDFView : PDFView {
	BOOL _selected, _selectionInitiated;
	NSRect _selectedRect;
	NSPoint _mouseDownLocation;
	IBOutlet ArthroplastyTemplatingWindowController* _controller;
}



@end
