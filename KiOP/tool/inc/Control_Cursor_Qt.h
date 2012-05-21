
#ifndef __CONTROL_CURSOR_QT_H__
#define __CONTROL_CURSOR_QT_H__


//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Parametres.h"
//#define SCRSZW3 1000
//#define SCRSZH3 500


//#include <qcursor.h>
#include <QCursor>
//#include <Qt/qpoint.h>
//#include <QPoint>
#include "qpoint.h"


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

	void MoveEnable(void);
	void MoveDisable(void);
	bool IsMoveEnable(void);

	void ClicEnable(void);
	void ClicDisable(void);
	bool IsClicEnable(void);

	void NewCursorSession(void);
	void EndCursorSession(void);

	void MoveCursor(unsigned int handPosX, unsigned int handPosY);

	void SteadyDetected(unsigned short nSteady);

private :

	QCursor m_cursor;

	short m_type;

	QPoint m_previousPos;
	bool m_moveEnable;
	bool m_clicEnable;
	bool m_mainFermee;

};





#endif





