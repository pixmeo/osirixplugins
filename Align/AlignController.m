//
//  AlignController.m
//  Align
//
//  Created by Joël Spaltenstein on 7/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AlignController.h"
#import "AlignDCMView.h"
#import "ViewerController.h"
#import "AppController.h"
#import "DCMPix.h"

//extern		AppController				*appController;

//extern ViewerController *draggedController;


static NSMutableDictionary *aligncontroller__instanceIDToIvars = nil;


@implementation AlignController

- (id) viewCinit:(NSMutableArray*)f :(NSMutableArray*) d :(NSData*) v
{
	self = [super viewCinit:f :d :v];
	[self setAlign_state:AL_NORMAL];
	[self setTileController:nil];
	return self;
}

- (void) CloseViewerNotification: (NSNotification*) note
{
	if([note object] == [self tileController]) // our tile serie is closing itself....
	{
		[self ActivateTiling: 0L];
	}
	[super CloseViewerNotification: note];
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *paste = [sender draggingPasteboard];
        //gets the dragging-specific pasteboard from the sender
    NSArray *types = [NSArray arrayWithObjects:NSFilenamesPboardType, nil];
	//a list of types that we can accept
    NSString *desiredType = [paste availableTypeFromArray:types];
    NSData *carriedData = [paste dataForType:desiredType];
	long	i, x, z;
	BOOL	found = NO;
	
//	if ([self align_state] == AL_TILE)
//		return NO;
	if ([self align_state] != AL_MOSAIC)
		return [super performDragOperation:sender];
	
    if (nil == carriedData)
    {
        //the operation failed for some reason
        NSRunAlertPanel(NSLocalizedString(@"Paste Error", nil), NSLocalizedString(@"Sorry, but the past operation failed", nil), nil, nil, nil);
        return NO;
    }
    else
    {
        //the pasteboard was able to give us some meaningful data
        if ([desiredType isEqualToString:NSFilenamesPboardType])
        {
            //we have a list of file names in an NSData object
            NSArray				*fileArray = [paste propertyListForType:@"NSFilenamesPboardType"];
			NSString			*draggedFile = [fileArray objectAtIndex:0];
 			
			// Find a 2D viewer containing this specific file!
			
			NSArray				*winList = [NSApp windows];
			
			for( i = 0; i < [winList count]; i++)
			{
				if( [[[winList objectAtIndex:i] windowController] isKindOfClass:[AlignController class]])
				{
					for( z = 0; z < [[[winList objectAtIndex:i] windowController] maxMovieIndex]; z++)
					{
						NSMutableArray  *pList = [[[winList objectAtIndex:i] windowController] pixList: z];
						
						for( x = 0; x < [pList count]; x++)
						{
							if([[(DCMPix*) [pList objectAtIndex: x] sourceFile] isEqualToString:draggedFile])
							{
								if ([[[winList objectAtIndex:i] windowController] align_state] == AL_TILE)
								{
									found = YES;
									[self ActivateTiling:[[winList objectAtIndex:i] windowController]];
									break;
								}
								if ([[[winList objectAtIndex:i] windowController] align_state] == AL_BACKGROUND)
								{
									found = YES;
									[self ActivateBackground:[[winList objectAtIndex:i] windowController]];
									break;
								}
							}
						}
						if (found)
							break;
					}
				}
				if (found)
					break;
			}
        }
        else
        {
            //this can't happen
            NSAssert(NO, @"This can't happen");
            return NO;
        }
    }
	
	if (found)
	{
		[ViewerController setDraggedController:0L];
		return YES;
	}
	else
		return [super performDragOperation:sender];
}
-(void) propagateSettings
{
	[super propagateSettings];
	
	long				i;
	NSArray				*winList = [NSApp windows];
	NSMutableArray		*viewersList;
	
	// *** 2D Viewers ***
	viewersList = [[NSMutableArray alloc] initWithCapacity:0];
	
	for( i = 0; i < [winList count]; i++)
	{
		//if( [[[[winList objectAtIndex:i] windowController] windowNibName] isEqualToString:@"Viewer"])
		if( [[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]])
		{
			if( self != [[winList objectAtIndex:i] windowController])
				[viewersList addObject: [[winList objectAtIndex:i] windowController]];
		}
	}
	
	for( i = 0; i < [viewersList count]; i++)
	{
		AlignController	*tC = [viewersList objectAtIndex: i];
		
		if( self == [tC tileController])
		{
			[[tC imageView] loadTextures];
			[[tC imageView] setNeedsDisplay:YES];
		}
	}
	
	[viewersList release];
}

-(void) ActivateTiling:(AlignController*) tC
{
	if( tC == self) return;
	
	NSLog( @"Tiling Activated!");
		
	[imageView sendSyncMessage:0];
	
	[self setTileController:tC];
	
	if([self tileController])
	{
		[(AlignDCMView*) imageView setTiling: (AlignDCMView*) [[self tileController] imageView]];
	}
	else
	{
		[(AlignDCMView*) imageView setTiling: 0L];
	}
}

-(void) ActivateBackground:(AlignController*) bC
{
	if( bC == self) return;
	
	NSLog( @"Background Activated!");
		
	[imageView sendSyncMessage:0];
	
//	[self setTileController:tC];
	
	if(bC)
	{
		[(AlignDCMView*) imageView setBackground: (AlignDCMView*) [bC imageView]];
	}
}



+ (AlignController *) newAlignWindow:(NSMutableArray*)f :(NSMutableArray*)d :(NSData*) v
{
	AppController *appController = 0L;
	appController = [AppController sharedAppController];


    AlignController *win = [[AlignController alloc] viewCinit:f :d :v];
	
	[win showWindowTransition];
	[win startLoadImageThread]; // Start async reading of all images
	

	[appController tileWindows: self];

	return win;
}


- (void) propagateControlPoints
{
	long				i, j;
	NSArray				*winList = [NSApp windows];
	NSMutableArray		*viewersList;
	
//	if( [[[[fileList[0] objectAtIndex: 0] valueForKey:@"completePath"] lastPathComponent] isEqualToString:@"Empty.tif"] == YES) return;
	
	viewersList = [[NSMutableArray alloc] initWithCapacity:0];
	
	for( i = 0; i < [winList count]; i++)
	{
		if( [[[winList objectAtIndex:i] windowController] isKindOfClass:[AlignController class]])
		{
			if( self != [[winList objectAtIndex:i] windowController]) [viewersList addObject: [[winList objectAtIndex:i] windowController]];
		}
	}
	
	for( i = 0; i < [viewersList count]; i++)
	{
		AlignController	*aC = [viewersList objectAtIndex: i];
		
		if ([(AlignDCMView*)[aC imageView] tileView] == [self imageView])
		{
			for (j = 0; j < 5; j++)
				[(AlignDCMView*)[aC imageView] controlPointMovedInTile:j: [(AlignDCMView*)[self imageView] controlPoint:j]];
			if ([(AlignDCMView*)[self imageView] activeControlPoints] != [(AlignDCMView*)[aC imageView] activeControlPoints])
			{
				[(AlignDCMView*)[aC imageView] setActiveControlPoints:[(AlignDCMView*)[self imageView] activeControlPoints]];
				[(AlignDCMView*)[aC imageView] recalcTransMatrix];
			}
		}
	}
	[viewersList release];
}


- (al_state) align_state
{
	return [(NSNumber*)[[self aligncontroller__ivars] objectForKey:@"align_state"] intValue];
}


- (void) setAlign_state:(al_state) state
{
	[[self aligncontroller__ivars] setObject:[NSNumber numberWithInt:state] forKey:@"align_state"];
	[[self imageView] loadTextures]; // not sure this is neccessary, but it can't hurt -JS
	[[self imageView] setNeedsDisplay:YES];
}

- (AlignController *) tileController
{
	return [(NSValue*) [[self aligncontroller__ivars] objectForKey:@"tile_controller"] pointerValue];
}


- (void) setTileController:(AlignController *) controller
{
	[[self aligncontroller__ivars] setObject:[NSValue valueWithPointer:controller] forKey:@"tile_controller"];
}



#pragma mark -

- (void) dealloc {
	if (aligncontroller__instanceIDToIvars)
	{
		[aligncontroller__instanceIDToIvars removeObjectForKey:[self aligncontroller__instanceID]];
		if ([aligncontroller__instanceIDToIvars count] == 0)
		{
			[aligncontroller__instanceIDToIvars release];
			aligncontroller__instanceIDToIvars = nil;
		}
	}


	[super dealloc];
}


- (id)aligncontroller__instanceID
{
    return [NSValue valueWithPointer:self];
}

- (NSMutableDictionary *) aligncontroller__ivars
{
    NSMutableDictionary *ivars;
    
    if (aligncontroller__instanceIDToIvars == nil)
        aligncontroller__instanceIDToIvars = [[NSMutableDictionary alloc] init];
    
    ivars = [aligncontroller__instanceIDToIvars objectForKey:[self aligncontroller__instanceID]];
    if (ivars == nil)
    {
        ivars = [NSMutableDictionary dictionary];
        [aligncontroller__instanceIDToIvars setObject:ivars forKey:[self aligncontroller__instanceID]];
    }
    
    return ivars;
}



@end
