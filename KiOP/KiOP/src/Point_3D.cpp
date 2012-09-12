
//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Point_3D.h"


//==========================================================================//
//================================ MÉTHODES ================================//

// -------------- Constructeur(s) ---------------- //
Point3D::Point3D()
{
	SetX(0); SetY(0); SetZ(0); Rename("NoName");
}
Point3D::Point3D(short x, short y, short z)
{
	SetX(x); SetY(y); SetZ(z); Rename("NoName");
}
Point3D::Point3D(const Point3D &pt)
{
	SetX(pt.X()); SetY(pt.Y()); SetZ(pt.Z()); Rename("NoName");
}
Point3D::Point3D(string name)
{
	SetX(0); SetY(0); SetZ(0); Rename(name);
}
Point3D::Point3D(short x, short y, short z, string name)
{
	SetX(x); SetY(y); SetZ(z); Rename(name);
}
Point3D::Point3D(const Point3D &pt, string name)
{
	SetX(pt.X()); SetY(pt.Y()); SetZ(pt.Z()); Rename(name);
}


// ---------------- Setter(s) ------------------ //
void Point3D::SetX(short x)
{	m_x = x;	}
void Point3D::SetY(short y)
{	m_y = y;	}
void Point3D::SetZ(short z)
{	m_z = z;	}

void Point3D::IcrX(short x)
{	m_x += x;	}
void Point3D::IcrY(short y)
{	m_y += y;	}
void Point3D::IcrZ(short z)
{	m_z += z;	}

void Point3D::Rename(string newName)
{	m_name = newName;	}


// ---------------- Getter(s) ------------------ //
short Point3D::X(void) const
{	return m_x;	}
short Point3D::Y(void) const
{	return m_y;	}
short Point3D::Z(void) const
{	return m_z;	}

string Point3D::Name(void) const
{	return m_name;	}


// ---------------- Afficheur(s) ------------------ //
void Point3D::Afficher(ostream &flux) const
{
	flux << "(" << X() << " ; " << Y() << " ; " << Z() << ")";
}

void Point3D::Print(void) const
{
	cout << Name() << " : ";
	Afficher(cout);
	cout << endl;
}
void Point3D::Print(unsigned short nbEndLine) const
{
	Print();
	for (int i=0; i<nbEndLine; i++)	cout << endl;
}


// --------------- Setters secondaires -------------- //
void Point3D::SetToZero(void)
{
	SetX(0);
	SetY(0);
	SetZ(0);
}

void Point3D::SetCoordinate(const Point3D &pt)
{
	SetX(pt.X());
	SetY(pt.Y());
	SetZ(pt.Z());
}
void Point3D::SetCoordinate(short x, short y, short z)
{
	SetX(x);
	SetY(y);
	SetZ(z);
}
void Point3D::SetCoordinate(const XnPoint3D xnPt)
{
	SetX(xnPt.X);
	SetY(xnPt.Y);
	SetZ(xnPt.Z);
}

void Point3D::IcrCoordinate(const Point3D &pt)
{
	IcrX(pt.X());
	IcrY(pt.Y());
	IcrZ(pt.Z());
}
void Point3D::IcrCoordinate(short x, short y, short z)
{
	IcrX(x);
	IcrY(y);
	IcrZ(z);
}
void Point3D::IcrCoordinate(const XnPoint3D xnPt)
{
	IcrX(xnPt.X);
	IcrY(xnPt.Y);
	IcrZ(xnPt.Z);
}


// ----------- AAAAA ------------ //
float Point3D::Norme(void) const
{
	return sqrt(powf(X(),2) + powf(Y(),2) + powf(Z(),2));
}

Point3D Point3D::Sgn(void) const
{
	Point3D temp;
	temp.SetX(X() >= 0 ? 1 : -1);
	temp.SetY(Y() >= 0 ? 1 : -1);
	temp.SetZ(Z() >= 0 ? 1 : -1);
	return temp;
}


// ----------- Opérateurs Arithmétiques ------------ //

// Operateur addition (+)
Point3D& Point3D::operator+=(const Point3D &pt)
{
	IcrX(pt.X());
	IcrY(pt.Y());
	IcrZ(pt.Z());
	return *this;
}
Point3D operator+(const Point3D &pt1, const Point3D &pt2)
{
	Point3D copie(pt1);
	copie += pt2;
	return copie;
}

// Operateur soustraction (-)
Point3D& Point3D::operator-=(const Point3D &pt)
{
	IcrX(-pt.X());
	IcrY(-pt.Y());
	IcrZ(-pt.Z());
	return *this;
}
Point3D operator-(const Point3D &pt1, const Point3D &pt2)
{
	Point3D copie(pt1);
	copie -= pt2;
	return copie;
}

// Operateur multiplication (*)
Point3D& Point3D::operator*=(const int nb)
{
	SetX(this->X()*nb);
	SetY(this->Y()*nb);
	SetZ(this->Z()*nb);
	return *this;
}
Point3D operator*(const Point3D &pt, const int nb)
{
	Point3D copie(pt);
	copie *= nb;
	return copie;
}

// Operateur division (/)
Point3D& Point3D::operator/=(const int nb)
{
	SetX(this->X()/nb);
	SetY(this->Y()/nb);
	SetZ(this->Z()/nb);
	return *this;
}
Point3D operator/(const Point3D &pt, const int nb)
{
	Point3D copie(pt);
	copie /= nb;
	return copie;
}


// ----------- Opérateurs de Comparaison ------------ //

// Operateur d'égalité (==)
bool operator==(const Point3D &pt1, const Point3D &pt2)
{
	return (pt1.X() == pt2.X() && pt1.Y() == pt2.Y() && pt1.Z() == pt2.Z());
}

// Operateur de différence (!=)
bool operator!=(const Point3D &pt1, const Point3D &pt2)
{
	return !(pt1 == pt2);
}

// Operateur <
Point3D operator<(const Point3D &pt1, const Point3D &pt2)
{
	Point3D temp(pt1.X() < pt2.X(), pt1.Y() < pt2.Y(), pt1.Z() < pt2.Z());
	return temp;
}

// Operateur <=
Point3D operator<=(const Point3D &pt1, const Point3D &pt2)
{
	Point3D temp(pt1.X() <= pt2.X(), pt1.Y() <= pt2.Y(), pt1.Z() <= pt2.Z());
	return temp;
}

// Operateur >
Point3D operator>(const Point3D &pt1, const Point3D &pt2)
{
	Point3D temp(pt1.X() > pt2.X(), pt1.Y() > pt2.Y(), pt1.Z() > pt2.Z());
	return temp;
}

// Operateur >=
Point3D operator>=(const Point3D &pt1, const Point3D &pt2)
{
	Point3D temp(pt1.X() >= pt2.X(), pt1.Y() >= pt2.Y(), pt1.Z() >= pt2.Z());
	return temp;
}


// ----------- Opérateurs de Flux ------------ //
ostream &operator<<(ostream &flux, const Point3D &pt)
{
	pt.Afficher(flux);
	return flux;
}


// ----------- AAAAAA ------------ //
// Renvoie true si le point pt est situé à l'intérieur de la zone formée par les points ptLim1 et ptLim2.
bool EstDansZone(const Point3D& pt, const Point3D& ptLim1, const Point3D& ptLim2)
{
	Point3D temp(ptLim1.X() <= ptLim2.X(), ptLim1.Y() <= ptLim2.Y(), ptLim1.Z() <= ptLim2.Z(), "temp");
	
	if ( pt.X() < (temp.X() ? ptLim1.X() : ptLim2.X()) || pt.X() > (temp.X() ? ptLim2.X() : ptLim1.X())
		|| pt.Y() < (temp.Y() ? ptLim1.Y() : ptLim2.Y()) || pt.Y() > (temp.Y() ? ptLim2.Y() : ptLim1.Y())
		|| pt.Z() < (temp.Z() ? ptLim1.Z() : ptLim2.Z()) || pt.Z() > (temp.Z() ? ptLim2.Z() : ptLim1.Z()) )
		return false;

	return true;
}


// ----------- Fonctions pour listes ------------ //
Point3D MeanListPt3D(const Point3D list[], unsigned short size)
{
	Point3D somme("somme");
	for (int i=0; i<size; i++)
		somme += list[i];
	return (somme/size);
}

void PushListPt3D(const Point3D &pt, Point3D list[], unsigned short size)
{
	for (int i=(size-1); i>0; i--)
		list[i].SetCoordinate(list[i-1]);
	list[0].SetCoordinate(pt);
}

void PrintListPt3D(const Point3D list[], unsigned short size)
{
	for (int i=0; i<size; i++)
		list[i].Print();
}


//================================= FIN ====================================//







