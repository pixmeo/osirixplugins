//
//  ArthroplastyTemplatingWindowController+Color.mm
//  Arthroplasty Templating II
//
//  Created by Alessandro Volz on 08.09.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "ArthroplastyTemplatingWindowController+Color.h"

@implementation ArthroplastyTemplatingWindowController (Color)

NSString* ColorifyKey = @"colorify";
NSString* ColorifyColorKey = @"colorify.color";

-(void)awakeColor {
	[_shouldTransformColor setState:[_userDefaults bool:ColorifyKey otherwise:[_shouldTransformColor state]]];
	[_transformColor setColor:[_userDefaults color:ColorifyColorKey otherwise:[_transformColor color]]];
}

-(IBAction)transformColorChanged:(id)sender {
	if (sender == _shouldTransformColor) {
		[_userDefaults setBool:[_shouldTransformColor state] forKey:ColorifyKey];
	} else if (sender == _transformColor) {
		[_userDefaults setColor:[_transformColor color] forKey:ColorifyColorKey];
	}
}

@end
