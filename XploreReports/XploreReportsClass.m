//
//  XploreReportsClass.m
//

#import "XploreReportsClass.h"

@implementation XploreReportsClass

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{
	NSString *patientID = [[[viewerController fileList] lastObject] valueForKeyPath: @"series.study.patientID"];
	
	NSString *address = @"172.16.1.13";
	
	NSURL *url = [NSURL URLWithString: [NSString stringWithFormat: @"http://%@/xploreintranet/Patients/PatientExamens.asp?PatientID=%@", address, patientID]];
	
	[[NSWorkspace sharedWorkspace] openURL: url];
	
	return 0; // No Errors
}
@end
