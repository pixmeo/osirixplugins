
/*****************************************************************************
****************************** FICHIERS INCLUS ******************************/

#include "Cursor.h"


/*****************************************************************************
******************************** CONSTANTES *********************************/

#define CORRECTION_DISTANCE_LINEAIRE 0

#if (SCRSZW >= SCRSZH)
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


/*****************************************************************************
**************************** VARIABLES GLOBALES *****************************/




/*****************************************************************************
********************************* MÉTHODES **********************************/

// Constructeur
Cursor::Cursor(short type)
{
	m_type = type;

	m_previousPos.x = SCRSZW/2;
	m_previousPos.y = SCRSZH/2;
	
	m_lastSteadyPos = m_previousPos;
	m_lastMoveEnablePos = m_previousPos;

	m_virtualPreviousPos.x = 640;
	m_virtualPreviousPos.y = 480;
	m_virtualPreviousPos.z = 1000;
	m_virtualPos = m_virtualPreviousPos;

	m_compteur = 0;
	m_mainFermee = false;
	m_moveEnable = false;
	m_clicEnable = false;
	m_cursorInitialised = false;

	UINT x1 = 70,		y1 = 30;
	UINT x2 = 110,	y2 = 80;

	double a = (double)(y2-y1)/(double)(x2-x1);
	double b = (double)y2-a*(double)x2;

	printf("\ta : %f\tb : %f\n\n",a,b);

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



short Cursor::GetCursorType(void)
{
	return m_type;
}



void Cursor::SetPos(POINT newPos)
{
	if (IsMoveEnable())
	{
		m_previousPos = GetPos();
		//SetCursorPos(newPos.x, newPos.y);
		m_cursor.setPos(newPos.x, newPos.y);
	}
}


void Cursor::IncrementPos(int dx, int dy)
{
	if (IsMoveEnable())
	{
		m_previousPos = GetPos();
		//SetCursorPos(m_previousPos.x+dx, m_previousPos.y+dy);
		m_cursor.setPos(m_previousPos.x+dx, m_previousPos.y+dy);
	}
}


POINT Cursor::GetPos(void)
{
	POINT temp;
	//GetCursorPos(&temp);

	temp.x = 	m_cursor.pos().x();
	temp.y = 	m_cursor.pos().y();

	return temp;
}


POINT Cursor::GetPreviousPos(void)
{
	return m_previousPos;
}


void Cursor::MoveEnable(void)
{
	if (!m_moveEnable)
	{
		m_moveEnable = true;
		SetPos(m_lastMoveEnablePos);
	}
}

void Cursor::MoveDisable(void)
{
	if (m_moveEnable)
	{
		m_moveEnable = false;
		m_lastMoveEnablePos = GetPos();
	}
}

bool Cursor::IsMoveEnable(void)
{
	return m_moveEnable;
}




void Cursor::ClicEnable(void)
{
	if (!m_clicEnable)
	{
		m_clicEnable = true;
	}
}

void Cursor::ClicDisable(void)
{
	if (m_clicEnable)
	{
		m_clicEnable = false;
	}
}

bool Cursor::IsClicEnable(void)
{
	return m_clicEnable;
}



void Cursor::SingleLeftClic(void)
{
	if (m_clicEnable)
	{
		mouse_event(MOUSEEVENTF_LEFTUP + MOUSEEVENTF_LEFTDOWN + MOUSEEVENTF_ABSOLUTE, 0, 0, 0, 0);
		printf("Simple Clic gauche\n");
	}
}

void Cursor::DoubleLeftClic(void)
{
	if (m_clicEnable)
	{
		mouse_event(MOUSEEVENTF_LEFTUP + MOUSEEVENTF_LEFTDOWN + MOUSEEVENTF_ABSOLUTE, 0, 0, 0, 0);
		mouse_event(MOUSEEVENTF_LEFTUP + MOUSEEVENTF_LEFTDOWN + MOUSEEVENTF_ABSOLUTE, 0, 0, 0, 0);
		printf("Double Clic gauche\n");
	}
}

void Cursor::PressLeftClic(void)
{
	if (m_clicEnable)
	{
		mouse_event(MOUSEEVENTF_LEFTDOWN + MOUSEEVENTF_ABSOLUTE, 0, 0, 0, 0);
		#ifdef _OS_WIN_
			ChangeCursor(5); // main fermée
		#endif
		printf("Clic gauche maintenu\n");
	}
}

void Cursor::ReleaseLeftClic(void)
{
	if (m_clicEnable)
	{
		mouse_event(MOUSEEVENTF_LEFTUP + MOUSEEVENTF_ABSOLUTE, 0, 0, 0, 0);
		#ifdef _OS_WIN_
			ChangeCursor(4); // main ouverte
		#endif
		printf("Clic gauche relache\n");
	}
}



void Cursor::SteadyDetected(UINT nb)
{
	if (GetState() != 0)
	{
		switch (nb)
		{

		case 1 :
			if			(m_type == 1) // Souris SteadyClic
			{
				SetLastSteadyPos(GetPos());
				if			(GetState() == 1)
					ChangeState(2);
				else if (GetState() == 2)
					ChangeState(1);
			}
			else if (m_type == 2) //Souris HandClosedClic
			{

			}
			break;

		case 2 :
			//cout << "m_currentState : " << m_currentState << endl;
			if			(m_type == 1) // Souris SteadyClic
			{
				
			}
			else if (m_type == 2) //Souris HandClosedClic
			{
				if (!m_mainFermee && m_moveEnable) // Main ouverte
					ChangeState(0);
			}
			break;

		default : 
			printf("\nERREUR STEADY : Steady %i n'existe pas!\n\n",nb);
			break;
		}
	}
}


void Cursor::NotSteadyDetected(void)
{

}



void Cursor::SetLastSteadyPos(POINT pos)
{
	m_lastSteadyPos = pos;
}

POINT Cursor::GetLastSteadyPos(void)
{
	return m_lastSteadyPos;
}


// A chaque fois que l'outil curseur est sélectionné
void Cursor::NewCursorSession(void)
{
	MoveEnable();
	ClicEnable();
	POINT temp; temp.x = SCRSZW/2+10; temp.y = SCRSZH/2+10;
	SetPos(temp);
	temp.x = SCRSZW/2; temp.y = SCRSZH/2;
	SetPos(temp);

	ChangeState(1);
	m_compteur = 0;
	SetCursorInitialised(true);
	cout << "-- Mode curseur initialise --" << endl;
}

// A chaque fois que l'on sort du mode curseur
void Cursor::EndCursorSession(void)
{
	MoveDisable();
	ClicDisable();
	SetCursorInitialised(false);
	#ifdef _OS_WIN_
		ChangeCursor(0);
	#endif
	cout << "-- Mode curseur termine --" << endl;
}



void Cursor::SetState(short newState)
{
	m_lastState = m_currentState;
	m_currentState = newState;
}

short Cursor::GetState(void)
{
	return m_currentState;
}

short Cursor::GetLastState(void)
{
	return m_lastState;
}

// Gestion de l'état
void Cursor::ChangeState(short newState)
{
	if (GetState() != newState)
	{
		SetState(newState);
		switch(newState)
		{

		// Hors session / Exit
		case 0 : 
			EndCursorSession();
			break;

		// Relâchement du clic / Déplacement du curseur libre
		case 1 : 
			ReleaseLeftClic();
			break;

		// Maintient du clic
		case 2 : 
			PressLeftClic();
			break;

		default : 
			printf("\nERREUR STATE : State %i n'existe pas!\n\n",newState);
			#ifdef _OS_WIN_
				ChangeCursor(0);
			#endif
			
			break;
		}
	}
}



void Cursor::NewCursorVirtualPos(int NewX, int NewY, int NewZ)
{
	m_virtualPreviousPos = m_virtualPos;

	m_virtualPos.x = NewX;
	m_virtualPos.y = NewY;
	m_virtualPos.z = NewZ;

	if ( (IsMoveEnable()) && (m_compteur++ > 0) ) // m_compteur à remplacer par : m_cursorInitialised
		NewCursorPos();
}

void Cursor::NewCursorPos(void)
{
	double dxp = (double)m_virtualPos.x - (double)m_virtualPreviousPos.x;
	double dyp = (double)m_virtualPos.y - (double)m_virtualPreviousPos.y;

	#if CORRECTION_DISTANCE_LINEAIRE
		int dxs = (COEFF_LIN_1X*dxp) / ((double)m_virtualPos.z + COEFF_LIN_2);
		int dys = (COEFF_LIN_1Y*dyp) / ((double)m_virtualPos.z + COEFF_LIN_2);
	#else
		int dxs = (COEFF_EXP_X*dxp) / exp((double)m_virtualPos.z*COEFF_D);
		int dys = (COEFF_EXP_Y*dyp) / exp((double)m_virtualPos.z*COEFF_D);
	#endif

	//IncrementPos(dxs,dys);
	//return;
	//printf("Déplacement dxs : %i\tdys : %i\n",dxs,dys);

	int dxt = 0, dyt = 0;

	if (dxs)
		dxt = m_courbeDeplacement[abs(dxs)] * (dxs>=0?1:-1);

	if (dys)
		dyt = m_courbeDeplacement[abs(dys)] * (dys>=0?1:-1);

	IncrementPos(dxt,dyt);
	//printf("Déplacement dxt : %i\tdyt : %i\n\n",dxt,dyt);
}



bool Cursor::CheckExitMouseMode(void)
{
	if (m_type == 1) // Souris SteadyClic
	{
		if (GetPos().y > (SCRSZH-10))
			return true;
		else
			return false;
	}
	return false;
}



void Cursor::SetMainFermee(bool mainFermee)
{
	if (m_type == 2) //Souris HandClosedClic
	{
		m_mainFermee = mainFermee;
		ChangeState((m_mainFermee?2:1));
	}
}



void Cursor::SetCursorInitialised(bool cursorInitialised)
{
	m_cursorInitialised = cursorInitialised;
}

bool Cursor::GetCursorInitialised(void)
{
	return m_cursorInitialised;
}








