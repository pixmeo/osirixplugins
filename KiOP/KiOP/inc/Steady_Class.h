
#ifndef __STEADY_CLASS__
#define __STEADY_CLASS__


//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include <iostream>
using namespace std;

#include <XnTypes.h>
//#include <GL/glut.h>
#include <GLUT/glut.h>

#include "Point_3D.h"


//==========================================================================//
//=============================== CONSTANTES ===============================//

#define MAX_TOC_FRAME_VALUE 1000000


//==========================================================================//
//================================ CLASSES =================================//

class SteadyClass
{
public :

	SteadyClass(void);

	void SteadyCheck(const Point3D& handPt, const Point3D& lastHandPt);

	void ResetSteadies(void);
	void SignalResetSteadies(void);
	bool Steady2(void) const;
	bool Steady5(void) const;
	bool Steady10(void) const;
	bool Steady15(void) const;
	bool Steady20(void) const;
	bool NotSteady(void) const;

	void IncrementCompteurTimer(void);

private :

	unsigned int m_compteurTimer;

};


//==========================================================================//
//============================== PROTOTYPES ================================//

void SetTocFrame(unsigned int tocFrame);

void EnclenchementTimer(unsigned int ticFrame);
void Steady2(int ticFrame);
void Steady5(int ticFrame);
void Steady10(int ticFrame);
void Steady15(int ticFrame);
void Steady20(int ticFrame);

void SteadyAllEnable(void);
void Steady2Enable(void);
void Steady5Enable(void);
void Steady10Enable(void);
void Steady15Enable(void);
void Steady20Enable(void);

void SteadyAllDisable(void);
void Steady2Disable(void);
void Steady5Disable(void);
void Steady10Disable(void);
void Steady15Disable(void);
void Steady20Disable(void);

#endif //========================== FIN ====================================//







