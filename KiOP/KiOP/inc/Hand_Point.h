
#ifndef __HAND_POINT__
#define __HAND_POINT__


//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include <iostream>
using namespace std;

#include "Steady_Class.h"
#include <XnTypes.h>
#include <math.h>


//==========================================================================//
//=============================== CONSTANTES ===============================//

#define MIN_SMOOTH_VALUE  0
#define MAX_SMOOTH_VALUE 40


//==========================================================================//
//================================ CLASSES =================================//

class HandPoint
{
public :

	HandPoint(void);

	void Update(XnPoint3D handPt);

	XnPoint3D HandPt(void) const;
	XnPoint3D HandPtBrut(void) const;
	XnPoint3D LastHandPt(void) const;
	XnPoint3D DeltaHandPt(void) const;

	void FiltreSmooth(void);
	void SetSmooth(XnPoint3D smooth);
	void SetSmooth(unsigned int smoothX, unsigned int smoothY, unsigned int smoothZ);
	void IncrementSmooth(XnPoint3D increment);
	void IncrementSmooth(int x, int y, int z);
	XnPoint3D Smooth(void) const;

	bool Steady2(void) const;
	bool Steady10(void) const;
	bool Steady20(void) const;
	bool NotSteady(void) const;

	void IncrementCompteurFrame(void);
	unsigned int CompteurFrame(void) const;

private :

	unsigned int m_compteurFrame;

	XnPoint3D m_handPtBrut;
	XnPoint3D m_handPt;
	XnPoint3D m_lastHandPt;
	XnPoint3D m_deltaHandPt;
	XnPoint3D m_diffHandPt;

	XnPoint3D m_smooth;

	SteadyClass sTD;
};



#endif //========================== FIN ====================================//







