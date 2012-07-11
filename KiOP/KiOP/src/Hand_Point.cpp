
//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Hand_Point.h"


//==========================================================================//
//================================ MÉTHODES ================================//

// -------------- Constructeur(s) ---------------- //

HandPoint::HandPoint(void) :
	m_compteurFrame(0),
	m_handPt("m_handPt"),
	m_lastHandPt("m_lastHandPt"),
	m_handPtBrut("m_handPtBrut0"),
	m_lastHandPtBrut(),
	m_handPtBrutFiltre("m_handPtBrut1"),
	m_diffHandPt("m_diffHandPt"),
	m_smooth(5,5,5,"m_smooth")
{
	std::ostringstream oss;
	for (int i=0; i<NB_CASE; i++)
	{
		oss << i;
		m_lastHandPtBrut[i].Rename("m_lastHandPtBrut1[" + oss.str() + "]");
		oss.seekp(0);
	}
}


// ------------------- Main ---------------------- //
void HandPoint::Update(XnPoint3D handPt)
{
	if (CompteurFrame() < 1)
	{
		for (int i=0; i<NB_CASE; i++)
		{
			m_lastHandPtBrut[i].Print();
		}
	}

	IncrementCompteurFrame();
	m_lastHandPt.SetCoordinate(m_handPt);
	m_handPtBrut.SetCoordinate(handPt);


	PushListPt3D(m_handPtBrut,m_lastHandPtBrut,NB_CASE);
	m_handPtBrutFiltre.SetCoordinate(MeanListPt3D(m_lastHandPtBrut,NB_CASE));
	//m_handPtBrut.Print();
	//m_handPtBrutFiltre.Print(); cout << endl;

	//FiltreBruit();
	FiltreSmooth();

	m_diffHandPt.SetCoordinate(m_handPtBrut - m_handPt);
	
	// Check for steadies
	sTD.SteadyCheck(m_handPt,m_lastHandPt);
}


// ---------------- Coordonnées ------------------ //
Point3D HandPoint::HandPt(void) const
{
	return m_handPt;
}

Point3D HandPoint::HandPtBrut(void) const
{
	return m_handPtBrut;
}

Point3D HandPoint::HandPtBrutFiltre(void) const
{
	return m_handPtBrutFiltre;
}

Point3D HandPoint::LastHandPt(void) const
{
	return m_lastHandPt;
}


// ------------------- Filtres ------------------- //

void HandPoint::FiltreBruit(void)
{


	//m_handPtBrutFiltre.SetCoordinate(MeanListPt3D(m_lastHandPtBrut,NB_CASE));

}

void HandPoint::FiltreSmooth(void)
{
	Point3D sgn = m_diffHandPt.Sgn();

	m_handPt.SetX(abs(m_diffHandPt.X()) > m_smooth.X() ? m_handPtBrutFiltre.X() - sgn.X()*(m_smooth.X()) : m_handPt.X());
	m_handPt.SetY(abs(m_diffHandPt.Y()) > m_smooth.Y() ? m_handPtBrutFiltre.Y() - sgn.Y()*(m_smooth.Y()) : m_handPt.Y());
	m_handPt.SetZ(abs(m_diffHandPt.Z()) > m_smooth.Z() ? m_handPtBrutFiltre.Z() - sgn.Z()*(m_smooth.Z()) : m_handPt.Z());

	m_handPt.Print();
}

// ------------------- Smooth -------------------- //

void HandPoint::SetSmooth(Point3D smooth)
{
	m_smooth.SetCoordinate(smooth);
}
void HandPoint::SetSmooth(unsigned int smoothX, unsigned int smoothY, unsigned int smoothZ)
{
	Point3D temp(smoothX,smoothY,smoothZ,"temp");
	SetSmooth(temp);
}

void HandPoint::IncrementSmooth(Point3D increment)
{
	m_smooth += increment;
	if (m_smooth.X() < MIN_SMOOTH_VALUE) m_smooth.SetX(MIN_SMOOTH_VALUE);
	if (m_smooth.X() > MAX_SMOOTH_VALUE) m_smooth.SetX(MAX_SMOOTH_VALUE);
	if (m_smooth.Y() < MIN_SMOOTH_VALUE) m_smooth.SetY(MIN_SMOOTH_VALUE);
	if (m_smooth.Y() > MAX_SMOOTH_VALUE) m_smooth.SetY(MAX_SMOOTH_VALUE);
	if (m_smooth.Z() < MIN_SMOOTH_VALUE) m_smooth.SetZ(MIN_SMOOTH_VALUE);
	if (m_smooth.Z() > MAX_SMOOTH_VALUE) m_smooth.SetZ(MAX_SMOOTH_VALUE);
}
void HandPoint::IncrementSmooth(int x, int y, int z)
{
	Point3D temp(x,y,z,"temp");
	IncrementSmooth(temp);
}

Point3D HandPoint::Smooth(void) const
{
	return m_smooth;
}


// ------------------ Steadies ------------------- //

bool HandPoint::Steady2(void) const
{
	return sTD.Steady2();
}
bool HandPoint::Steady10(void) const
{
	return sTD.Steady10();
}
bool HandPoint::Steady20(void) const
{
	return sTD.Steady20();
}
bool HandPoint::NotSteady(void) const
{
	return sTD.NotSteady();
}



// ------------------ Compteur ------------------- //

void HandPoint::IncrementCompteurFrame(void)
{
	if (m_compteurFrame++ > 1000000)
		m_compteurFrame = 0;
}
unsigned int HandPoint::CompteurFrame(void) const
{
	return m_compteurFrame;
}




//================================= FIN ====================================//







