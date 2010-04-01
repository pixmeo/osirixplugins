

@class ThreadInfoCell, ThreadsManager;


@interface ThreadsManagerThreadInfo : NSObject {
	ThreadsManager* _manager;
	NSThread* _thread;
	NSString* _status;
	CGFloat _progress;
	CGFloat _progressTotal;
	BOOL _supportsCancel;
//	BOOL _cancelled;
}

@property(retain) ThreadsManager* manager;
@property(retain) NSThread* thread;
@property(retain) NSString* status;
@property CGFloat progress;
@property CGFloat progressTotal;
//@property BOOL cancelled;
@property BOOL supportsCancel;

-(id)initWithThread:(NSThread*)thread manager:(ThreadsManager*)manager;

-(void)setProgress:(CGFloat)progress ofTotal:(CGFloat)total;

@end