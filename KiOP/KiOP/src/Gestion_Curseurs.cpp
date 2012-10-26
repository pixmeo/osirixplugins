
/*****************************************************************************
****************************** FICHIERS INCLUS ******************************/

#include "Gestion_Curseurs.h"


/*****************************************************************************
**************************** VARIABLES GLOBALES *****************************/

// Curseurs
HCURSOR hCurDefault = NULL,
		hCurBlue = NULL,
		hCurGreen = NULL,
		hCurRed = NULL,
		hCurYellow = NULL,
		hCurWhite = NULL,
		hCurStd = NULL,
		hCurTest1 = NULL,
		hCurTest2 = NULL,
		hCurWindows = NULL,
		hCurHandOpen = NULL,
		hCurHandClose = NULL,
		hCurHaloRed = NULL,
		hCurHaloBlue = NULL,
		hCurYellowPointer = NULL,
		hCurRedPointer = NULL;
HCURSOR hc0, hc1, hc2, hc3, hc4, hc5, hc6, hc7, hc8;
HCURSOR hCurAnime[9];

int test[2] = {1,2};

/*****************************************************************************
******************************** FONCTIONS **********************************/

void InitGestionCurseurs(void)
{
	hCurDefault = CopyCursor(GetCursor()); // Ne marche pas ?!?
	BOOL btest = 0;
	int i;

	LoadCursorFromCURFile(TEXT("res/cursors/aero_arrow.cur"),&hCurDefault,32,32);
	LoadCursorFromCURFile(TEXT("res/cursors/aero_arrow.cur"),&hCurWindows,32,32);
	LoadCursorFromCURFile(TEXT("res/cursors/aero_arrow_xl.cur"),&hCurWhite,32,32);
	LoadCursorFromCURFile(TEXT("res/cursors/main_ouverte.cur"),&hCurHandOpen,64,64);
	LoadCursorFromCURFile(TEXT("res/cursors/main_fermee.cur"),&hCurHandClose,64,64);
	LoadCursorFromCURFile(TEXT("res/cursors/pointeur_jaune.cur"),&hCurYellowPointer,64,64);
	LoadCursorFromCURFile(TEXT("res/cursors/pointeur_rouge.cur"),&hCurRedPointer,64,64);

}


// Charge un curseur à partir d'un fichier .cur
BOOL LoadCursorFromCURFile(LPTSTR szFileName, HCURSOR *phCursor, unsigned int dimX, unsigned int dimY)
{
	*phCursor = NULL;
	*phCursor = (HCURSOR)LoadImage( NULL, szFileName, IMAGE_CURSOR, dimX, dimY, LR_LOADFROMFILE | LR_SHARED);
	if(*phCursor == NULL)
		return FALSE;
	return TRUE;
}


// Change le type de curseur actuel
void ChangeCursor(unsigned short val)
{
	HCURSOR hCurTemp;
	BOOL testInt = 0;
	static unsigned short valPrev;

	if (val != valPrev)
	{
		switch (val)
		{
		case 0 : 
			hCurTemp = CopyCursor(hCurWindows);
			break;
		case 1 : 
			hCurTemp = CopyCursor(hCurRedPointer);
			break;
		case 2 : 
			hCurTemp = CopyCursor(hCurHaloBlue);
			break;
		case 3 : 
			hCurTemp = CopyCursor(hCurYellowPointer);
			break;
		case 4 : 
			hCurTemp = CopyCursor(hCurHandOpen);
			break;
		case 5 : 
			hCurTemp = CopyCursor(hCurHandClose);
			break;

		case 6 :
			hCurTemp = CopyCursor(hCurWindows);
			break;
		default :
			cout << "\n*** ERREUR : parametre de ChangeCursor(" << val << ") invalide. ***\n\n" << endl;
			return;
		}

		testInt = SetSystemCursor(hCurTemp, 32512);
		valPrev = val;
	}
}










