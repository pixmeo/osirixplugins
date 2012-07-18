
#ifndef __POINT_3D__
#define __POINT_3D__


//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include <iostream>
#include <string>
using namespace std;

#include <XnTypes.h>
#include "math.h"


//==========================================================================//
//=============================== CONSTANTES ===============================//




//==========================================================================//
//================================ CLASSES =================================//

class Point3D
{
public :

	// -------------- Constructeur(s) ---------------- //
	Point3D();
	Point3D(short x, short y, short z);
	Point3D(const Point3D &pt);
	Point3D(string name);
	Point3D(short x, short y, short z, string name);
	Point3D(const Point3D &pt, string name);

	// ---------------- Setter(s) ------------------ //
	void SetX(short x);
	void SetY(short y);
	void SetZ(short z);
	void IcrX(short x);
	void IcrY(short y);
	void IcrZ(short z);
	void Rename(string newName);

	// ---------------- Accesseur(s) ------------------ //
	short X(void) const;
	short Y(void) const;
	short Z(void) const;
	string Name(void) const;

	// ---------------- Afficheur(s) ------------------ //
	void Afficher(ostream &flux) const;
	void Print(void) const;
	void Print(unsigned short nbEndLine) const;

	// --------------- Setters secondaires -------------- //
	void SetToZero(void);
	void SetCoordinate(const Point3D &pt);
	void SetCoordinate(short x, short y, short z);
	void SetCoordinate(const XnPoint3D xnPt);
	void IcrCoordinate(const Point3D &pt);
	void IcrCoordinate(short x, short y, short z);
	void IcrCoordinate(const XnPoint3D xnPt);

	// ----------- AAAAA ------------ //
	float Norme(void) const;
	Point3D Sgn(void) const;

	// ----------- Opérateurs Arithmétiques ------------ //
	Point3D& operator+=(const Point3D &pt);
	Point3D& operator-=(const Point3D &pt);
	Point3D& operator*=(const int nb);
	Point3D& operator/=(const int nb);

protected :
	short m_x, m_y, m_z;
	string m_name;

};

// ----------- Opérateurs Arithmétiques ------------ //
Point3D operator+(const Point3D &pt1, const Point3D &pt2);
Point3D operator-(const Point3D &pt1, const Point3D &pt2);
Point3D operator*(const Point3D &pt, const int nb);
Point3D operator/(const Point3D &pt, const int nb);

// ----------- Opérateurs de Comparaison ------------ //
bool operator==(const Point3D &pt1, const Point3D &pt2);
bool operator!=(const Point3D &pt1, const Point3D &pt2);
Point3D operator<(const Point3D &pt1, const Point3D &pt2);
Point3D operator<=(const Point3D &pt1, const Point3D &pt2);
Point3D operator>(const Point3D &pt1, const Point3D &pt2);
Point3D operator>=(const Point3D &pt1, const Point3D &pt2);

// ----------- Opérateurs de Flux ------------ //
ostream &operator<<(ostream &flux, const Point3D &pt);

bool EstDansZone(const Point3D& pt, const Point3D& ptLim1, const Point3D& ptLim2);

// ----------- Fonctions pour listes ------------ //
Point3D MeanListPt3D(const Point3D list[], unsigned short size);
void PushListPt3D(const Point3D &pt, Point3D list[], unsigned short size);
void PrintListPt3D(const Point3D list[], unsigned short size);


#endif //========================== FIN ====================================//







