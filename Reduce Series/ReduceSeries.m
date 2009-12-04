//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "ReduceSeries.h"

@implementation ReduceSeries

-(IBAction) endDialog:(id) sender
{
    [window orderOut:sender];
    
    [NSApp endSheet:window returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
		// Contains a list of DCMPix objects: they contain the pixels of current series
		NSArray				*pixList = [viewerController pixList];	
		DCMPix				*firstPix = [pixList objectAtIndex: 0];
		long				i, newTotal;
		unsigned char		*emptyData;
		ViewerController	*new2DViewer;
		long				start, end, interval;
		
		// Get Values
		
		start = [[form cellAtIndex: 0] intValue]-1;
		end = [[form cellAtIndex: 1] intValue]-1;
		
		if( [[viewerController imageView] flippedData])
		{
			start = [pixList count]-1 - start;
			end = [pixList count]-1 - end;
		}
		
		interval = [[form cellAtIndex: 2] intValue];
		if( interval < 1) interval = 1;
		
		if( [[viewerController imageView] flippedData])
			interval = -interval;
		
		if( start == end) start = end-1;
		
		if( start < 0) start = 0;
		if( start >= [pixList count]) start = [pixList count]-1;

		if( end < 0) end = 0;
		if( end >= [pixList count]) end = [pixList count];
		
		if( start == end) end = start+1;
		
		// Display a waiting window
		id waitWindow = [viewerController startWaitWindow:@"I'm working for you!"];


		newTotal = 0;
		// Create a new series
		if( interval > 0)
		{
			for( i = start ; i <= end; i += interval) newTotal++;
			long imageSize = sizeof(float) * [firstPix pwidth] * [firstPix pheight];
			long size = newTotal * imageSize;

			// CREATE A NEW SERIES WITH ALL IMGES !
			
			
			emptyData = malloc( size);
			if( emptyData)
			{
				NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
				NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
				
				NSData	*newData = [NSData dataWithBytesNoCopy:emptyData length: size freeWhenDone:YES];
				
				for( i = start ; i <= end; i += interval)
				{
					[newPixList addObject: [[[pixList objectAtIndex: i] copy] autorelease]];
					[[newPixList lastObject] setfImage: (float*) (emptyData + imageSize * ([newPixList count] - 1))];
					memcpy( [[newPixList lastObject] fImage], [[pixList objectAtIndex: i] fImage], imageSize);
					[[newPixList lastObject] setTot: newTotal];
					[[newPixList lastObject] setFrameNo: [newPixList count]-1];
					[newDcmList addObject: [[viewerController fileList] objectAtIndex: i] ];
				}
				
				// CREATE A SERIES
				new2DViewer = [viewerController newWindow	:newPixList
															:newDcmList
															:newData];
			}
		}
		else
		{
			for( i = start ; i >= end; i += interval) newTotal++;
			long imageSize = sizeof(float) * [firstPix pwidth] * [firstPix pheight];
			long size = newTotal * imageSize;
			
			// CREATE A NEW SERIES WITH ALL IMGES !
			
			emptyData = malloc( size);
			if( emptyData)
			{
				NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
				NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
				
				NSData	*newData = [NSData dataWithBytesNoCopy:emptyData length: size freeWhenDone:YES];
				
				for( i = start ; i >= end; i += interval)
				{
					[newPixList addObject: [[[pixList objectAtIndex: i] copy] autorelease]];
					[[newPixList lastObject] setfImage: (float*) (emptyData + imageSize * ([newPixList count] - 1))];
					memcpy( [[newPixList lastObject] fImage], [[pixList objectAtIndex: i] fImage], imageSize);
					[[newPixList lastObject] setTot: newTotal];
					[[newPixList lastObject] setFrameNo: [newPixList count]-1];
					[newDcmList addObject: [[viewerController fileList] objectAtIndex: i] ];
				}
				
				// CREATE A SERIES
				new2DViewer = [viewerController newWindow	:newPixList
															:newDcmList
															:newData];
			}
		}
		// Close the waiting window
		[viewerController endWaitWindow: waitWindow];
			
		// We modified the pixels: OsiriX please update the display!
		[viewerController needsDisplayUpdate];
		
		if( [closeOriginal state])
		{
			[[viewerController window] performClose:nil];
			
			[new2DViewer tileWindows];
		}
    }
}

- (long) filterImage:(NSString*) menuName
{
	[NSBundle loadNibNamed:@"DialogReduce" owner:self];
	
	if( [[viewerController imageView] flippedData])
	{
		[[form cellAtIndex: 0] setIntValue: [[viewerController pixList] count] - [[viewerController imageView] curImage]];
		[[form cellAtIndex: 1] setIntValue: [[viewerController pixList] count]];
	}
	else
	{
		[[form cellAtIndex: 0] setIntValue: [[viewerController imageView] curImage] + 1];
		[[form cellAtIndex: 1] setIntValue: [[viewerController pixList] count]];
	}
	[[form cellAtIndex: 2] setIntValue: 1];
	
	[NSApp beginSheet: window modalForWindow:[NSApp keyWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
	
	return 0;   // No Errors
}

@end
