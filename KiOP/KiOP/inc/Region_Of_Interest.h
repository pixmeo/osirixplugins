
#ifndef __REGION_OF_INTEREST__
#define __REGION_OF_INTEREST__


//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include <iostream>

#include "Parametres.h"
#include <QSize>
#include <QPoint>

#include <XnTypes.h>
#include "XnCppWrapper.h"
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/highgui/highgui.hpp"

using namespace std;
using namespace cv;


//==========================================================================//
//=============================== CONSTANTES ===============================//

#define MAX_ROI_SIZE 250


//==========================================================================//
//================================ CLASSES =================================//



class RegionOfInterrest
{
public :

	// Constructeurs //
	RegionOfInterrest();
	RegionOfInterrest(QPoint pt, QSize size);

	void SetPt(QPoint newPoint);
	void SetPt(unsigned int x, unsigned int y);
	void SetSize(QSize newSize);
	void SetSize(unsigned int width, unsigned int height);

	QPoint Pt(void) const;
	QSize Size(void) const;

private :

	QSize m_size;
	QPoint m_pt;

};


#endif //========================== FIN ====================================//







