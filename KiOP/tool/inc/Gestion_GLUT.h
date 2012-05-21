/*****************************************************************************
******************************* INFORMATIONS *********************************
*                                                                            *
*			Fichier :	Gestion_GLUT.h                                               *
*			Auteur :	Thomas M. Strgar                                             *
*			Projet :	Projet Kinectop                                              *
*			Dernière modification : 11.08.2011                                     *
*                                                                            *
*                                                                            *
*****************************************************************************/

#ifndef Gestion_GLUT_h
#define Gestion_GLUT_h


/*****************************************************************************
****************************** FICHIERS INCLUS ******************************/

#include <stdio.h>
#ifdef _OS_WIN_
	#include <windows.h>
#endif
#include <GL/glut.h>

#include "main.h"


#define WIN_WIDTH (SCRSZW/RAPPORT_SCRSZW_WINSZW)
#define WIN_HEIGHT ( (int)(WIN_WIDTH*(240.0/320.0)) )

/*****************************************************************************
************************** PROTOTYPES DE FONCTIONS **************************/

void RedimensionnementFenetre(unsigned int width, unsigned int height);
//void RepositionnementFenetre(unsigned int val);
void RepositionnementFenetre(unsigned int x, unsigned int y);




#endif






