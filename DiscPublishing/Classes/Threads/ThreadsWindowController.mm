#import "ThreadsWindowController.h"
#import "ThreadsManager.h"
#import "ThreadsManagerThreadInfo.h"
#import "ThreadInfoCell.h"


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

-(void)setManager:(ThreadsManager*)manager {
	[_manager release];
	_manager = [manager retain];
}

-(void)awakeFromNib {
	[[self.tableView tableColumnWithIdentifier:@"all"] bind:@"value" toObject:self.manager.threadsController withKeyPath:@"arrangedObjects.self" options:NULL];
}

-(NSString*)windowFrameAutosaveName {
	return [NSString stringWithFormat:@"Threads Window Frame: %@", [[self window] title]];
}

-(NSCell*)cellForThreadInfo:(ThreadsManagerThreadInfo*)threadInfo {
	for (ThreadInfoCell* cell in _cells)
		if (cell.threadInfo == threadInfo)
			return cell;
	
	NSCell* cell = [[ThreadInfoCell alloc] initWithInfo:threadInfo view:self.tableView];
	[_cells addObject:cell];
	
	return [cell autorelease];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
	if (obj == self.manager)
		if ([keyPath isEqual:@"threads"]) { // we observe the threads array so we can release cells when they're not needed anymore
			if ([[change objectForKey:NSKeyValueChangeKindKey] unsignedIntValue] == NSKeyValueChangeRemoval)
				for (ThreadsManagerThreadInfo* threadInfo in [change objectForKey:NSKeyValueChangeOldKey])
					[_cells removeObject:[self cellForThreadInfo:threadInfo]];
			return;
		}
	
	[super observeValueForKeyPath:keyPath ofObject:obj change:change context:context];
}

-(NSCell*)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row {
	return [self cellForThreadInfo:[self.manager threadInfoAtIndex:row]];
}

@end
