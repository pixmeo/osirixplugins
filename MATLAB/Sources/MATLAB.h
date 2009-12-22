//
//  MATLABEngine.h
//  Mindstorming
//
//  Created by Alessandro Volz on 21.12.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <engine.h>

@class DCMPix;

@interface MATLAB : NSObject {
	Engine* _engine;
}

@property(readonly) Engine* engine;

-(id)init;
-(id)initWithPath:(NSString*)path;

+(NSString*)quote:(NSString*)string;

-(void)putMxArray:(mxArray*)mx name:(NSString*)name;
-(void)putDCMPix:(DCMPix*)pix name:(NSString*)name;	
-(mxArray*)getMxArray:(NSString*)name;
-(DCMPix*)getDCMPix:(NSString*)name;
-(void)evalString:(NSString*)string;

@end
