//
//  OSIDemoWindowController.h
//  OSIDemo
//
//  Created by Joël Spaltenstein on 2/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface OSIDemoWindowController : NSWindowController /*<NSOutlineViewDataSource, NSOutlineViewDelegate>*/ {
	NSOutlineView *_outlineView;
}

@property (nonatomic, readwrite, retain) IBOutlet NSOutlineView *outlineView;

- (id)init;



@end
