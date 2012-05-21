
#ifndef __HAND_CLOSED_DETECTION__
#define __HAND_CLOSED_DETECTION__


//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include <iostream>

#include "Parametres.h"
#include <XnTypes.h>
#include <QSize>

#include <QPoint>

#include "XnCppWrapper.h"

#include "opencv2/opencv.hpp"
//#include "opencv2/imgproc/imgproc.hpp"
//#include "opencv2/highgui/highgui.hpp"
#include "imgproc.hpp"
#include "highgui.hpp"

using namespace std;
using namespace cv;


//==========================================================================//
//================================ CLASSES =================================//



class HandClosedDetection
{
public : 

  HandClosedDetection(void);
	void SetDepthLimits(unsigned int handPointZ);

	void SetHandPt(XnPoint3D handPoint);
	void SetHandPtInROI(void);

	void SetROI_Size(void);
	void SetROI_Pt(void);
	QPoint ROI_Pt(void);

	void AfficheTest(xn::DepthMetaData& dpmd, Mat& matOut);
	void DefinitionPointsCadrage(Mat& ROI, QPoint& haut, QPoint& bas, QPoint& gauche, QPoint& droite);

private : 

	bool m_handClosed;
	
	unsigned int m_depthLimitMin, m_depthLimitMax;
	XnPoint3D m_handPt;
	QPoint m_handPtInROI;

	QSize m_ROI_Size;
	QPoint m_ROI_Pt;
};



#endif







