
#ifndef __CONTROL_CURSOR_QT_H__
#define __CONTROL_CURSOR_QT_H__


//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Parametres.h"

#ifdef _OS_WIN_
	#include <windows.h>
	#include "Gestion_Curseurs.h"
#endif

#include <XnTypes.h>
#include <QPoint>
#include <QCursor>
#include <QMouseEvent>


//==========================================================================//
//=============================== CONSTANTES ===============================//

#define CORRECTION_DISTANCE_LINEAIRE 0

#if (1)//(SCRSZW >= SCRSZH)
	#define MAXDX 45
	#define MAXDY ( (int)((double)MAXDX * ((double)SCRSZH/(double)SCRSZW)) )
#else
	#define MAXDY 45
	#define MAXDX ( (int)((double)MAXDY * ((double)SCRSZW/(double)SCRSZH)) )
#endif

#define COEFF_A -0.2502
#define COEFF_B 483.99
#define COEFF_C 654.98
#define COEFF_D -0.001

#define COEFF_LIN_1X ((40*SCRSZW)/(MAXDX*COEFF_A))
#define COEFF_LIN_1Y ((40*SCRSZH)/(MAXDY*COEFF_A))
#define COEFF_LIN_2  (COEFF_B/COEFF_A)

#define COEFF_EXP_X ((40*SCRSZW)/(MAXDX*COEFF_C))
#define COEFF_EXP_Y ((40*SCRSZH)/(MAXDY*COEFF_C))


//==========================================================================//
//================================ CLASSES =================================//

class CursorQt
{
public :
	CursorQt(short type); // 1 : Souris SteadyClic
												// 2 : Souris HandClosedClic
												// 3 : Souris NoClic (Pointeur)
	short CursorType(void);

	// Gestion des coordonnées
	void SetPos(unsigned int x, unsigned int y);
	void SetPos(QPoint newPos);
	void IncrementPos(int dx, int dy);
	void IncrementPos(QPoint deltaPos);
	QPoint Pos(void);
	QPoint PreviousPos(void);

	void SetMoveEnable(void);
	void SetMoveDisable(void);
	bool MoveEnable(void);

	void SetClicEnable(void);
	void SetClicDisable(void);
	bool ClicEnable(void);

	void SetHandClosed(bool handClosed);
	bool HandClosed(void);

	void PressLeftClic(void);
	void ReleaseLeftClic(void);

	void SetCursorInitialised(bool cursorInitialised);
	bool CursorInitialised(void);

	void NewCursorSession(void);
	void EndCursorSession(void);
	bool InCursorSession(void);

	void MoveCursor(XnPoint3D handPt);

	void SteadyDetected(unsigned short nSteady);

private :

	QCursor m_cursor;

	short m_type;

	QPoint m_previousPos;
	bool m_moveEnable;
	bool m_clicEnable;
	bool m_handClosed;
	bool m_cursorInitialised;
	bool m_notInCursorSession;

	double m_courbeDeplacement[1001];

};


#endif //========================== FIN ====================================//







