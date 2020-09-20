#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>

@interface HL7toDICOMPDF : PluginFilter
{
    NSTimer *scanReportsFolderTimer;
    
    IBOutlet NSWindow *settings;
    IBOutlet NSPathControl *pathControl;
}

- (long) filterImage:(NSString*) menuName;

@end
