#import "ThreadsWindowController.h"
#import "ThreadsManager.h"
#import "ThreadCell.h"


@implementation ThreadsWindowController

@synthesize manager = _manager;
@synthesize tableView = _tableView;
@synthesize statusLabel = _statusLabel;

+(ThreadsWindowController*)defaultController {
	static ThreadsWindowController* defaultController = [[self alloc] initWithManager:[ThreadsManager defaultManager]];
	return defaultController;
}

-(id)initWithManager:(ThreadsManager*)manager {
    self = [super initWithWindowNibName:@"ThreadsWindow"];
	
	_cells = [[NSMutableArray alloc] init];

	_manager = [manager retain];
	// we observe the threads array so we can release cells when they're not needed anymore
	[self.manager addObserver:self forKeyPath:@"threads" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionInitial context:NULL];
	
    return self;
}

-(void)dealloc {
	[self.manager removeObserver:self forKeyPath:@"threads"];
    [_manager release];
	[_cells release];
    [super dealloc];
}

-(void)awakeFromNib {
	[[self.tableView tableColumnWithIdentifier:@"all"] bind:@"value" toObject:self.manager.threadsController withKeyPath:@"arrangedObjects" options:NULL];
//	[self.window setLevel:NSNormalWindowLevel];
}

-(NSString*)windowFrameAutosaveName {
	return [NSString stringWithFormat:@"Threads Window Frame: %@", [[self window] title]];
}

-(NSCell*)cellForThread:(NSThread*)thread {
	for (ThreadCell* cell in _cells)
		if (cell.thread == thread)
			return cell;
	
	NSCell* cell = [[ThreadCell alloc] initWithThread:thread manager:self.manager view:self.tableView];
	[_cells addObject:cell];
	
	return [cell autorelease];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
	if (obj == self.manager)
		if ([keyPath isEqual:@"threads"]) { // we observe the threads array so we can release cells when they're not needed anymore
			if ([[change objectForKey:NSKeyValueChangeKindKey] unsignedIntValue] == NSKeyValueChangeRemoval)
				for (NSThread* thread in [change objectForKey:NSKeyValueChangeOldKey])
					[_cells removeObject:[self cellForThread:thread]];
			return;
		}
	
	[super observeValueForKeyPath:keyPath ofObject:obj change:change context:context];
}

-(NSCell*)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row {
	return [self cellForThread:[self.manager threadAtIndex:row]];
}

@end


@implementation ThreadsTableView

-(void)selectRowIndexes:(NSIndexSet*)indexes byExtendingSelection:(BOOL)extend {
}

-(void)mouseDown:(NSEvent*)evt {
}

@end
