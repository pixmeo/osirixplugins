//
//   DCMJpegImportFilter
//  
//

#import <Foundation/Foundation.h>
#import "OsiriXAPI/PluginFilter.h"

@class DCMCalendarDate, DICOMExport;

@interface DCMJpegImportFilter : PluginFilter
{
	int imageNumber;
	DICOMExport *e;
    IBOutlet NSView *accessoryView;
    BOOL selectedStudyAvailable;
}

@property BOOL selectedStudyAvailable;

- (long) filterImage:(NSString*) menuName;
- (DicomImage*) convertImageToDICOM:(NSString *)path source:(DicomImage *)src;

@end
