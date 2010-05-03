//
//  ArthroplastyTemplatingWindowController+List.h
//  Arthroplasty Templating II
//
//  Created by Alessandro Volz on 08.09.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "ArthroplastyTemplatingWindowController.h"

@interface ArthroplastyTemplatingWindowController (Templates)

-(void)awakeTemplates;
-(ArthroplastyTemplate*)templateAtPath:(NSString*)path;
-(ArthroplastyTemplate*)currentTemplate;
-(ArthroplastyTemplateFamily*)familyAtIndex:(int)index;
-(ArthroplastyTemplateFamily*)selectedFamily;
-(IBAction)searchFilterChanged:(id)sender;
-(BOOL)setFilter:(NSString*)string;

@end
