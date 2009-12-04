//
//  WindowAnchoredAnnotationsFilter.m
//  WindowAnchoredAnnotations
//
//  Copyright (c) 2007 jacques.fauquex@opendicom.com. All rights reserved.
//

#import "WindowAnchoredAnnotationsFilter.h"
#import "DCMViewAnnotationCategory.h"

static NSMutableDictionary *layouts; //key layoutName, object layoutObject
static NSMutableArray *correspondingView; //key viewers object layoutName
static NSMutableArray *correspondingLayout;


@implementation WindowAnchoredAnnotationsFilter






//===============================================================================================================================================
- (void) initPlugin
{
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(PLUGINdrawTextInfoFilter:) 
												 name:@"PLUGINdrawTextInfo"
											   object:nil]
	;
	
	layouts = [[NSMutableDictionary dictionaryWithCapacity:10] retain];
	correspondingLayout = [[NSMutableArray arrayWithCapacity:10] retain];
	correspondingView = [[NSMutableArray arrayWithCapacity:10] retain];	
	
	NSLog(@"WindowAnchoredAnnotationsFilter initialized as observer to notification PLUGINdrawTextInfo");
}






//================================================================================================================================================
- (long) filterImage:(NSString*) menuName
{
	//NSLog(@"access through plugin call by menuName");
	// menuName chooses the layout to be displayed
	// analyzing file and prepare the corresponding transformer
	
	//is the layout @"menuName" loaded into memory ?

	if ([layouts objectForKey:menuName] == nil)
	{

		//create representation of it in memory
		NSString *path = [NSString stringWithString:[[NSBundle bundleForClass:[self class]] pathForResource:menuName ofType:@"plist"]];
		//NSLog(path);

		NSArray *annotations = [NSArray arrayWithContentsOfFile:path];
		if (annotations)
		{
			NSArray *typeClassification = [NSArray arrayWithObjects:@"immutableString",@"string",@"date",@"boolValue",@"intValue",@"floatValue", nil]; 
			NSArray *objectClassification = [NSArray arrayWithObjects:@"view",@"imageMO",@"windowController",@"curRoi",@"DCMPix",@"dicomObject", nil]; 
			// creation of 6 parallel NSArrays for line, format, type, itemObject, itemSelector, itemArgument
			NSMutableArray *annotationLine     = [NSMutableArray arrayWithCapacity:4];//more than one item may share the same line. The first ones have a negative sign, the last one is positive
			NSMutableArray *annotationFormat   = [NSMutableArray arrayWithCapacity:4];
			NSMutableArray *annotationType     = [NSMutableArray arrayWithCapacity:4];
			NSMutableArray *annotationObject   = [NSMutableArray arrayWithCapacity:4];
			NSMutableArray *annotationSelector = [NSMutableArray arrayWithCapacity:4];
			NSMutableArray *annotationArgument = [NSMutableArray arrayWithCapacity:4];

			int currentLine;
			id currentLineArray;
			int currentItemPosition;
			id currentItem;		
			NSMutableString *tempFormat = [NSMutableString stringWithCapacity:32];
			int changeCharacters;
			
			for (currentLine=0;currentLine<21;currentLine++)
			{
				if(currentLineArray = [annotations objectAtIndex:currentLine])
				{
					if([currentLineArray isKindOfClass:[NSString class]]) //static line
					{
						[annotationLine     addObject:[NSNumber numberWithInt:currentLine]];
						[annotationFormat   addObject:currentLineArray];
						[annotationType     addObject:[NSNumber numberWithUnsignedInt:0]]; //immutableString
						[annotationObject   addObject:[NSNull null]];
						[annotationSelector addObject:[NSNull null]];
						[annotationArgument addObject:[NSNull null]];
					}
					else if ([currentLineArray count] == 0)
					{
						//NSLog(@"empty line:%d",currentLine);
					}
					else //array of 1 or more itemArrays
					{ 
						for (currentItemPosition=0;currentItemPosition < [currentLineArray count];currentItemPosition++)
						{
								if (currentItemPosition == ([currentLineArray count] - 1))	[annotationLine     addObject:[NSNumber numberWithInt:currentLine]];
								else													[annotationLine     addObject:[NSNumber numberWithInt:-1]];	
								currentItem = [currentLineArray objectAtIndex:currentItemPosition];
								tempFormat = [NSMutableString stringWithString:[currentItem objectAtIndex:0]];
								changeCharacters = [tempFormat replaceOccurrencesOfString:@"%%" 
																			   withString:@"%" 
																				  options:NSCaseInsensitiveSearch 
																					range:NSMakeRange(0, [tempFormat length])];								

								[annotationFormat   addObject:[NSString stringWithString:tempFormat]];
								[annotationType     addObject:[NSNumber numberWithUnsignedInt:[typeClassification indexOfObject:[currentItem objectAtIndex:1]]]];
								[annotationObject   addObject:[NSNumber numberWithUnsignedInt:[objectClassification indexOfObject:[currentItem objectAtIndex:2]]]];
								[annotationSelector addObject:[currentItem objectAtIndex:3]];
								[annotationArgument addObject:[currentItem objectAtIndex:4]];
						}
					}
				}
			}
			
			// consolidate these arrays and BOOL in a entry-dictionary added to it to static layouts
			[layouts setValue: [NSArray arrayWithObjects:  annotationLine,
														   annotationFormat, 
														   annotationType, 
														   annotationObject,
														   annotationSelector,
														   annotationArgument,
														   nil
								]
						forKey: menuName
			];
		}
		else
		{
			NSLog(@"dictionary not available");
			return -1;
		}
	}
	
	
	//the layout is processed an added to layouts
				
		
	//registering viewer (if necesary) and corresponding layout
	if ([correspondingView containsObject: [viewerController imageView]])
	{
		//viewer already registered
		[correspondingLayout replaceObjectAtIndex:[correspondingView indexOfObject: [viewerController imageView]]
									   withObject:menuName
		];
	}
	else
	{
		//new registration
		[correspondingLayout addObject:menuName];
		[correspondingView addObject:[viewerController imageView]];
	}
	return 0;

/*
	NSLog(@"layout count:%d",[correspondingLayout count]);		
	int i = [correspondingView indexOfObject: [viewerController imageView]];
	NSLog(@"view count:%d",[correspondingView count]);
	NSLog(@"corresponding view index:%d",i);
	NSString *correspondingLayoutString = [[correspondingLayout objectAtIndex:i] stringValue];
	NSLog(@"correspondingLayoutString:%@",correspondingLayoutString);
*/
}






//===========================================================================================================================================================
- (void) PLUGINdrawTextInfoFilter:(NSNotification*)note
{
	//NSLog(@"WindowAnchoreAnnotations notified");
	if ([[note userInfo] count] == 0) //in full annotations PLUGINdrawTextInfo is published with a dictionary. We don't want to use this notification.
	{
		if ([correspondingView containsObject:[note object]]) //neither do we annotate if there was no previous annotation scheme registered for this view.
		{
			//NSLog(@"View registered");
			NSString *layoutTitle = [correspondingLayout objectAtIndex:[correspondingView indexOfObject: [note object]]];
			//NSLog(layoutTitle);
			[[note object] processorOfLayout:[layouts valueForKey:layoutTitle]];
		}
	}
}



@end
