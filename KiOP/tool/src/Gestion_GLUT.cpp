
//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Gestion_GLUT.h"


//==========================================================================//
//=============================== FONCTIONS ================================//

void RepositionnementFenetre(unsigned int val)
{
	unsigned int posWindowX = 0, posWindowY = 0;
	 int dimWindowW = (INIT_WIDTH_WINDOW), dimWindowH = (INIT_HEIGHT_WINDOW);
	unsigned int bordFenetreHaut = 30, bordFenetre = 8;

	switch(val)
	{
	case 1 :
		glutPositionWindow(SCRSZW-dimWindowW-bordFenetre,bordFenetreHaut);
		break;
	case 2 :
		glutPositionWindow(bordFenetre,bordFenetreHaut);
		break;
	case 3 :
		glutPositionWindow(bordFenetre,SCRSZH-dimWindowH-bordFenetre);
		break;
	case 4 :
		glutPositionWindow(SCRSZW-dimWindowW-bordFenetre,SCRSZH-dimWindowH-bordFenetre);
		break;
	default : 
		return;
	}
}

void RepositionnementFenetre(unsigned int x, unsigned int y)
{
	glutPositionWindow(x,y);
}



