#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@interface VolumeCalculator : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;
- (ViewerController*)   viewerController;

@end
