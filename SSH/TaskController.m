//
//  TaskController.m
//  sshPlugin
//
//  Created by Lance Pysher on 7/19/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "TaskController.h"


@implementation TaskController

- (void)addObject:(id)object{
	[object setObject:@"USER@www.remotehost.com" forKey:@"destination"];
	[object setObject:@"4096" forKey:@"remoteOutPort"];
	[object setObject:@"5000" forKey:@"localOutPort"];
	[object setObject:@"5000" forKey:@"remoteInPort"];
	[object setObject:@"4096" forKey:@"localInPort"];
	[object setObject:@"127.0.0.1" forKey:@"LANHost"];
	[object setObject:[NSDate date] forKey:@"date"];
	//(@"add object to arranged Objects: %@", [[self arrangedObjects] description]);
	[super addObject:object];
	[_tasks setObject:[[[NSTask alloc] init] autorelease] forKey:[object objectForKey:@"date"]];
}


- (void)setContent:(id)content{
	if (!content)
		content = [NSArray array];
	[super setContent:content];
	[_tasks release];
	_tasks = [[NSMutableDictionary alloc] init];
	NSEnumerator *enumerator = [[self content] objectEnumerator];
	id dict;
	while (dict = [enumerator nextObject]) {
		//NSLog(@"add Task: %@", [dict description]);
		if ([dict objectForKey:@"date"])
			[_tasks setObject:[[[NSTask alloc] init] autorelease] forKey:[dict objectForKey:@"date"]];
	}
	
}

- (IBAction)tunnelAction: (id)sender{
	int tag = [[sender selectedItem] tag];
	SEL selector;
	NSArray *array;
	id key;

	switch (tag) {
		case 0: selector =  NSSelectorFromString(@"openTunnelForKey:");
				array = [self selectedObjects];
				break;
		case 1: selector =  NSSelectorFromString(@"closeTunnelForKey:");
				array = [self selectedObjects];
				break;
		case 2: selector =  NSSelectorFromString(@"openTunnelForKey:");
				array = [self arrangedObjects];
				break;
		case 3: selector =  NSSelectorFromString(@"closeTunnelForKey:");
				array = [self arrangedObjects];
				break;
		case 4: [self openTerminal:[self selectedObjects]];
				return;
	}
	NSEnumerator *enumerator = [array objectEnumerator];
	while (key = [enumerator nextObject])
		[self performSelector:selector withObject:key];
}



- (NSTask *)taskForKey:(id)key{

	return (NSTask *)[_tasks objectForKey:[key objectForKey:@"date"]];
}

- (void)openTunnelForKey:(id)key{
	NSTask *task;
	NSTask *newTask = [[[NSTask alloc] init] autorelease];
	[_tasks setObject:newTask forKey:[key objectForKey:@"date"]];
	task = newTask;


	
	NSString *sshPath = @"/usr/bin/ssh";
	NSString *lValue = [NSString stringWithFormat:@"%@:%@:%@", 
			[key objectForKey:@"localOutPort"], 
			[key objectForKey:@"LANHost"], 
			[key objectForKey:@"remoteOutPort"]];
	NSString *rValue = [NSString stringWithFormat:@"%@:%@:%@", 
			[key objectForKey:@"remoteInPort"], 
			[key objectForKey:@"LANHost"], 
			[key objectForKey:@"localInPort"]];

	NSArray *args = [NSArray arrayWithObjects:@"-T", @"-L", lValue, @"-R", rValue, [key objectForKey:@"destination"], nil];
	//NSLog(@"args: %@", [args description]);
	[task setLaunchPath:sshPath];
	[task setArguments:args];
	//NSLog(@"task %@", [task description]);
	[task launch];
	//if ([task isRunning])
	//	NSLog(@"task running");
		
}
- (void)closeTunnelForKey:(id)key{
	NSTask *task = [self taskForKey:key];
	//NSLog(@"Close Task: %@", [task description]);
	if ([task isRunning]) {
		[task terminate];
		[_tasks setObject:[[[NSTask alloc] init] autorelease] forKey:[key objectForKey:@"date"]];
	}
}

- (void)openTerminal:(NSArray *)selection{
	NSEnumerator *enumerator = [selection objectEnumerator];
	id dict;
	while (dict = [enumerator nextObject]) {
		NSString *lValue = [NSString stringWithFormat:@"%@:%@:%@", 
				[dict objectForKey:@"localOutPort"], 
				[dict objectForKey:@"LANHost"], 
				[dict objectForKey:@"remoteOutPort"]];
		NSString *rValue = [NSString stringWithFormat:@"%@:%@:%@", 
				[dict objectForKey:@"remoteInPort"], 
				[dict objectForKey:@"LANHost"], 
				[dict objectForKey:@"localInPort"]];
		NSString *command = [NSString stringWithFormat:@"ssh -T -L %@ -R %@ %@", lValue, rValue, [dict objectForKey:@"destination"]];
		NSString *script = [NSString stringWithFormat:@"tell Application \"Terminal\" to do script \"%@\"", command];
		NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
		NSDictionary *error;
		[appleScript executeAndReturnError:&error];
		[appleScript release];
	}	
}






@end
