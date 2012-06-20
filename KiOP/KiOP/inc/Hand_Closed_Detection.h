
#ifndef __HAND_CLOSED_DETECTION__
#define __HAND_CLOSED_DETECTION__


//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include <iostream>

#include "Parametres.h"
#include "Region_Of_Interest.h"

#include <XnTypes.h>
#include <QSize>
#include <QPoint>

#include "XnCppWrapper.h"
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/highgui/highgui.hpp"
//#include "cap_openni.cpp"

using namespace std;
using namespace cv;


//==========================================================================//
//=============================== CONSTANTES ===============================//

#define INTERVALLE_PROFONDEUR_DETECTION 200
#define RAPPORT_DIM_ROI 0.6
#define NB_CASE_HAND_CLOSED_PREV 20

#define SEUIL_BAS 0.85
#define SEUIL_HAUT (1/SEUIL_BAS)


//==========================================================================//
//================================ CLASSES =================================//

class HandClosedDetection
{
public :

	HandClosedDetection();
	void Update(unsigned int methode, const xn::DepthMetaData& dpmd, const XnPoint3D handPt);

	//void ExtractionROI(const xn::DepthMetaData& dpmd);
	void UpdateROI_Data(const xn::DepthMetaData& dpmd);
	void Display_ROI(Mat& ROI);

	void UpdateDepthLimits(void);
	void UpdateDepthLimits(unsigned int handPtZ);

	void UpdateHandPt(XnPoint3D handPoint);
	void UpdateHandPtInROI(void);

	void UpdateROI_Pt(void);
	void UpdateROI_Size(void);

	QPoint ROI_Pt(void) const;
	QSize ROI_Size(void) const;

	void DefinitionPointsCadrage(Mat& ROI, QPoint& haut, QPoint& bas, QPoint& gauche, QPoint& droite);

	void MethodeAireMain(const xn::DepthMetaData& dpmd);
	void MethodeSurfaceRect(const xn::DepthMetaData& dpmd);

	void IncrementCompteurFrame(void);
	void ResetCompteurFrame(void);
	int CompteurFrame(void) const;

	void UpdateHandClosedPrev(void);

	bool HandClosed(void) const;
	bool HandClosedPrev(unsigned int val) const;
	bool HandClosedFlancMont(void) const;
	bool HandClosedFlancDesc(void) const;
	bool HandClosedClic(unsigned int val) const;
	bool HandClosedStateChanged() const;

private :

	RegionOfInterrest m_ROI;
	Mat m_ROI_Data;
	Mat m_ROI_Data2;

	bool m_handClosed;
	bool m_handClosedPrev[NB_CASE_HAND_CLOSED_PREV];
	bool m_ROI_OutOfCamera;

	unsigned int m_depthLimitMin, m_depthLimitMax;
	XnPoint3D m_handPt;
	QPoint m_handPtInROI;

	unsigned int m_compteurFrame;
};


#endif //========================== FIN ====================================//







