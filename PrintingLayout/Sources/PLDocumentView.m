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
#import <OsiriXAPI/ViewerController.h>
#import <Accelerate/Accelerate.h>
#import <Quartz/Quartz.h>

@implementation PLDocumentView

@synthesize fullWidth, isDraggingDestination;
@synthesize topMargin, bottomMargin, sideMargin;
@synthesize pageFormat;
@synthesize scrollingMode;
@synthesize currentPage;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code here.
        self.isDraggingDestination  = NO;
        self.fullWidth              = NO;
        self.currentPage            = -1;
        self.pageFormat             = paper_A4;// [self.window.windowController scrollViewFormat];// 
        self.scrollingMode          = pageByPage;// [self.window.windowController scrollMode];
        
        self.topMargin       = /*fullWidth ? 0. : */floorf(frame.size.width / 200) + 1;
        self.sideMargin      = roundf(5 * topMargin / 2);
        self.bottomMargin    = 3 * topMargin;
//        pageHeight = frame.size.height - topMargin - bottomMargin;
//        pageWidth = frame.size.width - 2 * sideMargin;

        // Create the PLLayoutView
        NSRect layoutFrame = NSMakeRect(sideMargin, topMargin, frame.size.width - 2 * sideMargin, frame.size.height - bottomMargin);
        [self addSubview:[[PLLayoutView alloc] initWithFrame:layoutFrame]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resizePLDocumentView) name:NSViewFrameDidChangeNotification object:nil];
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
    
//    NSUInteger nbPages = self.subviews.count;
//    for (NSUInteger i = 0; i < nbPages; ++i)
//    {
//        [(PLLayoutView*)[self.subviews objectAtIndex:i] setLayoutFormat:format];
//    }
    
    [self resizePLDocumentView];
    [self setNeedsDisplay:YES];
}

#pragma mark-Events management

- (void)scrollWheel:(NSEvent *)theEvent
{
    if (scrollingMode == pageByPage)
    {
        if (theEvent.deltaY > 0)
        {
            [self.enclosingScrollView pageUp:theEvent];
        }
        else if (theEvent.deltaY < 0)
        {
            [self.enclosingScrollView pageDown:theEvent];
        }
    }
    else
    {
        [super scrollWheel:theEvent];
    }
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
        case 60:
            for (NSUInteger i = 0; i < nbWindows; ++i)
            {
                if ([[[[windowList objectAtIndex:i] windowController] className] isEqualToString:@"ViewerController"])
                {
                    DCMView *imageToImport = [(ViewerController*)[[windowList objectAtIndex:i] windowController] imageView];
                    NSLog(@"Current image = %d", imageToImport.curImage);
                    
                    NSUInteger nbPages = self.subviews.count;
                    
                    for (NSUInteger i = 0; i < nbPages; ++i)
                    {
                        NSUInteger nbThumbs = [[[self.subviews objectAtIndex:i] subviews] count];
                        
                        for (NSUInteger j = 0; j < nbThumbs; ++j)
                        {
                            PLThumbnailView *thumb = [[[self.subviews objectAtIndex:i] subviews] objectAtIndex:j];
                            if (thumb.isSelected && !thumb.curDCM)
                            {
                                [thumb fillView:j withDCMView:imageToImport atIndex:imageToImport.curImage] ;
                                return;
                            }
                        }
                    }
                    
                    NSRunAlertPanel(NSLocalizedString(@"Import Error", nil), NSLocalizedString(@"Select an empty view in the layout first.", nil), NSLocalizedString(@"OK", nil), nil, nil);
                }
            }
            break;
            
        case 62:
            NSLog(@"Insert whole serie.");
            break;

        case NSPageUpFunctionKey:
        case NSUpArrowFunctionKey:
        case NSLeftArrowFunctionKey:
            // page up
            if (clipView.bounds.origin.y >= self.enclosingScrollView.verticalPageScroll)
            {
                [clipView scrollToPoint:NSMakePoint(clipView.bounds.origin.x, clipView.bounds.origin.y - self.enclosingScrollView.verticalPageScroll)];
            }
            else if (clipView.bounds.origin.y > 0)
                [clipView scrollToPoint:NSMakePoint(clipView.bounds.origin.x, 0)];            
            break;
            
        case NSPageDownFunctionKey:
        case NSDownArrowFunctionKey:
        case NSRightArrowFunctionKey:
            // page down
            if (clipView.bounds.origin.y < self.enclosingScrollView.verticalPageScroll * (self.subviews.count - 2))
            {
                [clipView scrollToPoint:NSMakePoint(clipView.bounds.origin.x, clipView.bounds.origin.y + self.enclosingScrollView.verticalPageScroll)];
            }
            else if (clipView.bounds.origin.y < self.enclosingScrollView.verticalPageScroll * (self.subviews.count - 1))
            {
                [clipView scrollToPoint:NSMakePoint(clipView.bounds.origin.x, self.enclosingScrollView.verticalPageScroll * (self.subviews.count - 1))];
            }
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
        {
            NSUInteger nbPages = [[self subviews] count];
            for (NSUInteger i = 0; i < nbPages; ++i)
            {
                PLLayoutView *layout = [self.subviews objectAtIndex:i];
                NSUInteger nbSubviews = layout.subviews.count;
                for (NSUInteger j = 0; j < nbSubviews; ++j)
                {
                    PLThumbnailView *thumb = [layout.subviews objectAtIndex:j];
                    if (thumb.isSelected && [thumb curDCM])
                    {
                        [thumb clearView];
                        --(layout.filledThumbs);
                    }
                    thumb.isSelected = NO;
                }
            }
        }
            [self setNeedsDisplay:YES];
            break;
            
        default:
            break;
    }
}

#pragma mark-DICOM insertion

- (IBAction)insertImage:(id)sender
{
    NSPasteboard *pasteboard = [sender representedObject];
    
    if (![pasteboard dataForType:pasteBoardOsiriX])
    {
        NSLog(@"No data in pasteboardOsiriX");
    }
    
    [self insertPageAtIndex:currentPage];
    
    if (currentPage < 0)
    {
        currentPage = 0;
    }
    
    [[self.subviews objectAtIndex:currentPage] importImage:sender];
}

- (IBAction)insertSerie:(id)sender
{
    NSPasteboard *pasteboard = [sender representedObject];
    
    if (![pasteboard dataForType:pasteBoardOsiriX])
    {
        NSLog(@"No data in pasteboardOsiriX");
    }
    
    [self insertPageAtIndex:currentPage];
    
    if (currentPage < 0)
    {
        currentPage = 0;
    }
    
    [[self.subviews objectAtIndex:currentPage] importSerie:sender];
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
    menuItem = [theMenu insertItemWithTitle:@"Import Current image"    action:@selector(insertImage:)   keyEquivalent:@"" atIndex:0];
    [menuItem setRepresentedObject:[sender draggingPasteboard]];
    menuItem = [theMenu insertItemWithTitle:@"Import Whole serie"      action:@selector(insertSerie:)   keyEquivalent:@"" atIndex:1];
    [menuItem setRepresentedObject:[sender draggingPasteboard]];
//    [theMenu insertItemWithTitle:@"Import Bounded serie"    action:@selector(importBounded) keyEquivalent:@"" atIndex:2];
//    [menuItem setRepresentedObject:[sender draggingPasteboard]];
    
    // Needed to get the location of the context menu
    NSEvent *fakeEvent = [NSEvent mouseEventWithType:NSLeftMouseDown
                                            location:[sender draggingLocation]
                                       modifierFlags:0 timestamp:0
                                        windowNumber:[self.window windowNumber]
                                             context:nil eventNumber:0 clickCount:0 pressure:0];
    
    [NSMenu popUpContextMenu:theMenu withEvent:fakeEvent forView:self];

    // Does not work: problem with selectors
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
    [self setNeedsDisplay:YES];
    
    return;
}

#pragma mark-Layout management

- (void)resizePLDocumentView
{
    // One PLLayoutView = one page = one subview
    NSUInteger nbPages = self.subviews.count;
    
    NSRect fullFrame = self.enclosingScrollView.bounds;
    
    // Update the margins' size
    self.topMargin      = scrollingMode == continuous ? 0 : floorf(fullFrame.size.width / 200) + 1;
    self.sideMargin     = roundf(topMargin * 5 / 2);
    self.bottomMargin   = topMargin * 3;
    
    // Determine the size of pages (i.e. PLLayoutViews)
    pageWidth       = fullFrame.size.width - 2 * sideMargin;
    pageHeight      = pageFormat ? pageWidth * getRatioFromPaperFormat(pageFormat) : roundf((fullFrame.size.height - topMargin)/nbPages) - bottomMargin;
    
    [self.enclosingScrollView setVerticalPageScroll:pageHeight + bottomMargin];
    
    NSRect documentFrame = NSMakeRect(fullFrame.origin.x, fullFrame.origin.y, fullFrame.size.width, MAX(fullFrame.size.height, (pageHeight + bottomMargin)*nbPages + topMargin) );
    
    [self setFrame:documentFrame];
    [self.superview setFrame:documentFrame];
//    [self.enclosingScrollView setFrameSize:NSMakeSize(pageWidth + 2 * sideMargin, pageHeight + topMargin + bottomMargin)];
    
    for (NSUInteger i = 0; i < nbPages; ++i)
    {
        PLLayoutView *layoutView = [[self subviews] objectAtIndex:i];
        NSRect layoutFrame = NSMakeRect(sideMargin, topMargin + i * (pageHeight + bottomMargin), pageWidth, pageHeight);
        [layoutView resizeLayoutView:layoutFrame];
    }
    
    [self setNeedsDisplay:YES];
}

- (void)newPage
{
    [self addSubview:[[PLLayoutView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)]];
    [self resizePLDocumentView];
}

- (void)insertPageAtIndex:(NSUInteger)index
{
    NSUInteger nbSubviews = self.subviews.count;
    if (index < nbSubviews - 1)
    {
        NSMutableArray *shiftedViews = [[NSMutableArray alloc] initWithCapacity:nbSubviews - index];
        // Store views that will be shifted
        while (self.subviews.count > index)
        {
//            [[self.subviews lastObject] retain];
            [shiftedViews addObject:[[self.subviews lastObject] retain]];
            [[self.subviews lastObject] removeFromSuperviewWithoutNeedingDisplay];
        }

        // Insert view
        [self addSubview:[[PLLayoutView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)]];
        
        // Put back views
        for (NSInteger i = nbSubviews - index - 1; i >= 0; --i)
        {
            [self addSubview:[shiftedViews objectAtIndex:i]];
        }
        
        [shiftedViews release];
        [self resizePLDocumentView];
    }
    else
    {
        [self newPage];
    }
}

#pragma mark-Export methods

- (void)saveDocumentViewToPDF
{
    NSUInteger nbPages = self.subviews.count;
    
    if (!nbPages)
        return;
    
    PDFDocument *layoutPDF = [[PDFDocument alloc] init];
    
    // Index for PDF layout page
    NSInteger pageNumber = -1;
    
//    CGFloat pageRatio = getRatioFromPaperFormat(pageFormat);
    
    for (NSUInteger i = 0; i < nbPages; ++i)
    {
        PLLayoutView *page = [self.subviews objectAtIndex:i];
        NSUInteger nbThumbs = page.filledThumbs;
        
        if (nbThumbs)
        {
            ++pageNumber;
            
            NSUInteger matrixWidth = page.layoutMatrixWidth;
            NSUInteger matrixHeight = page.layoutMatrixHeight;
            
            // Determine the maximal size for the final image
            CGFloat maxWidth = 0,
                    maxHeight = 0;
            for (NSUInteger j = 0; j < nbThumbs; ++j)
            {
                PLThumbnailView *thumb = [page.subviews objectAtIndex:j];
                
                long width, height, spp, bps;
                [thumb getRawPixelsViewWidth:&width height:&height spp:&spp bpp:&bps
                               screenCapture:NO force8bits:YES removeGraphical:NO squarePixels:YES allowSmartCropping:YES
                                      origin:nil spacing:nil offset:nil isSigned:nil];
                
                if (maxHeight < height)
                    maxHeight = height;
                
                if (maxWidth < width)
                    maxWidth = width;
            }
            
            NSImage *pageImage = [[NSImage alloc] initWithSize:NSMakeSize(maxWidth * matrixWidth, maxHeight * matrixHeight)];
            
            [pageImage lockFocus];
            NSPoint origin = NSMakePoint(0., 0.);
            for (NSUInteger y = 0; y < matrixHeight; ++y)
            {
                NSUInteger currentLine = y * matrixWidth;
                
                origin.x = 0.;
                
                CGFloat currentLineHeight = 0.;

                for (NSUInteger x = 0; x < matrixWidth; ++x)
                {
                    PLThumbnailView *thumb = [page.subviews objectAtIndex:currentLine + x];
                    
                    // 1. Get raw data from PLThumbnailView (aka DCMView)
                    long width, height, spp, bps;
                    unsigned char *data = [thumb getRawPixelsViewWidth:&width height:&height spp:&spp bpp:&bps
                                                         screenCapture:NO force8bits:YES removeGraphical:NO squarePixels:YES allowSmartCropping:YES
                                                                origin:nil spacing:nil offset:nil isSigned:nil];
                    
                    NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
                                                                                     pixelsWide:width
                                                                                     pixelsHigh:height
                                                                                  bitsPerSample:bps
                                                                                samplesPerPixel:spp
                                                                                       hasAlpha:NO
                                                                                       isPlanar:NO
                                                                                 colorSpaceName:spp == 3 ? NSCalibratedRGBColorSpace : NSCalibratedWhiteColorSpace
                                                                                    bytesPerRow:width*bps*spp/8
                                                                                   bitsPerPixel:bps*spp]
                                             autorelease];
                    
                    // Memorize the representation
                    if (data)
                    {
                        memcpy(rep.bitmapData, data, height*width*bps*spp/8);
                        free(data);
                    }

                    // Define the origin for destination image
                    origin.x += width;
                    if (height > currentLineHeight)
                    {
                        currentLineHeight = height;
                    }
                    
                    // 2. Set [NSUserDefaults standardUserDefaults] so that frame in imageAsScreenCapture corresponds to original image size
                    
                    // 3. Get full image
                    NSImage *fullImage = [thumb.imageObj imageAsScreenCapture];
                    
                    // 4. Draw image on page
                    [pageImage drawAtPoint:origin fromRect:NSMakeRect(0, 0, fullImage.size.width, fullImage.size.height) operation:NSCompositeCopy fraction:1.0];
                }
                
                origin.y += currentLineHeight;
            }
            [pageImage unlockFocus];
                
//            unsigned char *fullPageData;
            
            float minPageHeight, minPageWidth;
            minPageHeight = MAXFLOAT;
            minPageWidth = MAXFLOAT;
            
            
            // Stocker les données de chaque thumbnail au format NSImageRepresentation
            NSMutableArray *pageRepresentations = [[NSMutableArray alloc] initWithCapacity:nbThumbs];
            NSMutableArray *pageImages = [[NSMutableArray alloc] initWithCapacity:nbThumbs];
            
            
//            for (NSUInteger y = 0; y < matrixHeight; ++y)
//            {
//                float minLineHeight = MAXFLOAT;
//                NSUInteger currentLine = y * matrixWidth;
//                
//                for (NSUInteger x = 0; x < matrixWidth; ++x)
//                {
//                    PLThumbnailView *thumb = [page.subviews objectAtIndex:currentLine + x];
//                    
//                    // screenCapture = NO : original data only, so we don't get, for instance, annotations, zoom, etc.
//                    // force8Bits = YES : sinon voir comment gérer le cas 16 bits écrasé vers le noir
//                    
//                    // Get raw data from PLThumbnailView (aka DCMView)
//                    unsigned char *data = [thumb getRawPixelsViewWidth:&width height:&height spp:&spp bpp:&bps
//                                                         screenCapture:NO force8bits:YES removeGraphical:NO squarePixels:YES allowSmartCropping:YES
//                                                                origin:nil spacing:nil offset:nil isSigned:nil];
//                    
//                    // Problème avec les images en ndg 16 bits : image écrasée vers le noir
//                    // Allocate the image representation
//                    NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
//                                                                                     pixelsWide:width
//                                                                                     pixelsHigh:height
//                                                                                  bitsPerSample:bps
//                                                                                samplesPerPixel:spp
//                                                                                       hasAlpha:NO
//                                                                                       isPlanar:NO
//                                                                                 colorSpaceName:spp == 3 ? NSCalibratedRGBColorSpace : NSCalibratedWhiteColorSpace
//                                                                                    bytesPerRow:width*bps*spp/8
//                                                                                   bitsPerPixel:bps*spp]
//                                             autorelease];
//
//                    // Determine the minimal height that can have the current line.
//                    if (height < minLineHeight)
//                    {
//                        minLineHeight = height;
//                    }
//                    
//                    // Memorize the representation
//                    if (data)
//                    {
//                        memcpy(rep.bitmapData, data, height*width*bps*spp/8);
//                        [pageRepresentations addObject:rep];
//                        free(data);
//                    }
//                    else
//                    {
//                        [pageRepresentations addObject:rep];
//                    }
//
////                    // Copy the raw data to the image representation
////                        int cpyStart = 0;
////                    cpyStart = (thumbHeight - height) / 2 * thumbWidth * spp * bps / 8;
//
////                        fullPageData = malloc(spp * page.frame.size.height * page.frame.size.width);
////                        NSPoint thumbOrigin = thumb.frame.origin;
////
////                        for (NSUInteger line = 0; line < height; ++line)
////                        {
////                            // TODO debug this
////                            int srcStart = line * width;
////                            int destStart = (roundf(thumbOrigin.x) + page.frame.size.width * roundf(thumbOrigin.y) + line * page.frame.size.width) * spp;
////                            
////                            //                        NSLog(@"line %d : %d %d", line, srcStart, destStart);
////                            
////                            memcpy(&(fullPageData[destStart]), &(rep.bitmapData[srcStart]), width*bps*spp/8);
////                        }
//                    
////                    float thumbRatio = thumb.frame.size.height / thumb.frame.size.width;
////                    // Determine the optimal size of the thumbnail
////                    long thumbWidth, thumbHeight;
////                    if (width * thumbRatio > height)
////                    {
////                        thumbWidth = width;
////                        thumbHeight = thumbWidth * thumbRatio;
////                    }
////                    else
////                    {
////                        thumbHeight = height;
////                        thumbWidth = thumbHeight / thumbRatio;
////                    }
////
////                    if (width < minThumbWidth)
////                    {
////                        minThumbWidth = width;
////                    }
////                    
////                    if (height < minThumbHeight)
////                    {
////                        minThumbHeight = height;
////                    }
//                }
//                
//                long lineWidth = 0;
//                for (NSUInteger x = 0; x < matrixWidth; ++x)
//                {
//                    NSBitmapImageRep *rep = [pageRepresentations objectAtIndex:currentLine + x];
//                    NSSize newSize = NSMakeSize(minLineHeight * rep.pixelsHigh / rep.pixelsWide, minLineHeight);
//                    
//                    if (rep.pixelsHigh != minLineHeight)
//                    {
//                        // resize the rep
//                        NSImage *sourceImage = [[NSImage alloc] init];
//                        [sourceImage addRepresentation:rep];
//                        
//                        // Report an error if the source isn't a valid image
//                        if (![sourceImage isValid])
//                        {
//                            NSLog(@"Invalid Image");
//                        }
//                        else
//                        {
//                            NSImage *smallImage = [[[NSImage alloc] initWithSize:newSize] autorelease];
//                            
//                            [smallImage lockFocus];
//                            
//                            [sourceImage setSize:newSize];
//                            [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
//                            [sourceImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
//                            
//                            [smallImage unlockFocus];
//                            [pageImages addObject:smallImage];
//                            [smallImage release];
//                        }
//                    }
//                    
//                    lineWidth += newSize.width;
//                }
//                
//                if (lineWidth < minPageWidth)
//                {
//                    minPageWidth = lineWidth;
//                }
//            }
//            
////            NSBitmapImageRep *pageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&fullPageData
////                                                                                pixelsWide:page.frame.size.width
////                                                                                pixelsHigh:page.frame.size.height
////                                                                             bitsPerSample:bps
////                                                                           samplesPerPixel:spp
////                                                                                  hasAlpha:NO
////                                                                                  isPlanar:NO
////                                                                            colorSpaceName:NSCalibratedRGBColorSpace
////                                                                               bytesPerRow:page.frame.size.width * spp
////                                                                              bitsPerPixel:spp * bps];
////            [pageImage addRepresentation:pageRep];
////            free(fullPageData);
//            
//            
//            // add all representations as new page
//            NSUInteger nbRep = pageRepresentations.count;
//            
//            for (NSUInteger j = 0; j < nbRep; ++j)
//            {
//                NSImage *currentImage = [[NSImage alloc] init];
//                [currentImage addRepresentation:[pageRepresentations objectAtIndex:j]];
//                PDFPage *layoutPage = [[PDFPage alloc] initWithImage:currentImage];
//                [layoutPDF insertPage:layoutPage atIndex:pageNumber++];
//                [layoutPage release];
//                [currentImage release];
//            }

            PDFPage *layoutPage = [[PDFPage alloc] initWithImage:pageImage];
            [layoutPDF insertPage:layoutPage atIndex:pageNumber];
            
            [layoutPage release];
            [pageRepresentations release];
            [pageImages release];
            [pageImage release];
        }
    }
    
    if (![layoutPDF writeToFile:@"/Users/bd/Pictures/OsiriX/view.pdf"])
    {
        NSLog(@"Error writing pdf file");
    }
    
    [layoutPDF release];
}


@end





























