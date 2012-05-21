
//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Control_Cursor_Qt.h"


//==========================================================================//
//=============================== MÉTHODES =================================//


// Constructeur
CursorQt::CursorQt(short type)
{
	m_type = type;
	m_moveEnable = false;
	m_clicEnable = false;
	m_mainFermee = false;


}

short CursorQt::CursorType(void)
{
	return m_type;
}

void CursorQt::SetPos(unsigned int x, unsigned int y)
{
	m_cursor.setPos(x, y);
}

void CursorQt::SetPos(QPoint newPos)
{
	m_cursor.setPos(newPos);
}

void CursorQt::IncrementPos(int dx, int dy)
{
	QPoint temp = m_cursor.pos();
	m_cursor.setPos(temp.x() + dx,temp.y() + dy);
}

void CursorQt::IncrementPos(QPoint deltaPos)
{
	//QPoint temp = m_cursor.pos();
	m_cursor.setPos(m_cursor.pos() + deltaPos);
}


QPoint CursorQt::Pos(void)
{
	return m_cursor.pos();
}

QPoint CursorQt::PreviousPos(void)
{
	return m_previousPos;
}

void CursorQt::MoveEnable(void)
{
	m_moveEnable = true;
}

void CursorQt::MoveDisable(void)
{
	m_moveEnable = false;
}

bool CursorQt::IsMoveEnable(void)
{
	return m_moveEnable;
}

void CursorQt::ClicEnable(void)
{
	m_clicEnable = true;
}

void CursorQt::ClicDisable(void)
{
	m_clicEnable = false;
}

bool CursorQt::IsClicEnable(void)
{
	return m_clicEnable;
}



void CursorQt::NewCursorSession(void)
{
	SetPos(SCRSZW/2,SCRSZH/2);
}

void CursorQt::EndCursorSession(void)
{

}



void CursorQt::MoveCursor(unsigned int handPosX, unsigned int handPosY)
{

	static QPoint posPrev(handPosX, handPosY);
	QPoint pos(handPosX, handPosY);
	QPoint deltaPos(pos - posPrev);
	posPrev = pos;

	IncrementPos(deltaPos);
	

}



void CursorQt::SteadyDetected(unsigned short nSteady)
{
	switch (nSteady)
	{
	case 10 :
		break;

	case 20 :
		break;

	default :
		break;
	}
}






