//
//  DicomTag.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 3/5/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DicomTag.h"


@implementation DicomTag

@synthesize a = _a;
@synthesize b = _b;

+(id)PatientsName {
	return [self tag:0x0010:0x0010];
}

+(id)tag:(UInt16)a :(UInt16)b {
	return [[[self alloc] init:a:b] autorelease];
}

-(id)init:(UInt16)a :(UInt16)b {
	self = [super init];
	[self setA:a];
	[self setB:b];
	return self;
}

-(id)copyWithZone:(NSZone*)zone {
	return [[DicomTag allocWithZone:zone] init:self.a:self.b];
}

-(id)initWithCoder:(NSCoder*)decoder {
	return [self init:[decoder decodeIntForKey:@"a"]:[decoder decodeIntForKey:@"b"]];
}

-(void)encodeWithCoder:(NSCoder*)encoder {
	[encoder encodeInt:self.a forKey:@"a"];
	[encoder encodeInt:self.b forKey:@"b"];
}

-(NSString*)string {
	return [NSString stringWithFormat:@"%04X,%04X", self.a, self.b]; 
}

-(NSUInteger)hash {
	return self.string.hash;
}

@end

