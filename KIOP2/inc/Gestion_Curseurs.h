
#ifndef Gestion_Curseurs_h
#define Gestion_Curseurs_h


/*****************************************************************************
****************************** FICHIERS INCLUS ******************************/

#include "Parametres.h"

#include <stdio.h>
#ifdef _OS_WIN_
	#include <windows.h>
#endif
#include <string.h>


#define CURSOR_FOLDER_PATH "kinect/Cursors"


/*****************************************************************************
************************** PROTOTYPES DE FONCTIONS **************************/

void InitGestionCurseurs(void);
BOOL LoadCursorFromCURFile(LPTSTR szFileName, HCURSOR *phCursor, UINT dimX, UINT dimY);
void ChangeCursor(unsigned short val);


#endif






