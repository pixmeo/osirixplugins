#ifndef PIXMAP_H
#define PIXMAP_H

#include <QtGui>
#include <QtGui/qapplication.h>
#include <QtGui/qgraphicswidget.h>
#include <QtGui/qpixmap.h>


class Pixmap : public QGraphicsWidget
{
    Q_OBJECT
public:
    explicit Pixmap(const QPixmap &pix, QGraphicsItem *parent = 0);
    void paint(QPainter *painter, const QStyleOptionGraphicsItem *, QWidget *);
    virtual void mousePressEvent(QGraphicsSceneMouseEvent * );
    virtual void setGeometry(const QRectF &rect);
	virtual void load(const QPixmap &pix);
	int getWidth();

Q_SIGNALS:
    void clicked();

private:
    QPixmap orig;
    QPixmap p;

signals:

public slots:

};


#endif //========================== FIN ====================================//







