//
//   Quicktime2DICOM
//  
//

#import <Foundation/Foundation.h>
#import "OsiriX Headers/PluginFilter.h"

@class DICOMExport;

@interface Quicktime2DICOM : PluginFilter
{
}

- (void)convertMovieToDICOM:(NSString *)path source:(NSString*) source;
- (long) filterImage:(NSString*) menuName;

@end
