
//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Hand_Point.h"


//==========================================================================//
//================================ MÉTHODES ================================//

// -------------- Constructeur(s) ---------------- //

HandPoint::HandPoint(void)
{
	m_compteurFrame = 0;

	m_handPt.X = 0; m_handPt.Y = 0; m_handPt.Z = 0;
	m_lastHandPt.X = 0; m_lastHandPt.Y = 0; m_lastHandPt.Z = 0;
	m_handPtBrut.X = 0; m_handPtBrut.Y = 0; m_handPtBrut.Z = 0;
	m_deltaHandPt.X = 0; m_deltaHandPt.Y = 0; m_deltaHandPt.Z = 0;
	m_diffHandPt.X = 0; m_diffHandPt.Y = 0; m_diffHandPt.Z = 0;

	m_smooth.X = 10; m_smooth.Y = 10; m_smooth.Z = 10;
}


// ------------------- Main ---------------------- //

void HandPoint::Update(XnPoint3D handPt)
{
	IncrementCompteurFrame();

	m_lastHandPt = m_handPt;
	m_handPtBrut = handPt;

	FiltreSmooth();

	m_deltaHandPt.X = m_handPt.X - m_lastHandPt.X;
	m_deltaHandPt.Y = m_handPt.Y - m_lastHandPt.Y;
	m_deltaHandPt.Z = m_handPt.Z - m_lastHandPt.Z;

	m_diffHandPt.X = m_handPtBrut.X - m_handPt.X;
	m_diffHandPt.Y = m_handPtBrut.Y - m_handPt.Y;
	m_diffHandPt.Z = m_handPtBrut.Z - m_handPt.Z;

	//cout << "\tdiffX : " << m_diffHandPt.X << "\tdiffY : " << m_diffHandPt.Y << "\tdiffZ : " << m_diffHandPt.Z << endl;

	// Check for steadies
	sTD.SteadyCheck(m_handPt,m_lastHandPt);
}

// ---------------- Coordonnées ------------------ //

XnPoint3D HandPoint::HandPt(void) const
{
	return m_handPt;
}

XnPoint3D HandPoint::HandPtBrut(void) const
{
	return m_handPtBrut;
}

XnPoint3D HandPoint::LastHandPt(void) const
{
	return m_lastHandPt;
}

XnPoint3D HandPoint::DeltaHandPt(void) const
{
	return m_deltaHandPt;
}


// ------------------- Smooth -------------------- //

void HandPoint::FiltreSmooth(void)
{
	XnPoint3D sgn;
	sgn.X = (m_diffHandPt.X >= 0 ? 1 : -1);
	sgn.Y = (m_diffHandPt.Y >= 0 ? 1 : -1);
	sgn.Z = (m_diffHandPt.Z >= 0 ? 1 : -1);

	m_handPt.X = (abs(m_diffHandPt.X) > m_smooth.X ? m_handPtBrut.X - sgn.X*(m_smooth.X) : m_handPt.X);
	m_handPt.Y = (abs(m_diffHandPt.Y) > m_smooth.Y ? m_handPtBrut.Y - sgn.Y*(m_smooth.Y) : m_handPt.Y);
	m_handPt.Z = (abs(m_diffHandPt.Z) > m_smooth.Z ? m_handPtBrut.Z - sgn.Z*(m_smooth.Z) : m_handPt.Z);
}

void HandPoint::SetSmooth(XnPoint3D smooth)
{
	m_smooth = smooth;
}
void HandPoint::SetSmooth(unsigned int smoothX, unsigned int smoothY, unsigned int smoothZ)
{
	m_smooth.X = smoothX;
	m_smooth.Y = smoothY;
	m_smooth.Z = smoothZ;
}

void HandPoint::IncrementSmooth(XnPoint3D increment)
{
	m_smooth.X += increment.X;
	if (m_smooth.X < MIN_SMOOTH_VALUE) m_smooth.X = MIN_SMOOTH_VALUE;
	if (m_smooth.X > MAX_SMOOTH_VALUE) m_smooth.X = MAX_SMOOTH_VALUE;
	m_smooth.Y += increment.Y;
	if (m_smooth.Y < MIN_SMOOTH_VALUE) m_smooth.Y = MIN_SMOOTH_VALUE;
	if (m_smooth.Y > MAX_SMOOTH_VALUE) m_smooth.Y = MAX_SMOOTH_VALUE;
	m_smooth.Z += increment.Z;
	if (m_smooth.Z < MIN_SMOOTH_VALUE) m_smooth.Z = MIN_SMOOTH_VALUE;
	if (m_smooth.Z > MAX_SMOOTH_VALUE) m_smooth.Z = MAX_SMOOTH_VALUE;
}
void HandPoint::IncrementSmooth(int x, int y, int z)
{
	m_smooth.X += x;
	if (m_smooth.X < MIN_SMOOTH_VALUE) m_smooth.X = MIN_SMOOTH_VALUE;
	if (m_smooth.X > MAX_SMOOTH_VALUE) m_smooth.X = MAX_SMOOTH_VALUE;
	m_smooth.Y += y;
	if (m_smooth.Y < MIN_SMOOTH_VALUE) m_smooth.Y = MIN_SMOOTH_VALUE;
	if (m_smooth.Y > MAX_SMOOTH_VALUE) m_smooth.Y = MAX_SMOOTH_VALUE;
	m_smooth.Z += z;
	if (m_smooth.Z < MIN_SMOOTH_VALUE) m_smooth.Z = MIN_SMOOTH_VALUE;
	if (m_smooth.Z > MAX_SMOOTH_VALUE) m_smooth.Z = MAX_SMOOTH_VALUE;
}

XnPoint3D HandPoint::Smooth(void) const
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







