
//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Control_Cursor_Qt.h"


//==========================================================================//
//=============================== MÉTHODES =================================//


// Constructeur
CursorQt::CursorQt(){}

CursorQt::CursorQt(short type)
{
	m_desktop = QApplication::desktop();




	m_type = type;
	m_moveEnable = false;
	m_clicEnable = false;
	m_handClosed = false;
	m_cursorInitialised = false;
	m_notInCursorSession = true;



	unsigned int x1 = 70,		y1 = 30;
	unsigned int x2 = 110,	y2 = 80;

	double a = (double)(y2-y1)/(double)(x2-x1);
	double b = (double)y2-a*(double)x2;

	double courbe[7] =
	{
		0,
		0,
		7.8227E-07,
		-0.00022224,
		0.020132,
		-0.029578,
		0.92355
	};

	for (int i = 1; i<x2; i++)
	{
		m_courbeDeplacement[i] = courbe[0]*powf(i,6)
							+ courbe[1]*powf(i,5)
							+ courbe[2]*powf(i,4)
							+ courbe[3]*powf(i,3)
							+ courbe[4]*powf(i,2)
							+ courbe[5]*i
							+ courbe[6];
	}

	for (int i = x2; i<1001; i++)
	{
		m_courbeDeplacement[i] = a*i + b;
	}


}

short CursorQt::CursorType(void)
{
	return m_type;
}

void CursorQt::SetPos(unsigned int x, unsigned int y)
{
	if (m_moveEnable)
	{
		m_previousPos = m_cursor.pos();
		m_cursor.setPos(x, y);
	}
}

void CursorQt::SetPos(QPoint newPos)
{
	if (m_moveEnable)
	{
		m_previousPos = m_cursor.pos();
		m_cursor.setPos(newPos);
	}
}

void CursorQt::IncrementPos(int dx, int dy)
{
	if (m_moveEnable)
	{
		m_previousPos = m_cursor.pos();
		QPoint temp = m_cursor.pos();
		m_cursor.setPos(temp.x() + dx,temp.y() + dy);
	}
}

void CursorQt::IncrementPos(QPoint deltaPos)
{
	if (m_moveEnable)
	{
		m_previousPos = m_cursor.pos();
		//QPoint temp = m_cursor.pos();
		m_cursor.setPos(m_cursor.pos() + deltaPos);
	}
}


QPoint CursorQt::Pos(void) const
{
	return m_cursor.pos();
}

QPoint CursorQt::PreviousPos(void) const
{
	return m_previousPos;
}

void CursorQt::SetMoveEnable(void)
{
	m_moveEnable = true;
}

void CursorQt::SetMoveDisable(void)
{
	m_moveEnable = false;
}

bool CursorQt::MoveEnable(void) const
{
	return m_moveEnable;
}

void CursorQt::SetClicEnable(void)
{
	m_clicEnable = true;
}

void CursorQt::SetClicDisable(void)
{
	m_clicEnable = false;
}

bool CursorQt::ClicEnable(void) const
{
	return m_clicEnable;
}


void CursorQt::SetHandClosed(bool handClosed)
{
	m_handClosed = handClosed;
	if (handClosed)
	{
		PressLeftClic();
	}
	else
	{
		ReleaseLeftClic();
	}
}

bool CursorQt::HandClosed(void) const
{
	return m_handClosed;
}


void CursorQt::PressLeftClic(void)
{
	if (ClicEnable())
	{
		#ifdef _OS_WIN_
			mouse_event(MOUSEEVENTF_LEFTDOWN + MOUSEEVENTF_ABSOLUTE, 0, 0, 0, 0);
			ChangeCursor(5); // main fermée
		#endif

		cout << "Clic gauche maintenu\n" << endl;
	}
}

void CursorQt::ReleaseLeftClic(void)
{
	if (ClicEnable())
	{
		#ifdef _OS_WIN_
			mouse_event(MOUSEEVENTF_LEFTUP + MOUSEEVENTF_ABSOLUTE, 0, 0, 0, 0);
			ChangeCursor(4); // main ouverte
		#endif
		cout << "Clic gauche relache\n" << endl;
	}
}



void CursorQt::SetCursorInitialised(bool cursorInitialised)
{
	m_cursorInitialised = cursorInitialised;
}

bool CursorQt::CursorInitialised(void)
{
	return m_cursorInitialised;
}


void CursorQt::NewCursorSession(void)
{
	m_notInCursorSession = false;
	m_handClosed = false;

	SetMoveEnable();
	SetClicEnable();
	SetPos(SCRSZW/2,SCRSZH/2);

	SetCursorInitialised(true);
	#ifdef _OS_WIN_
		ChangeCursor(4);
	#endif
	cout << "-- Mode curseur initialise --" << endl;
}

void CursorQt::EndCursorSession(void)
{
	m_notInCursorSession = true;
	SetMoveDisable();
	SetClicDisable();
	#ifdef _OS_WIN_
		ChangeCursor(0);
	#endif
	cout << "-- Mode curseur termine --" << endl;
}

bool CursorQt::InCursorSession(void)
{
	return !m_notInCursorSession;
}


void CursorQt::MoveCursor(Point3D handPt)
{
	static QPoint posPrev(handPt.X(), handPt.Y());
	QPoint pos(handPt.X(), handPt.Y());
	QPoint deltaPos(pos - posPrev);
	posPrev = pos;

	double dxp = (double)pos.x() - (double)posPrev.x();
	double dyp = (double)pos.y() - (double)posPrev.y();

	#if CORRECTION_DISTANCE_LINEAIRE
		int dxs = (COEFF_LIN_1X*deltaPos.x()) / ((double)handPosZ + COEFF_LIN_2);
		int dys = (COEFF_LIN_1Y*deltaPos.y()) / ((double)handPosZ + COEFF_LIN_2);
	#else
		int dxs = (COEFF_EXP_X*deltaPos.x()) / exp((double)handPt.Z()*COEFF_D);
		int dys = (COEFF_EXP_Y*deltaPos.y()) / exp((double)handPt.Z()*COEFF_D);
	#endif

	int dxt = 0, dyt = 0;

	if (dxs)
		dxt = m_courbeDeplacement[abs(dxs)] * (dxs>=0?1:-1);

	if (dys)
		dyt = m_courbeDeplacement[abs(dys)] * (dys>=0?1:-1);

	IncrementPos(dxt,dyt);
}



void CursorQt::SteadyDetected(unsigned short nSteady)
{
	cout << "CursorQt Steady " << nSteady << " detected" << endl;
	switch (nSteady)
	{
	case 10 :
		break;

	case 20 :
		if (!m_handClosed)
			EndCursorSession();
		break;

	default :
		break;
	}
}






