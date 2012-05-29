
//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Region_Of_Interest.h"


//==========================================================================//
//================================ MÉTHODES ================================//

RegionOfInterrest::RegionOfInterrest(void)
{
	m_pt.setX(0); m_pt.setY(0);
	m_size.setWidth(0); m_size.setHeight(0);
}
RegionOfInterrest::RegionOfInterrest(QPoint pt, QSize size)
{
	m_pt.setX(pt.x()); m_pt.setY(pt.y());
	m_size.setWidth(size.width()); m_size.setHeight(size.height());
}

void RegionOfInterrest::SetPt(QPoint newPoint)
{
	m_pt = newPoint;
}
void RegionOfInterrest::SetPt(unsigned int x, unsigned int y)
{
	m_pt.setX(x);
	m_pt.setY(y);
}

void RegionOfInterrest::SetSize(QSize newSize)
{
	m_size = newSize;
}
void RegionOfInterrest::SetSize(unsigned int width, unsigned int height)
{
	m_size.setWidth(width);
	m_size.setHeight(height);
}


QSize RegionOfInterrest::Size(void) const
{
	return m_size;
}

QPoint RegionOfInterrest::Pt(void) const
{
	return m_pt;
}





