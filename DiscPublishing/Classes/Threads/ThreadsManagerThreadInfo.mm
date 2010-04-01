#import "ThreadsManagerThreadInfo.h"
#import "ThreadInfoCell.h"


@implementation ThreadsManagerThreadInfo

@synthesize manager = _manager;
@synthesize thread = _thread;
@synthesize status = _status;
@synthesize progress = _progress;
@synthesize progressTotal = _progressTotal;
//@synthesize cancelled = _cancelled;
@synthesize supportsCancel = _supportsCancel;

-(id)initWithThread:(NSThread*)thread manager:(ThreadsManager*)manager {
	self = [super init];
	
	self.thread = thread;
	self.manager = manager;
	
	return self;
}

-(void)dealloc {
	self.status = NULL;
	self.thread = NULL;
	self.manager = NULL;
	[super dealloc];
}

-(void)setStatus:(NSString*)status {
	if ([[NSThread currentThread] isMainThread]) {
		[_status release];
		_status = [status retain];
	} else [self performSelectorOnMainThread:@selector(setStatus:) withObject:status waitUntilDone:NO];
}

-(void)setProgressValues:(NSValue*)values {
	if ([[NSThread currentThread] isMainThread]) {
		NSPoint progress = [values pointValue];
		self.progressTotal = progress.y;
		self.progress = progress.x;
	} else [self performSelectorOnMainThread:@selector(setProgressValues:) withObject:values waitUntilDone:NO];
}

-(void)setSupportsCancel:(BOOL)flag {
	if ([[NSThread currentThread] isMainThread]) {
		_supportsCancel = flag;
	} else [self performSelectorOnMainThread:@selector(setSupportsCancel:) withObject:[NSNumber numberWithBool:flag] waitUntilDone:NO];
}

-(void)setProgress:(CGFloat)progress ofTotal:(CGFloat)total {
	[self setProgressValues:[NSValue valueWithPoint:NSMakePoint(progress, total)]];
}

@end
