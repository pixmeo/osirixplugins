//
//  ReporterFilter.m
//  Reporter
//
//  Copyright (c) 2012 OsiriX. All rights reserved.
//

#import "ReporterFilter.h"
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/DicomImage.h>
#import <OsiriXAPI/NSAppleScript+N2.h>
#import <OsiriXAPI/NSFileManager+N2.h>
#import <OsiriXAPI/N2Debug.h>
#import <OsiriXAPI/SRAnnotation.h>
#import <OsiriXAPI/DCMView.h>
#import <OsiriXAPI/N2Stuff.h>
#import <OsiriXAPI/NSUserDefaults+OsiriX.h>
#import <OsiriXAPI/PreferencesWindowController.h>
#import <OsiriXAPI/KBPopUpToolbarItem.h>

#import <objc/runtime.h>
//#import <OsiriXAPI/BrowserController.h>
#import <OsiriXAPI/ViewerController.h>
#import <OsiriXAPI/ToolbarPanel.h>

@interface ReporterFilter ()

-(void)_initToolbarItems;

@end

@implementation ReporterFilter

//NSString* const ReporterReplaceDefaultsKey = @"ReporterReplace";

-(void)initPlugin {
    [self _initToolbarItems];
    
    NSImage* image = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"Reporter"]] autorelease];
	[PreferencesWindowController addPluginPaneWithResourceNamed:@"ReporterPrefs" inBundle:[NSBundle bundleForClass:[self class]] withTitle:NSLocalizedString(@"Reporter", nil) image:image];

}

+(NSString*)saveImageInTmp:(NSImage*)image {
    NSBitmapImageRep* rep = [image.representations objectAtIndex:0];
    NSString* path = @"~/Desktop/test.png";
    
    path = [path stringByExpandingTildeInPath];
    
    if ([[rep representationUsingType:NSPNGFileType properties:nil] writeToFile:path atomically:NO])
        return path;
    return nil;
}

-(void)add:(NSArray*)adds forStudy:(DicomStudy*)study {
    NSString* reportFilePath = [study reportURL];
    
    [viewerController performSelector:@selector(generateReport:) withObject:self];
    
    if (![reportFilePath hasSuffix:@"pages"]) {
        NSBeginAlertSheet(@"Reporter", nil, nil, nil, nil, nil, nil, nil, nil, @"The report must be written with the Pages application, part of Apple iWork.");
        return;
    }
    
    [NSWorkspace.sharedWorkspace openFile:reportFilePath withApplication:@"Pages"];
    
    NSURL* asurl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reporter" withExtension:@"scpt"];
    NSAppleScript* as = [[[NSAppleScript alloc] initWithContentsOfURL:asurl error:NULL] autorelease];
    
    @try {
        for (NSArray* add in adds) {
            NSDictionary* errs = nil;
            [as runWithArguments:[NSArray arrayWithObjects: reportFilePath, [add objectAtIndex:0], [add objectAtIndex:1], [add objectAtIndex:2], /*[NSNumber numberWithInteger:[NSUserDefaults.standardUserDefaults boolForKey:ReporterReplaceDefaultsKey]],*/ nil] error:&errs];
            if (errs.count) NSLog(@"Reporter AppleScript errors: %@", errs);
            
            [NSFileManager.defaultManager removeItemAtPath:[add objectAtIndex:1] error:NULL];
        }
    } @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    }
}

-(NSString*)captionForImage:(DicomImage*)image rois:(NSArray*)rois {
    NSMutableString* caption = [NSMutableString string];
    if (image.isKeyImage.boolValue)
        [caption appendString:NSLocalizedString(@"Key image: ", @"prefix of report image caption for key images")];
    [caption appendFormat:NSLocalizedString(@"Frame %@ of series %@", @"caption"), image.instanceNumber, image.series.name];
    if (rois.count)
        [caption appendFormat:NSLocalizedString(@", containing %@", @"suffix of report image caption for ROIs count"), N2LocalizedSingularPluralCount(rois.count, NSLocalizedString(@"ROI", nil), NSLocalizedString(@"ROIs", nil))];
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"ReporterIncludeStudyDateInImageCaptions"])
        [caption appendFormat:NSLocalizedString(@", %@", @"when appending dates"), [NSUserDefaults formatDate:image.series.study.date]];
    return caption;
}

-(NSString*)uidForImage:(DicomImage*)image {
    return [NSString stringWithFormat:@"%@-%@", image.sopInstanceUID, image.frameID];
}

-(void)processStudy:(DicomStudy*)study alsoImagesWithROIs:(BOOL)alsoImagesWithROIs {
    NSMutableArray* images = [NSMutableArray array];
    
    // save open viewers
    for (ViewerController* v in [ViewerController get2DViewers])
        for (int i = 0; i < v.maxMovieIndex; ++i)
            [v saveROI:i];

    // key images
    for (DicomImage* image in study.keyImages)
        [images addObject:image];
    
    // images with ROIs
    NSMutableArray* allImages = [NSMutableArray array];
    // saved ROIs
    for (DicomSeries* series in study.series)
        [allImages addObjectsFromArray:series.images.allObjects];
    
    if (alsoImagesWithROIs)
        for (DicomImage* roi in [study.roiSRSeries images]) {
            NSArray* robjs = [NSUnarchiver unarchiveObjectWithData:[SRAnnotation roiFromDICOM:[roi completePath]]];
            if (!robjs.count) continue;
            
            NSInteger it = [roi.comment rangeOfString:@"-" options:NSLiteralSearch+NSBackwardsSearch].location;
            NSString* uid = [roi.comment substringToIndex:it];
            int fid = [[roi.comment substringFromIndex:it+1] intValue];
            // find the image that uses these ROIs
            NSPredicate* p;
            if (fid)
                p = [NSPredicate predicateWithFormat:@"sopInstanceUID = %@ and frameID = %@", uid, [NSNumber numberWithInt:fid]];
            else p = [NSPredicate predicateWithFormat:@"sopInstanceUID = %@", uid];
            NSArray* found = [allImages filteredArrayUsingPredicate:p];
            if (found.count)
                [images addObject:[found objectAtIndex:0]];
        }
    
    // remove double entries: first sort, then remove subsequent doubles
    [images sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if (obj1 < obj2) return NSOrderedAscending;
        if (obj1 > obj2) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    for (NSInteger i = images.count-2; i >= 0; --i)
        if ([images objectAtIndex:i] == [images objectAtIndex:i+1])
            [images removeObjectAtIndex:i+1];
    
    NSMutableArray* adds = [NSMutableArray array];
    
    /* This applescript allows us to obtain the width our text boxes will take (100%), allowing us to adapt the image frame rect if we want
     tell application "Pages"
     tell front document
     set iwidth to width of last page
     set iwidth to iwidth - left margin - right margin
     set sc to paragraph style "Caption"
     set iwidth to iwidth - (first line indent of sc) - (right indent of sc)
     end tell
     end tell
     */

    for (DicomImage* image in images)
        @try {
            DCMPix* pix = [[DCMPix alloc] initWithPath:image.completePath :0 :0 :nil :0 :image.series.id.intValue isBonjour:NO imageObj:image];
            [pix CheckLoad]; // ?
            NSRect frame = NSMakeRect(0,0,768,768); // MAX(image.width.intValue*2, 750), MAX(image.height.intValue*2, 750)
            
            NSWindow* win = [[NSWindow alloc] initWithContentRect:frame styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];

            DicomImage* roisImage = [study roiForImage:image inArray:nil];
            NSArray* rois = roisImage? [NSUnarchiver unarchiveObjectWithData:[SRAnnotation roiFromDICOM:[roisImage completePath]]] : nil;
            
            DCMView* view = [[DCMView alloc] initWithFrame:frame imageRows:image.height.intValue imageColumns:image.width.intValue];
            [view setPixels:[NSMutableArray arrayWithObject:pix] files:[NSMutableArray arrayWithObject:image] rois:(rois? [NSMutableArray arrayWithObject:rois] : nil) firstImage:0 level:'i' reset:YES];
            [view setXFlipped:image.xFlipped.boolValue];
            [view setYFlipped:image.yFlipped.boolValue];
            [view setWLWW:pix.wl:pix.ww];
            [win.contentView addSubview:view];
            [view drawRect:frame];
            
            NSString* path = [[self class] saveImageInTmp:[view nsimage]];
            
            [view removeFromSuperview];
            [view release];
            [win release];
            [pix release];
            
            NSString* caption = [self captionForImage:image rois:rois];
            
            NSString* uid = [self uidForImage:image];
            
            if (path) [adds addObject:[NSArray arrayWithObjects: uid, path, caption, nil]];
        } @catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
        }
    
    [self add:adds forStudy:study];
}

-(long)filterImage:(NSString*)menuName {
    DCMView* imageView = [viewerController imageView];
    NSString* uid = [self uidForImage:[imageView dicomImage]];
    NSString* caption = [self captionForImage:[imageView dicomImage] rois:[imageView curRoiList]];
    NSString* path = [[self class] saveImageInTmp:[imageView nsimage]];
    [self add:[NSArray arrayWithObject:[NSArray arrayWithObjects: uid, path, caption, nil]] forStudy:viewerController.currentStudy];
    return 0;
}

#pragma mark Toolbars

ReporterFilter* ReporterInstance = nil;

-(void)_initToolbarItems {
    ReporterInstance = self;
    
    Method method;
    IMP imp;
    
    // ViewerController
    
    Class ViewerControllerClass = NSClassFromString(@"ViewerController");
    
    method = class_getInstanceMethod(ViewerControllerClass, @selector(toolbarAllowedItemIdentifiers:));
    imp = method_getImplementation(method);
    class_addMethod(ViewerControllerClass, @selector(_ReporterViewerToolbarAllowedItemIdentifiers:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_ReporterViewerToolbarAllowedItemIdentifiers:)));
    
    method = class_getInstanceMethod(ViewerControllerClass, @selector(toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:));
    imp = method_getImplementation(method);
    class_addMethod(ViewerControllerClass, @selector(_ReporterViewerToolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_ReporterViewerToolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:)));
}

NSString* ReporterViewerToolbarItemIdentifier = @"ReporterViewerToolbarItem";

-(NSArray*)_ReporterViewerToolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [[self _ReporterViewerToolbarAllowedItemIdentifiers:toolbar] arrayByAddingObject:ReporterViewerToolbarItemIdentifier];
}

-(NSToolbarItem*)_ReporterToolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
//    static NSString* ReporterIconFilePath = [[[NSBundle bundleForClass:[ReporterFilter class]] pathForImageResource:@"Reporter"] retain];
    
    if ([itemIdentifier isEqualToString:ReporterViewerToolbarItemIdentifier]) {
        KBPopUpToolbarItem* item = [[[KBPopUpToolbarItem alloc] initWithItemIdentifier:ReporterViewerToolbarItemIdentifier] autorelease];
        item.label = item.paletteLabel = NSLocalizedString(@"Reporter", @"Name of toolbar item");
        item.image = [[[NSImage alloc] initWithContentsOfURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"Reporter" withExtension:@"png"]] autorelease];
        [item.image setSize:NSMakeSize(33,33)];
        
        NSMenuItem* mi;
        item.menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
        mi = [item.menu addItemWithTitle:NSLocalizedString(@"Add currently displayed image to the Report", nil) action:@selector(_toolbarActionImage:) keyEquivalent:@""];
        mi.target = ReporterInstance;
        mi = [item.menu addItemWithTitle:NSLocalizedString(@"Add key images to the Report", nil) action:@selector(_toolbarActionKeyImages:) keyEquivalent:@""];
        mi.target = ReporterInstance;
        mi = [item.menu addItemWithTitle:NSLocalizedString(@"Add key images and images containing ROIs to the Report", nil) action:@selector(_toolbarActionKeyImagesAndROIs:) keyEquivalent:@""];
        mi.target = ReporterInstance;
//        [item.menu addItem:[NSMenuItem separatorItem]];
//        mi = [item.menu addItemWithTitle:NSLocalizedString(@"Replace previously added images instead of adding them again", nil) action:@selector(_toggleReplaceImages:) keyEquivalent:@""];
//        [mi bind:@"value" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[[NSArray arrayWithObjects:@"values", ReporterReplaceDefaultsKey, nil] componentsJoinedByString:@"."] options:nil];
        
        item.action = @selector(_toolbarActionImage:);
        item.target = ReporterInstance;
        
        return item;
    }
    
    return nil;
}

-(NSToolbarItem*)_ReporterViewerToolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem* item = [ReporterInstance _ReporterToolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
    if (item) return item;
    return [self _ReporterViewerToolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
}

-(BOOL)validateToolbarItem:(NSToolbarItem*)item {
//    if ([item.toolbar.delegate isKindOfClass:[BrowserController class]])
//        return [[(BrowserController*)item.toolbar.delegate databaseOutline] numberOfSelectedRows] >= 1;
    
    ViewerController* vc = [ViewerController frontMostDisplayed2DViewer];
    DicomStudy* study = [vc currentStudy];
    
    return study.reportURL != nil;
}

-(void)_toolbarActionImage:(id)sender {
    viewerController = [ViewerController frontMostDisplayed2DViewer];
    [self filterImage:nil];
    viewerController = nil;
}

-(void)_toolbarActionKeyImages:(id)sender {
    viewerController = [ViewerController frontMostDisplayed2DViewer];
    [self processStudy:[viewerController currentStudy] alsoImagesWithROIs:NO];
    viewerController = nil;
}

-(void)_toolbarActionKeyImagesAndROIs:(id)sender {
    viewerController = [ViewerController frontMostDisplayed2DViewer];
    [self processStudy:[viewerController currentStudy] alsoImagesWithROIs:YES];
    viewerController = nil;
}

/*-(void)_toggleReplaceImages:(id)sender {
    [NSUserDefaults.standardUserDefaults setBool:![NSUserDefaults.standardUserDefaults boolForKey:ReporterReplaceDefaultsKey] forKey:ReporterReplaceDefaultsKey];
}*/

@end

