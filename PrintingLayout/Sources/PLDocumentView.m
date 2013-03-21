//
//  PLDocumentView.m
//  PrintingLayout
//
//  Created by Benoit Deville on 19.11.12.
//
//

#import "PLDocumentView.h"
#import "PLLayoutView.h"
#import "PLThumbnailView.h"
#import "PLWindowController.h"
#import <OsiriXAPI/DicomImage.h>
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/SeriesView.h>
#import <OsiriXAPI/StudyView.h>
#import <OsiriXAPI/ViewerController.h>
#import <OsiriXAPI/WaitRendering.h>
#import <Accelerate/Accelerate.h>
#import <Quartz/Quartz.h>

@implementation PLDocumentView

@synthesize fullWidth, isDraggingDestination;
@synthesize topMargin, bottomMargin, sideMargin;
@synthesize pageFormat;
@synthesize currentPageIndex;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        // Initialization code here.
        self.isDraggingDestination  = NO;
        self.fullWidth              = NO;
        self.currentPageIndex       = -1;
        self.pageFormat             = paper_A4;
        
        self.topMargin       = floorf(frame.size.width / 200) + 1;
        self.sideMargin      = roundf(5 * topMargin / 2);
        self.bottomMargin    = 3 * topMargin;

        // Create the PLLayoutView
        NSRect layoutFrame = NSMakeRect(sideMargin, topMargin, frame.size.width - 2 * sideMargin, frame.size.height - bottomMargin);
        [self addSubview:[[[PLLayoutView alloc] initWithFrame:layoutFrame] autorelease]];
        ((PLWindowController*)self.window.windowController).currentPage = 0;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resizePLDocumentView:) name:NSViewFrameDidChangeNotification object:nil];
        [self registerForDraggedTypes:[NSArray arrayWithObjects:pasteBoardOsiriX, nil]];
    }
    
    return self;
}

- (void)drawRect:(NSRect)rect
{
    // Drawing code here.
    NSRect drawingFrame = self.enclosingScrollView.contentView.bounds;
    drawingFrame.origin.x += 1;
    drawingFrame.origin.y += 1;
    drawingFrame.size.height -= 2;
    drawingFrame.size.width -= 2;
    [NSBezierPath bezierPathWithRect:drawingFrame];
    
    if (isDraggingDestination)
    {
        [NSBezierPath setDefaultLineWidth:1.0];
        [[NSColor blueColor] setStroke];
        [[NSColor colorWithCalibratedWhite:0.65 alpha:1] setFill];
        [NSBezierPath strokeRect:drawingFrame];
    }
    else
    {
        [NSBezierPath setDefaultLineWidth:0.0];
        [[NSColor windowFrameColor] setFill];
    }
    
    [NSBezierPath fillRect:drawingFrame];
}

- (BOOL)isFlipped
{
    return YES;
}

#pragma mark-Setters/Getters

- (void)setPageFormat:(paperSize)format
{
    pageFormat = format;
    
    [self resizePLDocumentView:nil];
    [self setNeedsDisplay:YES];
}

#pragma mark-Events management

- (void)scrollWheel:(NSEvent *)theEvent
{
    if (theEvent.deltaY > 3)
        [self pageUp:nil];
    else if (theEvent.deltaY < -3)
        [self pageDown:nil];
}

- (BOOL)handleViewerEvent:(NSEvent*)event
{
    BOOL handled = NO;
    if (event.type == NSKeyDown)
    {
        switch (event.keyCode)
        {
            case NSF5FunctionKey:
            case NSF6FunctionKey:
            case NSF7FunctionKey:
                handled = YES;
                break;
                
            default:
                break;
        }
    }
    
    return handled;
}

- (void)keyDown:(NSEvent *)event
{
    if ([[event characters] length] == 0)
        return;

    NSClipView *clipView = self.enclosingScrollView.contentView;
    unichar key = [event.characters characterAtIndex:0];

    NSArray * windowList = [NSApp windows];
    NSUInteger nbWindows = [windowList count];

    switch (key)
    {
        case NSF1FunctionKey:
            // Insert one image
            for (NSUInteger i = 0; i < nbWindows; ++i)
            {
                // Look for the window that is the ViewerController of the DCMView
                if ([[[[windowList objectAtIndex:i] windowController] className] isEqualToString:@"ViewerController"])
                {
                    // Get the current DCMView
                    DCMView *imageToImport = [(ViewerController*)[[windowList objectAtIndex:i] windowController] imageView];
                    
                    int pageIndex = currentPageIndex;
                    NSUInteger viewIndex;
                    NSUInteger nbPages = self.subviews.count;
                    
                    // If the layout is empty, create a page
                    if (!nbPages || pageIndex < 0)
                    {
                        NSRect layoutFrame = NSMakeRect(sideMargin, topMargin, self.frame.size.width - 2 * sideMargin, self.frame.size.height - bottomMargin);
                        [self addSubview:[[[PLLayoutView alloc] initWithFrame:layoutFrame] autorelease]];
                        pageIndex = 0;
                        viewIndex = 0;
                    }
                    
                    PLLayoutView *currentPageLayout = [self.subviews objectAtIndex:currentPageIndex];
                    NSUInteger nbThumbs = currentPageLayout.subviews.count;
                    
                    if (!nbThumbs)
                    {
                        // Create a 1x1 layout if the current page is still empty
                        if ([currentPageLayout updateLayoutViewWidth:1 height:1])
                        {
                            [self.window.windowController layoutMatrixUpdated];
                            viewIndex = 0;
                        }
                        else
                            return;
                    }
                    else
                    {
                        NSUInteger j;
                        for (j = 0; j < nbThumbs; ++j)
                        {
                            PLThumbnailView *thumb = [[currentPageLayout subviews] objectAtIndex:j];
                            if (thumb.isSelected && !thumb.curDCM)
                            {
                                viewIndex = j;
                                [thumb setIsSelected:NO];
                                break;
                            }
                        }
                        
                        if (j >= nbThumbs)
                        {
                            int insertIndex = [currentPageLayout findNextEmptyViewFrom:0];
                            if (currentPageLayout.filledThumbs == currentPageLayout.subviews.count || insertIndex < 0)
                                return;
                            else
                                viewIndex = insertIndex;
                        }
                    }
                
                    [self insertImage:imageToImport atIndex:imageToImport.curImage toPage:pageIndex inView:viewIndex];
                }
                [(PLWindowController*)self.window.windowController layoutMatrixUpdated];
            }
            break;
            
        case NSF2FunctionKey:
            // Insert whole series
            [self insertSeries:nil];
            [(PLWindowController*)self.window.windowController layoutMatrixUpdated];
            [self setNeedsDisplay:YES];
            break;
            
        case NSF3FunctionKey:
        case NSF5FunctionKey:
            // Insert partial series
            NSLog(@"Insert partial series.");
            [self insertPartial:nil];
            [(PLWindowController*)self.window.windowController layoutMatrixUpdated];
            break;
            
        case NSPageUpFunctionKey:
        case NSUpArrowFunctionKey:
        case NSLeftArrowFunctionKey:
            [self pageUp:nil];
            break;
            
        case NSPageDownFunctionKey:
        case NSDownArrowFunctionKey:
        case NSRightArrowFunctionKey:
            [self pageDown:nil];
            break;
            
        case NSHomeFunctionKey:
            // beginning of document
            [clipView scrollToPoint:NSMakePoint(clipView.bounds.origin.x, 0)];
            break;
            
        case NSEndFunctionKey:
            // end of document
            [clipView scrollToPoint:NSMakePoint(clipView.bounds.origin.x, self.enclosingScrollView.verticalPageScroll * (self.subviews.count - 1))];
            break;
            
        case NSBackspaceCharacter:
        case NSDeleteCharacter:
            for (NSUInteger i = 0; i < self.subviews.count; ++i)
            {
                PLLayoutView *layout = [self.subviews objectAtIndex:i];
                NSUInteger nbSubviews = layout.subviews.count;
                for (NSUInteger j = 0; j < nbSubviews; ++j)
                {
                    PLThumbnailView *thumb = [layout.subviews objectAtIndex:j];
                    if (thumb.isSelected && [thumb curDCM])
                    {
                        [thumb removeFromSuperviewWithoutNeedingDisplay];
                        layout.filledThumbs--;
//                        thumb.isSelected = NO;
                    }
                }
            }
            [self setNeedsDisplay:YES];
            break;
            
        default:
            break;
    }
}

#pragma mark-Page navigation

- (void)pageDown:(id)sender
{
    NSClipView *clipView = self.enclosingScrollView.contentView;
    
    if (self.subviews.count > 1)
    {
        if (clipView.bounds.origin.y < self.enclosingScrollView.verticalPageScroll * (self.subviews.count - 2))
            [clipView scrollToPoint:NSMakePoint(clipView.bounds.origin.x, clipView.bounds.origin.y + self.enclosingScrollView.verticalPageScroll)];
        else if (clipView.bounds.origin.y < self.enclosingScrollView.verticalPageScroll * (self.subviews.count - 1))
            [clipView scrollToPoint:NSMakePoint(clipView.bounds.origin.x, self.enclosingScrollView.verticalPageScroll * (self.subviews.count - 1))];
    }
    
    [self setNeedsDisplay:YES];
}

- (void)pageUp:(id)sender
{
    NSClipView *clipView = self.enclosingScrollView.contentView;
    
    if (clipView.bounds.origin.y >= self.enclosingScrollView.verticalPageScroll)
        [clipView scrollToPoint:NSMakePoint(clipView.bounds.origin.x, clipView.bounds.origin.y - self.enclosingScrollView.verticalPageScroll)];
    else if (clipView.bounds.origin.y > 0)
        [clipView scrollToPoint:NSMakePoint(clipView.bounds.origin.x, 0)];
    
    [self setNeedsDisplay:YES];
}

- (void)goToPage:(NSUInteger)pageNumber
{
    NSClipView *clipView = self.enclosingScrollView.contentView;
    
    [clipView scrollToPoint:NSMakePoint(clipView.bounds.origin.x, self.enclosingScrollView.verticalPageScroll * pageNumber)];
}

#pragma mark-DICOM insertion

- (IBAction)insertImage:(id)sender
{
//    NSPasteboard *pasteboard = [sender representedObject];
//    
//    if (![pasteboard dataForType:pasteBoardOsiriX])
//        NSLog(@"No data in pasteboardOsiriX");
//    
//    [self insertPageAtIndex:currentPageIndex];
//    
//    if (currentPageIndex < 0)
//        currentPageIndex = 0;
//    
//    [[self.subviews objectAtIndex:currentPageIndex] importImage:sender];
}

- (IBAction)insertSeries:(id)sender
{
    NSArray * windowList = [NSApp windows];
    NSUInteger nbWindows = [windowList count];
    
    for (NSUInteger i = 0; i < nbWindows; ++i)
    {
        if ([[[windowList objectAtIndex:i] windowController] class] == [ViewerController class])
        {
            // Get the current DCMView
            DCMView *imageToImport = [(ViewerController*)[[windowList objectAtIndex:i] windowController] imageView];
            NSUInteger nbImgs = imageToImport.dcmPixList.count;
            
            // Create enough pages
            if (![[self.subviews objectAtIndex:currentPageIndex] updateLayoutViewWidth:4 height:6])
                return;
            
            if (nbImgs > 24)
            {
                NSUInteger nbPages = (nbImgs + 1) / 24;
                
                for (NSUInteger j = 1; j <= nbPages; ++j)
                {
                    [self insertPageAtIndex:currentPageIndex + j];
                    if (![[self.subviews objectAtIndex:currentPageIndex + j] updateLayoutViewWidth:4 height:6])
                        return;
                }
            }
            
            // Import images
            NSUInteger startingView = currentPageIndex;
            for (NSUInteger j = 0; j < nbImgs; ++j)
                [self insertImage:imageToImport atIndex:j toPage:startingView + j / 24 inView:j % 24];
        }
    }
}

- (IBAction)insertPartial:(id)sender
{
    NSPasteboard *pasteboard = [sender representedObject];
    
    if (![pasteboard dataForType:pasteBoardOsiriX])
        NSLog(@"No data in pasteboardOsiriX");
    
    [self insertPageAtIndex:currentPageIndex];
    
    if (currentPageIndex < 0)
        currentPageIndex = 0;
    
    [[self.subviews objectAtIndex:currentPageIndex] importPartialSeries:sender];
}

- (void)insertImage:(DCMView*)dcmImage atIndex:(short)imgIndex toPage:(int)pageIndex inView:(NSUInteger)viewIndex
{
    PLLayoutView *page = [self.subviews objectAtIndex:pageIndex];
    PLThumbnailView *thumb = [page.subviews objectAtIndex:viewIndex];
    if (!thumb.curDCM)
        ++page.filledThumbs;
    [thumb fillView:viewIndex withDCMView:dcmImage atIndex:imgIndex];
}

#pragma mark-Drag'n'Drop

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    if (    ([[sender draggingPasteboard] dataForType:pasteBoardOsiriX] || [NSImage canInitWithPasteboard:[sender draggingPasteboard]])
        &&  [sender draggingSourceOperationMask] & NSDragOperationCopy)
    {
        self.isDraggingDestination = YES;
        [self setNeedsDisplay:YES];
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Import DICOM Menu"];
    NSMenuItem *menuItem;
    menuItem = [theMenu insertItemWithTitle:@"Import Current image"     action:@selector(insertImage:)      keyEquivalent:@"" atIndex:0];
    [menuItem setRepresentedObject:[sender draggingPasteboard]];
    menuItem = [theMenu insertItemWithTitle:@"Import Whole series"      action:@selector(insertSeries:)     keyEquivalent:@"" atIndex:1];
    [menuItem setRepresentedObject:[sender draggingPasteboard]];
    menuItem = [theMenu insertItemWithTitle:@"Import Part of series"    action:@selector(insertPartial:)    keyEquivalent:@"" atIndex:2];
    [menuItem setRepresentedObject:[sender draggingPasteboard]];
    
    // Needed to get the location of the context menu
    NSEvent *fakeEvent = [NSEvent mouseEventWithType:NSLeftMouseDown
                                            location:[sender draggingLocation]
                                       modifierFlags:0 timestamp:0
                                        windowNumber:[self.window windowNumber]
                                             context:nil eventNumber:0 clickCount:0 pressure:0];
    
    [NSMenu popUpContextMenu:theMenu withEvent:fakeEvent forView:self];

    // Following does not work: problem with selectors. Maybe compare with what has been done in the XploreWebRC project?
//    NSPoint draglocation = [self convertPoint:[sender draggingLocation] fromView:nil];
//    [theMenu setAutoenablesItems:false];  // Make the items
//    [theMenu popUpMenuPositioningItem:nil atLocation:draglocation inView:self];
    
    [theMenu release];

    return YES;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    self.isDraggingDestination = NO;    
    [self setNeedsDisplay:YES];
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender
{
    self.isDraggingDestination = NO;
    [(PLWindowController*)self.window.windowController layoutMatrixUpdated];
    [self setNeedsDisplay:YES];
    
    return;
}

#pragma mark-Layout management

- (void)resizePLDocumentView:(NSNotification*)notification
{
    if (notification && !([notification.object class] == [PLDocumentView class]))
        return;
    
    NSUInteger nbPages = self.subviews.count;   // One PLLayoutView = one page = one subview
    
    if (nbPages)
    {
        NSRect fullFrame = self.enclosingScrollView.bounds;
        
        // Determine the size of pages in the document
        CGFloat width, height, pageRatio;
        
        pageRatio = getRatioFromPaperFormat(pageFormat);
        
        if (fullFrame.size.width * pageRatio < fullFrame.size.height)
            // The top and bottom margins will be wider, i.e. we want to maximize the pages' width
        {
            width = fullFrame.size.width;
            self.sideMargin = MAX(5, roundf(width / 200));
            
            width -= 2 * sideMargin;
            height = width * pageRatio;
            
            self.topMargin = roundf((fullFrame.size.height - height) / 2);
            self.bottomMargin = topMargin;
            
            height = fullFrame.size.height - topMargin - bottomMargin;
        }
        else
            // The side margins will be wider, i.e. we want to maximize the pages' height
        {
            height = fullFrame.size.height;
            self.topMargin      = MAX(5, roundf(fullFrame.size.width / 100));
            self.bottomMargin   = topMargin;
            
            height -= (topMargin + bottomMargin);
            width = height / pageRatio;
            self.sideMargin = roundf((fullFrame.size.width - width) / 2);
            
            width = fullFrame.size.width - 2 * sideMargin;
        }
        
        // Determine the size of pages (i.e. PLLayoutViews)
        pageHeight  = roundf(height);
        pageWidth   = roundf(width);
        
        [self.enclosingScrollView setVerticalPageScroll:pageHeight + bottomMargin];
        
        NSRect documentFrame = NSMakeRect(fullFrame.origin.x, fullFrame.origin.y, fullFrame.size.width, MAX(fullFrame.size.height, (pageHeight + bottomMargin)*nbPages + topMargin) );
        
        [self setFrame:documentFrame];
        [self.superview setFrame:documentFrame];
        
        for (NSUInteger i = 0; i < nbPages; ++i)
        {
            PLLayoutView *layoutView = [self.subviews objectAtIndex:i];
            NSRect layoutFrame = NSMakeRect(sideMargin, topMargin + i * (pageHeight + bottomMargin), pageWidth, pageHeight);
            [layoutView resizeLayoutView:layoutFrame];
        }
    }
    
    [self.enclosingScrollView display];
}

// Add a new page at the end of the document
- (PLLayoutView*)newPage
{
    PLLayoutView *page = [[[PLLayoutView alloc] initWithFrame:NSZeroRect] autorelease];
    [self addSubview:page];
    [self resizePLDocumentView:nil];
    return page;
}

// Insert a new page in the document at a given index
- (void)insertPageAtIndex:(NSUInteger)index
{
    NSUInteger nbSubviews = self.subviews.count;
    if (index < nbSubviews - 1)
    {
        NSMutableArray *shiftedViews = [[NSMutableArray alloc] initWithCapacity:nbSubviews - index/* + 1*/];
        // Store views that will be shifted
        while (self.subviews.count >/*=*/ index)
        {
            [shiftedViews addObject:[self.subviews lastObject]];
            [[self.subviews lastObject] removeFromSuperviewWithoutNeedingDisplay];
        }

        // Insert view
        [self addSubview:[[[PLLayoutView alloc] initWithFrame:NSZeroRect] autorelease]];
        
        // Put back views
//        while ([shiftedViews count])
//        {
//            [self addSubview:[shiftedViews lastObject]];
//            [shiftedViews removeAllObjects];
//
//        }
        for (NSInteger i = nbSubviews - index - 1; i >= 0; --i)
            [self addSubview:[shiftedViews objectAtIndex:i]];
        
        [shiftedViews release];
        [self resizePLDocumentView:nil];
    }
    else
        [self newPage];
}

- (void)removeCurrentPage
{
    NSUInteger nbPages = self.subviews.count;
    
    if (nbPages)
    {
        if (currentPageIndex < nbPages && currentPageIndex >= 0)
        {
            PLLayoutView *page = [self.subviews objectAtIndex:currentPageIndex];
            NSUInteger nbThumbs = page.subviews.count;
            for (NSUInteger i = 0; i < nbThumbs; ++i)
                [page.subviews.lastObject removeFromSuperviewWithoutNeedingDisplay];
            [page removeFromSuperviewWithoutNeedingDisplay];
            [self resizePLDocumentView:nil];
        }
        else
        {
            NSLog(@"Can't delete page %d (over %d pages)",currentPageIndex, (int)nbPages);
        }
    }
}

- (void)clearDocument
{
    NSUInteger nbPages = self.subviews.count;
    for (NSUInteger i = 0; i < nbPages; ++i)
    {
        PLLayoutView *page = self.subviews.lastObject;
        NSUInteger nbThumbs = page.subviews.count;
        for (NSUInteger i = 0; i < nbThumbs; ++i)
            [page.subviews.lastObject removeFromSuperviewWithoutNeedingDisplay];
        [page removeFromSuperviewWithoutNeedingDisplay];
    }
    [self setNeedsDisplay:YES];
}

// Reshape all the pages of the document
- (void)reshapeDocumentWithWidth:(NSUInteger)width andHeight:(NSUInteger)height
{
    NSUInteger nbPages = self.subviews.count;
    
    if (nbPages)
    {
        NSUInteger nbThumbs = [self getNumberOfFilledViewsInDocument];
        NSMutableArray *allDCMViews = [[NSMutableArray alloc] initWithCapacity:nbThumbs];
        
        // Prepare the pages to be reshaped
        for (NSUInteger i = 0; i < nbPages; ++i)
        {
            PLLayoutView *page = [self.subviews objectAtIndex:i];
            
            // Memorize the filled thumbnails
            NSUInteger filledThumbs = page.filledThumbs;
            for (NSUInteger j = 0; j < filledThumbs; ++j)
            {
                PLThumbnailView *thumb = [page.subviews objectAtIndex:j];
                if (thumb.curDCM)
                    [allDCMViews addObject:thumb];
            }
        }
        
        // Delete all the pages
        [self clearDocument];
        
        // Determine the number of needed pages
        NSUInteger pageSize = width * height;
        NSUInteger newDocumentSize = nbThumbs % pageSize == 0 ? nbThumbs / pageSize : 1 + nbThumbs / pageSize;
        if (!newDocumentSize)
            newDocumentSize = 1;
        
        // Reshape the pages and fill them with the stored DCMViews
        for (NSUInteger i = 0; i < newDocumentSize; ++i)
        {
            PLLayoutView *page = [self newPage];
            [page updateLayoutViewWidth:width height:height];
        }
        
        for (NSUInteger i = 0; i < nbThumbs; ++i)
        {
            NSUInteger pageIndex = i / pageSize;
            PLLayoutView *currentPage = [self.subviews objectAtIndex:pageIndex];
            currentPage.filledThumbs++;
            
            NSUInteger thumbIndex = i % pageSize;
            DCMView *currentDCM = [allDCMViews objectAtIndex:i];
            PLThumbnailView *thumb = [[currentPage subviews] objectAtIndex:thumbIndex];
            [thumb fillView:thumbIndex withDCMView:currentDCM atIndex:currentDCM.curImage];
        }
        
        [allDCMViews release];
        [self resizePLDocumentView:nil];
        [self setNeedsDisplay:YES];
    }
}


#pragma mark-Export methods

- (void)saveDocumentViewToPDF
{
    NSUInteger nbPages = self.subviews.count;
    
    if (!nbPages)
        return;
    
    // Look for pages that have less than 1/3 filled views
    BOOL sparsePage = NO;
    
    for (NSUInteger i = 0; i < nbPages; ++i)
    {
        PLLayoutView *page = [self.subviews objectAtIndex:i];
        
        if (page.filledThumbs && page.filledThumbs <= page.subviews.count / 3)
        {
            sparsePage = YES;
            break;
        }
    }
    
    if (sparsePage)
    {
        NSAlert *confirmDialog = [[[NSAlert alloc] init] autorelease];
        [confirmDialog addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
        [confirmDialog addButtonWithTitle:NSLocalizedString(@"No", nil)];
        [confirmDialog setMessageText:NSLocalizedString(@"Print sparse page?", nil)];
        [confirmDialog setInformativeText:NSLocalizedString(@"At least one page in your layout has few images.\nDo you still want to print it?", nil)];
        [confirmDialog setAlertStyle:NSInformationalAlertStyle];
        
        if ([confirmDialog runModal] == NSAlertSecondButtonReturn)
            return;
    }
    
    // Save panel for pdf files
    NSSavePanel *saveDialog = [NSSavePanel savePanel];

    [saveDialog setNameFieldStringValue:@"report.pdf"];
    if ([saveDialog runModal] == NSFileHandlingPanelCancelButton)
        return;
    
    WaitRendering* waiting = [[[WaitRendering alloc] init:NSLocalizedString(@"Saving File...", nil)] autorelease];
	[waiting showWindow:self];
    
    NSString *filename = [NSString stringWithFormat:@"%@/%@", saveDialog.directory, saveDialog.nameFieldStringValue];
    PDFDocument *layoutPDF = [[[PDFDocument alloc] init] autorelease];
    NSInteger pageNumber = -1;  // Index for PDF document's page
    CGFloat pageRatio = getRatioFromPaperFormat(pageFormat);
    NSRect pageBounds = getPDFPageBoundsFromPaperFormat(pageFormat);    // The bounds in pixels for each page
    
    // Memorize the general preference, and force it to be the local definition
    NSInteger annotations = [[NSUserDefaults standardUserDefaults] integerForKey:@"ANNOTATIONS"];
    [[NSUserDefaults standardUserDefaults] setInteger:[[[(PLWindowController*)self.window.windowController annotationRadioButton] selectedCell] tag] forKey:@"ANNOTATIONS"];
    
    for (NSUInteger i = 0; i < nbPages; ++i)
    @autoreleasepool{
        PLLayoutView *page = [self.subviews objectAtIndex:i];
        
        if (page.filledThumbs)
        @autoreleasepool
        {
            ++pageNumber;
            
            NSUInteger  matrixWidth     = page.layoutMatrixWidth,
                        matrixHeight    = page.layoutMatrixHeight;
            
            // Determine the minimal sizes of the pdfPage
            CGFloat maxWidth        = 0.,
                    maxHeight       = 0.;
            
            for (NSUInteger y = 0; y < matrixHeight; ++y)
            {
                NSUInteger currentLine = y * matrixWidth;
                CGFloat currentLineWidth    = 0.,
                        currentLineHeight   = 0;
                
                for (NSUInteger x = 0; x < matrixWidth; ++x)
                {
                    PLThumbnailView *thumb = [page.subviews objectAtIndex:currentLine + x];
                    CGFloat width, height;
                    
                    width   = [thumb.imageObj.width     floatValue],
                    height  = [thumb.imageObj.height    floatValue];
                    
                    if (currentLineHeight < height)
                        currentLineHeight = height;
                    
                    currentLineWidth += width;
                }
                
                if (maxWidth < currentLineWidth)
                    maxWidth = currentLineWidth;
                
                maxHeight += currentLineHeight;
            }
            
            // Determine the size of the page according to the page format (i.e. its ratio)
            if (maxWidth * pageRatio > maxHeight)
                maxHeight = maxWidth * pageRatio;
            else if (maxWidth * pageRatio < maxHeight)
                maxWidth = maxHeight / pageRatio;
            
            CGFloat newThumbHeight = roundf(maxHeight / matrixHeight);
            CGFloat newThumbWidth = roundf(maxWidth / matrixWidth);
            NSRect newThumbFrame = NSMakeRect(0, 0, newThumbWidth, newThumbHeight);
            NSSize newPageSize = NSMakeSize(roundf(newThumbWidth * matrixWidth), roundf(newThumbHeight * matrixHeight));
            
            // Draw images on page
            NSImage *pageImage = [[[NSImage alloc] initWithSize:newPageSize] autorelease];
            [[NSColor blackColor] setFill];
            
            // Draw black background
            [pageImage lockFocus];
            {
                [NSBezierPath fillRect:NSMakeRect(0, 0, maxWidth, maxHeight)];
            }
            [pageImage unlockFocus];
            
            // CAUTION!! The coordinates are flipped for all the views in the PrintingLayout plugin, not for NSImage
            NSPoint origin = NSZeroPoint;
            for (NSInteger y = matrixHeight - 1; y >= 0 ; --y)
            {
                NSUInteger currentLine = y * matrixWidth;
                
                origin.x = 0.;
                
                for (NSUInteger x = 0; x < matrixWidth; ++x)
                {
                    PLThumbnailView *thumb = [page.subviews objectAtIndex:currentLine + x];
                    
                    // Get size of original image
                    CGFloat width   = [thumb.imageObj.width     floatValue],
                            height  = [thumb.imageObj.height    floatValue];
                    NSRect frame = NSMakeRect(0, 0, width, height);
                    
                    // Get full image and draw it on pageImage
                    NSImage *fullImage = [thumb.imageObj imageAsScreenCapture:frame];
                    NSImage *newThumb = [[[NSImage alloc] initWithSize:NSMakeSize(newThumbWidth, newThumbHeight)] autorelease];
                    
                    // Draw black background on thumbnail
                    [newThumb lockFocus];
                    {
                        [NSBezierPath fillRect:newThumbFrame];
                        [fullImage drawAtPoint:NSMakePoint((newThumbWidth - width)/2, (newThumbHeight - height)/2) fromRect:frame operation:NSCompositeCopy fraction:1.0];
                    }
                    [newThumb unlockFocus];
                    
                    // Draw image in thumbnail
                    [pageImage lockFocus];
                    {
                        [newThumb drawAtPoint:origin fromRect:newThumbFrame operation:NSCompositeCopy fraction:1.0];
                    }
                    [pageImage unlockFocus];
                    
                    // Move x origin
                    origin.x += newThumbWidth;
                }
                
                origin.y += newThumbHeight;
            }
            
            // Put image on PDF page and insert page in PDF document
            PDFPage *layoutPage = [[[PDFPage alloc] initWithImage:pageImage] autorelease];
            [layoutPage setBounds:pageBounds forBox:kPDFDisplayBoxMediaBox];
            [layoutPDF insertPage:layoutPage atIndex:pageNumber];
        }
    }
    
    BOOL error = [layoutPDF writeToFile:filename];
    [waiting close];

    // Put back the original annotation preference
    [[NSUserDefaults standardUserDefaults] setInteger:annotations forKey:@"ANNOTATIONS"];
    
    if (!error)
        NSRunAlertPanel(NSLocalizedString(@"Export Error", nil), NSLocalizedString(@"Your file has not been saved.", nil), NSLocalizedString(@"OK", nil), nil, nil);
    else
    {
        NSString *msg = [NSString stringWithFormat:@"Your file has been saved to\n%@",filename];
        NSRunAlertPanel(NSLocalizedString(@"Export file", nil), NSLocalizedString(msg, nil), NSLocalizedString(@"OK", nil), nil, nil);
    }
}

#pragma mark-Other methods

- (NSUInteger)getNumberOfFilledViewsInDocument
{
    NSUInteger nbThumbs = 0;
    NSUInteger nbPages = self.subviews.count;
    
    for (NSUInteger i = 0; i < nbPages; ++i)
        nbThumbs += ((PLLayoutView*)[self.subviews objectAtIndex:i]).filledThumbs;
    
    return nbThumbs;
}



@end





























