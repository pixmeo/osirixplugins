
#ifndef __PARAMETRES_H__
#define __PARAMETRES_H__


//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include <iostream>

#include <QApplication>
#include <QDesktopWidget>
#include <GLUT/glut.h>

// Définition du système d'exploitation
#if defined (_WIN32)
	#define _OS_WIN_
#elif defined (__APPLE__)
	#define _OS_MAC_
#endif

#ifdef _OS_WIN_
	#include <windows.h>
#endif

using namespace std;


//==========================================================================//
//============================== CONSTANTES ================================//

#if defined _OS_WIN_
  #define SCRSZW (SCRSZWidth())
  #define SCRSZH (SCRSZHeight())
#elif defined _OS_MAC_
  #define SCRSZW (SCRSZWidth())
  #define SCRSZH (SCRSZHeight())
#endif

#if defined _OS_WIN_
  #define RESETALL		0
  #define LAYOUT			1
  #define MOVE			2
  #define CONTRAST		3
  #define ZOOM			4
  #define SCROLL			5
  #define MOUSE			6
  #define CROSS			7
#elif defined _OS_MAC_
  #define MOVE			0
  #define CONTRAST		1
  #define ZOOM			2
  #define SCROLL			3
  #define MOUSE			4
  #define CROSS			5
#endif


//const int TOOL_LIST[8] = {RESETALL, LAYOUT, MOVE, CONTRAST, ZOOM, SCROLL, MOUSE, CROSS};


//==========================================================================//
//============================== PARAMETRES ================================//

#define RAPPORT_SCRSZW_WINSZW 5		// Rapport de la largeur de l'écran sur la largeur de la fenêtre
#define RES_WINDOW_GLUT 4
#define INIT_POS_WINDOW 1					// Position initiale de la fenêtre

#if 1
	#define RES_X 640
	#define RES_Y 480
#else
	#define RES_X 480
	#define RES_Y 320
#endif

#define INIT_WIDTH_WINDOW (SCRSZW/RAPPORT_SCRSZW_WINSZW)
#define INIT_HEIGHT_WINDOW (INIT_WIDTH_WINDOW*((float)RES_Y/(float)RES_X))

#define MAX_STD_DEV_FOR_STEADY 0.002
#define MAX_STD_DEV_FOR_NOT_STEADY 0.006


//==========================================================================//
//============================== PROTOTYPES ================================//

unsigned int SCRSZWidth(void);
unsigned int SCRSZHeight(void);


#endif //========================== FIN ====================================//







