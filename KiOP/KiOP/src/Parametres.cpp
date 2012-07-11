
//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Parametres.h"


#if defined _OS_WIN_
//==========================================================================//
//=========================== VARIABLES GLOBALES ===========================//

QDesktopWidget *desktop2 = QApplication::desktop();
QRect rect = desktop2->screenGeometry(0);

//#include <Windows.h>
//RECT rc;
//bool temp = GetWindowRect(GetDesktopWindow(), &rc);
//unsigned int scrszw = rc.right;
//unsigned int scrszh = rc.bottom;


//==========================================================================//
//============================== FONCTIONS =================================//

unsigned int SCRSZWidth(void)
{
	return rect.width();
}

unsigned int SCRSZHeight(void)
{
	return rect.height();
}


//================================= FIN ====================================//
#endif






