//
//   DCMPDFImportFilter
//  
//

#import <Foundation/Foundation.h>
#import "OsiriXAPI/PluginFilter.h"

@class DCMCalendarDate;

@interface DCMPDFImportFilter : PluginFilter
{
	int imageNumber;
}

- (long) filterImage:(NSString*) menuName;
- (void)convertImageToDICOM:(NSString *)path source:(NSString *) source;

@end
