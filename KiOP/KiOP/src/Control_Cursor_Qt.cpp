
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
	m_inCursorSession = false;
	m_leftClicPressed = false;

	m_previousPos = QPoint(SCRSZW/2,SCRSZH/2);
	m_virtualPosPrev = QPoint(0,0);

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


// ---------------- Setter(s) ------------------ //
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
	SetPos(newPos.x(),newPos.y());
}

void CursorQt::IncrementPos(int dx, int dy)
{
	SetPos(m_cursor.pos().x() + dx, m_cursor.pos().y() + dy);
}
void CursorQt::IncrementPos(QPoint deltaPos)
{
	IncrementPos(deltaPos.x(),deltaPos.y());
}


void CursorQt::SetMoveEnable(void)
{
	m_moveEnable = true;
}
void CursorQt::SetMoveDisable(void)
{
	m_moveEnable = false;
}

void CursorQt::SetClicEnable(void)
{
	m_clicEnable = true;
}
void CursorQt::SetClicDisable(void)
{
	m_clicEnable = false;
}



// ---------------- Getter(s) ------------------ //
short CursorQt::CursorType(void) const
{
	return m_type;
}

QPoint CursorQt::Pos(void) const
{
	return m_cursor.pos();
}

QPoint CursorQt::PreviousPos(void) const
{
	return m_previousPos;
}

QPoint CursorQt::DeltaPos(void) const
{
	return Pos() - PreviousPos();
}

bool CursorQt::MoveEnable(void) const
{
	return m_moveEnable;
}

bool CursorQt::ClicEnable(void) const
{
	return m_clicEnable;
}

bool CursorQt::LeftClicPressed() const
{
	return m_leftClicPressed;
}

bool CursorQt::InCursorSession() const
{
	return m_inCursorSession;
}





void CursorQt::PressLeftClic(bool force)
{
	if ( m_type!=POINTER_TYPE && (ClicEnable() || force) )
	{
#ifdef _OS_WIN_
		mouse_event(MOUSEEVENTF_LEFTDOWN + MOUSEEVENTF_ABSOLUTE, 0, 0, 0, 0);
		ChangeCursor(5); // main fermée
#endif

		m_leftClicPressed = true;
		cout << "--- Clic gauche maintenu" << endl;
	}
}

void CursorQt::ReleaseLeftClic(bool force)
{
	if ( m_type!=POINTER_TYPE && (ClicEnable() || force) )
	{
#ifdef _OS_WIN_
		mouse_event(MOUSEEVENTF_LEFTUP + MOUSEEVENTF_ABSOLUTE, 0, 0, 0, 0);
		ChangeCursor(4); // main ouverte
#endif

		m_leftClicPressed = false;
		cout << "--- Clic gauche relache" << endl;
	}
}




void CursorQt::NewCursorSession(Point3D handPt)
{
	m_inCursorSession = true;

	SetMoveEnable();
	SetClicEnable();

	SetPos(SCRSZW/2,SCRSZH/2);
	m_previousPos = QPoint(SCRSZW/2,SCRSZH/2);
	m_virtualPosPrev = QPoint(handPt.X(), handPt.Y());

#ifdef _OS_WIN_
	if (m_type==POINTER_TYPE)
		ChangeCursor(1);
	else
		ChangeCursor(4);
#endif
	cout << "-- Mode curseur initialise --" << endl;
}

void CursorQt::EndCursorSession(void)
{
	m_inCursorSession = false;
	ReleaseLeftClic(true);

	SetMoveDisable();
	SetClicDisable();

#ifdef _OS_WIN_
	ChangeCursor(0);
#endif
	cout << "-- Mode curseur termine --" << endl;
}




void CursorQt::MoveCursor(Point3D handPt)
{
	QPoint pos(handPt.X(), handPt.Y());
	QPoint deltaPos(pos - m_virtualPosPrev);
	m_virtualPosPrev = pos;

	//cout << "pos : " << pos.x() << ";" << pos.y() << endl;
	cout << "deltaPos : " << deltaPos.x() << ";" << deltaPos.y() << endl;

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
	cout << "dt : " << dxt << ";" << dyt << endl;
}







