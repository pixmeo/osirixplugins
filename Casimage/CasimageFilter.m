//
//  Casimage.m
//  Casimage
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "CasimageFilter.h"

@implementation CasimageFilter

- (long) filterImage:(NSString*) menuName
{
	// Contains a list of DCMPix objects: they contain the pixels of current series
	NSArray				*pixList = [viewerController pixList];		
	DCMPix				*curPix = [pixList objectAtIndex: 0];
	NSManagedObject		*image = [curPix imageObj];
	
	// Display a waiting window
	id waitWindow = [viewerController startWaitWindow:@"Inverting..."];
	
	[[NSWorkspace sharedWorkspace] launchApplication:@"4D Client"];
	
	NSPasteboard	*pb = [NSPasteboard generalPasteboard];
	
	[pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	
	NSString	*dob = [[image valueForKeyPath:@"series.study.dateOfBirth"] descriptionWithCalendarFormat:@"%d/%m/%Y" timeZone: 0L locale: 0L];
	
	NSScanner	*scanner = [NSScanner scannerWithString: [image valueForKeyPath:@"series.study.name"]];
	NSString	*lastname, *firstname;
	
	[scanner scanUpToString:@" " intoString: &lastname];
	[scanner scanUpToString:@" " intoString: &firstname];
	
	NSString	*pbString = [NSString stringWithFormat: @"C@1.0&%@&%@&%@&%@&%@&", [image valueForKeyPath:@"series.study.patientID"], lastname, firstname, dob, [image valueForKeyPath:@"series.study.patientSex"]];
	
	[pb setString: pbString forType:NSStringPboardType];
	
	NSLog( pbString);
	
	// Close the waiting window
	[viewerController endWaitWindow: waitWindow];
		
	return 0;   // No Errors
}

@end
