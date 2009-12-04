//
//  RDNotificationServer.m
//  RDNotificationCenter
//
//  Created by Arnaud Garcia on 22.10.05.

static NSTimeInterval lastModificationOfPersistentQueue;

#import "RDNotificationServer.h"

@interface RDNotificationServer(PrivateAPI)
- (void)sendTxNotification;
- (void)startConnection;
	// Tx methods
- (void)sendTxNotification;
- (void)checkPersitentQueueAndSendTxNotification;
	// We try to reconnect ONLY if we abruptly exit the main run loop (startConnection function) 
- (void)tryToReconnect;
- (BOOL)isTransactional;
- (void)setIsTransactional:(BOOL)txStatus;
@end

@implementation RDNotificationServer

-(id)initWithTransactionalContainer
{
	NSLog(@"([SERVER],initWithTransactionalContainer)");
	isTransactional=YES;
	return [self init];
}

-(id)initWithDefaultContainer
{
	isTransactional=NO;
	return [self init];
	
}

-(id)init
{
	if ((self = [super init])) {
		isRunning=NO;
		NSLog(@"([SERVER], init), transactionMode=%d",isTransactional);	
		
		// var init
		tryToReconnect=NO; 
		stopSendingPQNotif=NO; 	
		exitRunLoop = NO;
		notifCenter = nil;
		lastModificationOfPersistentQueue = [[NSDate date] timeIntervalSince1970]; // init
		fullPathPersitentQueue=[[NSString alloc] initWithString:[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/CLUSTER/RDNCServerPersitentNotificationsQueue.db"]];
		fullPathToNotifCenter=[[NSString alloc] initWithString:[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/CLUSTER/RDNCServerNotifcenter.db"]];
		// if transactional mode, load notifications (persitentNotificationsQueue, array) and observers (notifCenter dictionary)
		if (isTransactional)
		{
			NSLog(@"([SERVER],init) TRANSACTION MODE !");
			persitentNotificationsQueue=[[NSUnarchiver unarchiveObjectWithFile:fullPathPersitentQueue] retain];
			if (!persitentNotificationsQueue)
			{
				NSLog(@"([SERVER],init), create a persitentNotificationsQueue !");
				persitentNotificationsQueue=[[NSMutableArray alloc] initWithCapacity:10];
			}
			else
			{
				NSLog(@"([SERVER],init), load the current persitentNotificationsQueue size=%d",[persitentNotificationsQueue count]);
			}
			notifCenter=[[NSUnarchiver unarchiveObjectWithFile:fullPathToNotifCenter] retain];
			sendPQstatus=NO;
		}
		
		// in both cases (transactional and !transactional) mode, create an Observer Center (notif Center dictionary)
		if (!notifCenter)
			notifCenter=[[NSMutableDictionary alloc] initWithCapacity:10];
		
		// launch main thread to listen observers ...
		[NSThread detachNewThreadSelector: @selector(startConnection)
								 toTarget:self withObject: nil];
		if(isTransactional)
		{
			if ([persitentNotificationsQueue count]>0)
			{
				[self sendTxNotification];
			}
		}
	}
	return self;
}

-(void)stopServer
{
	exitRunLoop=YES;		
}

-(void)dealloc
{
	NSLog(@"[SERVER],  dealloc !");
	/*
	 NSArray* all=[NSConnection allConnections];
	 NSEnumerator* conEnum=[all objectEnumerator];
	 NSConnection* aConnection=nil;
	 while(aConnection=[conEnum nextObject])
	 {
		 NSLog(@"([SERVER], startConnection) invalidate a Connection iniside main thread ! ...");
		 [aConnection invalidate];
	 }
	 */
	[fullPathPersitentQueue release];
	[fullPathToNotifCenter release];
	[notifCenter release];
	[persitentNotificationsQueue release];
	[super dealloc];
}

- (void)sendTxNotification
{
	// if we are not sending notification start a new thread ...
	if (!sendPQstatus)
	{
		NSLog(@"([SERVER],sendTxNotification), new Thread !- checkPersitentQueueAndSendTxNotification -");
		[NSThread detachNewThreadSelector: @selector(checkPersitentQueueAndSendTxNotification)
								 toTarget:self withObject: nil];
	}
}

// this method is only use in transactional mode ... by the sendTxNotification method
- (void)checkPersitentQueueAndSendTxNotification
{
	// as usual in a thread create an autorelease pool ...
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];	
	sendPQstatus=YES; // don't forget to say that you are sending notifications ... so sendTxNotification will not create another thread !
					  // are they some notifications to send ? [persitentNotificationsQueue count]
	NSLog(@"([SERVER],checkPersitentQueueAndSendTxNotification),  notifications count=%d",[persitentNotificationsQueue count]);
	
	if ([persitentNotificationsQueue count]==0)
	{
		NSLog(@"([SERVER],checkPersitentQueueAndSendTxNotification), no notifications  exit!");
	} else
	{
		// var init
		NSNumber* ack=nil; // Observer response, if >0 OK else a problem occurs 
		NSNotification* notif;
		NSString* notifTimeStamp;
		ObserverWrapper* obsWrapper;
		//BOOL connectionError=NO;  
		NSMutableArray* observers;
		
		NSEnumerator* notifEnumerator;
		NSEnumerator* observerEnumerator;
		NSMutableArray* observersOK=nil; // each time a notification has been successfully send we add the sofID Observer to this array ...
		BOOL deleteNotif=NO;
		BOOL needToSendTheNotif=YES;
		NSEnumerator* observersOKEnumerator;
		NSString* tempSoftID;
		
		NSTimeInterval tempLastModificationOfPersistentQueue = 0;
		//		int initialPersistentQueueLength = [persitentNotificationsQueue count];
		//		int currentPersistentQueueLength = -1;
		
		//		while((initialPersistentQueueLength!=currentPersistentQueueLength) && ((currentPersistentQueueLength!=1) && (initialPersistentQueueLength!=0)))
		while(tempLastModificationOfPersistentQueue!=lastModificationOfPersistentQueue)
		{
			tempLastModificationOfPersistentQueue=lastModificationOfPersistentQueue;
			//			initialPersistentQueueLength = [persitentNotificationsQueue count];
			notifEnumerator=[persitentNotificationsQueue objectEnumerator];
			//NSLog(@"+++++++++> [Server], while  ......... %d // %d", currentPersistentQueueLength, initialPersistentQueueLength);
			// For each notification whereas we don't want to stop the notification process stopSendingPQNotif
			while((notifTimeStamp=[notifEnumerator nextObject]) && (!stopSendingPQNotif))
			{
				NSAutoreleasePool* pool2 = [[NSAutoreleasePool alloc] init];
				
				notif = [NSUnarchiver unarchiveObjectWithFile:[[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/CLUSTER/SERVERQUEUE/"] stringByAppendingString:notifTimeStamp]];
				NSLog(@"+++++++++> [Server], process notification object");
				//NSLog(@"+++++++++> [Server], process notification object=%@",[notif object]);
				deleteNotif=YES; // if one observer didn't received the notification, deleteNotif=NO
								 // FIND all oberservers that already received the notification, use the dictionary userInfo of the notification which contains softID of successed observers 
				observersOK=[[notif userInfo] objectForKey:@"hasReceived"];
				//FIND all observers for this notification, (use the notifCenter to retrieve them)
				observers=[notifCenter objectForKey:[notif name]];
				
				// for each observer who are listening this kind of notification ...
				observerEnumerator=[observers objectEnumerator];
				while(obsWrapper=[observerEnumerator nextObject])
				{
					NSLog(@"... [Server], process observer softID=%@",[obsWrapper softID]);
					
					// Double check if we have already send it !, if yes the notification dictionary userInfo for key HAVERECEIVED contains its softID
					needToSendTheNotif=YES;
					observersOKEnumerator=[observersOK objectEnumerator];
					while((tempSoftID=[observersOKEnumerator nextObject]) && needToSendTheNotif)
					{
						if ([tempSoftID isEqualToString:[obsWrapper softID]])
							needToSendTheNotif=NO;
					}
					
					// if we never successed while sending the notification to this observer ...
					if (needToSendTheNotif)
					{
						NSLog(@"[SERVER], notification need to be send ...");
						@try{
							ack=[[obsWrapper slaveObserver] performSelector:[obsWrapper selector] withObject:notif];//TODO voir ce qui se passe avec les ack ?? mŽmoire ?
							NSLog(@"anObserver =%@",[obsWrapper slaveObserver]);
							if([ack intValue]>0) //sucess
							{
								@synchronized(persitentNotificationsQueue)
								{	
									// update notification status and save it
									[observersOK addObject:[obsWrapper softID]];
									//BOOL res=[NSArchiver archiveRootObject:persitentNotificationsQueue toFile:fullPathPersitentQueue];
									BOOL res=[NSArchiver archiveRootObject:notif toFile:[[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/CLUSTER/SERVERQUEUE/"] stringByAppendingString:notifTimeStamp]];
									NSLog(@"    write to file res=%x",res);
								}
								//NSLog(@"([SERVER],checkPersitentQueueAndSendTxNotification), success for notification object=%@ to softID=%@",[notif object],[obsWrapper softID]);
								NSLog(@"([SERVER],checkPersitentQueueAndSendTxNotification), success for notification object= to softID=%@",[obsWrapper softID]);
							} else
							{
								// a problem occurs, do not delete the notification, we have to try again next time ..
								//NSLog(@"([SERVER],checkPersitentQueueAndSendTxNotification), PROBLEM for notification object=%@ to softID=%@",[notif object],[obsWrapper softID]);
								NSLog(@"([SERVER],checkPersitentQueueAndSendTxNotification), PROBLEM for notification object= to softID=%@",[obsWrapper softID]);
								deleteNotif=NO;
							}
						}@catch (NSException *exception) {
							NSLog(@"<<ERROR>> :([SERVER],checkPersitentQueueAndSendTxNotification) exception name=%@: exception reason=%@", [exception name], [exception reason]);
							//connectionError=YES;
							deleteNotif=NO;
						}
					}		
				}
				//				currentPersistentQueueLength = [persitentNotificationsQueue count];
				//				NSLog(@"currentPersistentQueueLength=%d, initialPersistentQueueLength=%d", currentPersistentQueueLength, initialPersistentQueueLength);
				
				//2- DELETE NOTIFICATION IF ALL OBSERVERS RECEIVED IT
				if (deleteNotif)
				{
					@synchronized(persitentNotificationsQueue)
					{	
						//NSLog(@"----->[SERVER], checkPersitentQueueAndSendTxNotification: remove notification object=%@",[notif object]);
						NSLog(@"----->[SERVER], checkPersitentQueueAndSendTxNotification: remove notification object=");
						BOOL fileRemoved = [[NSFileManager defaultManager] removeFileAtPath:[[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/CLUSTER/SERVERQUEUE/"] stringByAppendingString:notifTimeStamp] handler:nil];
						if (fileRemoved)
						{
							[persitentNotificationsQueue removeObject:notifTimeStamp];
							BOOL res=[NSArchiver archiveRootObject:persitentNotificationsQueue toFile:fullPathPersitentQueue];
							NSLog(@"    write to file res=%x",res);
						}
						else
						{
							NSLog(@"    [NSFileManager defaultManager] removeFileAtPath FAILED");
						}
						//lastModificationOfPersistentQueue = [[NSDate date] timeIntervalSince1970];
					}
				}
				[pool2 release];
			}
		}
	}
	sendPQstatus=NO; // update the status, we are not sending anymore
	[pool release]; 
}


- (BOOL)isTransactional
{
	return isTransactional;
}

-(void)setIsTransactional:(BOOL)txStatus
{
	isTransactional=txStatus;
}

#pragma mark Protocol Implementation
- (void)addObserver:(id)anObserver selector:(SEL)aSelector name:(NSString *)notificationName withSoftID:(NSString*)aSoftID;
{
	NSLog(@"([SERVER], addObserver:(id)anObserver selector:(SEL)aSelector name:(NSString *)notificationName object:(id)anObject");
	NSLog(@"           for observer=%@",anObserver);
	NSLog(@"           with selector=%@",NSStringFromSelector(aSelector));
	NSLog(@"           for notificationName=%@",notificationName);
	NSLog(@"           with softID=%@",aSoftID);
	
	
	// add a new observer to notifCenter ...
	ObserverWrapper* newObserverWrapper=[[ObserverWrapper alloc] initWithObserver:anObserver 
												 andSelector:aSelector
										 forNotificationName:notificationName 
												  withSoftID:aSoftID];
	
	// I- retrieve or create an entry in the notifCenter for this notification name ..
	NSMutableArray* observersForNotifName=nil;
	observersForNotifName=[notifCenter objectForKey:notificationName];
	if (observersForNotifName) // entry exist
	{
		NSLog(@"[SERVER], observersForNotifName already exist for noticationName=%@ ...",notificationName);
		if(!isTransactional)
			[observersForNotifName addObject:newObserverWrapper];
		else
		{
			// In a transactional mode, the object could have been already added, before a crach so check the sofID
			NSEnumerator* observerEnumerator=[observersForNotifName objectEnumerator];
			ObserverWrapper* anObserverWrapper;
			BOOL alreadyExist=NO;
			while((anObserverWrapper=[observerEnumerator nextObject]) && (!alreadyExist))
			{
				NSLog(@"[SERVER], addObserver: anObserverWrapper=%@, newObserverWrapper=%@", [anObserverWrapper softID], [newObserverWrapper softID]);
				if ([[anObserverWrapper softID] isEqualToString:[newObserverWrapper softID]])
				{
					alreadyExist=YES;
					NSLog(@"[SERVER], addObserver: alreadyExist -> update proxy");
					//update proxy
					[anObserverWrapper setSlaveObserver:[newObserverWrapper slaveObserver]];
				}
			}
			
			if(!alreadyExist)
			{
				NSLog(@"([SERVER],addObserver) add new ObserverWrapper to NotifCenter");
				[observersForNotifName addObject:newObserverWrapper];
			}
			else
			{
				NSLog(@"([SERVER],addObserver) ObserverWrapper already exist");
			}
		}
	}
	else // create an entry
	{
		NSLog(@"[SERVER], observersForNotifName doesn't exist for noticationName=%@, create one entry...",notificationName);
		observersForNotifName=[NSMutableArray arrayWithCapacity:10];
		[observersForNotifName addObject:newObserverWrapper];
		@synchronized(notifCenter)
		{
			[notifCenter setObject:observersForNotifName forKey:notificationName];
		}
	}
	
	[newObserverWrapper release];
	
	// II- In transactional mode store the notifCenter !
	if (isTransactional)
	{
		NSLog(@"([SERVER],addObserver), writeToFile =%@ count=%d", fullPathToNotifCenter,[notifCenter count]);
		@synchronized(notifCenter)
		{
			BOOL res=[NSArchiver archiveRootObject:notifCenter toFile:fullPathToNotifCenter];	
			NSLog(@"([SERVER],addObserver), writeToFile ... res=%d",res);
		}	
		[self sendTxNotification];
	}
}
- (void)removeObserverWithSoftID:(NSString*)aSoftID
{
	NSLog(@"([SERVER],  removeObserverWithSoftID:(NSString*)aSoftID=, %@)",aSoftID);
	
	// var init
	NSMutableArray* observersForNotifName;
	ObserverWrapper* obsWrapper;
	NSEnumerator *enumeratorObs;
	NSString* notificationName;
	
	// find and remove the observer for all notifications it was registered
	
	// for all keys in the dictionary (notifCenter), get all the observers
	NSEnumerator *enumerator = [notifCenter objectEnumerator];
	while ((observersForNotifName = [enumerator nextObject])) {
		
		// for all observers of the key entry
		enumeratorObs = [observersForNotifName objectEnumerator];
		while ((obsWrapper = [enumeratorObs nextObject])) {
			notificationName=[NSString stringWithString:[obsWrapper notificationName]]; // Must be one else no entry are possible in the notifCenter
			if ([aSoftID isEqualToString:[obsWrapper softID]])
			{
				NSLog(@"([SERVER], Remove observer with softID=%@",aSoftID);
				@synchronized(notifCenter)
				{
					[observersForNotifName removeObject:obsWrapper];
					if (isTransactional)
					{
						BOOL res=[NSArchiver archiveRootObject:notifCenter toFile:fullPathToNotifCenter];	
						NSLog(@"([SERVER],removeObserver), remove for notification name=%@,  writeToFile ... res=%d",notificationName,res);
					}
				}
			}
		}
		
		// clean notifcation center if there is no more observers ....
		if ([observersForNotifName count]==0)
		{
			NSLog(@"[SERVER], Remove entry in NotificationCenter for notificationName=%@",notificationName);
			@synchronized(notifCenter)
			{
				[notifCenter removeObjectForKey:notificationName];
				if (isTransactional)
				{
					BOOL res=[NSArchiver archiveRootObject:notifCenter toFile:fullPathToNotifCenter];	
					NSLog(@"([SERVER],removeObserver), writeToFile ... res=%d",res);
				}
			}	
		}
	}
}

- (void)removeObserverWithSoftID:(NSString*)aSoftID forNotificationName:(NSString *)notificationName
{
	NSLog(@"[SERVER], removeObserverWithSoftID:(NSString*)aSoftID forNotificationName:(NSString *)notificationName");
	// retrive all observers for this notification name, find the observer, and remove it ...
	NSMutableArray* observersForNotifName=[notifCenter objectForKey:notificationName];
	if (observersForNotifName)
	{
		ObserverWrapper* obsWrapper;
		NSEnumerator *enumerator = [observersForNotifName objectEnumerator];
		// search in all observers, the observer which will be removed ...
		while ((obsWrapper = [enumerator nextObject])) 
		{
			if ([aSoftID isEqualToString:[obsWrapper softID]])
			{
				NSLog(@"[SERVER], Remove observer with softID=%@ for notificationName=%@",aSoftID,[obsWrapper notificationName]);
				@synchronized(notifCenter)
				{
					[observersForNotifName removeObject:obsWrapper];
					if (isTransactional)
					{
						BOOL res=[NSArchiver archiveRootObject:notifCenter toFile:fullPathToNotifCenter];	
						NSLog(@"	-> writeToFile ... res=%d",res);
					}
				}
			}
		}
		
		// clean notifcation center if there is no more observers ....
		if ([observersForNotifName count]==0)
		{
			NSLog(@"[SERVER], Remove entry in NotificationCenter for notificationName=%@",notificationName);
			@synchronized(notifCenter)
			{
				[notifCenter removeObjectForKey:notificationName];
				if (isTransactional)
				{
					BOOL res=[NSArchiver archiveRootObject:notifCenter toFile:fullPathToNotifCenter];	
					NSLog(@"([SERVER],removeObserver), writeToFile ... res=%d",res);
				}
			}	
		}
	}	
}


//Posting notifications
- (void)postNotification:(NSNotification *)notification
{
	NSLog(@"([SERVER],  postNotification)");
	NSLog(@"    --->notification name=%@",[notification name]);
	// get observers from notification name
	NSMutableArray* observersForNotifName=[notifCenter objectForKey:[notification name]];
	if (observersForNotifName)
	{
		NSLog(@"[SERVER], found some observers for this notification");
		NSEnumerator *enumerator=[observersForNotifName objectEnumerator];
		ObserverWrapper* obsWrapper;
		while ( (obsWrapper = [enumerator nextObject]) ) 
		{
			if(![[[notification userInfo] valueForKey:@"softID"] isEqualToString:[obsWrapper softID]])
			{
				NSLog(@"[SERVER], send notification for observer=%@ for notificationName=%@ to selector=%@",[obsWrapper slaveObserver],[obsWrapper notificationName],NSStringFromSelector([obsWrapper selector]));
				[[obsWrapper slaveObserver] performSelector:[obsWrapper selector] withObject:notification];
			}
			else
			{
				NSLog(@"[SERVER], notification NOT sent for observer=%@ for notificationName=%@ to selector=%@ (same softID!)",[obsWrapper slaveObserver],[obsWrapper notificationName],NSStringFromSelector([obsWrapper selector]));
			}
		}
	} 
	else {
		NSLog(@"[SERVER], No observers for this notification !");
	}
}

- (void)postNotificationName:(NSString *)notificationName object:(id)anObject
{
	NSLog(@"[SERVER], postNotificationName:(NSString *)notificationName object:(id)anObject");
	NSLog(@"    --->notification name=%@",notificationName);
	[self postNotification:[NSNotification notificationWithName:notificationName object:anObject]];
}

- (void)postNotificationName:(NSString *)notificationName object:(id)anObject userInfo:(NSDictionary *)userInfo
{
	NSLog(@"([SERVER], postNotificationName):(NSString *)notificationName object:(id)anObject userInfo:(NSDictionary *)userInfo");
	NSLog(@"    --->notificationname=%@",notificationName);
	[self postNotification:[NSNotification notificationWithName:notificationName object:anObject userInfo:userInfo]];
	
}

- (NSNumber*)postTransactionalNotification:(NSNotification *)notification
{
	NSLog(@"[SERVER],postTransactionalNotification");
	
	// Add a specific field to the notification dictionary to maintain its status (has reveived, not yet) with all the observers ...
	NSMutableDictionary* notifInfo=nil;
	NSMutableArray* observersOK=[NSMutableArray arrayWithCapacity:10];
	if ([notification userInfo])
		notifInfo=[NSMutableDictionary dictionaryWithDictionary:[notification userInfo]];
	if (!notifInfo)
		notifInfo=[NSMutableDictionary dictionaryWithCapacity:1];
	[notifInfo setObject:observersOK forKey:@"hasReceived"];
	NSNotification* notificationTx=[NSNotification notificationWithName:[notification name] object:[notification object] userInfo:notifInfo];
	
	// Add notification to the queue
	BOOL res;
	@synchronized(persitentNotificationsQueue)
	{	
		//[persitentNotificationsQueue addObject:notificationTx];
		NSString* notifTimeStamp = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
		[persitentNotificationsQueue addObject:notifTimeStamp];
		[NSArchiver archiveRootObject:notificationTx toFile:[[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/CLUSTER/SERVERQUEUE/"] stringByAppendingString:notifTimeStamp]];
		NSLog(@"[SERVER], notificationTx class : %@", [[[notificationTx object] objectAtIndex:0] className]);
		NSLog(@"[SERVER],postTransactionalNotification, persitentNotificationsQueue count=%d, notificationTx name=%@",[persitentNotificationsQueue count],[notificationTx name]);
		res=[NSArchiver archiveRootObject:persitentNotificationsQueue toFile:fullPathPersitentQueue];
		NSLog(@"[SERVER], res=[NSArchiver  OK");
		lastModificationOfPersistentQueue = [[NSDate date] timeIntervalSince1970];
	}
	// return code
	if (res)
	{
		[self sendTxNotification];
		return [NSNumber numberWithInt:1];
	}
	else
		return [NSNumber numberWithInt:-1];
}

- (NSNumber*)postTransactionalNotificationName:(NSString *)notificationName object:(id)anObject
{
	return [self postTransactionalNotification:[NSNotification notificationWithName:notificationName object:anObject]];
}

- (NSNumber*)postTransactionalNotificationName:(NSString *)notificationName object:(id)anObject userInfo:(NSDictionary *)userInfo
{
	return [self postTransactionalNotification:[NSNotification notificationWithName:notificationName object:anObject userInfo:userInfo]];
}

-(BOOL)isRunning
{
	return isRunning;
}

-(void)startConnection
{
	while(!exitRunLoop)
	{
		// in a thread, use an NSAutoreleasePool
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		// var init
		unsigned int port=4242;
		NSLog(@"([SERVER], startConnection)");
		NSSocketPort* receivePort=nil;
		NSConnection* connection;
		connectionStatus=NO;
		
		@try
		{
			// create a connection ...
			receivePort=[[NSSocketPort alloc] initWithTCPPort:port];
			connection=[NSConnection connectionWithReceivePort:receivePort sendPort:nil];
			[connection enableMultipleThreads];
			[connection setRequestTimeout:120];
			[connection setReplyTimeout:120];
			[receivePort release];
			[connection setRootObject:self];
			connectionStatus=YES; // don't forget to set the connection Status to YES
			
			// check if we are in reconnection mode 
			if (tryToReconnect)
			{
				NSLog(@"([SERVER], startConnection)");
				tryToReconnect=NO;
			}
			
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow: 1]];
			
			// MAIN run loop
			double resolution = 1.0;
			isRunning=NO;
			exitRunLoop = NO; // don't forget to set the exitRunLoop to NO for now ..., set to YES when you want to force to exit the run loop (stopServer method)
			NSLog(@"([SERVER], startConnection) -BEGIN listening");
			do {
				NSDate* next = [NSDate dateWithTimeIntervalSinceNow:resolution]; 
				isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
													 beforeDate:next];
			} while (isRunning && !exitRunLoop);
			
			
			// We exit the run loop => no more connections are possible, 2 possibilities
			// 1- we force to exit with the exitRunLoop
			// 2- the isRunning is set to NO, ... problem occurs with the port
			
			NSLog(@"([SERVER], startConnection), exitRunLoop=%d, isRunning=%d   (YES=%d, NO=%d) retainCount=%x",exitRunLoop,isRunning,YES,NO,[self retainCount]);
		}
		@catch (NSException *exception) {
			NSLog(@"<<ERROR>> : ([SERVER],startConnection) Unable to get port %d, maybe it is already bind !",port);
		}
		@finally { // the finally block is always use even if there if the program jump in the catch block
			
			// CLEAN EVERYTHING
			// We have to invalidate all the connections, not only the simple connection we create ... it seems that the connection create connections each time
			// an observer register to it
			NSArray* all=[NSConnection allConnections];
			NSEnumerator* conEnum=[all objectEnumerator];
			NSConnection* aConnection=nil;
			while(aConnection=[conEnum nextObject])
			{
				NSLog(@"([SERVER], startConnection) invalidate a Connection ...");
				[[aConnection receivePort] invalidate];
				[aConnection invalidate];
			}
			// NSRunLoop clean
			[[NSRunLoop currentRunLoop] removePort:receivePort forMode:NSConnectionReplyMode];
			[[NSRunLoop currentRunLoop] removePort:receivePort forMode:NSDefaultRunLoopMode];
			CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);  
			connectionStatus=NO;		
		}
		if (!exitRunLoop)
		{
			NSLog(@"[SERVER] --> try to reconnect !");
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow: 10]];
		}	
		
		//
		[pool release]; 
	}
}

#pragma mark -

- (void)emptyPersitentQueue;
{
	// empty the array
	[persitentNotificationsQueue removeAllObjects];
	[[NSFileManager defaultManager] removeFileAtPath:fullPathPersitentQueue handler:nil];
	
	// erase the files on the disk
	NSString *notificationFileName;
	NSString *notificationFilesDirectory = [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/CLUSTER/SERVERQUEUE/"];
	NSDirectoryEnumerator *notificationFilesDirectoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:notificationFilesDirectory];
	 
	while (notificationFileName = [notificationFilesDirectoryEnumerator nextObject])
	{
		[[NSFileManager defaultManager] removeFileAtPath:[notificationFilesDirectory stringByAppendingPathComponent:notificationFileName] handler:nil];
	}
}

- (void)removeConnectionsToNodes;
{
	[notifCenter removeAllObjects];
	[[NSFileManager defaultManager] removeFileAtPath:fullPathToNotifCenter handler:nil];
}

@end
