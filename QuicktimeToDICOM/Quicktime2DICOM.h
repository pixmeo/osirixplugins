//
//   Quicktime2DICOM
//  
//

#import <Foundation/Foundation.h>
#import "OsiriXAPI/PluginFilter.h"

@class DICOMExport;

@interface Quicktime2DICOM : PluginFilter
{
}

- (void)convertMovieToDICOM:(NSString *)path source:(DicomImage*) source;
- (long) filterImage:(NSString*) menuName;

@end
