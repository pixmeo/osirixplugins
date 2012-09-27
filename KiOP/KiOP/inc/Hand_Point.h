
#ifndef __HAND_POINT__
#define __HAND_POINT__


//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include <iostream>
#include <sstream>
#include <string>
using namespace std;

#include "Parametres.h"
#include "Point_3D.h"
#include "Steady_Class.h"
#include <XnTypes.h>
#include <math.h>


//==========================================================================//
//=============================== CONSTANTES ===============================//

#define MIN_SMOOTH_VALUE  0
#define MAX_SMOOTH_VALUE 40

#define SEUIL_BRUIT 2
#define NB_CASE 4


//==========================================================================//
//================================ CLASSES =================================//

class HandPoint
{
public :

	HandPoint(void);

	void Update(XnPoint3D handPt);

	Point3D HandPt(void) const;
	Point3D HandPtBrut(void) const;
	Point3D HandPtBrutFiltre(void) const;
	Point3D LastHandPt(void) const;
	Point3D DeltaHandPt(void) const;
	Point3D HandVirtualPt(void) const;

	Point3D Speed(void) const;

	void FiltreBruit(void);

	void FiltreSmooth(void);
	void SetSmooth(Point3D smooth);
	void SetSmooth(unsigned int smoothX, unsigned int smoothY, unsigned int smoothZ);
	void IncrementSmooth(Point3D increment);
	void IncrementSmooth(int x, int y, int z);
	Point3D Smooth(void) const;

	bool Steady2(void) const;
	bool Steady10(void) const;
	bool Steady20(void) const;
	bool NotSteady(void) const;
	void SignalResetSteadies(void);

	void IncrementCompteurFrame(void);
	unsigned int CompteurFrame(void) const;

	bool DetectLeft(void);
	bool DetectRight(void);
	bool DetectUp(void);
	bool DetectDown(void);
	bool DetectForward(void);
	bool DetectBackward(void);
	bool DetectStatic(void);

private :

	unsigned int m_compteurFrame;

	Point3D m_handPt;
	Point3D m_handPtBrut;
	Point3D m_handPtBrutFiltre;
	Point3D m_lastHandPt;
	Point3D m_lastHandPtBrut[NB_CASE];
	Point3D m_diffHandPt;

	Point3D m_handVirtualPt;

	Point3D m_smooth;

	SteadyClass m_sTD;
};




#endif //========================== FIN ====================================//







