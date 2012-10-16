#ifndef TOOLDOCK_H
#define TOOLDOCK_H

#include "Parametres.h"

#ifdef _OS_WIN_
	#include <windows.h>
#endif

#include <QtGui>
#include <QtGui/qapplication.h>
#include <QtGui/qpixmap.h>
#include <QtCore>
#include "qapplication.h"
#include "graphicsview.h"
#include "pixmap.h"



class ToolDock : public QGraphicsWidget
{
	//Q_OBJECT

public:
	explicit ToolDock(int nItems, QGraphicsItem *parent = 0);
	void addItem(QString name, QString resource);
	GraphicsView* getWindow();
	QGraphicsScene* getScene();
	vector<Pixmap*> getItems();
	int getItemSizeActive();
	int getItemSize();

	void setItemSize(int size);
	void setItemIdlePt(int pos);
	void setItemActivePt(int pos);
	void setItemActive(int item);
	void setItemIdle(int item);
	void createView();

	void setToolsBackgroundTransparent(void);
	void setToolsBackgroundRed(void);

//signals:
//
//public slots:

private:
	
protected:
	int itemSize;
	int itemSizeActive;
	float itemSizeF;
	float itemSizeAlpha;
	float itemIdlePt;
	float itemActivePt;
	int nItems;
	int resX;
	int resY;
	int minItemSize;
	int maxItemSize;
	vector<Pixmap*> items;
	GraphicsView *window;
	QGraphicsScene *scene;
};


#endif // TOOLDOCK_H







