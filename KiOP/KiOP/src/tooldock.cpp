
#include "tooldock.h"


ToolDock::ToolDock(int nItems, QGraphicsItem *parent) : QGraphicsWidget(parent)
{
	//this->resX = QApplication::desktop()->width();
	//this->resY = QApplication::desktop()->height();

	QDesktopWidget screen;
	QRect screenGeom = screen.screenGeometry();

	this->resX = screenGeom.width();
	this->resY = screenGeom.height();

	this->minItemSize = 64;
	this->maxItemSize = 160;

	this->itemSizeAlpha = 1.5;

	this->window = new GraphicsView(NULL);
	this->scene = new QGraphicsScene(NULL);

	//calculate the itemSize
	this->itemSize = (float)(this->resX)/(float)(nItems)/this->itemSizeAlpha;
	if (itemSize > this->maxItemSize){
		itemSize = this->maxItemSize;
	}
	else if (itemSize < this->minItemSize){
		itemSize = this->minItemSize;
	}

	this->itemIdlePt = itemSize*(itemSizeAlpha-1);
	this->itemActivePt = 0;
	this->itemSizeActive = (int)(itemSize + itemSize/2);
	
	this->nItems = 0;

	setToolsBackgroundTransparent();

	//cout << "itemSize: " << itemSize << endl;
	//cout << "itemActiveSize: " << itemSizeActive << endl;
}

void ToolDock::addItem(QString name, QString resource)
{
	Pixmap *p = new Pixmap(QPixmap(QString(resource)).scaled(itemSize,itemSize));
	p->setObjectName(name);

	this->items.push_back(p);
	this->scene->addItem(p);
	nItems++;
}

//Creates the GraphicsView
void ToolDock::createView(){

	//place the items in the window
	for (int i=0; i<this->nItems; i++){
		this->items[i]->setGeometry(QRectF((this->itemSizeAlpha*i*itemSize)+(itemSize/2), itemIdlePt, itemSize, itemSize));
	}

	//Calculate our GraphicsView size knowing number of items
	//	and screen resolution
	int width = (int)((itemSize*this->itemSizeAlpha*((float)(this->nItems)))+(this->itemSize/2));
	int height = itemSize*itemSizeAlpha;

	cout << "window: " << width << "," << height << endl;
	this->scene->setSceneRect(0,0,width,height);
	this->window->setSize(width,height);
	this->window->setScene(this->scene);
}

GraphicsView* ToolDock::getWindow()
{
	return this->window;
}


QGraphicsScene* ToolDock::getScene()
{
	return this->scene;
}

vector<Pixmap*> ToolDock::getItems()
{
	return this->items;
}

int ToolDock::getItemSize()
{
	return this->itemSize;
}

int ToolDock::getItemSizeActive()
{
	return this->itemSizeActive;
}

void ToolDock::setItemSize(int size)
{
	this->itemSize = size;
}

void ToolDock::setItemIdlePt(int pos)
{
	this->itemIdlePt = pos;
}

void ToolDock::setItemActivePt(int pos)
{
	this->itemActivePt = pos;
}


void ToolDock::setItemActive(int item){
	//this->items[item]->hide();
	//this->items[item]->setGeometry(QRectF((itemSizeAlpha*item*itemSize)+(itemSize/4), itemActivePt, itemSizeActive+5, itemSizeActive+5));
	//this->items[item]->setScale(itemSizeActive/(float)this->items[item]->getWidth());
	//QString itemName = this->items[item]->objectName();
	//this->items[item] = new Pixmap(QPixmap(":/images/"+itemName+".png").scaled(itemSizeActive, itemSizeActive));
	//this->items.at(item) = new Pixmap(QPixmap(":/images/"+itemName+".png").scaled(itemSizeActive, itemSizeActive));
	//this->items[item]->setGeometry(QRectF((itemSizeAlpha*item*itemSize)+(itemSize/4), itemActivePt, itemSizeActive, itemSizeActive));
	//this->items[item]->load(QPixmap(":/images/"+itemName+".png").scaled(itemSizeActive, itemSizeActive));
	this->items[item]->setGeometry(QRectF((itemSizeAlpha*item*itemSize)+(itemSize/4), itemActivePt, itemSizeActive, itemSizeActive));
	//this->items[item]->setScale(itemSizeActive/(float)this->items[item]->getWidth());
	/*cout << "aleft: " << itemSizeAlpha*item*itemSize << "; atop:" << itemActivePt << endl;
	cout << "setScale: " << itemSizeActive/(float)this->items[item]->getWidth() << endl;*/
	//this->items[item]->show();
}

void ToolDock::setItemIdle(int item){
	//this->items[item]->setScale(itemSize/this->items[item]->getWidth());
	//this->items[item]->setScale(0.3);
	//this->items[item]->setGeometry(QRectF((itemSizeAlpha*item*itemSize)+(itemSize/2), itemIdlePt, itemSize, itemSize));
	//this->items[item]->setGeometry(QRectF((itemSizeAlpha*item*itemSize)+(itemSize/2), this->window->size().height() - itemIdlePt, itemSize, itemSize));
	this->items[item]->setGeometry(QRectF((itemSizeAlpha*item*itemSize)+(itemSize/2), itemIdlePt, itemSize, itemSize));
	//this->items[item]->setScale(itemSize/(float)this->items[item]->getWidth());
	//this->items[item]->setScale(itemSize/this->items[item]->getWidth());
	
}


void ToolDock::setToolsBackgroundTransparent(void)
{
	window->setBackgroundBrush(Qt::NoBrush);
	//window->setBackgroundBrush(QBrush(Qt::blue, Qt::SolidPattern));
	window->setWindowOpacity(qreal(1.0));
}
void ToolDock::setToolsBackgroundRed(void)
{
	window->setBackgroundBrush(QBrush(Qt::red, Qt::SolidPattern));
	window->setWindowOpacity(qreal(0.7));
}





//ToolDock& ToolDock::operator=(const ToolDock &pt)
//{
//
//	return *this;
//}

















