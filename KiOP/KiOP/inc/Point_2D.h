
#ifndef __POINT_2D__
#define __POINT_2D__


//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Point_3D.h"


//==========================================================================//
//=============================== CONSTANTES ===============================//




//==========================================================================//
//================================ CLASSES =================================//

class Point2D : public Point3D
{
public :

	Point2D();
	Point2D(short x, short y);
	Point2D(string name);
	Point2D(short x, short y, string name);

	void SetCoordinate(const Point2D &pt);
	void SetCoordinate(const Point3D &pt);
	void SetCoordinate(short x, short y);
	void SetCoordinate(const XnPoint3D xnPt);

	void Afficher(ostream &flux) const;
	void Print(void) const;
	void Print(unsigned short nbEndLine) const;

protected :

};

ostream &operator<<(ostream &flux, const Point2D &pt);


#endif //========================== FIN ====================================//







