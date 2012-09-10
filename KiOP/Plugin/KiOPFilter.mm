//
//  KiOPFilter.m
//  KiOP
//
//  Copyright (c) 2012 KiOP. All rights reserved.
//

#import "KiOPFilter.h"
#import <OsiriXAPI/N2Connection.h>
#import <OsiriXAPI/N2ConnectionListener.h>
#import <OsiriXAPI/NSString+N2.h>
#import <OsiriXAPI/N2Debug.h>
#import <OsiriXAPI/N2Shell.h>



//@implementation KiOPFilter
//
//- (void) initPlugin
//{
//}
//
//- (long) filterImage:(NSString*) menuName
//{
//	ViewerController	*new2DViewer;
//	
//	// In this plugin, we will simply duplicate the current 2D window!
//	
//	new2DViewer = [self duplicateCurrent2DViewerWindow];
//	
//	if( new2DViewer) return 0; // No Errors
//	else return -1;
//}
//
//@end


@interface MyConn : N2Connection{
    
    NSPoint origin;
}

@end

@implementation MyConn


-(id)initWithAddress:(NSString *)address port:(NSInteger)port is:(NSInputStream *)is os:(NSOutputStream *)os {
    if ((self = [super initWithAddress:address port:port is:is os:os])) {
        NSLog(@"Client connected");
    }
    
    return self;
}

-(void)handleCommand:(NSString*)cmd{
    ViewerController* v = [ViewerController frontMostDisplayed2DViewer];
    
    //  [v setScaleValue:[v scaleValue]*1.2]; // Zoom
    // [v setImageIndex:[v imageIndex]+1]; // scroll
    
    
    //  - (void)setWL:(float)wl  WW:(float)ww; //window/level
    //  - (void)setOrigin:(NSPoint) o; //move
    //  - (void) setImageIndex:(long) i
    NSLog(@"%@ \n",cmd);
    
    if ([cmd hasPrefix:@"zoom"]){
        int value = 0;
        NSRange r = [cmd rangeOfString:@"-i"];
        if (r.location != NSNotFound){
            value = [[cmd substringWithRange:NSMakeRange(r.location+3, [cmd length] - r.location-3)] intValue];
            NSLog(@"i: %d",value);
            [v setScaleValue:[v scaleValue]*(1+((float)value/30.0))];
            NSLog(@"%f",(1-(((float)value/10))));
        }
        else{
            NSRange r2 = [cmd rangeOfString:@"-d"];
            if (r2.location != NSNotFound){
                value = [[cmd substringWithRange:NSMakeRange(r2.location+3, [cmd length] - r2.location-3)] intValue];
                NSLog(@"d: %d",value);
                [v setScaleValue:[v scaleValue]*(1-((float)value/30.0))];
                NSLog(@"%f",(1-((float)value/10)));
            }
        }
        
    }
    
    if ([cmd hasPrefix:@"wl"]){
        
        NSRange r = [cmd rangeOfString:@"--"];
        
        if (r.location != NSNotFound){
            
            NSString *values = [cmd substringWithRange:NSMakeRange(r.location+3, [cmd length] - r.location-3)];
            NSLog(@"values: [%@]",values); // values = X_Y
            NSArray *tokens = [values componentsSeparatedByString: @" "]; //seperate X , Y
            
            float valueX = [(NSString*)[tokens objectAtIndex:0] floatValue];
            float valueY = [(NSString*)[tokens objectAtIndex:1] floatValue];
            
            NSLog(@"valueX: [%f]",valueX);
            NSLog(@"valueY: [%f]",valueY);
            
            [v setWL:([v curWL]+valueX) WW:([v curWW]+valueY)];
            //NSLog(@"i: %d",value);
            //            NSLog(@"%f",(1-(((float)value/10))));
        }
        else{
            NSLog(@"No values for \"wl\"");
        }
        
    }
    
    if ([cmd hasPrefix:@"move"]){
        
        NSRange r = [cmd rangeOfString:@"--"];
        
        if (r.location != NSNotFound){
            
            NSString *values = [cmd substringWithRange:NSMakeRange(r.location+3, [cmd length] - r.location-3)];
            NSLog(@"values: [%@]",values); // values = X_Y
            NSArray *tokens = [values componentsSeparatedByString: @" "]; //seperate X , Y
            
            float valueX = [(NSString*)[tokens objectAtIndex:0] floatValue];
            float valueY = [(NSString*)[tokens objectAtIndex:1] floatValue];
            
            NSLog(@"valueX: [%f]",valueX);
            NSLog(@"valueY: [%f]",valueY);
            
            origin.x = origin.x + valueX;
            origin.y = origin.y + valueY;
            //            NSPoint pt;
            //            pt.x = valueX;
            //            pt.y = valueY;
            [v setOrigin:origin];
        }
        else{
            NSLog(@"No values for \"move\"");
        }
        
    }
    
    
    // [v setImageIndex:[v imageIndex]+1]; //scroll
    if ([cmd hasPrefix:@"scroll"]){
        int value = 0;
        NSRange r = [cmd rangeOfString:@"-i"];
        if (r.location != NSNotFound){
            value = [[cmd substringWithRange:NSMakeRange(r.location+3, [cmd length] - r.location-3)] intValue];
            NSLog(@"i: %d",value);
            [v setImageIndex:[v imageIndex]+value];
        }
        else{
            NSRange r2 = [cmd rangeOfString:@"-d"];
            if (r2.location != NSNotFound){
                value = [[cmd substringWithRange:NSMakeRange(r2.location+3, [cmd length] - r2.location-3)] intValue];
                NSLog(@"d: %d",value);
                [v setImageIndex:[v imageIndex]-value];
            }
            
        }
        
    }
    
}

-(void)handleLine:(NSString*)line {
    
    NSLog(@"line: %@", line);
    
    NSRange r = [line rangeOfCharacterFromSet:[NSCharacterSet punctuationCharacterSet]];
    //if (r.location == NSNotFound)
    //    break;
    
    NSString* cmd = [line substringToIndex:r.location];
    NSArray *tokens = [line componentsSeparatedByString: @":"];
    NSLog(@"%d",(int)[tokens count]);
    for (int i = 0; i<[tokens count]; i++) {
        
        [self handleCommand:[tokens objectAtIndex:i]];
    }
    
    if (cmd.length){
        @try {
            NSLog(@"viewer: %@", cmd);
        } @catch (NSException* e) {
            NSLog(@"%@", e);
        }
    }
    
    
}

-(void)handleData:(NSMutableData*)data {
    while (data.length) {
        NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
        @try {
            NSString* str = [[[NSString alloc] initWithBytesNoCopy:(void*)data.bytes length:data.length encoding:NSUTF8StringEncoding freeWhenDone:NO] autorelease];
            
            NSRange r = [str rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]];
            if (r.location == NSNotFound)
                break;
            
            NSString* line = [str substringToIndex:r.location];
            [data replaceBytesInRange:NSMakeRange(0, r.location+r.length) withBytes:nil length:0];
            
            if (line.length)
                @try {
                    [self handleLine:line];
                } @catch (NSException* e) {
                    NSLog(@"%@", e);
                }
        } @catch (NSException* e) {
            NSLog(@"%@", e);
            break;
        } @finally {
            [pool release];
        }
    }
}



@end



@implementation KiOPFilter

- (void) initPlugin
{    
    origin.x = 0.0;
    origin.y = 0.0;
    N2ConnectionListener* cl = [[N2ConnectionListener alloc] initWithPort:17179 connectionClass:[MyConn class]];
    
    [N2Shell execute:@"/usr/bin/open" arguments:[NSArray arrayWithObjects: @"-a", [[NSBundle bundleForClass:[self class]] pathForAuxiliaryExecutable:@"KiOP.app"], nil]];
    
    
    /*ViewerController	*new2DViewer;
     
     // In this plugin, we will simply duplicate the current 2D window!
     
     new2DViewer = [self duplicateCurrent2DViewerWindow];
     
     NSAlert *myAlert = [NSAlert alertWithMessageText:@"KinectOP"
     defaultButton:@"launched"
     alternateButton:nil
     otherButton:nil
     informativeTextWithFormat:@"Plugin launched"];
     [myAlert runModal];*/
}



- (long) filterImage:(NSString*) menuName
{
	//ViewerController	*new2DViewer;
	
	// In this plugin, we will simply duplicate the current 2D window!
	
	//new2DViewer = [self duplicateCurrent2DViewerWindow];
	
    /*NSAlert *myAlert = [NSAlert alertWithMessageText:@"KinectOP"
     defaultButton:@"launched"
     alternateButton:nil
     otherButton:nil
     informativeTextWithFormat:@"Plugin launched"];
     [myAlert runModal];*/
	//if( new2DViewer) return 0; // No Errors
	//else return -1;
    
    
    
    
    // pour lancer un binaire externe:
    // NSTask // N2Task
    
    
    
    //    
    //    MyConn* conn = [[MyConn alloc] initWithAddress:@"localhost" port:17179];
    //    [conn reconnect];
    
    
    
    return 0;
}

@end
