//
//  ZoomMatrix.m
//  EjectionFraction
//
//  Created by joris on 4/4/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ZoomMatrix.h"

@implementation ZoomMatrix

- (id) init {
	if (![super init]) return nil;
	
	images = [[NSMutableArray alloc] initWithCapacity:0];
	
	return self;
}


- (void)dealloc
{
	if(images) [images release];
	[super dealloc];
}

- (void)drawRect:(NSRect)aRect
{
	NSEnumerator *e = [[self cells] objectEnumerator];
	NSEnumerator *eIm = [images objectEnumerator];
	id cell, previousCell=nil, im;
	NSSize sz, szIm, newSz;
	float factH, factV, minFact;
	while ( cell = [e nextObject])
	{
		im = [eIm nextObject];
		sz = [self cellSize];
		szIm = [im size];
		if(([im size].width<=0 || [im size].height<=0) && previousCell)
			szIm = [[previousCell image] size];
		previousCell = cell;
	
		factH = (float)sz.width/(float)szIm.width;
		factV = (float)sz.height/(float)szIm.height;
		
		minFact = (factH<factV)?factH:factV;
		
		//minFact = (minFact<1)?1:minFact;
		NSInteger row = 0;
		NSInteger col = 0;
		[self getRow: &row column: &col ofCell: (NSCell*)cell];
		newSz = NSMakeSize(szIm.width*minFact,szIm.height*minFact);
		if (col<2)
		{
			if(minFact>1)
			{
				NSImage * img = [[NSImage alloc] initWithSize: newSz];
				[im setScalesWhenResized:YES];
				
				if(newSz.width>0 && newSz.height>0)
				{
					[img lockFocus];
					[NSGraphicsContext saveGraphicsState];
					[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
					[im drawInRect:NSMakeRect(0.0,0.0,newSz.width,newSz.height) fromRect:NSMakeRect(0.0,0.0, szIm.width, szIm.height) operation:NSCompositeCopy fraction:1.0];
					[NSGraphicsContext restoreGraphicsState];
					[img unlockFocus];
					[cell setImage: img];
				}
			}
		}
		else if (col==2)
		{
			NSImage *image = [[NSImage alloc] initWithSize: newSz];
			[image setFlipped:YES];
			[image setScalesWhenResized:YES];
			if(newSz.width>0 && newSz.height>0)
			{
				[image lockFocus];
				[[NSColor whiteColor] set];
				NSRectFill( NSMakeRect( 0, 0, [image size].width, [image size].height ));
				[image unlockFocus];
			}
			NSMutableArray * rois;
			
			if(row==0)
			{
				rois = ROIrow0;
			}
			else if(row==1)
			{
				rois = ROIrow1;
			}
			else if(row==2)
			{
				rois = ROIrow2;
			}
			
			int ind = ([[[rois objectAtIndex:0] name] hasPrefix:@"Dias"])? 0: 1;
			ROI * roi = [rois objectAtIndex:ind];
			NSPoint cm;
			cm.x = 0;
			cm.y = 0;
			long m, x, y, x1, y1;
			for( m = 0 ; m < [[roi points] count]; m++)
			{
				cm.x += [[[roi points] objectAtIndex:m] x];
				cm.y += [[[roi points] objectAtIndex:m] y];
			}
			
			cm.x = cm.x / [[roi points] count];
			cm.y = cm.y / [[roi points] count];
			float minx,maxx,miny,maxy,h,w,s1,s2;
			minx = 100000;
			maxx = 0;
			miny = 100000;
			maxy = 0;
			for( m = 0 ; m < [[roi points] count]; m++)
			{
				x = [[[roi points] objectAtIndex: m] point].x;
				y = [[[roi points] objectAtIndex: m] point].y;
				
				x = x - cm.x;
				y = y - cm.y;
				// rotation
				float cos_angle = cos(angle[row]);
				float sin_angle = sin(angle[row]);
				x1 = x * cos_angle - y * sin_angle;
				y1 = x * sin_angle + y * cos_angle;
				// min
				minx = (minx <= x1) ? minx : x1 ;
				miny = (miny <= y1) ? miny : y1 ;
				// max
				maxx = (maxx >= x1) ? maxx : x1 ;
				maxy = (maxy >= y1) ? maxy : y1 ;
			}
			h = maxy - miny;
			w = maxx - minx;
			s1 = (float)newSz.height/(float)h;
			s2 = (float)newSz.width/(float)w;
			float scale=(s1<s2)?s1:s2; // =min(s1,s2)
			scale = 0.8*scale;
			[self drawROI: [rois objectAtIndex:0]: (NSImage*) image: (float) scale: (NSPoint) cm: (float) angle[row]];
			[self drawROI: [rois objectAtIndex:1]: (NSImage*) image: (float) scale: (NSPoint) cm: (float) angle[row]];
			[cell setImage: image];
			previousCell = nil;
		}
	}
	[super drawRect:(NSRect)aRect];
}

-(void) setType:(int)t atindex:(int)index
{
	//[types removeObjectAtIndex: index];
	[types insertObject: [[NSNumber alloc] initWithInt: t] atIndex: index];
	
}

-(void) setImage:(NSImage*)im atindex:(int)index
{
	//[images removeObjectAtIndex: index];
	[images insertObject: im atIndex: index];
}

-(int) getTypeAtindex:(int)index
{
	return [[types objectAtIndex: index] intValue];
}

-(NSImage*) getImageAtindex:(int)index
{
	return [images objectAtIndex: index];
}

-(NSImage*) copyImage:(NSImage*)im
{
	return [im copy];
}

-(void) setImage:(NSImage*)im cellAtRow:(int)r column:(int)c
{
	[self setImage:im atindex:3*r+c];
	[[self cellAtRow: r column: c] setImage: im];
}

-(void) copyImages
{
//	images = [[NSMutableArray alloc] initWithCapacity:[[self cells] count]];

	NSEnumerator *e = [[self cells] objectEnumerator];
	id cell;
	while ( cell = [e nextObject])
	{	
		NSImage * img = [[NSImage alloc] initWithSize: [[cell image] size]];
		if([[cell image] size].width>0 && [[cell image] size].height>0)
		{
			[img lockFocus];
			[NSGraphicsContext saveGraphicsState];
			[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
			[[cell image] drawInRect:NSMakeRect(0.0,0.0,[[cell image] size].width,[[cell image] size].height) fromRect:NSMakeRect(0.0,0.0,[[cell image] size].width, [[cell image] size].height) operation:NSCompositeCopy fraction:1.0];
			[NSGraphicsContext restoreGraphicsState];
			[img unlockFocus];
			[images addObject: img];
		}
	}
}

-(void) drawROI:(ROI*) roi: (NSImage*) image: (float) scale: (NSPoint) cmDias: (float) a
{
	// ROI center of mass 
	NSPoint cm;
	cm.x = 0;
	cm.y = 0;
	long m;
	for( m = 0 ; m < [[roi points] count]; m++)
	{
		cm.x += [[[roi points] objectAtIndex:m] x];
		cm.y += [[[roi points] objectAtIndex:m] y];
	}
	cm.x = cm.x / [[roi points] count];
	cm.y = cm.y / [[roi points] count];

	// starting point
	NSMutableArray *pts = [roi points];

	NSPoint startingPoint;
	// original coordinates
	int x, y, x1, y1;
	x = [[pts objectAtIndex: 0] point].x;
	y = [[pts objectAtIndex: 0] point].y;
	// center of mass is translated on the origin for scaling and rotation
	// translation on origin
	x = (x - cm.x);
	y = (y - cm.y);
	// scaling
	x = x * scale;
	y = y * scale;
	// rotation
	float cos_angle = cos(a);
	float sin_angle = sin(a);
	x1 = x * cos_angle - y * sin_angle;
	y1 = x * sin_angle + y * cos_angle;

	NSColor *color;
	if([[roi name] hasPrefix:@"Syst"])
	{
		// translation on original position
		x1 = x1 + (cm.x - cmDias.x) * scale;
		y1 = y1 + (cm.y - cmDias.y) * scale;
		// color of the path
		color = [NSColor grayColor];
	}
	else
	{
		color = [NSColor blackColor];
	}

	// origin is translated in the middle of the image
	x1 = x1 + [image size].width/2;
	y1 = y1 + [image size].height/2;

	// point is moved
	startingPoint.x = x1;
	startingPoint.y = y1;

	if([image size].width<=0 || [image size].height<=0) return;
	
	[image lockFocus];
	// path
	NSBezierPath *bp = [NSBezierPath bezierPath];
	// path thickness
	float thick = round(0.005*([image size].width+[image size].height)/2);
	thick = (thick<1)?1:thick;
	[bp setLineWidth:thick];

	[bp moveToPoint:startingPoint];
	[color set];

	NSPoint p;
	
	for( m = 1 ; m < [pts count]; m++)
	{	
		// original coordinates
		x = [[pts objectAtIndex: m] point].x;
		y = [[pts objectAtIndex: m] point].y;
		
		// center of mass is translated on the origin for scaling and rotation
		// translation on origin
		x = (x - cm.x);
		y = (y - cm.y);
		
		// scaling
		x = x * scale;
		y = y * scale;
		
		// rotation
		x1 = x * cos_angle - y * sin_angle;
		y1 = x * sin_angle + y * cos_angle;
		
		if([[roi name] hasPrefix:@"Syst"])
		{
			// tranlation on original position
			x1 = x1 + (cm.x - cmDias.x) * scale;
			y1 = y1 + (cm.y - cmDias.y) * scale;
		}

		// origin is translated in the middle of the image
		x1 = x1 + [image size].width/2;
		y1 = y1 + [image size].height/2;
		
		p.x = x1;
		p.y = y1;
		
		[bp lineToPoint:p];
	}

	[bp closePath];
	[bp stroke];
	[image unlockFocus];
}

-(void) addROI:(ROI*)roi:(int)row
{
	if(row==0)
	{
		if([ROIrow0 count]==0)
		{
			ROIrow0 = [[NSMutableArray alloc] initWithCapacity:2];
		}
		[ROIrow0 addObject:roi];
	}
	else if(row==1)
	{
		if([ROIrow1 count]==0)
		{
			ROIrow1 = [[NSMutableArray alloc] initWithCapacity:2];
		}
		[ROIrow1 addObject:roi];
	}
	else if(row==2)
	{
		if([ROIrow2 count]==0)
		{
			ROIrow2 = [[NSMutableArray alloc] initWithCapacity:2];
		}
		[ROIrow2 addObject:roi];
	}
}

-(void) setAngle: (float) a: (int) row
{
	angle[row] = a;
}

@end
