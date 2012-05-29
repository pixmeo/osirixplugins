#ifndef GRAPHICSVIEW_H
#define GRAPHICSVIEW_H

#include "Parametres.h"

#ifdef _OS_WIN_
	#include <windows.h>
#endif

#include <QtGui>
#include <QtGui/qapplication.h>
#include <QtGui/qgraphicsview.h>
#include <QtCore>


class GraphicsView : public QGraphicsView
{
    Q_OBJECT
public:
    explicit GraphicsView(QGraphicsScene *scene, QWidget *parent = 0);
    virtual void resizeEvent(QResizeEvent *event);
	int getResX();
	int getResY();
	void setSize(int width, int height);
	QPoint Size(void);
	void GraphicsView::setPosition(int x, int y);
signals:

public slots:

private:
    void createUI();
	void moveBottom(GraphicsView* widget);
	int WIDTH;
	int HEIGHT;
	
protected:
    void keyPressEvent(QKeyEvent * event);
	/*void paintEvent(QPaintEvent * event);*/
	

};


#endif //========================== FIN ====================================//







