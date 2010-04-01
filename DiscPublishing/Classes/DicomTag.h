//
//  DicomTag.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 3/5/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DicomTag : NSObject <NSCopying, NSCoding> {
	UInt16 _a, _b;
}

@property UInt16 a;
@property UInt16 b;

+(id)PatientsName;

+(id)tag:(UInt16)a :(UInt16)b;
-(id)init:(UInt16)a :(UInt16)b;

-(NSString*)string;

@end

