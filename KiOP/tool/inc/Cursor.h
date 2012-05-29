
#ifndef Cursor_h
#define Cursor_h


//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Parametres.h"

#include <conio.h>
#include <stdio.h>
#include <math.h>
#include <map>
#include <list>
#ifdef _OS_WIN_
	#include <windows.h>
#endif
#include <GL/glut.h>

#include <QCursor>
#include <QPoint>

#include "main.h"


//==========================================================================//
//================================ TYPEDEF =================================//

typedef struct POINT3D
{
	unsigned int x;
	unsigned int y;
	unsigned int z;
} POINT3D;


//==========================================================================//
//============================== PROTOTYPES ================================//



//==========================================================================//
//================================ CLASSES =================================//

class Cursor
{
public : 

	Cursor(short type); // 1 : Souris SteadyClic
											// 2 : Souris HandClosedClic
											// 3 : Souris NoClic (Pointeur)
	short GetCursorType(void);

	void SetPos(POINT newPos);
	void IncrementPos(int dx, int dy);

	POINT GetPos(void);
	POINT GetPreviousPos(void);

	void SetState(short newState);
	short GetState(void);
	short GetLastState(void);

	void MoveEnable(void);
	void MoveDisable(void);
	bool IsMoveEnable(void);

	void ClicEnable(void);
	void ClicDisable(void);
	bool IsClicEnable(void);

	void SingleLeftClic(void);
	void DoubleLeftClic(void);
	void PressLeftClic(void);
	void ReleaseLeftClic(void);

	void SteadyDetected(unsigned int nb);
	void NotSteadyDetected(void);

	void SetLastSteadyPos(POINT pos);
	POINT GetLastSteadyPos(void);

	void NewCursorSession(void);
	void EndCursorSession(void);

	void ChangeState(short newState);
	void NewCursorVirtualPos(int NewX, int NewY, int NewZ);
	void NewCursorPos(void);

	bool CheckExitMouseMode(void);

	void SetMainFermee(bool mainFermee);
	void SetCursorInitialised(bool cursorInitialised);
	bool GetCursorInitialised(void);

private : 

	short m_type;
	QCursor m_cursor;

	POINT m_previousPos;
	POINT m_lastSteadyPos;
	POINT m_lastMoveEnablePos;

	POINT3D m_virtualPos;
	POINT3D m_virtualPreviousPos;

	short m_currentState;
	short m_lastState;

	bool m_cursorInitialised;
	bool m_moveEnable;
	bool m_clicEnable;

	unsigned int m_compteur;
	
	bool m_mainFermee;

	double m_courbeDeplacement[1001];

};


#endif //========================== FIN ====================================//







