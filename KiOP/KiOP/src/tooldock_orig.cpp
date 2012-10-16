
#include "tooldock.h"


ToolDock::ToolDock(int nItems, QGraphicsItem *parent) : QGraphicsWidget(parent)
{
	this->resX = QApplication::desktop()->width();
	this->resY = QApplication::desktop()->height();
	this->itemSize = 128;
	this->itemSizeAlpha = 1.5;
	this->itemSizeActive = 192;
	this->itemSizeF = (float) this->itemSize;
	this->itemIdlePt = 192.0;
	this->itemActivePt = 64.0;
	this->nItems = nItems;
	this->minItemSize = 64;
	this->maxItemSize = 160;
	this->window = new GraphicsView(NULL);
	//this->scene = new QGraphicsScene(0,0,1280,320);
	this->scene = new QGraphicsScene(NULL);
	//cout << resX << "x" << resY << endl;

	//calculate the itemSize
	float itemSize = (float)(this->resX)/(float)(this->nItems)/this->itemSizeAlpha;
	if (itemSize > this->maxItemSize){
		itemSize = this->maxItemSize;
		//cout << "maxSize atteint" << endl;
	}
	else if (itemSize < this->minItemSize){
		itemSize = this->minItemSize;
		//cout << "minSize atteint" << endl;
	}
	//cout << "itemSize: " << itemSize << endl;
	this->itemSize = (int)itemSize;
	this->itemIdlePt = itemSize*this->itemSizeAlpha;
	this->itemActivePt = this->itemIdlePt - (itemSize/2);
	this->itemSizeActive = (int)(itemSize + itemSize/2);
	//cout << "itemActiveSize: " << itemSizeActive << endl;
	this->nItems = 0;
}

void ToolDock::addItem(QString name, QString resource)
{
	Pixmap *p = new Pixmap(QPixmap(QString(resource)).scaled(itemSize,itemSize));
	p->setObjectName(name);
	//p->setGeometry(QRectF(1.5*nItems*itemSize, itemIdlePt, itemSize, itemSize));
	
	this->items.push_back(p);
	this->scene->addItem(p);
	nItems++;
}

//Creates the GraphicsView
void ToolDock::createView(){

	//place the items in the window
	for (int i=0; i<this->nItems; i++){
		this->items[i]->setGeometry(QRectF((this->itemSizeAlpha*i*itemSize)+(itemSize/2), itemIdlePt, itemSize, itemSize));
		//this->items[i]->setScale(itemSize/(float)this->items[i]->getWidth());
	}

	//Calculate our GraphicsView size knowing number of items
	//	and screen resolution
	// width = (size*alpha*nItems)+(size/2)
	int width = (int)((itemSize*this->itemSizeAlpha*((float)(this->nItems)))+(this->itemSize/2));

	//int height = (int)(itemSize*2)+(itemSize/2);


	int height = itemSize*3;



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
	this->items[item]->setGeometry(QRectF((itemSizeAlpha*item*itemSize)+(itemSize/2), itemIdlePt, itemSize, itemSize));
	//this->items[item]->setScale(itemSize/(float)this->items[item]->getWidth());
	//this->items[item]->setScale(itemSize/this->items[item]->getWidth());
	
}


void ToolDock::setToolsBackgroundTransparent(void)
{
	for (int i=0; i<nItems; i++)
	{
		this->items[i]->setOpacity(1.0);
	}
}
void ToolDock::setToolsBackgroundRed(void)
{
	for (int i=0; i<nItems; i++)
	{
		this->items[i]->setOpacity(0.3);
		
	}
}
