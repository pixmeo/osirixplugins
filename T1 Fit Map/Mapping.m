#import "Mapping.h"
#import "Controller.h"

@implementation MappingT1FitFilter

- (ViewerController*)   viewerController
{
	return viewerController;
}

- (long) filterImage:(NSString*) menuName
{
	// Display a nice window to thanks the user for using our powerful filter!
	ControllerT1Fit* coWin = [[ControllerT1Fit alloc] init:self];
	[coWin showWindow:self];
	
	return 0;
}
@end
