//
//  RDNotificationServer.h
//  RDNotificationCenter
//
//  Created by Arnaud Garcia on 22.10.05.

#import <Cocoa/Cocoa.h>
#import "RDNotificationCenterProtocol.h"
#import "ObserverWrapper.h"
#import "BrowserController.h"

// The RDNotificationServer is in charge to listen and dispatch notifications to all the cluster ...
// Two modes: Transactional, Default
// In transactional mode the system guarantie the notification has been received 

@interface RDNotificationServer : NSObject<RDNotificationCenter> {
	NSMutableArray* persitentNotificationsQueue; // it contains the list of all notifications we have received ...
	NSMutableDictionary* notifCenter; // it contains all the observers (ID=softID), and the notificationName they are listening ...
	NSString* fullPathPersitentQueue;
	NSString* fullPathToNotifCenter;
	BOOL connectionStatus; // connection state UP=YES, DOWN=NO
	BOOL exitRunLoop; // use exitRunLoop to force exit the main listening loop
	BOOL stopSendingPQNotif; // force to exit the sending loop checkPersitentQueueAndSendTxNotification
	BOOL tryToReconnect; // Are we always try to reconnect ?
	BOOL isTransactional; // transactional mode
	BOOL sendPQstatus; // we are sending notification  ....
	BOOL isRunning; // status of the runloop
}
// set the container in transactional mode
-(id)initWithTransactionalContainer;
// set the container in default mode, no persistence you can lose notifications ! if a node shutdown ...
-(id)initWithDefaultContainer;
// stop the runloop, use this method before releasing RDNotificationServer
-(void)stopServer;
-(BOOL)isRunning;


- (void)emptyPersitentQueue;
- (void)removeConnectionsToNodes;

@end
