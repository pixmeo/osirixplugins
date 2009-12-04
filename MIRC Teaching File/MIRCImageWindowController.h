
//
//  MIRCImageWindowController.h
//  TeachingFile
//
//  Created by Lance Pysher on 8/24/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MIRCImageWindowController : NSWindowController {

	NSArray *_images;
	NSXMLElement *_image;
	IBOutlet NSArrayController *imageArrayController;
	IBOutlet NSArrayController *nodeController;

}

- (id)initWithImage:(NSXMLElement *)image imageArray:(NSArray *)images;
- (NSXMLElement *)image;
- (NSArray *)images;





@end
