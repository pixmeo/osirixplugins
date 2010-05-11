//
//  ThreadInfoCancelButton.mm
//  Threads
//
//  Created by Alessandro Volz on 2/18/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "ThreadCellCancelButton.h"
#import <OsiriX Headers/NSView+N2.h>


@implementation ThreadCellCancelButton

-(NSImage*)image {
	return [NSImage imageNamed:@"NSStopProgressFreestandingTemplate"];
}

-(NSImage*)alternateImage {
	static NSImage* alternateImage = NULL;
	if (!alternateImage) {
		NSUInteger w = self.image.size.width, h = self.image.size.height;
		alternateImage = [[NSImage alloc] initWithSize:self.image.size];
		[alternateImage lockFocus];
		NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithData:[self.image TIFFRepresentation]];
		
		for (NSUInteger y = 0; y < h; ++y)
			for (NSUInteger x = 0; x < w; ++x) {
				NSColor* c = [bitmap colorAtX:x y:y];
				c = [c highlightWithLevel:[c alphaComponent]/1.5];
				[bitmap setColor:c atX:x y:y];
			}
		
		[bitmap draw]; [bitmap release];
		[alternateImage unlockFocus];
	}
	
	return alternateImage;
}

-(BOOL)isOpaque {
	return NO;
}

-(void)drawRect:(NSRect)dirtyRect {
	NSImage* image = [self.cell isHighlighted]? self.image : self.alternateImage;
	NSRect frame = NSZeroRect; frame.size = image.size;
	[image drawInRect:self.bounds fromRect:frame operation:NSCompositeSourceOver fraction:1];
}

@end
