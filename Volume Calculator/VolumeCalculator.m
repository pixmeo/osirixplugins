#import "VolumeCalculator.h"
#import "ControllerVolumeCalculator.h"

@implementation VolumeCalculator

- (ViewerController*)   viewerController
{
	return viewerController;
}

- (long) filterImage:(NSString*) menuName
{
	ControllerVolumeCalculator* coWin = [[ControllerVolumeCalculator alloc] init:self];
	[coWin showWindow:self];
	
	return 0;
}
@end
