/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

/** \brief base class for Window Controllers in OsiriX
*
*Root class for the Viewer Window Controllers such as ViewerController
*and Window3DController
*/

#import <Cocoa/Cocoa.h>
@class DicomDatabase;


#ifdef __cplusplus
extern "C"
{
#endif

NSInteger OSIRunPanel( NSAlertStyle style, NSString *title, NSString *msgFormat, NSString *defaultButton, NSString *alternateButton, NSString *otherButton, ...);

NSInteger OSIRunCriticalAlertPanel( NSString *title, NSString *msgFormat, NSString *defaultButton, NSString *alternateButton, NSString *otherButton, ...);
NSInteger OSIRunInformationalAlertPanel( NSString *title, NSString *msgFormat, NSString *defaultButton, NSString *alternateButton, NSString *otherButton, ...);
NSInteger OSIRunAlertPanel( NSString *title, NSString *msgFormat, NSString *defaultButton, NSString *alternateButton, NSString *otherButton, ...);

#ifdef __cplusplus
}
#endif

enum OsiriXBlendingTypes {BlendingPlugin = -1, BlendingFusion = 1, BlendingSubtraction, BlendingMultiplication, BlendingRed, BlendingGreen, BlendingBlue, Blending2DRegistration, Blending3DRegistration, BlendingLL};

#ifdef id
#define redefineID
#undef id
#endif

@class DicomImage, DicomSeries, DicomStudy;

@interface OSIWindowController : NSWindowController <NSWindowDelegate>
{
	int _blendingType;
	
	BOOL magneticWindowActivated;
	BOOL windowIsMovedByTheUserO;
	NSRect savedWindowsFrameO;
	
	DicomDatabase* _database;
}

@property(nonatomic,retain) DicomDatabase* database;
-(void)refreshDatabase:(NSArray*)newImages;
- (void) autoreleaseIfClosed;
+ (BOOL) dontWindowDidChangeScreen;
+ (void) setDontEnterWindowDidChangeScreen:(BOOL) a;
+ (void) setDontEnterMagneticFunctions:(BOOL) a;
- (void) setMagnetic:(BOOL) a;
- (BOOL) magnetic;

+ (void) setWindowAppearance: (NSWindow*) window;
+ (NSColor*) darkAppearanceFontColor;
+ (NSColor*) darkAppearanceBackgroundColor;
+ (float) darkAppearanceFontColorWhiteLevel;

- (NSMutableArray*) pixList;
- (void) addToUndoQueue:(NSString*) what;
- (int)blendingType;

- (IBAction) redo:(id) sender;
- (IBAction) undo:(id) sender;

- (IBAction) applyShading:(id) sender;
- (void) updateAutoAdjustPrinting: (id) sender;

#pragma mark-
#pragma mark current Core Data Objects
- (DicomStudy *)currentStudy;
- (DicomSeries *)currentSeries;
- (DicomImage *)currentImage;

- (float)curWW;
- (float)curWL;
@end

#ifdef redefineID
#define id Id
#undef redefineID
#endif
