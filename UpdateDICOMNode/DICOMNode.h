//
//  DICOMNodeUpdate.h
//  DICOMNodeUpdate

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@interface DICOMNodeUpdate : PluginFilter {

	BOOL done;
}

- (long) filterImage:(NSString*) menuName;

@end
