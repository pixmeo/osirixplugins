/*****************************************************************************
******************************* INFORMATIONS *********************************
*                                                                            *
*			Fichier :	Gestion_GLUT.cpp                                             *
*			Auteur :	Thomas M. Strgar                                             *
*			Projet :	Projet Kinectop                                              *
*			Dernière modification : 11.08.2011                                     *
*                                                                            *
*                                                                            *
*****************************************************************************/

#ifndef Gestion_GLUT_cpp
#define Gestion_GLUT_cpp


/*****************************************************************************
****************************** FICHIERS INCLUS ******************************/

#include "Gestion_GLUT.h"


/*****************************************************************************
**************************** VARIABLES GLOBALES *****************************/

unsigned int posWindowX = 0, posWindowY = 0;
unsigned int dimWindowW = (SCRSZW/RAPPORT_SCRSZW_WINSZW), dimWindowH = (dimWindowW*(240.0/320.0));
unsigned int bordFenetreHaut = 30, bordFenetre = 8;


/*****************************************************************************
******************************** FONCTIONS **********************************/


void RedimensionnementFenetre(unsigned int width, unsigned int height)
{
	// Redimensionnement de la fenêtre
	dimWindowW = (width>0 ? width : dimWindowW);
	dimWindowH = (height>0 ? height : dimWindowH);
	glutReshapeWindow(dimWindowW, dimWindowH);

	printf("\nDimensions : %ix%i\n\n", dimWindowW, dimWindowH);
}

/*
void RepositionnementFenetre(unsigned int val)
{
	RECT zone;
	SystemParametersInfo(SPI_GETWORKAREA,0,&zone,0);

	//if ((zone.right >= dimWindowW) || (zone.bottom >= dimWindowH))
		//RedimensionnementFenetre(dimWindowW, dimWindowH);
	printf("\nDimensions de la fenetre : %ix%i\n\n",dimWindowW,dimWindowH);

	switch(val)
	{
	case 1 :
		glutPositionWindow(zone.right-dimWindowW-bordFenetre,zone.top+bordFenetreHaut);
		break;
	case 2 :
		glutPositionWindow(zone.left+bordFenetre,zone.top+bordFenetreHaut);
		break;
	case 3 :
		glutPositionWindow(zone.left+bordFenetre,zone.bottom-dimWindowH-bordFenetre);
		break;
	case 4 :
		glutPositionWindow(zone.right-dimWindowW-bordFenetre,zone.bottom-dimWindowH-bordFenetre);
		break;
	default : 
		return;
	}
}
 */

void RepositionnementFenetre(unsigned int x, unsigned int y)
{
	glutPositionWindow(x,y);
}



#endif







