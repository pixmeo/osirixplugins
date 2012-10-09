
#include "pixmap.h"


Pixmap::Pixmap(const QPixmap &pix, QGraphicsItem *parent)
    : QGraphicsWidget(parent), orig(pix), p(pix)
{
}

void Pixmap::paint(QPainter *painter, const QStyleOptionGraphicsItem *, QWidget *)
{
    painter->drawPixmap(QPointF(), p);
}

void Pixmap::mousePressEvent(QGraphicsSceneMouseEvent * )
{
    emit clicked();
}

void Pixmap::setGeometry(const QRectF &rect)
{
    QGraphicsWidget::setGeometry(rect);

    if (rect.size().width() > orig.size().width())
        p = orig.scaled(rect.size().toSize());
    else
        p = orig;
}


void Pixmap::load(const QPixmap &pix){
	p = pix;
}

int Pixmap::getWidth(){
	return this->p.width();
}