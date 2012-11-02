#import "Application.h"


@implementation MyApplication

- (void) applicationDidFinishLaunching:(NSNotification*) aNotification
{
	#if __LP64__
	NSRunInformationalAlertPanel( @"64-bit Tester", @"Yes, your computer can execute 64-bit application !", @"OK", 0L, 0L);
	#else
	NSRunInformationalAlertPanel( @"64-bit Tester", @"No, your computer cannot execute 64-bit application... It's a 32-bit only processor.", @"OK", 0L, 0L);
	#endif
	
	exit( 0);
}

@end
