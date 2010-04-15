//
//  XploreReportsClass.m
//

#import "XploreReportsClass.h"
#import <OsiriX Headers/Notifications.h>
#import <OsiriX Headers/DicomImage.h>
#import <OsiriX Headers/DicomStudy.h>

#define ADDRESS @"172.16.1.13"

@implementation XploreReportsClass

- (void) initPlugin
{
	NSLog( @"------ XploreReportsClass initPlugin");
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(databaseAddition:) name: OsirixAddToDBCompleteNotification object:NULL];
}

-(void)databaseAddition:(NSNotification*)notification
{
	NSArray* addedImages = [[notification userInfo] objectForKey: OsirixAddToDBCompleteNotificationImagesArray];
	
	NSMutableArray *studies = [NSMutableArray array];
	
	@try
	{
		for( DicomImage* image in addedImages)
			if( [studies containsObject: [image valueForKeyPath: @"series.study"]] == NO)
				[studies addObject: [image valueForKeyPath: @"series.study"]];
		
		for( DicomStudy* study in studies)
			if( [study valueForKey: @"reportURL"] == nil || [[study valueForKey: @"reportURL"] length] == 0)
			{
				NSString *patientID = [study valueForKey: @"patientID"];
				
				[study setValue: [NSString stringWithFormat: @"http://%@/xploreintranet/Patients/PatientExamens.asp?PatientID=%@", ADDRESS, patientID] forKey: @"reportURL"];
			}
	}
	
	@catch (NSException* e)
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
	}
}

- (long) filterImage:(NSString*) menuName
{
	NSString *patientID = [[[viewerController fileList] lastObject] valueForKeyPath: @"series.study.patientID"];
	
	NSURL *url = [NSURL URLWithString: [NSString stringWithFormat: @"http://%@/xploreintranet/Patients/PatientExamens.asp?PatientID=%@", ADDRESS, patientID]];
	
	[[NSWorkspace sharedWorkspace] openURL: url];
	
	return 0; // No Errors
}
@end
