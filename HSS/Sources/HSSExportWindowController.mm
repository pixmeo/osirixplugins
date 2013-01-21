//
//  HSSExportWindowController.m
//  HSS
//
//  Created by Alessandro Volz on 21.12.11.
//  Copyright (c) 2011 OsiriX Team. All rights reserved.
//

#import "HSSExportWindowController.h"
#import "HSSAuthenticationWindowController.h"
#import <OsiriXAPI/N2Debug.h>
#import "HSS.h"
#import "HSSAPI.h"
#import <OsiriXAPI/ThreadModalForWindowController.h>
#import <OsiriXAPI/NSThread+N2.h>
#import "HSSAPISession.h"
#import "HSSFolder.h"
#import "HSSMedcase.h"
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/DicomImage.h>
#import "HSSMedcaseCreation.h"
#import "HSSCell.h"
#import <OsiriXAPI/ThreadsManager.h>
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/DicomImage.h>

@interface HSSExportWindowController ()

@property(retain,readwrite) NSArray* series;
@property(retain,readwrite) NSArray* images;
@property(retain,readwrite) HSSAPISession* session;
@property(retain,readwrite) HSSMedcaseCreation* medcase;
@property(retain,readwrite) NSAnimation* animation;

@end

@implementation HSSExportWindowController

@synthesize series = _series;
@synthesize images = _images;
@synthesize session = _session;
@synthesize medcase = _medcase;
@synthesize folder = _folder;
@synthesize animation = _animation;

@synthesize foldersOutline = _foldersOutline;
@synthesize treeController = _treeController;
@synthesize usernameField = _usernameField;
@synthesize nameField = _nameField;
@synthesize imagesMatrix = _imagesMatrix;
@synthesize diagnosisField = _diagnosisField;
@synthesize historyField = _historyField;
@synthesize openCheckbox = _openCheckbox;
@synthesize progressIndicator = _progressIndicator;
@synthesize foldersOutlineScroll = _foldersOutlineScroll;
@synthesize sendButton = _sendButton;

static NSString* const HSSExportWindowControllerContext = @"HSSExportWindowControllerContext";

- (id)initWithSeries:(NSArray*)series images:(NSArray*)images {
	if ((self = [super initWithWindowNibName:@"HSSExportWindow"])) {
        self.series = series;
        self.images = images;
        self.medcase = [[[HSSMedcaseCreation alloc] initWithSession:nil] autorelease];
    }
	
	return self;
}

+ (NSArray*)imagesInSeries:(NSArray*)series {
    NSMutableArray* images = [NSMutableArray array];
    
    for (DicomSeries* serie in series)
        for (DicomImage* image in serie.images)
            if (![images containsObject:image])
                [images addObject:image];
    
    return images;
}

+ (NSArray*)keyImagesInSeries:(NSArray*)series {
    NSMutableArray* images = [NSMutableArray array];
    
    for (DicomImage* image in [self imagesInSeries:series])
        if (image.storedIsKeyImage.boolValue)
            [images addObject:image];
    
    return images;
}

+ (NSArray*)imagesExcludingMultiframes:(NSArray*)images {
    NSMutableArray* rimages = [NSMutableArray array];
    
    for (NSInteger i = images.count-1; i >= 0; --i) {
        DicomImage* image = [images objectAtIndex:i];
        DicomSeries* series = image.series;
        if (series.images.count > 1) {
            BOOL isMultiframe = NO;
            for (DicomImage* oimage in series.images)
                if (oimage != image && [oimage.completePath isEqualToString:image.completePath]) {
                    isMultiframe = YES;
                    break;
                }
            if (!isMultiframe)
                [rimages addObject:image];
        }
    }
    
    return rimages;
}

- (void)awakeFromNib {
    NSCell* cell;
    NSInteger count;
    
    cell = [_imagesMatrix cellWithTag:0];
    count = [[[self class] imagesInSeries:self.series] count];
    if (self.series.count == 1)
        cell.title = [NSString stringWithFormat:NSLocalizedString(@"All images in this series (%d)", nil), (int)count];
    else cell.title = [NSString stringWithFormat:NSLocalizedString(@"All images in these series (%d)", nil), (int)count];;
    [cell setEnabled:(count > 0)];

    NSArray* pimages = [[self.images retain] autorelease];
    self.images = [[self class] imagesExcludingMultiframes:self.images];
    
    cell = [_imagesMatrix cellWithTag:1];
    NSArray* pkeyImages = [[self class] keyImagesInSeries:self.series];
    NSArray* keyImages = [[self class] imagesExcludingMultiframes:pkeyImages];
    count = [keyImages count];
    if (self.series.count == 1)
        cell.title = [NSString stringWithFormat:NSLocalizedString(@"Key images in this series (%d)", nil), (int)count];
    else cell.title = [NSString stringWithFormat:NSLocalizedString(@"Key images in these series (%d)", nil), (int)count];;
    if (pkeyImages.count > count)
        cell.title = [NSString stringWithFormat:@"%@ - %@", cell.title, NSLocalizedString(@"multiframe files excluded", @"keep this string short...")];
    [cell setEnabled:(count > 0)];
    
    cell = [_imagesMatrix cellWithTag:2];
    count = self.images.count;
    if (count == 1)
        cell.title = [NSString stringWithFormat:NSLocalizedString(@"Current image", nil)];
    else cell.title = [NSString stringWithFormat:NSLocalizedString(@"Selected images (%d)", nil), (int)count];
    if (pimages.count > count)
        cell.title = [NSString stringWithFormat:@"%@ - %@", cell.title, NSLocalizedString(@"multiframe files excluded", @"keep this string short...")];
    [cell setEnabled:(count > 0)];

    [_imagesMatrix selectCellWithTag:2]; // default d'apres la spec
    while (_imagesMatrix.selectedTag > 0 && ![_imagesMatrix.selectedCell isEnabled])
        [_imagesMatrix selectCellWithTag:_imagesMatrix.selectedTag-1];
    
    [_progressIndicator startAnimation:self];
    
    cell = [[[HSSCell alloc] initTextCell:@""] autorelease];
    cell.font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
    cell.lineBreakMode = NSLineBreakByClipping;
    _foldersOutline.cell = cell;
    
    _foldersOutline.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
   
    [_treeController addObserver:self forKeyPath:@"selectedObjects" options:0 context:HSSExportWindowControllerContext]; // useless: McKesson said "adding images to an existing case is outside the scope of this project" (Rex Jakobovits, 2012/1/27 00:47:26 HNEC)
    
/*    NSMenu* menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
    menu.delegate = self;
    [_foldersOutline setMenu:menu];*/
}

- (void)dealloc {
    [_treeController removeObserver:self forKeyPath:@"selectedObjects"];
    
    self.animation = nil;
    
    self.session = nil;
    self.images = nil;
    self.series = nil;
    self.medcase = nil;
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != HSSExportWindowControllerContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if ([keyPath isEqualToString:@"selectedObjects"] && object == _treeController && _treeController.selectedObjects.count) {  // useless: McKesson said "adding images to an existing case is outside the scope of this project" (Rex Jakobovits, 2012/1/27 00:47:26 HNEC)
        HSSItem* item = [_treeController.selectedObjects objectAtIndex:0];
        
        BOOL merge = [item isKindOfClass:[HSSMedcase class]];
        BOOL enable = !merge;
        
        [_diagnosisField setEnabled:enable];
        [_historyField setEnabled:enable];
        if (enable != [_nameField isEnabled]) {
            [_nameField setEnabled:enable];
            [self.medcase setCaseName:(merge? item.name : @"")];
        }
        
        [_sendButton setTitle:(merge? NSLocalizedString(@"Merge", nil) : NSLocalizedString(@"Send", nil))];
    }
}

- (void)beginSheetOnWindow:(NSWindow*)parentWindow {
	[NSApp beginSheet:self.window modalForWindow:parentWindow modalDelegate:self didEndSelector:@selector(_sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
    self.medcase.docWindow = parentWindow;
//	[self.window makeKeyAndOrderFront:self];
}


- (void)windowDidBecomeKey:(NSNotification*)notification {
    if (!_alreadyDidBecomeSheet) {
        _alreadyDidBecomeSheet = YES;
        
        @try {
            Class enterprise = [HSS enterpriseClass];
            NSString* enterpriseUsername = nil;
            if ([enterprise respondsToSelector:@selector(Username)])
                enterpriseUsername = [enterprise performSelector:@selector(Username)];
            if (enterpriseUsername.length) {
                NSString* storedPassword = nil;
                if ([enterprise respondsToSelector:@selector(StoredPasswordForUsername:)])
                    storedPassword = [enterprise performSelector:@selector(StoredPasswordForUsername:) withObject:enterpriseUsername];
                if (storedPassword.length) {
                    self.session = [HSSAPI.defaultAPI newSessionWithLogin:enterpriseUsername password:storedPassword timeout:2.5 error:NULL];
                }
            }
        } @catch (...) {
        }
        
        if (!self.session)
            [[HSSAuthenticationWindowController new] beginSheetOnWindow:self.window callbackTarget:self selector:@selector(_authSheetCallbackWithSession:contextInfo:) context:nil];
        else [self performSelectorInBackground:@selector(_getUserFolderTreeThread) withObject:nil];
    }
}

- (NSString*)_patientId {
    for (DicomImage* image in self.images)
        if (image.series.study.patientID.length)
            return image.series.study.patientID;
    for (DicomSeries* series in self.series)
        if (series.study.patientID.length)
            return series.study.patientID;
    return nil;
}


- (void)_authSheetCallbackWithSession:(HSSAPISession*)session contextInfo:(void*)contextInfo {
    if (!session) {
        [self cancelAction:self];
        return;
    }
    
    self.session = session;
    [self.usernameField performSelectorOnMainThread:@selector(setStringValue:) withObject:session.userName waitUntilDone:NO];
    
//    [self performSelectorInBackground:@selector(_getFolderThread:) withObject:[NSArray arrayWithObjects: session.userHomeFolderOid, _folder, nil]];
    
    [self performSelectorInBackground:@selector(_getUserFolderTreeThread) withObject:nil];
}

- (void)_getUserFolderTreeThread {
    @autoreleasepool {
        NSArray* related = nil;
        @try {
            NSError* error = nil;
            
            NSArray* response = [self.session getHomeFolderTreeWithError:&error];
            
            if (error)
                [NSException raise:NSGenericException format:@"%@", error.localizedDescription];
            
            HSSFolder* temp = [[[HSSFolder alloc] init] autorelease];
            [temp syncWithAPIFolders:response];
            
            [self performSelectorOnMainThread:@selector(_fillUserFolderTreeWithResponse:) withObject:temp.content waitUntilDone:NO];
            
            related = [self.session getMedcasesRelatedToPatientId:[self _patientId] error:&error];
            
            if (error)
                [NSException raise:NSGenericException format:@"%@", error.localizedDescription];
            
        } @catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
            [self performSelectorOnMainThread:@selector(_showErrorAlert:) withObject:[NSError errorWithDomain:HSSErrorDomain code:-1 userInfo:[NSDictionary dictionaryWithObject:e.reason forKey:NSLocalizedDescriptionKey]] waitUntilDone:NO];
            return;
        }
        
        @try {
            NSError* error = nil;

            NSMutableDictionary* medcasesByFolder = [NSMutableDictionary dictionary];
            for (NSDictionary* medcase in related) {
                NSString* medcaseOid = [medcase objectForKey:@"oid"];

                NSDictionary* medcaseInfo = [self.session getMedcaseWithOid:medcaseOid error:&error];
                    
                if (error)
                    [NSException raise:NSGenericException format:@"%@", error.localizedDescription];
                    
                for (NSDictionary* folder in [medcaseInfo objectForKey:@"folders"]) {
                    NSString* folderOid = [folder objectForKey:@"oid"];
                    
                    NSMutableArray* medcasesInFolder = [medcasesByFolder objectForKey:folderOid];
                    if (!medcasesInFolder)
                        [medcasesByFolder setObject:(medcasesInFolder = [NSMutableArray array]) forKey:folderOid];
                    
                    [medcasesInFolder addObject:medcase];
                }
            }
            
            [self performSelectorOnMainThread:@selector(_fillUserMedcases:) withObject:medcasesByFolder waitUntilDone:NO];
            
        } @catch (NSException* e) {
            [self performSelectorOnMainThread:@selector(_fillUserMedcases:) withObject:nil waitUntilDone:NO];
            N2LogExceptionWithStackTrace(e);
            [self performSelectorOnMainThread:@selector(_showWarningAlert:) withObject:[NSError errorWithDomain:HSSErrorDomain code:-1 userInfo:[NSDictionary dictionaryWithObject:e.reason forKey:NSLocalizedDescriptionKey]] waitUntilDone:NO];
        }
    }
}

+ (NSIndexPath*)node:(id)node findFolderWithOid:(NSString*)oid {
    NSArray* childNodes = [node childNodes];
    for (NSUInteger i = 0; i < childNodes.count; ++i) {
        id childNode = [childNodes objectAtIndex:i];
        HSSFolder* child = [childNode representedObject];
        if ([child isKindOfClass:[HSSFolder class]]) {
            if ([child.oid isEqualToString:oid]) {
                return [NSIndexPath indexPathWithIndex:i];
            } else {
                NSIndexPath* subpath = [self node:childNode findFolderWithOid:oid];
                if (subpath) {
                    NSUInteger indexes[subpath.length+1];
                    indexes[0] = i;
                    [subpath getIndexes:&indexes[1]];
                    return [NSIndexPath indexPathWithIndexes:indexes length:subpath.length+1];
                }
            }
        }
    }
    
    return nil;
}

+ (NSString*)_defaultsKeyForLastFolderUidForUser:(NSString*)user {
    return [NSString stringWithFormat:@"HSS folder selection for user %@", user];
}

- (void)_expandIndexPath:(NSIndexPath*)path {
    if (path.length > 1)
        [self _expandIndexPath:[path indexPathByRemovingLastIndex]];
    [_foldersOutline expandItem:[_treeController.arrangedObjects descendantNodeAtIndexPath:path]];
}

- (void)_fillUserFolderTreeWithResponse:(id)content {
    if (![self.window isVisible])
        return;
    
    @synchronized (content) {
        _folder.content = content;
    
        NSString* userLastFolderOid = [NSUserDefaults.standardUserDefaults stringForKey:[[self class] _defaultsKeyForLastFolderUidForUser:_session.userLogin]];
        NSIndexPath* path = [[self class] node:_treeController.arrangedObjects findFolderWithOid:userLastFolderOid];
        if (!path)
            path = [[self class] node:_treeController.arrangedObjects findFolderWithOid:_session.userHomeFolderOid];
        
        if (path) {
            [self _expandIndexPath:path];
            [_treeController setSelectionIndexPath:path];
        }
    }
    
    NSRect rect;
    
    NSMutableDictionary* progressAnimation = [NSMutableDictionary dictionary];
    [progressAnimation setObject:_progressIndicator forKey:NSViewAnimationTargetKey];
    rect = _progressIndicator.frame;
    [progressAnimation setObject:[NSValue valueWithRect:rect] forKey:NSViewAnimationStartFrameKey];
    rect.origin = NSMakePoint([_progressIndicator.superview frame].size.width-rect.size.width, 65);
    [progressAnimation setObject:[NSValue valueWithRect:rect] forKey:NSViewAnimationEndFrameKey];

    NSMutableDictionary* nameAnimation = [NSMutableDictionary dictionary];
    [nameAnimation setObject:_nameField forKey:NSViewAnimationTargetKey];
    rect = _nameField.frame;
    [nameAnimation setObject:[NSValue valueWithRect:rect] forKey:NSViewAnimationStartFrameKey];
    rect.size.width -= 20;
    [nameAnimation setObject:[NSValue valueWithRect:rect] forKey:NSViewAnimationEndFrameKey];

    NSViewAnimation* a = [[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects: progressAnimation, nameAnimation, nil]] autorelease];
    a.duration = 0.25;
    a.animationCurve = NSAnimationEaseIn;
    [a startAnimation];
    self.animation = a;
}

/*- (void)setAnimation:(NSAnimation*)animation {
    if (animation != _animation) {
        if ([self.animation isAnimating])
            [self.animation stopAnimation];
        [self.animation release];
        
        _animation = [animation retain];
    }
}*/

+ (BOOL)indexPath:(NSIndexPath*)ip withRoot:(id)node includesFolderWithOid:(NSString*)folderOid {
    @try {
        for (NSUInteger p = 0; p < ip.length; ++p) {
            node = [[node childNodes] objectAtIndex:[ip indexAtPosition:p]];
            HSSFolder* folder = [node representedObject];
            if ([folder isKindOfClass:[HSSFolder class]]) {
                if ([folder.oid isEqualToString:folderOid])
                    return YES;
            } else
                return NO;
        }
    } @catch (...) {
        // do nothing
    }
    
    return NO;
}

- (void)_fillUserMedcases:(NSDictionary*)medcasesByFolder {
    [self.animation stopAnimation];
    
    NSMutableArray* mips = [NSMutableArray array];
    
    for (NSString* folderOid in medcasesByFolder) {
        NSArray* medcases = [medcasesByFolder objectForKey:folderOid];
        
        NSIndexPath* fip = [[self class] node:_treeController.arrangedObjects findFolderWithOid:folderOid];
        if (fip) {
            id item = [_treeController.arrangedObjects descendantNodeAtIndexPath:fip];
            HSSFolder* folder = [item representedObject];
            
            [folder syncWithAPIMedcases:medcases];

            for (NSUInteger i = 0; i < medcases.count; ++i)
                [mips addObject:[fip indexPathByAddingIndex:i]];
        }
    }

    NSString* favoriteFolderOid = [NSUserDefaults.standardUserDefaults stringForKey:[[self class] _defaultsKeyForLastFolderUidForUser:_session.userLogin]];
    if (favoriteFolderOid && ![[self class] node:_treeController.arrangedObjects findFolderWithOid:favoriteFolderOid])
        favoriteFolderOid = nil;
    if (!favoriteFolderOid)
        favoriteFolderOid = _session.userHomeFolderOid;
    
    [mips sortUsingComparator:^NSComparisonResult(NSIndexPath* ip1, NSIndexPath* ip2) { // prefer folders in the user's home folder
        BOOL ip1home = [[self class] indexPath:ip1 withRoot:_treeController.arrangedObjects includesFolderWithOid:favoriteFolderOid];
        BOOL ip2home = [[self class] indexPath:ip2 withRoot:_treeController.arrangedObjects includesFolderWithOid:favoriteFolderOid];
        
        if (ip1home != ip2home)
            return ip1home > ip2home ? NSOrderedAscending : NSOrderedDescending;
        
        return [ip1 compare:ip2];
    }];
    
    for (NSInteger i = mips.count-1; i >= 0; --i) {
        NSIndexPath* path = [mips objectAtIndex:i];
        [self _expandIndexPath:path];
        if (!i)
            [_treeController setSelectionIndexPath:path];
    }
    
    [_progressIndicator stopAnimation:self];
    
    NSRect rect;
    
    NSMutableDictionary* nameAnimation = [NSMutableDictionary dictionary];
    [nameAnimation setObject:_nameField forKey:NSViewAnimationTargetKey];
    rect = _nameField.frame;
    [nameAnimation setObject:[NSValue valueWithRect:rect] forKey:NSViewAnimationStartFrameKey];
    rect.size.width = [_progressIndicator.superview frame].size.width-rect.origin.x;
    [nameAnimation setObject:[NSValue valueWithRect:rect] forKey:NSViewAnimationEndFrameKey];
    
    NSViewAnimation* a = [[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects: nameAnimation, nil]] autorelease];
    a.duration = 0.25;
    a.animationCurve = NSAnimationEaseIn;
    [a startAnimation];
    self.animation = a;
}

/*- (void)_getFolderThread:(NSArray*)args {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try {
        NSString* folderOid = [args objectAtIndex:0];
        HSSFolder* folder = [args objectAtIndex:1];
        
        NSError* error;
        
        NSDictionary* response = [self.session getFolderWithOid:folderOid error:&error];
        
        [self performSelectorOnMainThread:@selector(_fillFolderWithResponse:)
                               withObject:[NSArray arrayWithObjects: folder, response, nil]
                            waitUntilDone:NO];
    } @catch (NSException* e) {
        [self performSelectorOnMainThread:@selector(_showErrorAlert:) withObject:[NSError errorWithDomain:HSSErrorDomain code:-1 userInfo:[NSDictionary dictionaryWithObject:e.reason forKey:NSLocalizedDescriptionKey]] waitUntilDone:NO];
    } @finally {
        [pool release];
    }
}

- (void)_fillFolderWithResponse:(NSArray*)args {
    HSSFolder* folder = [args objectAtIndex:0];
    NSDictionary* response = [args objectAtIndex:1];
    
    [folder syncWithAPIFolders:[response valueForKey:@"children"]];
//  [folder syncWithAPIMedcases:[response valueForKey:@"medcases"]];
    
    for (HSSFolder* child in folder.content)
        if ([child isKindOfClass:[HSSFolder class]])
            [self performSelectorInBackground:@selector(_getFolderThread:) withObject:[NSArray arrayWithObjects: child.oid, child, nil]];
    
    [_progressIndicator stopAnimation:self];
    [_foldersOutline expandItem:nil expandChildren:YES];
    
    NSTreeNode* node;
    BOOL selected = NO;
    for (NSInteger i = 0; (node = [_foldersOutline itemAtRow:i]) != nil; ++i) {
        HSSItem* item = node.representedObject;
        if (item.assignable) {
            [_foldersOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
            selected = YES;
            break;
        }
    }
    if (!selected) // if there is no assignable folder, deselect all
        [_foldersOutline selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
}*/

- (void)_showErrorAlert:(NSError*)error {
    [[NSAlert alertWithError:error] beginSheetModalForWindow:(self.window.isVisible? self.window : nil) modalDelegate:self didEndSelector:@selector(_errorAlertSheedDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)_showWarningAlert:(NSError*)error {
    if (self.window.isVisible)
        [[NSAlert alertWithError:error] beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (void)_errorAlertSheedDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
    [self cancelAction:self];
}

- (NSArray*)imagesToSend {
    switch (_imagesMatrix.selectedTag) {
        case 0: // all images
            return [[self class] imagesInSeries:self.series];
        case 1: // key images
            return [[self class] keyImagesInSeries:self.series];
        case 2: // current image(s)
            return self.images;
    }
    
    return nil;
}

- (IBAction)sendAction:(id)sender {
    NSArray* images = [self imagesToSend];
    if (images.count > 20)
        [[NSAlert alertWithMessageText:nil defaultButton:@"Send" alternateButton:NSLocalizedString(@"Cancel", nil) otherButton:nil informativeTextWithFormat:NSLocalizedString(@"You are adding %d images to HSS, a rather large amount of images for the purpose of HSS. Do you wish to proceed?", nil), (int)images.count] beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(_confirmSendSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
    else [NSApp endSheet:self.window];
}

- (void)_confirmSendSheetDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
    [alert.window orderOut:self];
    if (returnCode == NSAlertDefaultReturn)
        [NSApp endSheet:self.window];
}

- (IBAction)cancelAction:(id)sender {
    [NSApp endSheet:self.window returnCode:NSRunAbortedResponse];
}

- (void)_sheetDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
    @try {
        if (returnCode != NSRunAbortedResponse) {
            [sheet makeFirstResponder:nil]; // makes the currently edited text commit
            
            NSIndexPath* sp = [_treeController selectionIndexPath];
            HSSItem* destination = [[_treeController.arrangedObjects descendantNodeAtIndexPath:sp] representedObject];

            self.medcase.session = self.session;
            
            self.medcase.images = [self imagesToSend];
            
            self.medcase.destination = destination;
            
            NSString* folderOid = destination.oid;
            if ([destination isKindOfClass:[HSSMedcase class]]) // we want its containing folder
                folderOid = [[[[_treeController.arrangedObjects descendantNodeAtIndexPath:sp] parentNode] representedObject] oid];
            [NSUserDefaults.standardUserDefaults setObject:folderOid forKey:[[self class] _defaultsKeyForLastFolderUidForUser:_session.userLogin]];
            
            [ThreadsManager.defaultManager addThreadAndStart:self.medcase];
        }
    } @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    } @finally {
        [self.window close];
//        [self.window release];
        [self autorelease];
    }
}

#pragma mark NSOutlineViewDelegate

- (BOOL)outlineView:(NSOutlineView*)outlineView shouldSelectItem:(NSTreeNode*)node {
    HSSItem* item = node.representedObject;
    return item.assignable;
}

- (NSCell*)outlineView:(NSOutlineView*)outlineView dataCellForTableColumn:(NSTableColumn*)tableColumn item:(NSTreeNode*)node {
    if (!tableColumn) { // column not specified, they want to know if there's a cell to span over the whole table width instead of a cell per column
        HSSItem* item = node.representedObject;
        if ([item isKindOfClass:[HSSMedcase class]]) // medcases always span over the description column
            return outlineView.cell;
        if ([item isKindOfClass:[HSSFolder class]]) // folders only span over the description column if the description is empty
            if (!((HSSFolder*)item).desc.string.length)
                return outlineView.cell;
        
        return nil; // return nil to make them know that there's no span
    }
    
    return outlineView.cell;
}

- (void)outlineView:(NSOutlineView*)outlineView willDisplayCell:(HSSCell*)cell forTableColumn:(NSTableColumn*)tableColumn item:(NSTreeNode*)node {
    HSSItem* item = node.representedObject;
    if ([item isKindOfClass:[HSSMedcase class]]) {
        NSRect f = [outlineView frameOfCellAtColumn:(tableColumn? [[outlineView tableColumns] indexOfObject:tableColumn] : 0) row:[outlineView rowForItem:node]];
        f.origin.x -= 9;
        [@"●" drawAtPoint:f.origin withAttributes:[[cell attributedStringValue] attributesAtIndex:0 effectiveRange:NULL]];
    }
}


/*#pragma mark NSMenuDelegate

- (void)menuWillOpen:(NSMenu*)menu {
    if (![_foldersOutline.selectedRowIndexes containsIndex:_foldersOutline.clickedRow])
        [_foldersOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:_foldersOutline.clickedRow] byExtendingSelection:NO];
    
    [menu removeAllItems];
    NSMenuItem* mi;
    
//  Impossible: the API doesn't offer this feature
//    mi = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Create Subfolder...", nil) action:@selector(_addSubfolderAction:) keyEquivalent:@""];
//    mi.target = self;
//    mi.representedObject = [[_foldersOutline itemAtRow:_foldersOutline.clickedRow] representedObject];
//    [menu addItem:mi];
}

- (void)_addSubfolderAction:(NSMenuItem*)mi {
    HSSFolder* folder = mi.representedObject;
    NSLog(@"Add subfolder to %@", folder);
}*/

#pragma mark NSSplitViewDelegate

- (CGFloat)splitView:(NSSplitView*)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex {
    CGFloat dividerThickness = splitView.dividerThickness;
    switch (dividerIndex) {
        case 0: return 147;
        case 1: return NSHeight([[splitView.subviews objectAtIndex:0] bounds])+dividerThickness+51;
    }
    
    return proposedMin;
}

- (CGFloat)splitView:(NSSplitView*)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex {
    CGFloat dividerThickness = splitView.dividerThickness;
    CGFloat totHeight = NSHeight(splitView.bounds);
    
    switch (dividerIndex) {
        case 0: return totHeight-NSHeight([[splitView.subviews objectAtIndex:2] bounds])-dividerThickness-51-dividerThickness;
        case 1: return totHeight-41-dividerThickness;
    }
    
    return proposedMax;
}

@end





















