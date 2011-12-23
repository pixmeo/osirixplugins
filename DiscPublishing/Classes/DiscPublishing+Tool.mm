//
//  DiscPublishing+Toolm.m
//  DiscPublishing
//
//  Created by Alessandro Volz on 6/24/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishing+Tool.h"
#import <Carbon/Carbon.h>
#import <OsiriXAPI/NSAppleEventDescriptor+N2.h>


@implementation DiscPublishing (Tool)

+(NSAppleScript*)toolAS {
	static NSAppleScript* appleScript = NULL;
	
	if (!appleScript) {
		NSString* scptPath = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"DiscPublishingTool.scpt"];
		NSDictionary* errors = [NSDictionary dictionary];
		appleScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scptPath] error:&errors];
		if (!appleScript)
			[NSException raise:NSGenericException format:@"Failed creating NSAppleScript object: %@", [errors objectForKey:NSAppleScriptErrorBriefMessage]];
	}
	
	return appleScript;
}

+(NSString*)PublishDisc:(NSString*)name root:(NSString*)root info:(NSDictionary*)info { // return taskId
	ProcessSerialNumber psn = {0, kCurrentProcess};
	NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
	
	NSAppleEventDescriptor* event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:target returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[@"PublishDisc" lowercaseString]] forKeyword:keyASSubroutineName];
	
	NSAppleEventDescriptor* params = [NSAppleEventDescriptor listDescriptor];
	[params insertDescriptor:[name appleEventDescriptor] atIndex:1];
	[params insertDescriptor:[root appleEventDescriptor] atIndex:2];
	[params insertDescriptor:[info appleEventDescriptor] atIndex:3];
	[event setParamDescriptor:params forKeyword:keyDirectObject];
	
	NSDictionary* errors = [NSDictionary dictionary];
	NSAppleEventDescriptor* result = [[self toolAS] executeAppleEvent:event error:&errors];
	if (!result)
		[NSException raise:NSGenericException format:@"PublishDisc error in %@: %@", [errors objectForKey:NSAppleScriptErrorAppName], [errors objectForKey:NSAppleScriptErrorBriefMessage]];
	
	return [result object];
}

+(NSArray*)ListTasks { // returns all current tasks' taskId
	ProcessSerialNumber psn = {0, kCurrentProcess};
	NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
	
	NSAppleEventDescriptor* event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:target returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[@"ListTasks" lowercaseString]] forKeyword:keyASSubroutineName];
	
	NSDictionary* errors = [NSDictionary dictionary];
	NSAppleEventDescriptor* result = [[self toolAS] executeAppleEvent:event error:&errors];
	if (!result)
		[NSException raise:NSGenericException format:@"ListTasks error in %@: %@", [errors objectForKey:NSAppleScriptErrorAppName], [errors objectForKey:NSAppleScriptErrorBriefMessage]];
	
	return [result object];
}

+(NSDictionary*)GetTaskInfo:(NSString*)taskId {
	ProcessSerialNumber psn = {0, kCurrentProcess};
	NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
	
	NSAppleEventDescriptor* event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:target returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[@"GetTaskInfo" lowercaseString]] forKeyword:keyASSubroutineName];
	
	NSAppleEventDescriptor* params = [NSAppleEventDescriptor listDescriptor];
	[params insertDescriptor:[taskId appleEventDescriptor] atIndex:1];
	[event setParamDescriptor:params forKeyword:keyDirectObject];
	
	NSDictionary* errors = [NSDictionary dictionary];
	NSAppleEventDescriptor* result = [[self toolAS] executeAppleEvent:event error:&errors];
	if (!result)
		[NSException raise:NSGenericException format:@"GetTaskInfo error in %@: %@", [errors objectForKey:NSAppleScriptErrorAppName], [errors objectForKey:NSAppleScriptErrorBriefMessage]];
	
	return [result object];
}

+(void)SetQuitWhenDone:(BOOL)flag {
	ProcessSerialNumber psn = {0, kCurrentProcess};
	NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
	
	NSAppleEventDescriptor* event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:target returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[@"SetQuitWhenDone" lowercaseString]] forKeyword:keyASSubroutineName];
	
	NSAppleEventDescriptor* params = [NSAppleEventDescriptor listDescriptor];
	[params insertDescriptor:[[NSNumber numberWithInt:flag] appleEventDescriptor] atIndex:1];
	[event setParamDescriptor:params forKeyword:keyDirectObject];
	
	NSDictionary* errors = [NSDictionary dictionary];
	NSAppleEventDescriptor* result = [[self toolAS] executeAppleEvent:event error:&errors];
	if (!result)
		[NSException raise:NSGenericException format:@"SetQuitWhenDone error in %@: %@", [errors objectForKey:NSAppleScriptErrorAppName], [errors objectForKey:NSAppleScriptErrorBriefMessage]];
}

+(NSString*)GetStatusXML {
	ProcessSerialNumber psn = {0, kCurrentProcess};
	NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
	
	NSAppleEventDescriptor* event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:target returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[@"GetStatusXML" lowercaseString]] forKeyword:keyASSubroutineName];
	
	NSDictionary* errors = [NSDictionary dictionary];
	NSAppleEventDescriptor* result = [[self toolAS] executeAppleEvent:event error:&errors];
	if (!result)
		[NSException raise:NSGenericException format:@"GetStatusXML error in %@: %@", [errors objectForKey:NSAppleScriptErrorAppName], [errors objectForKey:NSAppleScriptErrorBriefMessage]];
	
	return [result object];
}

+(void)SetBinSelection:(BOOL)enabled leftBinMediaType:(NSUInteger)leftBinMediaType rightBinMediaType:(NSUInteger)rightBinMediaType defaultBin:(NSUInteger)defaultBin {
	NSLog(@"SetBinSelection:%d leftBinMediaType:%lu rightBinMediaType:%lu defaultBin:%lu", enabled, (unsigned long)leftBinMediaType, (unsigned long)rightBinMediaType, (unsigned long)defaultBin);
	
	ProcessSerialNumber psn = {0, kCurrentProcess};
	NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
	
	NSAppleEventDescriptor* event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:target returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[@"SetBinSelection" lowercaseString]] forKeyword:keyASSubroutineName];
	
	NSAppleEventDescriptor* params = [NSAppleEventDescriptor listDescriptor];
	[params insertDescriptor:[[NSNumber numberWithInteger:enabled] appleEventDescriptor] atIndex:1];
	[params insertDescriptor:[[NSNumber numberWithInteger:leftBinMediaType] appleEventDescriptor] atIndex:2];
	[params insertDescriptor:[[NSNumber numberWithInteger:rightBinMediaType] appleEventDescriptor] atIndex:3];
	[params insertDescriptor:[[NSNumber numberWithInteger:defaultBin] appleEventDescriptor] atIndex:4];
	[event setParamDescriptor:params forKeyword:keyDirectObject];
	
	NSDictionary* errors = [NSDictionary dictionary];
	NSAppleEventDescriptor* result = [[self toolAS] executeAppleEvent:event error:&errors];
	if (!result)
		[NSException raise:NSGenericException format:@"SetBinSelection error in %@: %@", [errors objectForKey:NSAppleScriptErrorAppName], [errors objectForKey:NSAppleScriptErrorBriefMessage]];
}

@end
