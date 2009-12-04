//
//  ResultsController.m
//  ResultsController
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "ResultsCardiacController.h"

#include <OpenGL/gl.h>
#include <OpenGL/glext.h>
#include <OpenGL/glu.h>

@implementation ResultsCardiacController

- (void)awakeFromNib
{
	NSLog( @"Nib loaded!");
}

- (id) init
{
	self = [super initWithWindowNibName:@"ResultsEjectionFraction"];
	[[self window] setDelegate:self];   //In order to receive the windowWillClose notification!
	[thumbnails setIntercellSpacing:NSMakeSize(1,1)];
	return self;
}

//-(void) setDICOMElements: (NSMutableDictionary*) dE
-(void) setDICOMElements: (NSManagedObject*) dE;
{
	//dicomElements = dE ;
	NSString *ID, *name, *birthDate;
	//ID = ([dE objectForKey: @"PatientID"]==nil)?@"":[dE objectForKey: @"PatientID"];
	ID = [dE valueForKeyPath:@"series.study.patientID"];
	if (!ID) ID = @"";
	//name = ([dE objectForKey: @"PatientsName"]==nil)?@"":[dE objectForKey: @"PatientsName"];
	name = [dE valueForKeyPath:@"series.study.name"];
	if (!name) name = @"";
	//birthDate = ([dE objectForKey: @"PatientsBirthDate"]==nil)?@"":[dE objectForKey: @"PatientsBirthDate"];
	birthDate = [[dE valueForKeyPath:@"series.study.dateOfBirth"] descriptionWithCalendarFormat:[[NSUserDefaults standardUserDefaults] stringForKey: NSShortDateFormatString] timeZone:0L locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
	if (!birthDate) birthDate = @"";
	[patientID setStringValue: ID];
	[patientName setStringValue: name];
	[patientBirthDate setStringValue: birthDate];
}

- (void)windowWillClose:(NSNotification *)notification
{
	NSLog(@"Window will close.... and release his memory...");
	[self release];
}

- (void) setResults:(NSString*) met :(NSString*) d :(NSString*) vD :(NSString*) vS :(NSString*)ef : (NSString*) dia :(NSMutableArray*) imArray:(NSMutableArray*) roiArray: (float[]) scalesArray: (float[]) rotationArray: (NSMutableArray*) originArray
{
	// info for top and right part.
	if ([dia length] > 0)
	{
		NSBundle *bundle = [NSBundle bundleForClass:[self class]];
		NSString *path = [bundle pathForResource:dia ofType:@"jpg"];
		NSImage* picture = [[NSImage alloc] initWithContentsOfFile:path];
		[diagram setImage: picture];
		[picture release];
	}
	else
	{
		[diagram setHidden:YES];
//		NSRect boundsResultTextBox = [resultTextBox bounds];
//		[resultTextBox setBoundsOrigin:NSMakePoint(boundsResultTextBox.origin.x,boundsResultTextBox.origin.y+218)];
//		[resultTextBox setNeedsDisplay:YES];
//		[resultTextBox display];
	}
	
	[method setStringValue: met];
	[volDiast setStringValue: vD];
	[volSyst setStringValue: vS];
	[EF setStringValue: ef];
	
	// result display.
	NSImage* im; 
	ROI* roi;
	long i, j, k, l;
	
	NSSize cSize = [thumbnails cellSize];
	// ROIs to display
	NSMutableArray *ROInamesToDisplay;
	ROInamesToDisplay = [[NSMutableArray alloc] initWithCapacity:0];

	if([met isEqualToString:@"MonoPlane"])
	{
		[ROInamesToDisplay addObject:@"DiasLong"];
		[ROInamesToDisplay addObject:@"SystLong"];
		
		[thumbnails setCellSize :NSMakeSize(cSize.width,cSize.height*3)];
		[thumbnails removeRow:1];
		[thumbnails removeRow:1];
	}
	else if([met isEqualToString:@"Bi-Plane"])
	{
		[ROInamesToDisplay addObject:@"DiasHorLong"];
		[ROInamesToDisplay addObject:@"SystHorLong"];
		[ROInamesToDisplay addObject:@"DiasVerLong"];
		[ROInamesToDisplay addObject:@"SystVerLong"];
		//[ROInamesToDisplay addObject:@"DiasLength"];
		//[ROInamesToDisplay addObject:@"SystLength"];
		
		[thumbnails setCellSize :NSMakeSize(cSize.width,cSize.height*((float) 3/(float) 2))];
		[thumbnails removeRow:1];
	}
	else if([met isEqualToString:@"Simpson"])
	{
		[ROInamesToDisplay addObject:@"DiasMitral"];
		[ROInamesToDisplay addObject:@"SystMitral"];
		[ROInamesToDisplay addObject:@"DiasPapi"];
		[ROInamesToDisplay addObject:@"SystPapi"];
		[ROInamesToDisplay addObject:@"DiasLength"];
		[ROInamesToDisplay addObject:@"SystLength"];
	}
	else if([met isEqualToString:@"Hemi-Ellipse"])
	{
		[ROInamesToDisplay addObject:@"DiasShort"];
		[ROInamesToDisplay addObject:@"SystShort"];
		[ROInamesToDisplay addObject:@"DiasLength"];
		[ROInamesToDisplay addObject:@"SystLength"];
		
		[thumbnails setCellSize :NSMakeSize(cSize.width,cSize.height*((float) 3/(float) 2))];
		[thumbnails removeRow:1];
	}
	else if([met isEqualToString:@"Teichholz"])
	{
		[ROInamesToDisplay addObject:@"DiasLength"];
		[ROInamesToDisplay addObject:@"SystLength"];
		
		[thumbnails setCellSize :NSMakeSize(cSize.width,cSize.height*3)];
		[thumbnails removeRow:1];
		[thumbnails removeRow:1];
		//[thumbnails removeRow:0];
	}
	[thumbnails sizeToCells];
	
	for( i = 0 ; i < [roiArray count]; i++)
	{	
		BOOL displayROI = FALSE;
		roi = [roiArray objectAtIndex: i];
		
		for(j = 0 ; (j < [ROInamesToDisplay count]) && !displayROI ; j++)
		{
			displayROI = displayROI || [[roi name] isEqualToString: [ROInamesToDisplay objectAtIndex: j]];
		}
		
		
		if(displayROI)
		{
			im = [imArray objectAtIndex: i];

			BOOL draw = YES;
					
			if([[roi name] hasPrefix:@"Dias"])
			{
				l = 0;
			}
			else if([[roi name] hasPrefix:@"Syst"])
			{
				l = 1;
			}

			if([[[roi name] substringFromIndex: 4] hasPrefix:@"Long"] ||
				[[[roi name] substringFromIndex: 4] hasPrefix:@"Hor"] ||
				[[[roi name] substringFromIndex: 4] hasPrefix:@"Mitral"] ||
				[[[roi name] substringFromIndex: 4] hasPrefix:@"Short"] ||
				([[[roi name] substringFromIndex: 4] hasPrefix:@"Length"] && [met isEqualToString:@"Teichholz"]) )
			{
				k = 0;
			}
			else if([[[roi name] substringFromIndex: 4] hasPrefix:@"Ver"] ||
				[[[roi name] substringFromIndex: 4] hasPrefix:@"Papi"] ||
				([[[roi name] substringFromIndex: 4] hasPrefix:@"Length"] && [met isEqualToString:@"Hemi-Ellipse"]))
			{	
				if (![met isEqualToString:@"MonoPlane"])
				{
					k = 1;
				}
				else
				{
					draw = NO;
				}
			}
			else if([[[roi name] substringFromIndex: 4] hasPrefix:@"Length"] && ![met isEqualToString:@"Teichholz"])
			{
				k = 2;
			}
			
			// rotation
			float angle = (float)(rotationArray[i]*2*pi)/(float)360;
			[thumbnails setAngle: angle: k];

			if (draw)
			{
				[thumbnails setImage:im cellAtRow:k column:l];
				[thumbnails addROI: roi: k];
				[thumbnails setNeedsDisplay:YES];		
				[thumbnails display];
				[[self window] display];
			}
		}
	}	

	[thumbnails copyImages];
	[thumbnails setNeedsDisplay:YES];
	[thumbnails drawRect:[thumbnails bounds]];
}

- (void) dealloc
{
    NSLog(@"My window is deallocating a pointer");
	[super dealloc];
}

- (IBAction)printResults:(id)sender
{
	[self print:sender];
}

- (void)print:(id)sender;
{
	NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
	[printInfo setHorizontalPagination:NSFitPagination];
	[printInfo setVerticalPagination:NSFitPagination];
	
	// Creating Printing View
	NSSize printingSize = [imagesBox bounds].size;

	// paper orientation
	if (printingSize.width > printingSize.height)
	{
		[printInfo setOrientation: NSLandscapeOrientation];
	}
	else
	{
		[printInfo setOrientation: NSPortraitOrientation];
	}
	// printing
	NSPrintOperation *printingOperation = [NSPrintOperation printOperationWithView:imagesBox printInfo:printInfo];
	[printingOperation runOperation];
	[patientInfos setHidden:YES];
}

/*- (NSWindow *)window
{
	return efpanel;
}*/

@end
