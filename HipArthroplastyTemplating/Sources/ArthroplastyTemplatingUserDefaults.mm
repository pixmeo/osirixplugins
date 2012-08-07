/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "ArthroplastyTemplatingUserDefaults.h"


@implementation ArthroplastyTemplatingUserDefaults

-(id)init {
	self = [super init];
	
	_dictionary = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:[[NSBundle bundleForClass:[self class]] bundleIdentifier]] mutableCopy];
	if (!_dictionary)
		_dictionary = [[NSMutableDictionary alloc] init];
	
	return self;
}

-(void)dealloc {
	[_dictionary release]; _dictionary = NULL;
	[super dealloc];
}

-(void)save {
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:_dictionary forName:[[NSBundle bundleForClass:[self class]] bundleIdentifier]];
}

-(BOOL)keyExists:(NSString*)key {
	return [_dictionary valueForKey:key] != NULL;
}

-(BOOL)bool:(NSString*)key otherwise:(BOOL)otherwise {
	NSNumber* value = [_dictionary valueForKey:key];
	if (value)
		return [value boolValue];
	return otherwise;
}

-(void)setBool:(BOOL)value forKey:(NSString*)key {
	[_dictionary setValue:[NSNumber numberWithBool:value] forKey:key];
	[self save];
}

-(int)int:(NSString*)key otherwise:(int)otherwise {
	NSNumber* value = [_dictionary valueForKey:key];
	if (value)
		return [value intValue];
	return otherwise;
}

-(void)setInt:(int)value forKey:(NSString*)key {
	[_dictionary setValue:[NSNumber numberWithInt: value] forKey:key];
	[self save];
}

-(float)float:(NSString*)key otherwise:(float)otherwise {
	NSNumber* value = [_dictionary valueForKey:key];
	if (value)
		return [value floatValue];
	return otherwise;
}

-(void)setFloat:(float)value forKey:(NSString*)key {
	[_dictionary setValue:[NSNumber numberWithFloat:value] forKey:key];
	[self save];
}

-(NSColor*)color:(NSString*)key otherwise:(NSColor*)otherwise {
	NSData* value = [_dictionary valueForKey:key];
	if (value)
		return [NSUnarchiver unarchiveObjectWithData:value];
	return otherwise;
}

-(void)setColor:(NSColor*)value forKey:(NSString*)key {
	[_dictionary setValue:[NSArchiver archivedDataWithRootObject:value] forKey:key];
	[self save];
}

-(NSRect)rect:(NSString*)key otherwise:(NSRect)otherwise {
	return [ArthroplastyTemplatingUserDefaults NSRectFromData:[_dictionary valueForKey:key] otherwise:otherwise];
}

-(void)setRect:(NSRect)value forKey:(NSString*)key {
	NSMutableData* data = [NSMutableData dataWithCapacity:32];
	[data appendBytes:&value length:sizeof(NSRect)];
	[_dictionary setValue:data forKey:key];
	[self save];
}

+(NSRect)NSRectFromData:(NSData*)data otherwise:(NSRect)otherwise {
	if (!data)
		return otherwise;
	
	NSRect temp;
	if ([data length] == sizeof(NSRect))
		[data getBytes:&temp length:sizeof(NSRect)];
	else if ([data length] == 16 && sizeof(NSRect) == 32) {
		float* f = (float*)[data bytes];
		double* d = (double*)&temp;
		for (int i = 0; i < 4; ++i)
			d[i] = f[i];
	} else if ([data length] == 32 && sizeof(NSRect) == 16) {
		double* d = (double*)[data bytes];
		float* f = (float*)&temp;
		for (int i = 0; i < 4; ++i)
			f[i] = d[i];
	} else [NSException raise:NSGenericException format:@"NSRect cannot be extracted from data of size %d", (int)[data length]];
	
	return temp;
}

-(void)setObject:(id)value forKey:(NSString*)key {
	[_dictionary setValue:[NSArchiver archivedDataWithRootObject:value] forKey:key];
	[self save];
}

-(id)object:(NSString*)key otherwise:(id)otherwise {
	NSData* value = [_dictionary valueForKey:key];
	if (value)
		return [NSUnarchiver unarchiveObjectWithData:value];
	return otherwise;	
}


@end
