
#ifndef __CONTROL_CURSOR_QT_H__
#define __CONTROL_CURSOR_QT_H__


//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Parametres.h"
#include "Point_3D.h"

#ifdef _OS_WIN_
	#include <windows.h>
	#include "Gestion_Curseurs.h"
#endif



#include <XnTypes.h>
#include <QApplication>
#include <QPoint>
#include <QCursor>
#include <Qt>
#include <QEvent>
#include <QMouseEvent>
#include <qgraphicsscene.h>
#include <qgraphicssceneevent.h>
#include <math.h>


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

	// ---------------- Constructeur(s) ------------------ //
	CursorQt(short type=1); // 1 : Souris SteadyClic
													// 2 : Souris HandClosedClic
													// 3 : Souris NoClic (Pointeur)

	// ---------------- Setter(s) ------------------ //
	void SetPos(unsigned int x, unsigned int y);
	void SetPos(QPoint newPos);

	void IncrementPos(int dx, int dy);
	void IncrementPos(QPoint deltaPos);

	void SetMoveEnable(void);
	void SetMoveDisable(void);

	void SetClicEnable(void);
	void SetClicDisable(void);

	// ---------------- Getter(s) ------------------ //
	short CursorType(void) const;

	QPoint Pos(void) const;
	QPoint PreviousPos(void) const;
	bool MoveEnable(void) const;

	bool ClicEnable(void) const;
	bool LeftClicPressed() const;

	bool InCursorSession() const;

	void PressLeftClic(bool force=false);
	void ReleaseLeftClic(bool force=false);

	void NewCursorSession(void);
	void EndCursorSession(void);

	void MoveCursor(Point3D handPt);

protected :

	short m_type;

	QCursor m_cursor;
	QPoint m_previousPos;

	bool m_moveEnable;
	bool m_clicEnable;

	bool m_inCursorSession;
	bool m_leftClicPressed;

	double m_courbeDeplacement[1001];

};


#endif //========================== FIN ====================================//







