/* ClusteringController */

#import <Cocoa/Cocoa.h>
#import "RemoteDistributedNotificationCenter.h"
#import "RDNotificationServer.h"

@interface ClusteringController : NSWindowController
{
	// first tab
    IBOutlet NSTabView *clusterTab;
	IBOutlet NSTableView *clustersTabView;
	IBOutlet NSButton *joinButton;
	
	//second tab
	IBOutlet NSForm *createForm;
	IBOutlet NSTabView *createTabView;
	
	IBOutlet NSTextField *ipTextField;
	IBOutlet NSProgressIndicator *progressConnection;
	IBOutlet NSButton *activateButton;
	
	//third tab
	IBOutlet NSBox *serverToolsBox;
	
	NSMutableArray* clusterDS; 
	//NSTask *wget;
	//NSString* ftpServer; //for wget strategy
	
	//RDNC
	RDNotificationServer* RDNCServer;
	RemoteDistributedNotificationCenter* remoteDistributedNC;
	
	NSTimer* timerServerStatus;
	BOOL connectionDone;
}
- (IBAction)connectToServer:(id)sender;
- (IBAction)enableServer:(id)sender;
- (IBAction)disableServer:(id)sender;
- (NSString*)softID;
- (void)waitConnection;
- (NSString*)retrieveHUGIP;
- (NSNumber*)osirixRDAddToDB:(NSNotification*) note;

- (void)updateProxyWhenReconnect;

- (IBAction)cleanQueue:(id)sender;
- (IBAction)cleanAll:(id)sender;

@end
