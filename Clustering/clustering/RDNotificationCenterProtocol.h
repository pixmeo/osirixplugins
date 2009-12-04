// Remote Distributed Notification Center Protocol
// this protocol map all the NSNotification methods 

@protocol RDNotificationCenter

// Adding and removing observers
- (void)addObserver:(id)anObserver selector:(SEL)aSelector name:(NSString *)notificationName withSoftID:(NSString*)aSoftID;
- (void)removeObserverWithSoftID:(NSString*)aSoftID;
- (void)removeObserverWithSoftID:(NSString*)aSoftID forNotificationName:(NSString *)notificationName;

//Posting notifications
- (void)postNotification:(NSNotification *)notification;
- (void)postNotificationName:(NSString *)notificationName object:(id)anObject;
- (void)postNotificationName:(NSString *)notificationName object:(id)anObject userInfo:(NSDictionary *)userInfo;

// extend functions for Persistence and Transaction
- (NSNumber*)postTransactionalNotification:(NSNotification *)notification;
- (NSNumber*)postTransactionalNotificationName:(NSString *)notificationName object:(id)anObject;
- (NSNumber*)postTransactionalNotificationName:(NSString *)notificationName object:(id)anObject userInfo:(NSDictionary *)userInfo;
@end