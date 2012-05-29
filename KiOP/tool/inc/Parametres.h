
#ifndef __PARAMETRES_H__
#define __PARAMETRES_H__


//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include <iostream>

#include <QApplication>
#include <QDesktopWidget>

#if (1)
	#define _OS_WIN_
#else
	#define _OS_MAC_
#endif

#ifdef _OS_WIN_
	#include <windows.h>
#endif

using namespace std;


//==========================================================================//
//============================== CONSTANTES ================================//

#ifdef _OS_WIN_
#	define SCRSZW (SCRSZWidth())
#	define SCRSZH (SCRSZHeight())
#endif
#ifdef _OS_MAC_
#	define SCRSZW 2560
#	define SCRSZH 1440
#endif


//==========================================================================//
//============================== PARAMETRES ================================//

#define RAPPORT_SCRSZW_WINSZW 4		// Rapport de la largeur de l'écran sur la largeur de la fenêtre
#define RES_WINDOW_GLUT 1
#define INIT_POS_WINDOW 1					// Position initiale de la fenêtre

#define RES_X 640
#define RES_Y 480
#define INIT_WIDTH_WINDOW (SCRSZW/RAPPORT_SCRSZW_WINSZW)
#define INIT_HEIGHT_WINDOW (INIT_WIDTH_WINDOW*((float)RES_Y/(float)RES_X))

#define MAX_STD_DEV_FOR_STEADY 0.002
#define MAX_STD_DEV_FOR_NOT_STEADY 0.006


//==========================================================================//
//============================== PROTOTYPES ================================//

unsigned int SCRSZWidth(void);
unsigned int SCRSZHeight(void);


#endif //========================== FIN ====================================//







