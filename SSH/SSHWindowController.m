//
//  SSHWindowController.m
//  sshPlugin
//
//  Created by Lance Pysher on 7/19/06.
//  Copyright 2006 Macrad, LLC. All rights reserved.
//

#import "SSHWindowController.h"


@implementation SSHWindowController

- (id )init {
	if (self = [super initWithWindowNibName:@"ssh"]) {
		NSArray *array = [[NSUserDefaults standardUserDefaults] arrayForKey:@"sshFilterTaskArray"];
		if (!array)
			array = [NSArray array];
		NSMutableArray *newArray = [NSMutableArray array];
		NSEnumerator *enumerator = [array objectEnumerator];
		id object;
		while (object = [enumerator nextObject])
			[newArray addObject:[NSMutableDictionary dictionaryWithDictionary:object]];
		_content = [newArray retain];
		_running = NO;
		[[NSNotificationCenter defaultCenter] 
				addObserver:self  
				selector:@selector(windowWillClose:) 
				name:NSWindowWillCloseNotification 
				object:[self window]];
				
		[[NSNotificationCenter defaultCenter] 
				addObserver:self  
				selector:@selector(windowWillClose:) 
				name:NSApplicationWillTerminateNotification 
				object:nil];
				
	}
	return self;
}

- (void)dealloc{
	[[NSUserDefaults standardUserDefaults] setObject:[_taskController content] forKey:@"sshFilterTaskArray"];
	[_content release];
	[super dealloc];
}

- (NSArray *)content{
	return _content;
}
- (void)setContent:(NSArray *)content{
	[_content release];
	_content = [content retain];
	[[NSUserDefaults standardUserDefaults] setObject:_content forKey:@"sshFilterTaskArray"];
}

- (void)setTaskController:(NSArrayController *)taskController{
	_taskController = taskController;
}
- (NSArrayController *)taskController{
	return _taskController;
}

- (void)windowWillClose:(NSNotification *)note{
	[[NSUserDefaults standardUserDefaults] setObject:[_taskController content] forKey:@"sshFilterTaskArray"];
}
	
- (IBAction)help:(id)sender{
	[_helpWindow makeKeyAndOrderFront:nil];
}


@end
