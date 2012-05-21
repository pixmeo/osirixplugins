
//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Hand_Closed_Detection.h"


//==========================================================================//
//=============================== CONSTANTES ===============================//

#define INTERVALLE_PROFONDEUR_DETECTION 200
#define MAX_ROI_SIZE 300

#define TAILLE 10

//==========================================================================//
//================================ MÉTHODES ================================//


HandClosedDetection::HandClosedDetection(void)
{}


void HandClosedDetection::SetDepthLimits(unsigned int handPointZ)
{
	m_depthLimitMin = handPointZ - INTERVALLE_PROFONDEUR_DETECTION/2;
	m_depthLimitMax = handPointZ + INTERVALLE_PROFONDEUR_DETECTION/2;
}



void HandClosedDetection::SetHandPt(XnPoint3D handPoint)
{
	m_handPt = handPoint;
}

void HandClosedDetection::SetHandPtInROI(void)
{
	m_handPtInROI.setX(m_handPt.X - m_ROI_Pt.x());
	m_handPtInROI.setY(m_handPt.Y - m_ROI_Pt.y());
}


void HandClosedDetection::SetROI_Size(void)
{
	static const float x1 = 500, x2 = 2500;
	static const float y1 = 250, y2 = 50;

	static const int ROI_SizeOffset = 60;
	static const float ROI_SizeCoeffA = (x1*x2) * (y1-y2)/(x2-x1);
	static const float ROI_SizeCoeffB = y1 - ROI_SizeCoeffA/x1 + ROI_SizeOffset;

	m_ROI_Size.setWidth(ROI_SizeCoeffA/m_handPt.Z + ROI_SizeCoeffB);
	m_ROI_Size.setHeight(m_ROI_Size.width() * 0.8);

	//cout << "NWidth : " << m_ROI_Size.width() << "\tNHeight : " << m_ROI_Size.height() << endl;
}


void HandClosedDetection::SetROI_Pt(void)
{
	//m_ROI_Pt.setX(m_handPt.X - m_ROI_Size.width() /2);
	//m_ROI_Pt.setY(m_handPt.Y - m_ROI_Size.height()/2);


	m_ROI_Pt.setX(m_handPt.X > m_ROI_Size.width() /2 ? m_handPt.X - m_ROI_Size.width() /2 : 0);
	m_ROI_Pt.setY(m_handPt.Y > m_ROI_Size.height()/2 ? m_handPt.Y - m_ROI_Size.height()/2 : 0);

	m_ROI_Pt.setX(m_handPt.X < (RES_X - m_ROI_Size.width() /2) ? m_ROI_Pt.x() : RES_X - m_ROI_Size.width()-1);
	m_ROI_Pt.setY(m_handPt.Y < (RES_Y - m_ROI_Size.height()/2) ? m_ROI_Pt.y() : RES_Y - m_ROI_Size.height()-1);


	//cout << "N_x : " << m_ROI_Pt.x() << "\tN_y : " << m_ROI_Pt.y() << endl;

	SetHandPtInROI();
}


QPoint HandClosedDetection::ROI_Pt(void)
{
	return m_ROI_Pt;
}



void HandClosedDetection::AfficheTest(xn::DepthMetaData& dpmd, Mat& matOut)
{
	unsigned int i, j;
	unsigned char imBin[MAX_ROI_SIZE][MAX_ROI_SIZE] = {0};

	for (i=0; i<m_ROI_Size.width(); i++)
		for (j=0; j<m_ROI_Size.height(); j++)
		{
			imBin[j][i] = 255*(int)((dpmd(i+m_ROI_Pt.x(),j+m_ROI_Pt.y()) > m_depthLimitMin) && (dpmd(i+m_ROI_Pt.x(),j+m_ROI_Pt.y()) < m_depthLimitMax));
		}

	matOut = Mat(MAX_ROI_SIZE,MAX_ROI_SIZE,CV_8UC1,imBin);



	QPoint haut, bas, gauche, droite;
	DefinitionPointsCadrage(matOut,haut,bas,gauche,droite);

	// Affichage des 3 points
	int color = 127, taille = 8;
	for (i=0; i<taille; i++)
		for (j=0; j<taille; j++)
		{
			matOut.at<unsigned char>(gauche.y()+j,gauche.x()+i) = color;
			matOut.at<unsigned char>(droite.y()+j,droite.x()+i) = color;
			matOut.at<unsigned char>(haut.y()+j  ,haut.x()+i  ) = color;
			matOut.at<unsigned char>(bas.y()+j   ,bas.x()+i   ) = color;
		}

	namedWindow("test4");
	imshow("test4", matOut);

}



void HandClosedDetection::DefinitionPointsCadrage(Mat& ROI, QPoint& haut, QPoint& bas, QPoint& gauche, QPoint& droite)
{
	unsigned int i, j;
	haut.setX(20);		haut.setY(20);
	bas.setX(50);			bas.setY(50);
	gauche.setX(80);	gauche.setY(80);
	droite.setX(m_handPtInROI.x());	droite.setY(m_handPtInROI.y());

	/*
	for (i = 0; i<boxWidth; i++)
		for (j = 0; j<boxHeight; j++)
			if (ROI.at<unsigned char>(j,i))
			{
				// haut
				if (haut.y()>j)
				{
					haut.setX(i); haut.setY(j);
				}
			}
*/

}



