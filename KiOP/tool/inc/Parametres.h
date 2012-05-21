
#ifndef __PARAMETRES_H__
#define __PARAMETRES_H__


//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include <stdio.h>
#include <stdlib.h>
#include <iostream>

#include <QApplication>
#include "qapplication.h"
#include <QDesktopWidget>
//#include <QPoint>
#include "qpoint.h"


//#define _OS_WIN_
#define _OS_MAC_


#ifdef _OS_WIN_
	#include <windows.h>
#endif



//==========================================================================//
//============================== CONSTANTES ================================//

//QDesktopWidget* desktopWidget = QApplication::desktop();
//QRect clientRect = desktopWidget->availableGeometry();
//QRect applicationRect = desktopWidget->screenGeometry();

//QDesktopWidget *qt_desktop = new QDesktopWidget();
////QDesktopWidget *qt_desktop;
//QPoint resolution;
////QRect *test = new QRect;
//	
//	qt_desktop->screenGeometry(resolution);

//const unsigned int resx = resolution.x();
//const unsigned int resy = resolution.y();

	#define SCRSZW2 100//resx
	#define SCRSZH2 100//resy

#ifdef _OS_WIN_
	const unsigned int scrszw = GetSystemMetrics(SM_CXSCREEN);
	const unsigned int scrszh = GetSystemMetrics(SM_CYSCREEN);

	#define SCRSZW scrszw
	#define SCRSZH scrszh
#endif

#ifdef _OS_MAC_
	#define SCRSZW 2560
	#define SCRSZH 1440
#endif


//==========================================================================//
//============================== PARAMETRES ================================//

#define RAPPORT_SCRSZW_WINSZW 3		// Rapport de la largeur de l'écran sur la largeur de la fenêtre
#define RES_WINDOW_GLUT 1
#define INIT_POS_WINDOW 1					// Position initiale de la fenêtre
#define RES_X 640
#define RES_Y 480

#define MAX_STD_DEV_FOR_STEADY 0.002
#define MAX_STD_DEV_FOR_NOT_STEADY 0.006



#endif





