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
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    [NSBezierPath bezierPathWithRect:self.bounds];
    
    if (isDraggingDestination)
    {
        [NSBezierPath setDefaultLineWidth:3.0];
        [[NSColor blueColor] setStroke];
        [[NSColor colorWithCalibratedWhite:0.65 alpha:1] setFill];
        [NSBezierPath strokeRect:self.bounds];
    }
    else
    {
        [NSBezierPath setDefaultLineWidth:0.0];
        [[NSColor windowFrameColor] setFill];
    }
    
    [NSBezierPath fillRect:self.bounds];
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
//    NSLog(@"PLDocumentView caught %c", key);
    
    switch (key)
    {
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
            
            [self setNeedsDisplay:YES];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark-Layout management

- (void)resizePLDocumentView
{
    // One PLLayoutView = one page = one subview
    NSUInteger nbPages = self.subviews.count;
    
    NSRect fullFrame = self.enclosingScrollView.bounds;
    
    // Update the margins' size
//    self.topMargin       = fullWidth ? 0. : floorf(fullFrame.size.width / 200) + 1;
    switch (scrollingMode)
    {
        case pageByPage:
        case pageScroll:
            self.topMargin = floorf(fullFrame.size.width / 200) + 1;
            break;
            
        default:
            self.topMargin = 0;
            break;
    }
    self.sideMargin      = roundf(topMargin * 5 / 2);
    self.bottomMargin    = topMargin * 3;
    
    // Determine the size of pages (i.e. PLLayoutView)
    pageWidth       = fullFrame.size.width - 2 * sideMargin;
    pageHeight      = pageFormat ? pageWidth * getRatioFromPaperFormat(pageFormat) : roundf((fullFrame.size.height - topMargin)/nbPages) - bottomMargin;
    
//    [self.enclosingScrollView setPageScroll:pageHeight];
    [self.enclosingScrollView setVerticalPageScroll:pageHeight + bottomMargin];
    
    NSRect documentFrame = NSMakeRect(fullFrame.origin.x, fullFrame.origin.y, fullFrame.size.width, (pageHeight + bottomMargin)*nbPages + topMargin);
    
    [self setFrame:documentFrame];
    [self.superview setFrame:documentFrame];
    
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

@end





























