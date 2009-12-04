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

#import "UserDefaults.h"


@implementation UserDefaults

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
	NSData* value = [_dictionary valueForKey:key];
	if (value) {
		NSRect temp;
		[value getBytes:&temp length:sizeof(NSRect)];
		return temp;
	}
	return otherwise;
}

-(void)setRect:(NSRect)value forKey:(NSString*)key {
	NSMutableData* data = [NSMutableData dataWithCapacity:32];
	[data appendBytes:&value length:sizeof(NSRect)];
	[_dictionary setValue:data forKey:key];
	[self save];
}


@end
