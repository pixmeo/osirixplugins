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
}

- (long) filterImage:(NSString*) menuName;
- (void) convertImageToDICOM:(NSString *)path source:(NSString *)src;

@end
