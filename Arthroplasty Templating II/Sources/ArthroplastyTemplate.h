//
//  ArthroplastyTemplate.h
//  Arthroplasty Templating II
//  Created by Joris Heuberger on 04/04/07.
//  Copyright (c) 2007-2009 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ArthroplastyTemplateFamily;


typedef enum {
	ArthroplastyTemplateAnteriorPosteriorDirection = 0,
	ArthroplastyTemplateLateralDirection
} ArthroplastyTemplateViewDirection;


@interface ArthroplastyTemplate : NSObject {
	NSString* _path;
	ArthroplastyTemplateFamily* _family;
}

@property(readonly) NSString* path;
@property(assign) ArthroplastyTemplateFamily* family;
@property(readonly) NSString *fixation, *group, *manufacturer, *modularity, *name, *placement, *surgery, *type, *size, *referenceNumber;
@property(readonly) CGFloat scale, rotation;

-(id)initWithPath:(NSString*)path;

@end

@interface ArthroplastyTemplate (Abstract)

-(NSString*)pdfPathForDirection:(ArthroplastyTemplateViewDirection)direction;
-(BOOL)origin:(NSPoint*)point forDirection:(ArthroplastyTemplateViewDirection)direction;
-(NSArray*)textualData;
-(NSArray*)rotationPointsForDirection:(ArthroplastyTemplateViewDirection)direction;

@end
