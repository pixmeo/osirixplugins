/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


//#if !__LP64__

@class BrowserController;
@class SplashScreen;
@class DCMNetServiceDelegate;
@class XMLRPCMethods;
@class WebServicesMethods;


@interface AppController : NSObject// 	<GrowlApplicationBridgeDelegate>
//#else
//@interface AppController : NSObject
//#endif
{
	IBOutlet BrowserController		*browserController;

    IBOutlet NSMenu					*filtersMenu;
	IBOutlet NSMenu					*roisMenu;
	IBOutlet NSMenu					*othersMenu;
	IBOutlet NSMenu					*dbMenu;
	IBOutlet NSWindow				*dbWindow;
	
	NSDictionary					*previousDefaults;
	
	BOOL							showRestartNeeded;
		
    SplashScreen					*splashController;
	
    volatile BOOL					quitting;
	BOOL							verboseUpdateCheck;
    NSTask							*theTask;
	NSNetService					*BonjourDICOMService;
	
	BOOL							xFlipped, yFlipped;  // Dependent on current DCMView settings.
	
	NSTimer							*updateTimer;
	DCMNetServiceDelegate			*dicomNetServiceDelegate;
	XMLRPCMethods					*XMLRPCServer;
	WebServicesMethods				*webServer;
}

+ (id) sharedAppController; /**< Return the shared AppController instance */

@end

