//
//  PLDocumentView.m
//  PrintingLayout
//
//  Created by Benoit Deville on 19.11.12.
//
//

#import "PLDocumentView.h"
#import "PLLayoutView.h"

@implementation PLDocumentView

@synthesize fullWidth;
//@synthesize sideMargin;
@synthesize pageFormat;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code here.
        isDraggingDestination   = NO;
        fullWidth               = NO;
        pageFormat              = paper_none;
        
        topMargin       = fullWidth ? 0. : floorf(frame.size.width / 200) + 1;
        sideMargin      = roundf(5 * topMargin / 2);
        bottomMargin    = 3 * topMargin;
        
        // Create the PLLayoutView
        NSRect layoutFrame = NSMakeRect(sideMargin, topMargin, frame.size.width - 2 * sideMargin, frame.size.height - bottomMargin);
        [self addSubview:[[PLLayoutView alloc] initWithFrame:layoutFrame]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resizePLDocumentView) name:NSViewFrameDidChangeNotification object:nil];
    }
    
    return self;
}

//- (void)setFrameSize:(NSSize)newSize
//{
//    marginSize = fullWidth ? 0 : roundf(newSize.width / 80);
//    [super setFrameSize:newSize];
//}
//
//- (void)setFrame:(NSRect)frameRect
//{
//    marginSize = fullWidth ? 0 : roundf(frameRect.size.width / 80);
//    [super setFrame:frameRect];
//}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    if (isDraggingDestination)
    {
        [NSBezierPath setDefaultLineWidth:3.0];
        [[NSColor blueColor] setStroke];
        [[NSColor colorWithCalibratedWhite:0.65 alpha:1] setFill];
    }
    else
    {
        [NSBezierPath setDefaultLineWidth:1.0];
        [[NSColor windowFrameColor] setFill];
    }
    
    [NSBezierPath bezierPathWithRect:self.bounds];
    [NSBezierPath fillRect:self.bounds];
//    [NSBezierPath strokeRect:self.bounds];
}

- (BOOL)isFlipped
{
    return YES;
}

#pragma mark-Setters/Getters

- (void)setPageFormat:(paperSize)format
{
    pageFormat = format;
    NSUInteger nbPages = self.subviews.count;
    for (NSUInteger i = 0; i < nbPages; ++i)
    {
        [(PLLayoutView*)[self.subviews objectAtIndex:i] setLayoutFormat:format];
    }
    
    [self resizePLDocumentView];
    [self setNeedsDisplay:YES];
}

#pragma mark-Size management


- (void)resizePLDocumentView
{
    // One PLLayoutView = one page = one subview
    NSUInteger nbPages = self.subviews.count;
    
    NSRect fullFrame = self.enclosingScrollView.bounds;
    
    // Update the margins' size
    topMargin       = fullWidth ? 0. : floorf( fullFrame.size.width / 200) + 1;
    sideMargin      = roundf(topMargin * 5 / 2);
    bottomMargin    = topMargin * 3;
    
    // Determine the size of pages (i.e. PLLayoutView)
    CGFloat pageWidth   = fullFrame.size.width - 2 * sideMargin;
    CGFloat pageHeight  = pageFormat ? pageWidth * getRatioFromPaperFormat(pageFormat) : roundf((fullFrame.size.width - topMargin)/nbPages) - bottomMargin;
    
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

@end
