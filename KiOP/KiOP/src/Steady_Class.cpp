
//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Steady_Class.h"


//==========================================================================//
//=========================== VARIABLES GLOBALES ===========================//

unsigned int g_tocFrame = 0;
bool g_steady2 = false, g_steady10 = false, g_steady20 = false;
bool g_notSteady = false;


//==========================================================================//
//================================ MÉTHODES ================================//

// -------------- Constructeur(s) ---------------- //

SteadyClass::SteadyClass(void)
{
	m_compteurTimer = 0;
}


// ------------------- Main ---------------------- //

void SteadyClass::SteadyCheck(Point3D handPt, Point3D lastHandPt)
{
	// Si le handPoint n'a pas bougé (sur une frame)
	//if (lastHandPt == handPt)
	if ( (lastHandPt.X() == handPt.X()) && (lastHandPt.Y() == handPt.Y()) )
	{
		g_notSteady = false;
		EnclenchementTimer(m_compteurTimer);
	}
	else
	{
		g_notSteady = true;
		ResetSteadies();
		IncrementCompteurTimer();
	}
	SetTocFrame(m_compteurTimer);
}


// ------------------ Steadies ------------------- //

void SteadyClass::ResetSteadies(void)
{
	g_steady2 = false;
	g_steady10 = false;
	g_steady20 = false;
}

bool SteadyClass::Steady2(void) const
{
	return g_steady2;
}
bool SteadyClass::Steady10(void) const
{
	return g_steady10;
}
bool SteadyClass::Steady20(void) const
{
	return g_steady20;
}
bool SteadyClass::NotSteady(void) const
{
	return g_notSteady;
}


// ------------------ Compteur ------------------- //

void SteadyClass::IncrementCompteurTimer(void)
{
	if (m_compteurTimer++ > 1000000)
		m_compteurTimer = 0;
}


//==========================================================================//
//============================== FONCTIONS =================================//

void SetTocFrame(unsigned int tocFrame)
{
	g_tocFrame = tocFrame;
}

void EnclenchementTimer(unsigned int ticFrame)
{
	glutTimerFunc( 200, Steady2,ticFrame);
	glutTimerFunc(1000,Steady10,ticFrame);
	glutTimerFunc(2000,Steady20,ticFrame);
}

void Steady2(int ticFrame)
{
	if (ticFrame == g_tocFrame)	g_steady2 = true;
}
void Steady10(int ticFrame)
{
	if (ticFrame == g_tocFrame)	g_steady10 = true;
}
void Steady20(int ticFrame)
{
	if (ticFrame == g_tocFrame)	g_steady20 = true;
}


//================================= FIN ====================================//







