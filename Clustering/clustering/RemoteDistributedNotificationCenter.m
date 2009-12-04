//
//  RemoteDistributedNotificationCenter.m
//  RDNotificationCenter
//
//  Created by Arnaud Garcia on 23.10.05.
//

static NSTimeInterval lastModificationOfPersistentClientQueue;

#import "RemoteDistributedNotificationCenter.h"

// private methods !
// these methods are in the RDNotificationServer, but the user do not need to call them directly ...
// Transactional notification are transparent for the user, we just need to set the initWithTCPPort ...transaction:YES
// and everything will start automatically !
@interface RemoteDistributedNotificationCenter(PrivateAPI)
- (void)postTxNotification:(NSNotification *)notification;
- (void)postTxNotificationName:(NSString *)notificationName object:(id)anObject;
- (void)postTxNotificationName:(NSString *)notificationName object:(id)anObject userInfo:(NSDictionary *)userInfo;
- (void)sendTxNotification;
- (void)startConnection;
- (void)startConnection:(NSTimer*)theTimer;
- (void)generateSoftID;
- (void)checkPersitentQueueAndSendTxNotification;
- (void)tryToReconnect;
-(void) startConnectionOnMainThread: (id) sender;
@end


@implementation RemoteDistributedNotificationCenter

-(id)initWithTCPPort:(unsigned short)RDNCport host:(NSString*)RDNCHost isTransactional:(BOOL)transaction{
	if ((self = [super init])) {
		NSLog(@"(RemoteDistributedNotificationCenter, initWithTCPPort)");
		
		// var init 
		proxy=nil;
		softID=nil;
		pathRDNotifationProperties=nil;
		persitentNotificationsQueue=nil;
		tryToReconnect=NO;
		connectionStatus=NO;
		isTransactional=transaction;
		serverHost=[[NSString alloc] initWithString:RDNCHost];
		serverPort=RDNCport;
		lastModificationOfPersistentClientQueue = 0;
		pathRDNotifationProperties=[[NSString alloc] initWithString:[[NSBundle bundleForClass:[self class]] pathForResource:@"RDNotification" ofType:@"plist"]];
		//fullPathPersitentQueue=[[NSString alloc] initWithString:[[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/RDNCPersitentNotificationsQueue.db"]];
		fullPathPersitentQueue=[[NSString alloc] initWithString:[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/CLUSTER/RDNCPersitentNotificationsQueue.db"]];
		
		// retrieve or create a softID
		NSDictionary* prop=[NSDictionary dictionaryWithContentsOfFile:pathRDNotifationProperties];
		softID=[[NSString alloc] initWithString:[prop objectForKey:@"softID"]];
		//if ([softID length]<2) // 2 is an arbitrary value ! lower than a real timestamp
			[self generateSoftID]; 
		NSLog(@"(RemoteDistributedNotificationCenter, initWithTCPPort) softID=%@",softID);
		
		// if transactional mode, create a persitent Queue to store the notifications
		if (isTransactional)
		{
			persitentNotificationsQueue=[[NSUnarchiver unarchiveObjectWithFile:fullPathPersitentQueue] retain];
			if (!persitentNotificationsQueue)
			{
				NSLog(@"(RemoteDistributedNotificationCenter,initWithTCPPort), create a persitentNotificationsQueue !");
				persitentNotificationsQueue=[[NSMutableArray alloc] initWithCapacity:5];
			}
			else
			{
				NSLog(@"(RemoteDistributedNotificationCenter,initWithTCPPort), load the current persitentNotificationsQueue size=%d",[persitentNotificationsQueue count]);
			}
		}
		
		// bind the server, proxy creation ...
		[self startConnection];
	}
	return self;
}

-(void)dealloc
{	
	NSLog(@"(RemoteDistributedNotificationCenter, dealloc)");
	//stopSendingPQNotif=YES;
	[persitentNotificationsQueue release];
	//[reconnectionTimer invalidate];
	//[reconnectionTimer release];
	
	
	// ---------------- Invalidate connecion 
	NSArray* all=[NSConnection allConnections];
	NSEnumerator* conEnum=[all objectEnumerator];
	NSConnection* aConnection=nil;
	while(aConnection=[conEnum nextObject])
	{
		NSLog(@"([CLIENT], startConnection) invalidate a Connection ...");
		[[aConnection receivePort] invalidate];
		[aConnection invalidate];
	}
	// ------------------	
	[proxy release];
	[softID release];
	[pathRDNotifationProperties release];
	[fullPathPersitentQueue release];
	[serverHost release];
	[super dealloc];
}

-(void)generateSoftID
{
	NSLog(@"(RemoteDistributedNotificationCenter, generateSoftID) First initialization generateSoftID ...");
	[softID release]; // clean  ...
					  //generate
					  //	NSDate *today = [NSDate date];
					  // save softID
					  //	softID=[[NSString alloc] initWithFormat:@"%f",[today timeIntervalSince1970]];
	NSArray	*addresses = [[NSHost currentHost] addresses];
	NSEnumerator *addressesEnumerator = [addresses objectEnumerator];
	NSString *anAddress, *tempSoftID;
	int maxLength = 0;
	while (anAddress = [addressesEnumerator nextObject])
	{
		NSLog(@"anAddress : %@", anAddress);
		if([anAddress length]>maxLength)
		{
			tempSoftID = [NSString stringWithString:anAddress];
			maxLength = [anAddress length];
		}
	}
	softID = [[NSString alloc] initWithString:tempSoftID];
	//softID = [[NSString alloc] initWithString:@"test"];
	
	NSLog(@"(RemoteDistributedNotificationCenter, generateSoftID), new softID=%@",softID);
	NSMutableDictionary* prop=[NSMutableDictionary dictionary];
	[prop setObject:softID forKey:@"softID"];
	[prop writeToFile:pathRDNotifationProperties atomically:YES];
}

// assume there is no proxy !
- (void)startConnection
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSLog(@"(RemoteDistributedNotificationCenter, startConnection):%d host:%@",serverPort,serverHost);
	NSSocketPort* sendPort=nil;
	NSConnection* connection;
	connectionStatus=NO;
	@try {
		//[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow: 2]];
		sendPort=[[NSSocketPort alloc] initRemoteWithTCPPort:serverPort host:serverHost];
		connection=[NSConnection connectionWithReceivePort:nil sendPort:sendPort];
		[connection enableMultipleThreads];
		[connection setRequestTimeout:120];
		[connection setReplyTimeout:120];
		[sendPort release];
		proxy=[[connection rootProxy] retain];
		[proxy setProtocolForProxy:@protocol(RDNotificationCenter)];
		connectionStatus=YES;
		// check if we are in reconnection mode ..
		if (proxy && tryToReconnect)
		{
			NSLog(@"(RemoteDistributedNotificationCenter,startConnection) invalidate reconnectionTimer ...");
			[reconnectionTimer invalidate];
			[reconnectionTimer release];
			//reconnectionTimer=nil; // TODO nil ?
			tryToReconnect=NO;
			if(delegate) [delegate updateProxyWhenReconnect];
		}
	}
	@catch (NSException *exception) {
		NSLog(@"<<ERROR>> :(RemoteDistributedNotificationCenter,startConnection)");
		connectionStatus=NO;
		// ---------------- Invalidate connecion 
		NSArray* all=[NSConnection allConnections];
		NSEnumerator* conEnum=[all objectEnumerator];
		NSConnection* aConnection=nil;
		while(aConnection=[conEnum nextObject])
		{
			NSLog(@"([CLIENT], startConnection) invalidate a Connection ...");
			[[aConnection receivePort] invalidate];
			[aConnection invalidate];
		}
		// ------------------	
		
		[proxy release];
		//proxy=nil;  
	}
	[pool release];
	
	if ((connectionStatus) && (isTransactional))
		[self sendTxNotification];
}

- (void)startConnection:(NSTimer*)theTimer
{
	NSLog(@"- (void)startConnection:(NSTimer*)theTimer");
	if(softID)
	{
		[self generateSoftID];
	}
	NSLog(@"(RemoteDistributedNotificationCenter, startConnection), current softID=%@", softID);
	[self startConnection];
}

#pragma mark Protocol Implementation
// Adding and removing observers
- (void)addObserver:(id)anObserver selector:(SEL)aSelector name:(NSString *)notificationName
{ 
	NSLog(@"RemoteDistributedNotificationCenter, addObserver, notificationName=%@, softID=%@",notificationName,softID);
	@try {
		[proxy addObserver:anObserver selector:aSelector name:notificationName withSoftID:softID];
	}
	@catch (NSException *exception) {
		NSLog(@"<<ERROR>> :(RemoteDistributedNotificationCenter,addObserver) exception name=%@: exception reason=%@", [exception name], [exception reason]);
		//[self tryToReconnect];
	}
	
}

- (void)removeObserver:(id)anObserver
{
	@try {
		[proxy removeObserverWithSoftID:softID];
	}
	@catch (NSException *exception) {
		NSLog(@"<<ERROR>> :(RemoteDistributedNotificationCenter,anObserver) exception name=%@: exception reason=%@", [exception name], [exception reason]);
		
		//TODO faire un tryToReconnect uniquement en cas de perte de connection !
		// pour les autres erreurs ne rien faire ...
		//[self tryToReconnect];
	}
}

- (void)removeObserver:(id)anObserver name:(NSString *)notificationName
{
	
	@try {
		[proxy removeObserverWithSoftID:softID forNotificationName:notificationName];
	}
	@catch (NSException *exception) {
		NSLog(@"<<ERROR>> :(RemoteDistributedNotificationCenter,removeObserver) exception name=%@: exception reason=%@", [exception name], [exception reason]);
		//[self tryToReconnect];
	}
}

//Posting notifications
- (void)postNotification:(NSNotification *)notification
{
	if (!isTransactional)
	{
		@try {
			[proxy postNotification:notification];
		}
		@catch (NSException *exception) {
			NSLog(@"<<ERROR>> :(RemoteDistributedNotificationCenter,postNotification) exception name=%@: exception reason=%@", [exception name], [exception reason]);
			[self tryToReconnect];
		}
	}
	else
		[self postTxNotification:notification];
}

- (void)postNotificationName:(NSString *)notificationName object:(id)anObject
{
	[self postNotification:[NSNotification notificationWithName:notificationName object:anObject]];
}


- (void)postNotificationName:(NSString *)notificationName object:(id)anObject userInfo:(NSDictionary *)userInfo
{
	[self postNotification:[NSNotification notificationWithName:notificationName object:anObject userInfo:userInfo]];
	
}

-(NSString*)softID
{
	return softID;
}

// BEGIN - Private implementation
- (void)postTxNotification:(NSNotification *)notification
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSLog(@"(RemoteDistributedNotificationCenter,postTxNotification)");
	// add softID to the Tx Notification
	NSMutableDictionary* notifInfo=nil;
	if ([notification userInfo])
		notifInfo=[NSMutableDictionary dictionaryWithDictionary:[notification userInfo]];
	if (!notifInfo)
		notifInfo=[NSMutableDictionary dictionaryWithCapacity:1];
	[notifInfo setObject:softID forKey:@"softID"];
	NSNotification* notificationTx=[NSNotification notificationWithName:[notification name] object:[notification object] userInfo:notifInfo];
	
	// add notificationTx to persitentNotificationsQueue
	@synchronized(persitentNotificationsQueue)
	{
		// TODO store persistent Queue !!
		//[persitentNotificationsQueue addObject:notificationTx];
		NSString* notifTimeStamp = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
		[persitentNotificationsQueue addObject:notifTimeStamp];
			NSLog(@"(RemoteDistributedNotificationCenter,postTxNotification) notificationTx time stamp = %@", notifTimeStamp);
		[NSArchiver archiveRootObject:notificationTx toFile:[[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/CLUSTER/CLIENTQUEUE/"] stringByAppendingString:notifTimeStamp]];
		lastModificationOfPersistentClientQueue = [[NSDate date] timeIntervalSince1970];
		NSLog(@"lastModificationOfPersistentClientQueue = [[NSDate date] timeIntervalSince1970]; : %f", lastModificationOfPersistentClientQueue);
	}
	[self sendTxNotification];
	[pool release];
}

- (void)postTxNotificationName:(NSString *)notificationName object:(id)anObject
{
	[self postTxNotification:[NSNotification notificationWithName:notificationName object:anObject]];
}

- (void)postTxNotificationName:(NSString *)notificationName object:(id)anObject userInfo:(NSDictionary *)userInfo
{
	[self postTxNotification:[NSNotification notificationWithName:notificationName object:anObject userInfo:userInfo]];
}

// END - Category implementation
-(void) startConnectionOnMainThread: (id) sender
{
	NSLog(@"startConnectionOnMainThread ...");
	reconnectionTimer=[[NSTimer scheduledTimerWithTimeInterval:5
														target:self
													  selector:@selector(startConnection:)
													  userInfo:nil
													   repeats:YES] retain];
   	NSLog(@"startConnectionOnMainThread DONE");
}

-(void)tryToReconnect
{
	NSLog(@"(RemoteDistributedNotificationCenter,tryToReconnect) ...");
	if (!tryToReconnect)
	{
		// clear existing proxy and all its connections  ...
		if (proxy)
		{
			// ---------------- Invalidate connection 
			NSArray* all=[NSConnection allConnections];
			NSEnumerator* conEnum=[all objectEnumerator];
			NSConnection* aConnection=nil;
			while(aConnection=[conEnum nextObject])
			{
				NSLog(@"([CLIENT], startConnection) invalidate a Connection ...");
				[[aConnection receivePort] invalidate];
				[aConnection invalidate];
			}
			// ------------------	
			[proxy release];
			proxy=nil;
		}
		tryToReconnect=YES;
		NSLog(@"([CLIENT], startConnection) performSelectorOnMainThread ...");
		[self performSelectorOnMainThread:@selector(startConnectionOnMainThread:) withObject:nil waitUntilDone:YES];
		if([reconnectionTimer isValid])
		{
			NSLog(@"reconnectionTimer is valid");
		}
		else
		{
			NSLog(@"reconnectionTimer is NOT valid");
		}
		NSLog(@"([CLIENT], startConnection) performSelectorOnMainThread DONE");		
	}	
}

-(void)sendTxNotification
{
	if (!sendPQstatus)
	{
		[NSThread detachNewThreadSelector: @selector(checkPersitentQueueAndSendTxNotification)
								 toTarget:self withObject: nil];
	}
}

-(void)checkPersitentQueueAndSendTxNotification
{
	sendPQstatus=YES;
	BOOL connectionError=NO;
	if ([persitentNotificationsQueue count]==0)
	{
		NSLog(@"(RemoteDistributedNotificationCenter,checkPersitentQueueAndSendTxNotification), no notifications, => exit THREAD!");
	} else
	{
		NSTimeInterval tempLastModificationOfPersistentQueue = 0;
		NSLog(@"lastModificationOfPersistentClientQueue : %f", lastModificationOfPersistentClientQueue);
		while(tempLastModificationOfPersistentQueue != lastModificationOfPersistentClientQueue)
		{
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			
			tempLastModificationOfPersistentQueue = lastModificationOfPersistentClientQueue;
			
			NSEnumerator *notifEnumerator =[persitentNotificationsQueue objectEnumerator];
			NSNotification* notif;
			NSString* notifTimeStamp;
			NSNumber* ack=nil;
			while((notifTimeStamp=[notifEnumerator nextObject]) && (!connectionError) && (!stopSendingPQNotif)) //TODO double check if nextObject need to be synchronized ...
			{
				NSAutoreleasePool* pool2 = [[NSAutoreleasePool alloc] init];
				notif = [NSUnarchiver unarchiveObjectWithFile:[[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/CLUSTER/CLIENTQUEUE/"] stringByAppendingString:notifTimeStamp]];
				NSLog(@"(RemoteDistributedNotificationCenter,checkPersitentQueueAndSendTxNotification), notif (unarchived) name = %@", [notif name]);
				@try{
					if (!proxy)
						[self tryToReconnect];
					ack=[proxy postTransactionalNotification:notif];
					NSLog(@"(RemoteDistributedNotificationCenter,checkPersitentQueueAndSendTxNotification), ack =%d ", [ack intValue]);
				}@catch (NSException *exception) {
					NSLog(@"<<ERROR>> :(RemoteDistributedNotificationCenter,checkPersitentQueueAndSendTxNotification) exception name=%@: exception reason=%@", [exception name], [exception reason]);
					connectionError=YES;
					[self tryToReconnect];
				}@finally {
					if ((stopSendingPQNotif) || (connectionError) || (!ack) || [ack intValue]<0) // Notification has not been posted ! save it and play it later ...
					{
						// store notification
						//TODO do not store if there are no more notifications !!
						@synchronized(persitentNotificationsQueue)
						{	
							[NSArchiver archiveRootObject:notif toFile:[[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/CLUSTER/CLIENTQUEUE/"] stringByAppendingString:notifTimeStamp]];
							BOOL res=[NSArchiver archiveRootObject:persitentNotificationsQueue toFile:fullPathPersitentQueue];
							NSLog(@"(RemoteDistributedNotificationCenter,checkPersitentQueueAndSendTxNotification), store notifications !, result=%x",res);
						}
					}
				}
				if ([ack intValue]>0) // success, so remove the notification ...
				{
					@synchronized(persitentNotificationsQueue)
					{	
						[[NSFileManager defaultManager] removeFileAtPath:[[[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/CLUSTER/CLIENTQUEUE/"] stringByAppendingString:notifTimeStamp] handler:nil];
						[persitentNotificationsQueue removeObject:notifTimeStamp];
						//TODO	performance: optimisation possible, ne pas sauvegarder si la notif vient juste d'arriver !
						//					 archiver uniquement si la notif avait été sauvegardée précédement
						BOOL res=[NSArchiver archiveRootObject:persitentNotificationsQueue toFile:fullPathPersitentQueue];
						//lastModificationOfPersistentClientQueue = [[NSDate date] timeIntervalSince1970];
						//NSLog(@"lastModificationOfPersistentClientQueue = [[NSDate date] timeIntervalSince1970]; : %f", lastModificationOfPersistentClientQueue);
						NSLog(@"(RemoteDistributedNotificationCenter,checkPersitentQueueAndSendTxNotification), remove notification, save operation=%x",res);
					}
				}
				else
				{
					NSLog(@"(RemoteDistributedNotificationCenter,checkPersitentQueueAndSendTxNotification), CANNOT remove notification object, no ACK");
				}
				[pool2 release];
			}
			[pool release];
		}
	}
	sendPQstatus=NO;
}

-(BOOL)isTransactional
{
	return isTransactional;
}

-(NSMutableArray*)persitentNotificationsQueue
{
	return persitentNotificationsQueue;
}

#pragma mark -

- (void)setDelegate:(id)aDelegate;
{
	delegate = aDelegate;
}

- (void)emptyPersitentQueue;
{
	// empty the array
	[persitentNotificationsQueue removeAllObjects];
	[[NSFileManager defaultManager] removeFileAtPath:fullPathPersitentQueue handler:nil];
	
	// erase the files on the disk
	NSString *notificationFileName;
	NSString *notificationFilesDirectory = [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/CLUSTER/CLIENTQUEUE/"];
	NSDirectoryEnumerator *notificationFilesDirectoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:notificationFilesDirectory];
	 
	while (notificationFileName = [notificationFilesDirectoryEnumerator nextObject])
	{
		[[NSFileManager defaultManager] removeFileAtPath:[notificationFilesDirectory stringByAppendingPathComponent:notificationFileName] handler:nil];
	}
}

@end
