
#ifndef __GESTION_GLUT_H__
#define __GESTION_GLUT_H__


//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Parametres.h"

#include <stdio.h>
#ifdef _OS_WIN_
	#include <windows.h>
#endif
#include <GL/glut.h>


//==========================================================================//
//============================== PROTOTYPES ================================//

void RepositionnementFenetre(unsigned int val);
void RepositionnementFenetre(unsigned int x, unsigned int y);


#endif //========================== FIN ====================================//







