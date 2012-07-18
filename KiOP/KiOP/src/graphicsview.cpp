
#include "graphicsview.h"


GraphicsView::GraphicsView(QGraphicsScene *scene, QWidget *parent) : QGraphicsView(scene, parent)
{
	Q_INIT_RESOURCE(images);

	this->setWindowOpacity(1.0);
	this->setWindowFlags(Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint);
	this->setAttribute(Qt::WA_TranslucentBackground);
	this->setStyleSheet("background: transparent");
	//this->setStyleSheet("background: green");
	//this->setStyleSheet("background-color: rgba(139,137,137,0.5);");
	//this->setStyleSheet("background-image: url(:/images/Resources/background.png)");
	this->setFrameStyle(0);
	this->setAlignment(Qt::AlignLeft | Qt::AlignTop);
	this->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
	this->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
	//QColor bgColor = palette().light().color();
	//bgColor.setAlpha(50);
	
}

void GraphicsView::createUI()
{
	//this->show();
}

void GraphicsView::keyPressEvent(QKeyEvent *event)
{
	if (event->key() == Qt::Key_Escape)
	{
		qApp->quit();
	}
}
void GraphicsView::resizeEvent(QResizeEvent *event)
{
	fitInView(sceneRect(), Qt::KeepAspectRatio);
}

//void GraphicsView::paintEvent(QPaintEvent *event)
//{
//	QColor backgroundColor = palette().light().color();
//	backgroundColor.setAlpha(50);
//	QPainter customPainter(this);
//	customPainter.fillRect(rect(),backgroundColor);
//}


void GraphicsView::moveBottom(GraphicsView* widget)
{
	//int cx = GetSystemMetrics(SM_CXSCREEN);
	//int cy = GetSystemMetrics(SM_CYSCREEN);
	int cx = getResX();
	int cy = getResY();


	int x, y;
	int screenWidth;
	int screenHeight;

	//int WIDTH = 768;
	//int HEIGHT = 256;
	

	QDesktopWidget *desktop = QApplication::desktop();

	screenWidth = desktop->width();
	screenHeight = desktop->height();

	x = (cx - WIDTH);
	y = (cy - HEIGHT);
	/*x = (cx - WIDTH - 8);
	y = (cy - HEIGHT + 40)/2;*/
	/*x = ((cx - WIDTH));
	y = ((cy - HEIGHT-40));*/

	widget->setGeometry(x, y-40, WIDTH, HEIGHT);
	widget->setFixedSize(WIDTH, HEIGHT);
}

int GraphicsView::getResX()
{
	//return GetSystemMetrics(SM_CXSCREEN);
	return SCRSZW;
}
int GraphicsView::getResY()
{
	//return GetSystemMetrics(SM_CYSCREEN);
	return SCRSZH;
}

void GraphicsView::setSize(int width, int height)
{
	this->WIDTH = width;
	this->HEIGHT = height;

	this->createUI();
	this->moveBottom(this);
}

QPoint GraphicsView::Size(void)
{
	QPoint temp;
	temp.setX(WIDTH);
	temp.setY(HEIGHT);
	return temp;
}

void GraphicsView::setPosition(int x, int y)
{

}