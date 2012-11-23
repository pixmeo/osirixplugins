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
#import </usr/include/objc/objc-class.h>

#import <OsiriXAPI/StringTexture.h>

@implementation PLThumbnailView

@synthesize isDraggingDestination, isSelected;
@synthesize shrinking;
@synthesize originalFrame;
@synthesize layoutIndex;

- (id)init
{
    self = [super init];
    if (self)
    {
        isDraggingDestination   = NO;
        isGoingToBeSelected     = NO;
        isSelected              = NO;
        shrinking               = none;
        layoutIndex             = -1;
        
        [self setPostsFrameChangedNotifications:NO];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        isDraggingDestination   = NO;
        isGoingToBeSelected     = NO;
        isSelected              = NO;
        shrinking               = none;
        layoutIndex             = -1;
        
        originalFrame           = frame;
        drawingFrameRect        = frame;
        
        [self setPostsFrameChangedNotifications:NO];
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

- (void)fillViewWith:(NSPasteboard*)pasteboard atIndex:(NSInteger)gridIndex
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
            layoutIndex = gridIndex;
        }
    }
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

- (void)clearView
{
    [self setPixels:nil files:nil rois:nil firstImage:0 level:0 reset:YES];
    isSelected = NO;
    [self setNeedsDisplay:YES];
}

- (void)selectView
{
    isSelected = !isSelected;
    isGoingToBeSelected = NO;
    [self setNeedsDisplay:YES];
}


#pragma mark-Events handling
- (void) rightMouseDown:(NSEvent *)event
{
    isGoingToBeSelected = YES;
}

// Action on right mouse button up
- (void) rightMouseUp:(NSEvent *)event
{
    NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
    if (isGoingToBeSelected && NSPointInRect(p, self.bounds))
    {
        if (curDCM)
        {
            NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];
            [theMenu insertItemWithTitle:@"Delete"  action:@selector(clearView)     keyEquivalent:@"" atIndex:0];
            [theMenu insertItemWithTitle:@"Reset"   action:@selector(resetView)     keyEquivalent:@"" atIndex:1];
            [theMenu insertItemWithTitle:@"Rescale" action:@selector(rescaleView)   keyEquivalent:@"" atIndex:2];
            [theMenu insertItemWithTitle:@"Select"  action:@selector(selectView)    keyEquivalent:@"" atIndex:3];
            [NSMenu popUpContextMenu:theMenu withEvent:event forView:self];
        }
        else
            [self selectView];
    }
    [self setNeedsDisplay:YES];
}

// Force the scroll to be handled by the layout view
- (void)scrollWheel:(NSEvent *)event
{
    [[self superview] scrollWheel:event];
}

- (void)mouseDown:(NSEvent *)event
{
    PLLayoutView *parentView = (PLLayoutView *)[self superview];
    
    // Tell the layout view that the current thumbnail is the one dragged
    [parentView setDraggedThumbnailIndex:layoutIndex];
    
    if ([event type] == NSLeftMouseDown && [event clickCount] == 2)
    {
        [super startDrag:nil];
    }
    else
    {
        [super mouseDown:event];
    }
}

@end



















































