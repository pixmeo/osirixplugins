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



#import "SectorManagerController.h"
#import "Notifications.h"

#import "CardiacStatisticsFilter.h"

@implementation SectorManagerController

- (id) initWithViewer:(ViewerController*) v :(NSMutableArray*) InputArray
{
	//viewer = nil;
	
	viewer = v;
	curPix = [[viewer pixList] objectAtIndex:0];
	pixelSpacingZ = [curPix sliceInterval];
	// get viewer pixels
	//DCMPix *curPix = [[v pixList] objectAtIndex: [[v imageView] curImage]];
	
	
	self = [super initWithWindowNibName:@"SectorManager"];
	
	[[self window] setFrameAutosaveName:@"SectorManagerWindow"];
	
	//TestInterSegmentationFilter *FilterController = [TestInterSegmentationFilter getControllerForMainViewer:v registeredViewer:[v blendedWindow]];
	//LocSectorArray = [FilterController SectorArray];
	LocSectorArray = InputArray;
	
	// register to notification
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];	
	[nc addObserver: self
           selector: @selector(CloseViewerNotification:)
               name: OsirixCloseViewerNotification
             object: nil];
	[nc addObserver: self
           selector: @selector(roiListModification:)
               name: OsirixROIChangeNotification
             object: nil];
	[nc addObserver: self
           selector: @selector(fireUpdate:)
               name: OsirixRemoveROINotification
             object: nil];
	[nc addObserver: self
           selector: @selector(roiListModification:)
               name: OsirixDCMUpdateCurrentImageNotification
             object: nil];
	[nc addObserver: self
           selector: @selector(roiListModification:)
               name: OsirixROISelectedNotification
             object: nil];
		 
	
	[self fireUpdate: nil];
	
	[[tableView tableColumnWithIdentifier:@"Min"] setHidden:YES];
	[[tableView tableColumnWithIdentifier:@"Max"] setHidden:YES];
	[[tableView tableColumnWithIdentifier:@"Area"] setHidden:YES];
	[[tableView tableColumnWithIdentifier:@"Median"] setHidden:YES];
	
	[inputThreshold setStringValue: [[NSNumber numberWithInt:50.0] stringValue]];
	
	
	return self;
}

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
			  row:(NSInteger)rowIndex
{
	//NSMutableArray	*curRoiList = [[viewer roiList] objectAtIndex: [[viewer imageView] curImage]];
	NSMutableArray	*curRoiList = LocSectorArray;
	
	ROI				*editedROI = [curRoiList objectAtIndex: rowIndex];
		
	[viewer renameSeriesROIwithName: [editedROI name] newName:anObject];
	
	[tableView reloadData];
}

- (void) keyDown:(NSEvent *)event
{
	unichar c = [[event characters] characterAtIndex:0];
	
    if( c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter || c == NSDeleteCharFunctionKey)
	{
		[self deleteROI: self];
	}
}

- (IBAction)deleteROI:(id)sender
{
	NSInteger index;
	NSIndexSet* indexSet = [tableView selectedRowIndexes];
	index = [indexSet lastIndex];
	
	if ((index == NSNotFound) || index < 0) return;
	
	//NSMutableArray	*curRoiList = [[viewer roiList] objectAtIndex: [[viewer imageView] curImage]];
	NSMutableArray	*curRoiList = LocSectorArray;
	
	while ( index != NSNotFound) 
	{
		ROI	*selectedRoi = [curRoiList objectAtIndex:index];
	
		[viewer deleteSeriesROIwithName: [selectedRoi name]];
	
//		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixRemoveROINotification object:selectedRoi userInfo: nil];
//		[curRoiList removeObject:selectedRoi];
		
		index = [indexSet indexLessThanIndex:index];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateViewNotification object:nil userInfo: nil];
}

//- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
//{
//	NSMutableArray	*curRoiList = [[viewer roiList] objectAtIndex: [[viewer imageView] curImage]];
//	
//	long i;
//	
//	for( i = 0; i < [curRoiList count]; i++)
//	{
//		ROI	*curROI = [curRoiList objectAtIndex: i];
//		
//		if( [tableView isRowSelected: i])
//		{
//			[curROI setROIMode: ROI_selected];
//		}
//		else
//		{
//			[curROI setROIMode: ROI_sleep];
//		}
//		
//		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:curROI userInfo: nil];
//	}
//}

- (void) roiListModification: (NSNotification*) note
{
	[tableView reloadData];
}

- (void) fireUpdate: (NSNotification*) note
{
	[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(roiListModification:) userInfo:nil repeats:NO];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	//NSMutableArray	*curRoiList = [[viewer roiList] objectAtIndex: [[viewer imageView] curImage]];
	NSMutableArray	*curRoiList = LocSectorArray;
	
    return [curRoiList count];
}

- (id)tableView:(NSTableView *)tableView
    objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(NSInteger)row
{
	if( viewer == nil) return nil;
	
	//NSMutableArray	*curRoiList = [[viewer roiList] objectAtIndex: [[viewer imageView] curImage]];
	NSMutableArray	*curRoiList = LocSectorArray;
	
	//curPix = [[viewer pixList] objectAtIndex: [[viewer imageView] curImage]];
	float rmean, rtotal, rdev, rmin, rmax;
	[curPix computeROI: [curRoiList objectAtIndex:row] :&rmean :&rtotal :&rdev :&rmin :&rmax];
	
	float rmedian = [self GetMedianValueinRoi: [curRoiList objectAtIndex:row] : curPix];
	
	float thresh = [[inputThreshold stringValue] floatValue] ;
	float rpcntoverT = [self GetPercentAboveThreshinRoi:[curRoiList objectAtIndex:row] : curPix: thresh];
	
	if( [[tableColumn identifier] isEqualToString:@"Index"])
	{
		return [NSString stringWithFormat:@"%d", row+1];
	}
	
	if( [[tableColumn identifier] isEqualToString:@"Name"])
	{
		return [[curRoiList objectAtIndex:row] name];
	}
	
	if( [[tableColumn identifier] isEqualToString:@"Mean"])
	{
		return [NSNumber numberWithFloat:rmean];
	}
	if( [[tableColumn identifier] isEqualToString:@"Median"])
	{
		return [NSNumber numberWithFloat:rmedian];
	}	
	if( [[tableColumn identifier] isEqualToString:@"Stdev"])
	{
		return [NSNumber numberWithFloat:rdev];
	}
	if( [[tableColumn identifier] isEqualToString:@"Min"])
	{
		return [NSNumber numberWithFloat:rmin];
	}
	if( [[tableColumn identifier] isEqualToString:@"Max"])
	{
		return [NSNumber numberWithFloat:rmax];
	}
	if( [[tableColumn identifier] isEqualToString:@"Area"])
	{
		return [NSNumber numberWithFloat:[[curRoiList objectAtIndex:row] roiArea]];
	}
	if( [[tableColumn identifier] isEqualToString:@"Npix"])
	{
		return [NSNumber numberWithFloat:rtotal];
	}
	if( [[tableColumn identifier] isEqualToString:@"Pcnt>T"])
	{
		return [NSNumber numberWithFloat:rpcntoverT];
	}
	
	return nil;
}

// delegate method setROIMode

-(void) CloseViewerNotification:(NSNotification*) note
{	
	if( [note object] == viewer)
	{
		NSLog( @"ROIManager CloseViewerNotification");
		
		[[self window] close];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
 
	NSLog( @"ROIManager windowWillClose");
	
	[self autorelease];
}

- (void) dealloc
{
	NSLog( @"ROIManager dealloc");
	[tableView setDataSource: nil];
	viewer = nil;
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[super dealloc];
}
- (IBAction) menuExport: (id)sender
{
	NSSavePanel * saveDialog = [NSSavePanel savePanel];
	[saveDialog setRequiredFileType:@"txt"];
	[saveDialog setTitle:@"Export to Text File"];
	
	if ([saveDialog runModal] != NSOKButton)
		return;
	
	const char * fullPath = [[saveDialog filename] UTF8String];
	FILE * handle = fopen ( fullPath, "w" );
	if (handle == NULL)
		return;
	
	//write first line with values identifiers
	NSMutableArray *identifiers = [[NSMutableArray alloc] init];   	
	[identifiers addObject: @"Index"];
	[identifiers addObject: @"Name"];
	[identifiers addObject: @"Mean"];
	[identifiers addObject: @"Median"];
	[identifiers addObject: @"Min"];
	[identifiers addObject: @"Max"];
	[identifiers addObject: @"Stdev"];
	[identifiers addObject: @"Area"];
	[identifiers addObject: @"Pcnt>T"];
	[identifiers addObject: @"Npix"];
	
	for (NSString *s in identifiers) 
	{
		if([s isEqualToString: @"Pcnt>T"])
			s=[NSString stringWithFormat:@"%@%@",
			   NSLocalizedString(@"Pcnt>", nil),
			   [inputThreshold stringValue]];
		
		if( [[tableView tableColumnWithIdentifier: s ] isHidden] == NO)
			fprintf(handle, "%s\t",[s UTF8String]);
	}
	fprintf(handle, "\n");
	
		// iterate through the existing List cache
	int i;
	int n = [self numberOfRowsInTableView:tableView];
	for (i = 0; i < n; i++)
	{
		for (NSString *s in identifiers) 
		{
			if( [[tableView tableColumnWithIdentifier: s ] isHidden] == NO)
			{
				NSString *tempS = [NSString stringWithFormat:@"%@",[self tableView:tableView objectValueForTableColumn:
																[tableView tableColumnWithIdentifier: s ]
																		   row:i]];
				fprintf(handle, "%s\t",[tempS UTF8String]);
			}
		}
		fprintf(handle, "\n");
		
			
		/*
		NSString * ind = [self tableView:tableView objectValueForTableColumn:
						  [tableView tableColumnWithIdentifier:@"Index"]
						   row:i];
		NSString * name = [self tableView:tableView objectValueForTableColumn:
						  [tableView tableColumnWithIdentifier:@"Name"]
									 row:i];
		NSString * mean = [NSString stringWithFormat:@"%@",[self tableView:tableView objectValueForTableColumn:
						   [tableView tableColumnWithIdentifier:@"Mean"]
									  row:i]];
		NSString * min = [NSString stringWithFormat:@"%@",[self tableView:tableView objectValueForTableColumn:
															[tableView tableColumnWithIdentifier:@"Min"]
																	   row:i]];
		NSString * max = [NSString stringWithFormat:@"%@",[self tableView:tableView objectValueForTableColumn:
															[tableView tableColumnWithIdentifier:@"Max"]
																	   row:i]];
		NSString * stdev = [NSString stringWithFormat:@"%@",[self tableView:tableView objectValueForTableColumn:
															[tableView tableColumnWithIdentifier:@"Stdev"]
																	   row:i]];
		NSString * area = [NSString stringWithFormat:@"%@",[self tableView:tableView objectValueForTableColumn:
															[tableView tableColumnWithIdentifier:@"Area"]
																	   row:i]];
		NSString * total = [NSString stringWithFormat:@"%@",[self tableView:tableView objectValueForTableColumn:
															[tableView tableColumnWithIdentifier:@"Npix"]
																	   row:i]];
		
		fprintf(handle, "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", 
				[ind UTF8String], 
				[name UTF8String] , 
				[mean UTF8String] ,
				[min UTF8String], 
				[max UTF8String] , 
				[stdev UTF8String] ,
				[area UTF8String] ,
				[total UTF8String] 
				);	
		 */
	}
		
	fclose(handle);
}

-(IBAction) AvdancedMode:(id) sender
{
	NSLog( @"Advanced mode");
	
	BOOL isTableHiddenMin =[[tableView tableColumnWithIdentifier:@"Min"] isHidden];
	
	[[tableView tableColumnWithIdentifier:@"Min"] setHidden: !isTableHiddenMin];

	BOOL isTableHiddenMax =[[tableView tableColumnWithIdentifier:@"Max"] isHidden];
	
	[[tableView tableColumnWithIdentifier:@"Max"] setHidden: !isTableHiddenMax];
	
	BOOL isTableHiddenArea =[[tableView tableColumnWithIdentifier:@"Area"] isHidden];
	
	[[tableView tableColumnWithIdentifier:@"Area"] setHidden: !isTableHiddenArea];
	
	[[tableView tableColumnWithIdentifier:@"Median"] setHidden: 
		![[tableView tableColumnWithIdentifier:@"Median"] isHidden]];
	
}

-(float) GetMedianValueinRoi:(ROI*)myROI:(DCMPix*)myPix
{
	// and now... take all pixels of the ROI
	long noOfValues;
	float *Pixlocations;
	float *theVal = [myPix getROIValue:&noOfValues :myROI  : &Pixlocations];
	
	//float *sortedVal = [theVal sortedArrayUsingSelector:@selector(compare:)];
	
	qsort((void*) theVal, /*number of items*/ noOfValues, /*size of an item*/ sizeof(theVal[0]),
		  /*comparison-function*/ CmpFunc);

	
	//float *sortedVal = ;
	
	return theVal[ (int)(noOfValues/2) ];
	
}

-(float) GetPercentAboveThreshinRoi:(ROI*)myROI:(DCMPix*)myPix:(float)thresh
{
	// and now... take all pixels of the ROI
	long noOfValues;
	float *Pixlocations;
	float *theVal = [myPix getROIValue:&noOfValues :myROI  : &Pixlocations];
	
	qsort((void*) theVal, /*number of items*/ noOfValues, /*size of an item*/ sizeof(theVal[0]),
		  /*comparison-function*/ CmpFunc);
	
	int i,n=0;
	for(i=0;i<noOfValues;i++)
	{
		if (theVal[i]>thresh) {
			n++;
		}
	}
	
	return (float)100*n/noOfValues;
	
}

-(IBAction) keyDownInput:(id)sender
{
	[self fireUpdate: nil];
}

// comparison-function for the sort-algorithm
// two items are taken by void-pointer, converted and compared
int CmpFunc ( const void* _a , const void* _b)
{
	// you've got to explicitly cast to the correct type
	const float* a = (const float*) _a;
	const float* b = (const float*) _b;
	
	if(*a > *b) return 1;              // first item is bigger than the second one -> return 1
	else{
		if(*a == *b) return  0;         // equality -> return 0
		else         return -1;         // second item is bigger than the first one -> return -1
	}
}



@end
