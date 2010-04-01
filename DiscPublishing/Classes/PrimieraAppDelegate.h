//
//  PrimieraAppDelegate.h
//  Primiera
//
//  Created by Alessandro Volz on 2/5/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DiscPublisher;

@interface PrimieraAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow* _window;
}

@property(assign) IBOutlet NSWindow* window;

-(IBAction)testJobAction:(id)source;
-(IBAction)printOnlyTestJobAction:(id)source;
-(IBAction)statusAction:(id)source;

@end
