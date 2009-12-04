//
//  Notification.h
//  RemoteDistributedNotificationCenter
//
//  Created by Arnaud Garcia on 19.10.05.
//

#import <Cocoa/Cocoa.h>


@interface ObserverWrapper : NSObject<NSCoding> {
	id slaveObserver;
	NSString* softID;
	NSString* aSelectorString;
	NSString* notificationName;
}
-(id)initWithObserver:(id)obs andSelector:(SEL)sel forNotificationName:(NSString*)name withSoftID:(NSString*)aSoftID;
	// slaveObserver
-(id)slaveObserver;
-(void)setSlaveObserver:(id)obs;

//softID
-(NSString*)softID;
-(void)SetSoftID:(NSString*)aSoftID;
	//notificationName
-(NSString*)notificationName;
-(void)setNotificationName:(NSString*)name;

	//Selector
- (SEL)selector;
- (void)setSelector:(SEL)selector;

@end
