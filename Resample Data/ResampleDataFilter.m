//
//  ResampleDataFilter.m
//  Resample Data
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004-2016 Rosset Antoine. All rights reserved.
//

#import "ResampleDataFilter.h"
#import <OsiriXAPI/NSString+N2.h>

@implementation ResampleDataFilter

- (id)init
{
	NSLog( @"ResampleDataFilter Init");
	
	return [super init];
}

- (void) dealloc
{
	NSLog( @"ResampleDataFilter Dealloc");
	
	[super dealloc];
}


- (IBAction) setXYZSlider:(id) sender;
{
	switch( [sender tag])
	{
		case 0:
		{
			int xValue = [sender integerValue] * originWidth / 100.;
			[XText setIntegerValue:  xValue];
			[self setXYZValue: XText];
		}
		break;
		
		case 1:
		{
			int yValue = [sender integerValue] * originHeight / 100.;
			[YText setIntegerValue:  yValue];
			[self setXYZValue: YText];
		}
		break;
		
		case 2:
		{
			int zValue = [sender integerValue] * originZ / 100.;
			[ZText setIntegerValue:  zValue];
			[self setXYZValue: ZText];
		}
		break;
	}
}

- (IBAction) setXYZValue:(id) sender
{
	DCMPix	*curPix = [[viewerController pixList] objectAtIndex: 0];
	
	if( [ForceRatioCheck state] == NSOnState)
	{
		switch( [sender tag])
		{
			case 0:
				[YText setIntegerValue:  originRatio * ([sender integerValue]  * originHeight) / (originWidth)];
			break;
			
			case 1:
				[XText setIntegerValue: ([sender integerValue]  * originWidth) / (originHeight * originRatio)];
			break;
			
			case 2:
			break;
		}
		
		[RatioText setDoubleValue:1.0];
	}
	else
	{
		[RatioText setDoubleValue: originRatio * ([XText doubleValue] / (double) originWidth) / ([YText doubleValue] / (double) originHeight) ];
	}
	
	unsigned long long mem = 4 * (([XText integerValue] * [YText integerValue] * [ZText integerValue]));
	unsigned long long oldmem = 4 * (originHeight * originWidth * originZ) / (1024 * 1024);
	
    [MemoryText setStringValue: [NSString stringWithFormat:@"%@ / %llu%%", [NSString sizeString: mem], (unsigned long long) (100 * (mem / (1024 * 1024)) / oldmem)]];
	[thicknessText setStringValue: [NSString stringWithFormat: @"Original: %.2f mm / Resampled: %.2f mm", [curPix sliceThickness], [curPix sliceThickness] * (double) originZ / (double) [ZText integerValue]]];
	
	[xSlider setDoubleValue: 100. * [XText doubleValue] / (double) originWidth];
	[ySlider setDoubleValue: 100. * [YText doubleValue] / (double) originHeight];
	[zSlider setDoubleValue: 100. * [ZText doubleValue] / (double) originZ];
}

- (IBAction) setForceRatio:(id) sender
{
	if( [sender state] == NSOnState)
	{
		[self setXYZValue: XText];
	}
}

-(IBAction) endDialog:(id) sender
{
    [window orderOut:sender];
    
    [NSApp endSheet:window returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
	{
		id waitWindow = [viewerController startWaitWindow:@"Resampling data..."];
		
		// resampling
		double xFactor = (double) originWidth / [XText doubleValue];
		double yFactor = (double) originHeight / [YText doubleValue];
		double zFactor = (double) originZ / [ZText doubleValue];
		BOOL isResampled = [viewerController resampleDataWithXFactor:xFactor yFactor:yFactor zFactor:zFactor];

		[viewerController endWaitWindow: waitWindow];
		if(!isResampled)
		{
			NSRunAlertPanel(NSLocalizedString(@"Not enough memory", nil), NSLocalizedString(@"Your computer doesn't have enough RAM to complete the resampling - Upgrade to OsiriX 64-bit to solve this problem.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		}
	}
}

- (long) filterImage:(NSString*) menuName
{
	DCMPix			*curPix;
	
	[NSBundle loadNibNamed:@"DialogResampleData" owner:self];
	
	curPix = [[viewerController pixList] objectAtIndex: [[viewerController imageView] curImage]];
	
	originRatio = [curPix pixelRatio];
	originWidth = [curPix pwidth];
	originHeight = [curPix pheight];
	originZ = [[viewerController pixList] count];
	
	if( originRatio == 1.0) [ForceRatioCheck setState: NSOnState];
	else [ForceRatioCheck setState: NSOffState];
	
	[RatioText setDoubleValue: originRatio];
	[XText setDoubleValue: originWidth];
	[YText setDoubleValue: originHeight];
	[ZText setDoubleValue: originZ];
	
	[oXText setDoubleValue: originWidth];
	[oYText setDoubleValue: originHeight];
	[oZText setDoubleValue: originZ];
	
	if( [curPix sliceInterval] == 0)
	{
		[oZText setEnabled: NSOffState];
		[ZText setEnabled: NSOffState];
		[zSlider setEnabled: NSOffState];
	}
	
	[self setXYZValue: XText];
	
	[NSApp beginSheet: window modalForWindow:[NSApp keyWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
	
	return 0;
}

@end
