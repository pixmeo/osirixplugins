//
//  RemoteDistributedNotificationCenter.h
//  RDNotificationCenter
//
//  Created by Arnaud Garcia on 23.10.05.
//

#import <Cocoa/Cocoa.h>
#import "RDNotificationCenterProtocol.h"
#import "BrowserController.h"

@interface RemoteDistributedNotificationCenter : NSObject {
	//TODO voir si nécessaire de rendre toutes les variables bool en synchronized !
	id proxy;
	BOOL isTransactional;
	BOOL connectionStatus; 
	BOOL stopSendingPQNotif; // set to YES to exit THREAD checkPersitentQueueAndSendTxNotification
	BOOL tryToReconnect; 
	BOOL sendPQstatus;
	NSString* softID; // primary key, use by the server to send the notification
	NSString* pathRDNotifationProperties;
	NSString* fullPathPersitentQueue;
	NSMutableArray* persitentNotificationsQueue;
	NSTimer* reconnectionTimer;
	NSString* serverHost;
	unsigned short serverPort;
	id delegate;
	
}

-(id)initWithTCPPort:(unsigned short)RDNCport host:(NSString*)RDNCHost isTransactional:(BOOL)transaction;

	// ----- standard notifications functions  -----

- (void)addObserver:(id)anObserver selector:(SEL)aSelector name:(NSString *)notificationName;
- (void)removeObserver:(id)anObserver;
- (void)removeObserver:(id)anObserver name:(NSString *)notificationName;


- (void)postNotification:(NSNotification *)notification;
- (void)postNotificationName:(NSString *)notificationName object:(id)anObject;
- (void)postNotificationName:(NSString *)notificationName object:(id)anObject userInfo:(NSDictionary *)userInfo;

	// use this method to identify your software when you want to addObserver with TX notifications ...
- (NSString*)softID;
- (BOOL)isTransactional;

- (void)setDelegate:(id)aDelegate;
// Delegate Method:
// - (void) updateProxyWhenReconnect;

- (void)emptyPersitentQueue;

@end
