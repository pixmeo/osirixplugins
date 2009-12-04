/* FileTypeSelector */

#import <Cocoa/Cocoa.h>

@interface FileTypeSelector : NSObject
{
    IBOutlet id addPanel;
    IBOutlet id csvRadio;
    IBOutlet id matrix;
    IBOutlet id xmlRadio;
}

- (id) init;
- (void) awakeFromNib;
- (NSView *) addPanel;
- (NSMatrix *) matrix;
- (NSButtonCell *) csvRadio;
- (NSButtonCell *) xmlRadio;

@end
