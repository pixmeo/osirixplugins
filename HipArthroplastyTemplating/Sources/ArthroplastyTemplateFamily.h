//
//  ArthroplastyTemplateFamily.h
//  Arthroplasty Templating II
//  Created by Alessandro Volz on 6/4/09.
//  Copyright (c) 2007-2009 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ArthroplastyTemplate.h"


@interface ArthroplastyTemplateFamily : NSObject {
	NSMutableArray* _templates;
}

@property(readonly) NSArray* templates;
@property(readonly) NSString *fixation, *group, *manufacturer, *modularity, *name, *patientSide, *surgery, *type;

-(id)initWithTemplate:(ArthroplastyTemplate*)templat;
-(BOOL)matches:(ArthroplastyTemplate*)templat;
-(void)add:(ArthroplastyTemplate*)templat;
-(ArthroplastyTemplate*)templateMatchingSize:(NSString*)size side:(ATSide)side;

-(ArthroplastyTemplate*)templateAfter:(ArthroplastyTemplate*)t;
-(ArthroplastyTemplate*)templateBefore:(ArthroplastyTemplate*)t;

+(CGFloat)numberForSize:(NSString*)size;

@end
