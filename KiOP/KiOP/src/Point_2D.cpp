
//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Point_2D.h"


//==========================================================================//
//================================ MÉTHODES ================================//

// -------------- Constructeur(s) ---------------- //
Point2D::Point2D() : Point3D()
{
}
Point2D::Point2D(short x, short y) : Point3D(x,y,0)
{
}
Point2D::Point2D(string name) : Point3D(name)
{
}
Point2D::Point2D(short x, short y, string name) : Point3D(x,y,0,name)
{
}


void Point2D::SetCoordinate(const Point2D &pt)
{
	SetX(pt.X());
	SetY(pt.Y());
	SetZ(0);
}
void Point2D::SetCoordinate(const Point3D &pt)
{
	SetX(pt.X());
	SetY(pt.Y());
	SetZ(0);
}
void Point2D::SetCoordinate(short x, short y)
{
	SetX(x);
	SetY(y);
	SetZ(0);
}
void Point2D::SetCoordinate(const XnPoint3D xnPt)
{
	SetX(xnPt.X);
	SetY(xnPt.Y);
	SetZ(0);
}


void Point2D::Afficher(ostream &flux) const
{
	flux << "(" << X() << " ; " << Y() << ")";
}

void Point2D::Print(void) const
{
	cout << m_name << " : ";
	Afficher(cout);
	cout << endl;
}
void Point2D::Print(unsigned short nbEndLine) const
{
	Print();
	for (int i=0; i<nbEndLine; i++)	cout << endl;
}

ostream &operator<<(ostream &flux, const Point2D &pt)
{
	pt.Afficher(flux);
	return flux;
}


//================================= FIN ====================================//







