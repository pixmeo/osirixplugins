#import "FileTypeSelector.h"

@implementation FileTypeSelector


- (id) init
{
	NSLog( @"FileTypeSelector init !" );

	return self;
}

- (void) awakeFromNib
{
	NSLog( @"FileTypeSelector awake !" );
}

- (NSView *) addPanel
{
	return addPanel;
}

- (NSMatrix *) matrix
{
	return matrix;
}

- (NSButtonCell *) csvRadio
{
	return csvRadio;
}

- (NSButtonCell *) xmlRadio
{
	return xmlRadio;
}

@end
