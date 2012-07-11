
//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Hand_Closed_Detection.h"


//==========================================================================//
//================================ MÉTHODES ================================//

// Constructeur(s)
HandClosedDetection::HandClosedDetection()
{
	m_compteurFrame = 0;
	m_handClosed = false;
	for (unsigned int i=0;i<NB_CASE_HAND_CLOSED_PREV;i++) m_handClosedPrev[i] = false;
	m_ROI_OutOfCamera = false;
}

// Méthode principale pour la détection de la main fermée :
// Met à jours tous les attributs et appelle les méthodes pour définir le handClosed
void HandClosedDetection::Update(unsigned int methode, const xn::DepthMetaData& dpmd, const Point3D handPt)
{
	IncrementCompteurFrame();
	UpdateHandClosedPrev();
	UpdateHandPt(handPt);
	UpdateDepthLimits();
	UpdateROI_Size();
	UpdateROI_Pt();
	UpdateHandPtInROI();

	if (!m_ROI_OutOfCamera)
	{
		UpdateROI_Data(dpmd);

		if (methode == 1)
			MethodeAireMain(dpmd);
		else if (methode == 2)
			MethodeSurfaceRect(dpmd);
	}
	else
	{
		m_handClosed = false;
	}

	if (m_compteurFrame < 10)
		m_handClosed = false;
}


void HandClosedDetection::MethodeAireMain(const xn::DepthMetaData& dpmd)
{
	Mat dst1, dst2;
	unsigned int tailleElement = 20;
	Mat element1 = getStructuringElement(MORPH_RECT,Size(tailleElement,tailleElement));
	//Mat element2 = getStructuringElement(MORPH_RECT,Size(5,5));

	morphologyEx(m_ROI_Data, dst1, MORPH_CLOSE, element1);
	//morphologyEx(m_ROI_Data, dst2, MORPH_GRADIENT, element2);

	namedWindow("1234m_ROI_Data");
	imshow("1234m_ROI_Data", m_ROI_Data);
	//namedWindow("1234dst1");
	//imshow("1234dst1", dst1);
	//namedWindow("1234dst2");
	//imshow("1234dst2", dst2);

	int aire1 = countNonZero(dst1);

	static int aireS1 = 0, aireS2 = 0, aireS3 = 0, aireS4 = 0, aireSPrec = 0;
	aireSPrec = aireS4;
	aireS4 = aireS3;
	aireS3 = aireS2;
	aireS2 = aireS1;
	aireS1 = aire1;

	static int profS1 = 0, profS2 = 0, profS3 = 0, profS4 = 0, profSPrec = 0;
	profSPrec = profS4;
	profS4 = profS3;
	profS3 = profS2;
	profS2 = profS1;
	profS1 = m_handPt.Z();
	int deltaZ = profS1 - profSPrec;

	//float rapport = 1.0;
	float rapport = ((abs(deltaZ)>10) ? 1.0 : float(aireS1)/float(aireSPrec) );
	//cout << "deltaZ : " << deltaZ << "\trapport : " << rapport << endl;
	//cout << "rapport : " << rapport << endl;

	// Détection de main fermée
	if ((rapport < SEUIL_BAS ))
		m_handClosed = true;
	else if ((rapport > SEUIL_HAUT))
		m_handClosed = false;
}

void HandClosedDetection::MethodeSurfaceRect(const xn::DepthMetaData& dpmd)
{
	QPoint haut, bas, gauche, droite;
	DefinitionPointsCadrage(m_ROI_Data,haut,bas,gauche,droite);

	int largeurSurface = (droite.x() - gauche.x());
	int hauteurSurface = (bas.y() - haut.y());
	//cout << "Largeur : " << largeurSurface << "\tHauteur : " << hauteurSurface << endl;

	static int surface1 = 0, surface2 = 0, surface3 = 0, surface4 = 0, surfacePrec = 0, surfaceMoy = 0, surfaceMoyPrec = 0;
	surfacePrec = surface4;
	surface4 = surface3;
	surface3 = surface2;
	surface2 = surface1;
	surface1 = largeurSurface * hauteurSurface;

	if (!(m_compteurFrame%4))
	{
		surfaceMoyPrec = surfaceMoy;
		surfaceMoy = (surface1+surface2+surface3+surface4)/4;
	}
	//cout << "SurfMoy : " << surfaceMoy;

	static int profS1 = 0, profS2 = 0, profS3 = 0, profS4 = 0, profSPrec = 0;
	profSPrec = profS4;
	profS4 = profS3;
	profS3 = profS2;
	profS2 = profS1;
	profS1 = m_handPt.Z();
	int deltaZ = profS1 - profSPrec;
	//cout << "DeltaZ : " << deltaZ;

	float rapport = ( (abs(deltaZ)>20) ? 1.0 : float(surfaceMoy)/float(surfaceMoyPrec) );
	static const float seuilBas = 0.5, seuilHaut = 1/seuilBas;
	//cout << "Z : " << handPt.Z << "\taire : " << aireS1 << endl;

	// Détection de main fermée
	if ((rapport < seuilBas ))
		m_handClosed = true;
	else if ((rapport > seuilHaut))
		m_handClosed = false;
}


// Défini l'intervalle de distances dans lequel il faut regarder
void HandClosedDetection::UpdateDepthLimits(void)
{
	m_depthLimitMin = m_handPt.Z() - INTERVALLE_PROFONDEUR_DETECTION/2;
	m_depthLimitMax = m_handPt.Z() + INTERVALLE_PROFONDEUR_DETECTION/2;
}
void HandClosedDetection::UpdateDepthLimits(unsigned int handPtZ)
{
	m_depthLimitMin = handPtZ - INTERVALLE_PROFONDEUR_DETECTION/2;
	m_depthLimitMax = handPtZ + INTERVALLE_PROFONDEUR_DETECTION/2;
}

// Récupère les coordonnées 3D du handPoint
void HandClosedDetection::UpdateHandPt(Point3D handPt)
{
	m_handPt = handPt;
}

// Défini les coordonnées de handPointInROI
void HandClosedDetection::UpdateHandPtInROI(void)
{
	m_handPtInROI.setX(m_handPt.X() - m_ROI.Pt().x());
	m_handPtInROI.setY(m_handPt.Y() - m_ROI.Pt().y());
}

// Défini les dimensions du ROI
void HandClosedDetection::UpdateROI_Size(void)
{
	static const float x1 = 500, x2 = 2500;
	static const float y1 = 250, y2 = 50;

	static const int ROI_SizeOffset = 60;
	static const float ROI_SizeCoeffA = (x1*x2) * (y1-y2)/(x2-x1);
	static const float ROI_SizeCoeffB = y1 - ROI_SizeCoeffA/x1 + ROI_SizeOffset;
	int val = (ROI_SizeCoeffA/m_handPt.Z()) + ROI_SizeCoeffB;

	m_ROI.SetSize(val,RAPPORT_DIM_ROI*val); // Un peu moins haut que large

	//cout << "NWidth : " << m_ROI.Size().width() << "\tNHeight : " << m_ROI.Size().height() << endl;
}

// Défini les coordonnées haut-gauche du ROI
void HandClosedDetection::UpdateROI_Pt(void)
{
	m_ROI.SetPt(m_handPt.X() - m_ROI.Size().width() /2,
							m_handPt.Y() - m_ROI.Size().height()/2);

	// Si le ROI est hors de la résolution de la caméra
	if ( (m_ROI.Pt().x() <= 0) || (m_ROI.Pt().y() <= 0) 
		|| ((m_ROI.Pt().x()+m_ROI.Size().width()) >= RES_X) || ((m_ROI.Pt().y()+m_ROI.Size().height()) >= RES_Y) )
		m_ROI_OutOfCamera = true;
	else
		m_ROI_OutOfCamera = false;

	//cout << "N_x : " << m_ROI.Pt().x() << "\tN_y : " << m_ROI.Pt().y() << endl;
}

////== A EFFACER ==//
//// Extrait les données de l'image de profondeur de la zone ROI
//void HandClosedDetection::ExtractionROI(const xn::DepthMetaData& dpmd)
//{
//	unsigned int i, j;
//	unsigned char imBin[MAX_ROI_SIZE][MAX_ROI_SIZE] = {0};
//	unsigned int im2[MAX_ROI_SIZE][MAX_ROI_SIZE] = {0};
//	unsigned int depth = 0;
//
//	//for (i=0; i<=m_ROI.Size().height(); i++)
//	//	for (j=0; j<=m_ROI.Size().width(); j++)
//	//	{
//	//		depth = dpmd(j+m_ROI.Pt().x(),i+m_ROI.Pt().y());
//	//		imBin[i][j] = 255*(int)((depth > m_depthLimitMin) && (depth < m_depthLimitMax));
//	//	}
//
//	for (i=0; i<=m_ROI.Size().height(); i++)
//		for (j=0; j<=m_ROI.Size().width(); j++)
//		{
//			depth = dpmd(j+m_ROI.Pt().x(),i+m_ROI.Pt().y());
//			imBin[i][j] = 255*(int)((depth > m_depthLimitMin) && (depth < m_depthLimitMax));
//			//im2[i][j] = depth;
//			
//		}
//
//	//ROI = Mat(MAX_ROI_SIZE,MAX_ROI_SIZE,CV_8UC1,imBin);
//	m_ROI_Data = Mat(MAX_ROI_SIZE,MAX_ROI_SIZE,CV_8UC1,imBin);
//	//m_ROI_Data2 = Mat(MAX_ROI_SIZE,MAX_ROI_SIZE,CV_8UC1,im2);
//
//	//Mat test;
//	//UpdateROI_Data(dpmd,test);
//	//UpdateROI_Data(dpmd);
//
//	//Display_ROI(ROI);
//	//namedWindow("1234m_ROI_Data");
//	//imshow("1234dst1", m_ROI_Data);
//	//namedWindow("1234test",CV_WINDOW_AUTOSIZE);
//	//imshow("1234test", test);
//
//
//}

// Extrait les données de l'image de profondeur de la zone ROI
void HandClosedDetection::UpdateROI_Data(const xn::DepthMetaData& dpmd)
{
	int i, j;
	int cols = dpmd.XRes();
	int rows = dpmd.YRes();

	// Acquisition de l'image de profondeur
	Mat depthMap;
	depthMap.create(rows, cols, CV_16UC1);
	const XnDepthPixel* pDepthMap = dpmd.Data();
	CV_Assert(sizeof(unsigned short) == sizeof(XnDepthPixel));
	memcpy(depthMap.data, pDepthMap, cols*rows*sizeof(XnDepthPixel));

	// Définition de la ROI
	Mat depthMapROI (depthMap, Rect(m_ROI.Pt().x(), m_ROI.Pt().y(), m_ROI.Size().width(), m_ROI.Size().height()));

	// Binarisation de la ROI (MAJ de m_ROI_Data)
	m_ROI_Data = (depthMapROI > m_depthLimitMin) & (depthMapROI < m_depthLimitMax);

	//// Collage de la ROI binaire sur l'image de profondeur
	//depthMapROI.setTo(Scalar::all(255*256), m_ROI_Data);
	//depthMapROI.setTo(Scalar::all(0), (m_ROI_Data==0));

	//// Collage du cadre de la ROI sur l'image de profondeur
	//for (i=-1; i<m_ROI.Size().width(); i++)
	//	for (j=0; j<=1; j++)
	//		depthMapROI.at<unsigned short>(j*m_ROI.Size().height()-1,i) = 255*256;
	//for (i=0; i<=1; i++)
	//	for (j=-1; j<m_ROI.Size().height(); j++)
	//		depthMapROI.at<unsigned short>(j,i*m_ROI.Size().width()-1) = 255*256;

	//// Affichage de l'image de profondeur
	//namedWindow("1234depthMap",CV_WINDOW_AUTOSIZE);
	//imshow("1234depthMap", depthMap);
}


void HandClosedDetection::Display_ROI(Mat& ROI)
{
	//int i, j;
	unsigned int color = 127;

	QPoint haut, bas, gauche, droite;
	DefinitionPointsCadrage(ROI,haut,bas,gauche,droite);

	// Affichage des 3 points
	if (0)
	{
		unsigned int taille = 8;
		for (unsigned int i=0; i<taille; i++)
			for (unsigned int j=0; j<taille; j++)
			{
				ROI.at<unsigned char>(gauche.y()+j,gauche.x()+i) = color;
				ROI.at<unsigned char>(droite.y()+j,droite.x()+i) = color;
				ROI.at<unsigned char>(haut.y()+j  ,haut.x()+i  ) = color;
				ROI.at<unsigned char>(bas.y()+j   ,bas.x()+i   ) = color;
			}
	}

	// Affichage du cadre
	if (1)
	{
		for (int i=gauche.x(); i<=droite.x(); i++)
			for (int j=haut.y(); j<=bas.y(); j++)
			{
				if ( (j==haut.y()) || (j==bas.y()) || (i==gauche.x()) || (i==droite.x()) )
					ROI.at<unsigned char>(j,i) = color;
			}
	}

	namedWindow("123456789");
	imshow("123456789", ROI);

}


QPoint HandClosedDetection::ROI_Pt(void) const
{
	return m_ROI.Pt();
}

QSize HandClosedDetection::ROI_Size(void) const
{
	return m_ROI.Size();
}


void HandClosedDetection::DefinitionPointsCadrage(Mat& ROI, QPoint& haut, QPoint& bas, QPoint& gauche, QPoint& droite)
{
	//unsigned int i, j;
	droite.setX(m_handPtInROI.x());	droite.setY(m_handPtInROI.y());

	// Point Haut //
	haut.setX(0);		haut.setY(0);
	for (int j=0; j<m_handPtInROI.y(); j++)
		for (int i=0; i<m_ROI.Size().width(); i++)
			if (ROI.at<unsigned char>(j,i) && !haut.y())
			{
				haut.setX(i); haut.setY(j);
			}

	// Point Bas //
	bas.setX(haut.x());		bas.setY(0.6*(m_ROI.Size().height() + haut.y()));

	// Point Gauche //
	gauche.setX(0);		gauche.setY(0);
	for (int i=0; i<m_handPtInROI.x(); i++)
		for (int j=haut.y(); j<bas.y(); j++)
			if (ROI.at<unsigned char>(j,i) && !gauche.x())
			{
				gauche.setX(i); gauche.setY(j);
			}

	// Point Droite //
	droite.setX(0);		droite.setY(0);
	for (int i=m_ROI.Size().width(); i>m_handPtInROI.x(); i--)
		for (int j=haut.y(); j<bas.y(); j++)
			if (ROI.at<unsigned char>(j,i) && !droite.x())
			{
				droite.setX(i); droite.setY(j);
			}


}



void HandClosedDetection::IncrementCompteurFrame(void)
{
	m_compteurFrame++;
}

void HandClosedDetection::ResetCompteurFrame(void)
{
	m_compteurFrame = 0;
}

int HandClosedDetection::CompteurFrame(void) const
{
	return m_compteurFrame;
}


void HandClosedDetection::UpdateHandClosedPrev(void)
{
	unsigned int i;
	for (i=(NB_CASE_HAND_CLOSED_PREV-1); i>0; i--)
		m_handClosedPrev[i] = m_handClosedPrev[i-1];
	m_handClosedPrev[0] = m_handClosed;
	
	//cout << endl << "handPrev : ";
	//for (i=0; i<NB_CASE_HAND_CLOSED_PREV; i++)
	//	cout << m_handClosedPrev[i];
}

bool HandClosedDetection::HandClosed(void) const
{
	return m_handClosed;
}

bool HandClosedDetection::HandClosedPrev(unsigned int val) const
{
	return m_handClosedPrev[val];
}

bool HandClosedDetection::HandClosedFlancMont(void) const
{
	return (m_handClosed && !m_handClosedPrev[0]);
}

bool HandClosedDetection::HandClosedFlancDesc(void) const
{
	return (!m_handClosed && m_handClosedPrev[0]);
}

bool HandClosedDetection::HandClosedClic(unsigned int val) const
{
	return (!m_handClosedPrev[val] && m_handClosedPrev[0] && !m_handClosed);
}

bool HandClosedDetection::HandClosedStateChanged() const
{
	return (HandClosedFlancMont() || HandClosedFlancDesc());
}


//================================= FIN ====================================//







