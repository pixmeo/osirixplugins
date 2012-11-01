//
//  PLThumbnailView
//  PrintingLayout
//
//  Created by Benoit Deville on 03.09.12.
//
//

#import "PLThumbnailView.h"
#import "PLLayoutView.h"
#import <OsiriXAPI/DCMPix.h>
#include <OpenGL/CGLMacro.h>
#include <OpenGL/CGLCurrent.h>
#include <OpenGL/CGLContext.h>
#import <OsiriXAPI/GLString.h>

@implementation PLThumbnailView

@synthesize isDraggingDestination, isSelected;
@synthesize shrinking;
@synthesize originalFrame;

- (id)init
{
    self = [super init];
    if (self)
    {
        isDraggingDestination = NO;
        isSelected = NO;
        shrinking = none;
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        isDraggingDestination = NO;
        isSelected = NO;
        shrinking = none;
        originalFrame = frame;
        drawingFrameRect = frame;
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

//- (BOOL)acceptsFirstResponder
//{
//    return NO;
//}

- (BOOL)is2DViewer
{
	return NO;
}

#pragma mark-View's graphic management
//- (void)drawRect:(NSRect)rect
//{
//    [super drawRect:rect];
//
//    // NSImage version, with NSBezierPath
//    if (!image)
//    {
//        [[NSColor blackColor] setFill];
//        [NSBezierPath fillRect:self.bounds];
//    }
//    else
//    {
//        [image drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeCopy fraction:1];
//    }
//
//    if (isDraggingDestination)
//    {
//        [[NSColor blueColor] setStroke];
//        [NSBezierPath setDefaultLineWidth:3.0];
//        [[NSColor colorWithCalibratedWhite:1 alpha:0.5] setFill];
//        [NSBezierPath fillRect:self.bounds];
//    }
//    else
//    {
//        if (isSelected)
//        {
//            [[NSColor orangeColor] setStroke];
//            [NSBezierPath setDefaultLineWidth:3.0];
//        }
//        else
//        {
//            [[NSColor greenColor] setStroke];
//            [NSBezierPath setDefaultLineWidth:1.0];
//        }
//    }
//    [NSBezierPath strokeRect:self.bounds];
//}
//
//- (void)subDrawRect: (NSRect)aRect
//{
//    NSLog(@"subdrawrect");
//    CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
//    float sf = [self.window backingScaleFactor];
//    
//    float width, height;
//    width = self.bounds.size.width/2;
//    height = self.bounds.size.height/2;
//    glBegin(GL_LINE_LOOP);
//    {
//        glVertex2f(self.bounds.size.width - width - 0.5,  height - self.bounds.size.height + 0.5);
//        glVertex2f(-width + 0.5,                          height - self.bounds.size.height + 0.5);
//        glVertex2f(-width + 0.5,                          height - 0.5);
//        glVertex2f(self.bounds.size.width - width - 0.5,  height - 0.5);
//    }
//    glEnd();
//}

- (void)drawRectAnyway:(NSRect)aRect
{
    CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    
    float heighthalf = self.frame.size.height/2 - 0.5;
    float widthhalf = self.frame.size.width/2 - 0.5;
    float sf = [self.window backingScaleFactor];
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glScalef (2.0f /(xFlipped ? -(self.frame.size.width) : self.frame.size.width), -2.0f / (yFlipped ? -(self.frame.size.height) : self.frame.size.height), 1.0f);

    if (isDraggingDestination)
    {
        glEnable(GL_BLEND);
        glColor4f(.5, .5, .5, .5);
        glBegin(GL_QUADS);
        {
            glVertex2f(-widthhalf, -heighthalf);
            glVertex2f(-widthhalf,  heighthalf);
            glVertex2f( widthhalf,  heighthalf);
            glVertex2f( widthhalf, -heighthalf);
        }
        glEnd();
        glDisable(GL_BLEND);
        glColor4f(0., 0., 1., 0.);
        glLineWidth(3 * sf);
    }
    else
    {
        if (isSelected)
        {
            glColor4f(1., .5, 0., 0.);
            glLineWidth(3 * sf);
        }
        else
        {
            glColor4f(0., 1., 0., 0.);
            glLineWidth(1. * sf);
        }
    }
    
    glBegin(GL_LINE_LOOP);
    {
        glVertex2f(-widthhalf, -heighthalf);
        glVertex2f(-widthhalf,  heighthalf);
        glVertex2f( widthhalf,  heighthalf);
        glVertex2f( widthhalf, -heighthalf);
    }
    glEnd();
}

- (void)fillViewWith:(NSPasteboard*)pasteboard
{
    if ([[pasteboard availableTypeFromArray:[NSArray arrayWithObject:pasteBoardOsiriX]] isEqualToString:pasteBoardOsiriX])
    {
        if (![pasteboard dataForType:pasteBoardOsiriX])
        {
            NSLog(@"No data in pasteboardOsiriX");
        }
        else
        {
            DCMView **draggedView = (DCMView**)malloc(sizeof(DCMView*));
            NSData *draggedData = [pasteboard dataForType:pasteBoardOsiriX];
            [draggedData getBytes:draggedView length:sizeof(DCMView*)];
            
            short index = [*draggedView curImage];
            
            NSMutableArray *pixList = [NSMutableArray arrayWithCapacity:1];
            [[[*draggedView dcmPixList] objectAtIndex:index] retain];
            [pixList addObject:[[*draggedView dcmPixList] objectAtIndex:index]];

            NSMutableArray *filesList = [NSMutableArray arrayWithCapacity:1];
            if ([[*draggedView dcmFilesList] count])
            {
                [[[*draggedView dcmFilesList] objectAtIndex:index] retain];
                [filesList addObject:[[*draggedView dcmFilesList] objectAtIndex:index]];
            }
            
            NSMutableArray *roiList = [NSMutableArray arrayWithCapacity:1];
            if ([[*draggedView dcmRoiList] count])
            {
                [[[*draggedView dcmRoiList] objectAtIndex:index] retain];
                [roiList addObject:[[*draggedView dcmRoiList] objectAtIndex:index]];
            }
            
            [self setPixels:pixList
                      files:[[*draggedView dcmFilesList]   count] ? filesList  : nil
                       rois:[[*draggedView dcmRoiList]     count] ? roiList    : nil
                 firstImage:0
                      level:'i'
                      reset:YES];
            free(draggedView);
        }
    }
//    else if ([NSImage canInitWithPasteboard:pasteboard])
//    {
//        [self setImage:[[NSImage alloc] initWithPasteboard:pasteboard]];
//    }
}

- (void)fillViewFrom:(id <NSDraggingInfo>)sender
{
    [self fillViewWith:[sender draggingPasteboard]];
}

- (void)shrinkWidth:(int)marginSize onIts:(shrinkType)side
{
    if ([dcmPixList count] && shrinking == none)
    {
        shrinking = side;

        NSViewAnimation *shrink;
        NSMutableDictionary *viewDict = [NSMutableDictionary dictionaryWithCapacity:3];
        NSRect startFrame, endFrame;
        
        startFrame = originalFrame;
        [viewDict setObject:self forKey:NSViewAnimationTargetKey];
        [viewDict setObject:[NSValue valueWithRect:startFrame] forKey:NSViewAnimationStartFrameKey];
        endFrame = startFrame;
        int size = originalFrame.size.width * marginSize / 100;
        
        endFrame.size.width -= size;
        if (side == left)
        {
            endFrame.origin.x += size;
        }
        
        [viewDict setObject:[NSValue valueWithRect:endFrame] forKey:NSViewAnimationEndFrameKey];
        shrink = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:viewDict]];
        
        [shrink setDuration:0.25];
        [shrink startAnimation];
        [shrink release];
        [self setNeedsDisplay:YES];
    }
}

- (void)backToOriginalSize
{
    if ([dcmPixList count])
    {
        NSViewAnimation *shrink;
        NSMutableDictionary *viewDict = [NSMutableDictionary dictionaryWithCapacity:3];
        NSRect startFrame, endFrame;
        
        startFrame = self.frame;
        [viewDict setObject:self forKey:NSViewAnimationTargetKey];
        [viewDict setObject:[NSValue valueWithRect:startFrame] forKey:NSViewAnimationStartFrameKey];
        endFrame = originalFrame;
        shrinking = none;
        [viewDict setObject:[NSValue valueWithRect:endFrame] forKey:NSViewAnimationEndFrameKey];
        shrink = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:viewDict]];
        
        [shrink setDuration:0.25];
        [shrink startAnimation];
        [shrink release];
        [self setNeedsDisplay:YES];
    }
}

@end



















































