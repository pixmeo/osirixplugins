
//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Parametres.h"
#include "main.h"


//==========================================================================//
//=========================== VARIABLES GLOBALES ===========================//

// 0: Inactive; 1: in menu; 2: tool chosen
int currentState = 0;
int lastState = 0;
int moveCounter = 0;

// 0: Zoom; 1: Contrast; 2: Move
int currentTool = 3; 
int lastTool = 3;
int toolToChoose = -1; 
int totalTools = 6; // +1
int positionTool[7]; //position des outils dans le menu
int afficheTool[7]; //affichage des outils

//Layout
int totalLayoutTools = 6; //+1
int currentLayout = 0;
int currentLayoutTool = 0;
int lastLayoutTool = 0;
bool layoutSelected = false;

float iconIdlePt = 192.0;
float iconActivePt = 64.0;
xn::Context context;
xn::DepthGenerator dpGen;
xn::DepthMetaData dpMD;
xn::HandsGenerator myHandsGenerator;
XnStatus status;

int depthRefVal = 0;
bool realDepth = false;
float lastX = 0.0;
float lastY = 0.0;
float lastZ = 0.0;
//number of frames after which we collect point data
int nFrames = 2; 
//actual frame number
int actualFrame = 0; 
int moveThreshold = 4;
float handDepthLimit;
float handSurfaceLimit;
// Paramètre de profondeur de la main
float handDepthThreshold = 50.0;
float handSurfaceThreshold = 50.0;
bool handDown = false;
int cptHand = 0;
int handFrames = 5;

bool handClosed = false;
bool handStateChanged = false;
bool handFlancMont = false;
bool handFlancDesc = false;
bool handClic = false;
bool lastHandClosed = false;

bool toolSelectable = false;
bool methodeMainFermeeSwitch = false;

// NITE
bool activeSession = false;
bool steadyState = false;
bool steady2 = false;
XnVSessionManager *sessionManager;
XnVPointControl *pointControl;
XnPoint3D handPt;
XnPoint3D lastPt;
XnVFlowRouter* g_pFlowRouter;
XnFloat g_fSmoothing = 0.0f;

// Qt
#ifdef _OS_WIN_
	int qargc = 0;
	char **qargv = NULL;
	QApplication app(qargc,qargv);
#endif
GraphicsView *window;
GraphicsView *windowActiveTool;
QGraphicsScene *sceneActiveTool;
GraphicsView *viewLayouts;
vector<Pixmap*> pix; //for main tools
vector<Pixmap*> pixL; //for layouts
Pixmap* pixActive; //for activeTool
QColor toolColorActive = Qt::green;
QColor toolColorInactive = Qt::gray;

// KiOP //
CursorQt cursorQt;
HandClosedDetection hCD;
HandPoint hP;




//==========================================================================//
//============================== FONCTIONS =================================//

// Fonction d'initialisation
void Initialisation(void)
{
	ostringstream oss;
	const int nb(4);
	Point3D liste[nb];
	for (int i=0; i<nb; i++)
	{
		oss << i;
		liste[i].SetCoordinate(i*2,-i*3,-i*4);
		liste[i].Rename("liste[" + oss.str() + "]");
		oss.seekp(0);
	}

	cout << "= = = = = = = = = = = = = = = =" << endl;
	cout << "\tINITIALISAAAAAAAATION" << endl;
	cout << "= = = = = = = = = = = = = = = =" << endl << endl;
	cout << "Resolution d'ecran : " << SCRSZW << "x" << SCRSZH << endl << endl;

	#ifdef _OS_WIN_
		ChangeCursor(0);
		InitGestionCurseurs();
	#endif
}

// Fonction de fermeture du programme
void CleanupExit()
{
	context.Shutdown();
	exit(1);
}


// Incrémente une valeur sans jamais dépasser les bornes sup et inf
void IcrWithLimits(int &val, const int icr, const int limUp, const int limDown)
{
	val += icr;
	if (val > limUp) val = limUp;
	if (val < limDown) val = limDown;
}


inline bool isHandPointNull()
{
	return ((handPt.X == -1) ? true : false);
}


void chooseTool(int &currentTool, int &lastTool, int &totalTools)
{
	if (hP.DetectLeft())
	{
		if (moveCounter > 0)
			moveCounter = 0;
		moveCounter -= (hP.LastHandPt().X() - hP.HandPt().X());
	}
	else if (hP.DetectRight())
	{
		if (moveCounter < 0)
			moveCounter = 0;
		moveCounter -= (hP.LastHandPt().X() - hP.HandPt().X());
	}

	#if TEST_FLUIDITE
		//vitesse dans le menu en fonction de la distance
		int seuil = 20 - (abs(hP.Speed().X())+(hP.HandPt().Z()/300))/3;
	#else
		int seuil = 6;
	#endif

	//cout << "Seuil : " << seuil << endl;
	if (moveCounter <= -seuil)
	{
		// Go left in the menu
		lastTool = currentTool;
		IcrWithLimits(currentTool,-1,totalTools,0);
		moveCounter = 0;
	}
	else if (moveCounter >= seuil)
	{
		// Go right in the menu
		lastTool = currentTool;
		IcrWithLimits(currentTool,1,totalTools,0);
		moveCounter = 0;
	}
}

void browse(int currentTool, int lastTool, vector<Pixmap*> pix)
{
	//only set the pixmap geometry when needed 
	if (lastTool != currentTool)
	{
        //pix.operator[](lastTool)->hide();
        pix.operator[](currentTool)->hide();
		if (currentTool == 0)
			pix.operator[](currentTool)->setGeometry(QRectF( (currentTool*128.0), iconIdlePt-64, 128.0, 128.0));//for zooming on the tool
		else
			pix.operator[](currentTool)->setGeometry(QRectF( (currentTool*128.0)-32, iconIdlePt-64, 128.0, 128.0));//for zooming on the tool
        pix.operator[](currentTool)->show();
		pix.operator[](lastTool)->setGeometry(QRectF( lastTool*128.0, iconIdlePt, 64.0, 64.0));
        //pix.operator[](lastTool)->show();
	}
}

void detectHandDown()
{
	//code à ameliorer/////////////////////////////
	//quitter la session lorsqu'on baisse la main
	handDown = false;
	if (hP.HandPt().Z() < 1500)
	{
		if (hP.HandPt().Y() > lastPt.Y+150)
		{
			handDown = true;
		}
	}
	else if((hP.HandPt().Z() < 2100)&&(hP.HandPt().Z()>=1500))
	{
		if (hP.HandPt().Y() > lastPt.Y+130)
		{
			handDown = true;
		}
	}
	else if(hP.HandPt().Z() > 2100)
	{
		if (hP.HandPt().Y() > lastPt.Y+100)
		{
			handDown = true;
		}
	}

	//test de la vitesse
	//int detectHighSpeed = 20 - (abs(hP.Speed().X())+(hP.HandPt().Z()/300))/3;
	
}

void handleState()
{
	static TelnetClient telnet;
	//cout << currentState << endl;

	bool inIntervalleX = (hP.HandPt().X() < handSurfaceLimit+handSurfaceThreshold)&&(hP.HandPt().X() > handSurfaceLimit-handSurfaceThreshold); // Booléen pour indiquer si la main est dans le bon intervelle de distance en X
	bool inIntervalleZ = (hP.HandPt().Z() < handDepthLimit+handDepthThreshold); // Booléen pour indiquer si la main est dans le bon intervelle de distance en Z

	detectHandDown();
	if (toolSelectable){
		if(abs((hP.Speed().X())+(hP.HandPt().Z()/300)) > 40){
			handDown = true;	
			cout << abs(hP.Speed().X())+(hP.HandPt().Z()/300) << endl;
		}
	}
	switch(currentState)
	{
		case -2 :
			if (!handClosed) // ?
			{
				currentState = 1;
			}

		// L'outil a été sélectionné
		case -1 :
			if (lastState == 1)
			{
				pix.operator[](currentTool)->setGeometry(QRectF( currentTool*128.0, iconIdlePt, 64.0, 64.0));
				window->hide();
				windowActiveTool->show();
				//pixActive->show();
				pixActive->load(QPixmap(":/images/"+pix.operator[](currentTool)->objectName()+".png").scaled(128,128));
				windowActiveTool->setBackgroundBrush(QBrush(toolColorInactive, Qt::SolidPattern));
				if (currentTool==totalTools)
					currentState = 2;
				lastTool = currentTool;
				lastState = currentState;
			}

			if (1)
			{
				windowActiveTool->hide();
				currentState = 2;
				windowActiveTool->show();
				//pixActive->load(QPixmap(":/images/Resources/activeTool/_"+pix.operator[](currentTool)->objectName()+".png").scaled(128,128));
				windowActiveTool->setBackgroundBrush(QBrush(toolColorActive, Qt::SolidPattern));
				//timerOut = false;
				handDepthLimit = hP.HandPt().Z();
				handSurfaceLimit = hP.HandPt().X();
				switch(currentTool){
					case 0:
						telnet.sendCommand(QString("\r\ndcmview2d:mouseLeftAction bonjour\r\n"));
						break;
					case 1:
						telnet.sendCommand(QString("\r\ndcmview2d:mouseLeftAction pan\r\n"));
						break;
					case 2:
						telnet.sendCommand(QString("\r\ndcmview2d:mouseLeftAction winLevel\r\n"));
						break;
					case 3:
						telnet.sendCommand(QString("\r\ndcmview2d:mouseLeftAction zoom\r\n"));
						break;
					case 4:
						telnet.sendCommand(QString("\r\ndcmview2d:mouseLeftAction sequence\r\n"));
						break;
					case 5:
						telnet.sendCommand(QString("\r\ndcmview2d:mouseLeftAction bonjour\r\n"));
						break;
					case 6:
						telnet.sendCommand(QString("\r\ndcmview2d:mouseLeftAction bonjour\r\n"));
						break;

				}
			}
			break;

		// En attente d'un coucou
		case 0 :
			steady2 = false;
			steadyState = false;
			break;

		// Coucou effectué, afficher le menu
		case 1 :
			Steady2Enable();
			Steady10Disable();
			Steady20Disable();
			if (lastState == 0)
			{
				viewLayouts->hide();
				windowActiveTool->hide();
                window->show();
//				for (int i=0; i<=totalTools; i++)
//				{
//					pix.operator[](i)->setGeometry(QRectF( i*128.0, iconIdlePt, 64.0, 64.0));
//					pix.operator[](i)->show();
//				}
				lastState = currentState;
				telnet.connexion();
				toolSelectable = false;
				toolToChoose = -1;
				layoutSelected = false;
			}

			//if (!handClosed)
			//{
				if (!toolSelectable){
					window->setWindowOpacity(qreal(0.4));
				}else{
					chooseTool(currentTool, lastTool, totalTools);
					browse(currentTool,lastTool, pix);
					window->setWindowOpacity(qreal(1.0));
				}
			/*}*/

			// Si la main est fermée, on choisi un outil
			//if (0)
			//cout << "handClosed: " << handClosed << " ; lastHandClosed: " << lastHandClosed << endl;
			if (toolSelectable)
			{	
				if (handClosed && !lastHandClosed){
					toolToChoose = currentTool;
				}
				if (lastHandClosed && !handClosed){
					if (currentTool == toolToChoose){
						lastState = currentState;
						currentState = -1;
						nFrames = 2;
						moveThreshold = 4;
						cout << "Tool selected" << endl;
						telnet.connexion();
					}
				}
			}

			//if (!toolSelectable)
			//{
			//	MenuTransparent();
			//}
			//else
			//{
			//	MenuOpaque();
			//}
			break;

		// L'outil a été selectionné
		case 2 :
			Steady10Enable();
			Steady20Enable();
			windowActiveTool->setBackgroundBrush(QBrush(toolColorActive, Qt::SolidPattern));
			switch(currentTool)
			{
				// Zoom
				case 3 :
					//if (handPt.Z < handDepthLimit+handDepthThreshold)
					if (handClosed)
					{
						if (hP.DetectBackward())
						{
							#if !TEST_FLUIDITE
							for (int i=0; i<3; i++)
							#endif
							{
								telnet.sendCommand(QString("\r\ndcmview2d:zoom -i 1\r\n"));
							}
						}
						else if(hP.DetectForward())
						{
							#if !TEST_FLUIDITE
							for (int i=0; i<3; i++)
							#endif
							{
								telnet.sendCommand(QString("\r\ndcmview2d:zoom -d 1\r\n"));
							}
						}
						else { }
					}
					else
					{
						windowActiveTool->setBackgroundBrush(QBrush(toolColorInactive, Qt::SolidPattern));
					}
					break;

				// Contraste
				case 2 :
					if (handClosed)
					{
						int valX = (int)(lastX-hP.HandPt().X());//((hP.Speed().X())+(hP.HandPt().Z()/300));
						int valY = (int)(hP.LastHandPt().Y()-hP.HandPt().Y());//((hP.Speed().Y())+(hP.HandPt().Z()/300));
						cout << valX << " ; " << valY << endl;
						telnet.sendCommand(QString("\r\ndcmview2d:wl -- %1 %2\r\n").arg(valX).arg(valY));
						//telnet.sendCommand(QString("\r\ndcmview2d:wl -- %1 %2\r\n").arg(valX).arg(valY));
					} 
					else
					{
						windowActiveTool->setBackgroundBrush(QBrush(toolColorInactive, Qt::SolidPattern));
					}
					break;

				// Translation
				case 1 :
					if (handClosed)
					{
						int valX = (int)(lastX-hP.HandPt().X());//((hP.Speed().X())+(hP.HandPt().Z()/300))/2;
						int valY = (int)(hP.LastHandPt().Y()-hP.HandPt().Y());	//-((hP.Speed().Y())+(hP.HandPt().Z()/300))/2;
						cout << valX << " ; " << valY << endl;
						telnet.sendCommand(QString("\r\ndcmview2d:move -- %1 %2\r\n").arg(valX).arg(valY));
						//telnet.sendCommand(QString("\r\ndcmview2d:move -- %1 %2\r\n").arg(valX).arg(valY));
					} 
					else
					{
						windowActiveTool->setBackgroundBrush(QBrush(toolColorInactive, Qt::SolidPattern));
					}
					break;

				// Scroll
				case 4 :
					//if (handPt.Z < handSurfaceLimit+handSurfaceThreshold) //&& (handDepthLimit-40 < handPt.Z)){
					//if (handPt.Z < handDepthLimit+handDepthThreshold) {
					if (handClosed)
					{
						if (hP.DetectBackward())
						{
							#if !TEST_FLUIDITE
							for (int i=0; i<-(lastZ-hP.HandPt().Z())/6; i++)
							#endif
							{
								telnet.sendCommand(QString("\r\ndcmview2d:scroll -i 1\r\n"));
							}
						}
						else if (hP.DetectForward())
						{
							#if !TEST_FLUIDITE
							for (int i=0; i<(lastZ-hP.HandPt().Z())/6; i++)
							#endif
							{
								telnet.sendCommand(QString("\r\ndcmview2d:scroll -d 1\r\n"));
							}
						}
						else { }
					} 
					else
					{
						windowActiveTool->setBackgroundBrush(QBrush(toolColorInactive, Qt::SolidPattern));
					}
					break;

				// Souris
				case 5 :
					if (!handClosed)
					{
						lastState = currentState;
						currentState = 3;						// MODE SOURIS
						cursorQt.NewCursorSession();
					}
					break;

				// Layouts (currentTool = 5 , -5, -55)
				case 0 :
					//window->hide();
					//pix.operator[](currentTool)->hide();
					windowActiveTool->hide();
					viewLayouts->show();
					if (!handClosed)
					{
						currentTool = -5;
						toolToChoose = -1;
						cout << "Menu des Layouts" << endl;
					}
					break;

				case -5:
					//cout << "Menu des Layouts" << endl;
					chooseTool(currentLayoutTool, lastLayoutTool, totalLayoutTools);
					browse(currentLayoutTool,lastLayoutTool, pixL);
					//if (handClosed)
					if (handClosed && !lastHandClosed){
						toolToChoose = currentLayoutTool;
					}
					if (lastHandClosed && !handClosed){
						if (currentLayoutTool == toolToChoose){
							cout << "Layout selectionne" << endl;
							viewLayouts->hide();
							switch(currentLayoutTool)
							{
								case 0 :
									telnet.sendCommand(QString("\r\ndcmview2d:layout -i 1x1\r\n"));
									break;
								case 1 :
									telnet.sendCommand(QString("\r\ndcmview2d:layout -i 1x2\r\n"));
									break;
								case 2 :
									telnet.sendCommand(QString("\r\ndcmview2d:layout -i 2x1\r\n"));
									break;
								case 3 :
									telnet.sendCommand(QString("\r\ndcmview2d:layout -i layout_c1x2\r\n"));
									break;
								case 4 :
									telnet.sendCommand(QString("\r\ndcmview2d:layout -i layout_c2x1\r\n"));
									break;
								case 5 :
									telnet.sendCommand(QString("\r\ndcmview2d:layout -i 2x2\r\n"));
									break;
								case 6 :
									currentTool = -55;
									break;
							}
							layoutSelected = true;
							if (currentLayoutTool != 6){
								currentTool = 0;
								//layoutSelected = false;
							}
							
						}
					}
					break;

				case -55:
					if (!handClosed){
						cout << "quit layout" << endl;
					}
					break;
				// Croix (exit)
				case 6 :
					cout << lastTool << endl;
					sessionManager->EndSession();
					telnet.deconnexion();
					windowActiveTool->hide();
					viewLayouts->hide();
                    window->hide();
					//currentTool = 0;
					//currentState = 0;
					//switch(currentLayoutTool)
					break;
			}

			// Pour quitter l'outil et revenir dans le menu
			if ( ( steadyState && (!handClosed) && (currentState != 3) && (currentTool != -5) && (currentTool != -55)) 
					|| ((currentTool == -55) && (layoutSelected)) )
			{
				cout << "Sortie de l'outil, retour au menu" << endl;
				lastState = 0;
				currentState = 1;
				nFrames = 2;
				moveThreshold = 4;
				windowActiveTool->hide();
				viewLayouts->hide();
                window->show();
//				for (int i=0; i<=totalTools; i++)
//				{
//					pix.operator[](i)->setGeometry(QRectF( i*128.0, iconIdlePt, 64.0, 64.0));
//					pix.operator[](i)->show();
//				}
				currentTool=totalTools;
				lastTool=0;
				XnPoint3D ptTemp;
				ptTemp.X = hP.HandPt().X();
				ptTemp.Y = hP.HandPt().Y();
				ptTemp.Z = hP.HandPt().Z();
				lastPt = ptTemp;
				//toolSelectable = false;
				layoutSelected = false;
				Steady2Disable();

				//steadyState = false;
			}
			break;

		// Mouse control
		case 3 :

			if (cursorQt.InCursorSession())
			{
				// Distance limite de la main au capteur
				if (hP.HandPt().Z() < (handDepthLimit + handDepthThreshold))
				{
					cursorQt.SetMoveEnable();
					cursorQt.SetClicEnable();
					windowActiveTool->setBackgroundBrush(QBrush(toolColorActive, Qt::SolidPattern));
					if (handFlancMont)
						pixActive->load(QPixmap(":/images/mouse_fermee.png").scaled(128,128));
					else if (handFlancDesc)
						pixActive->load(QPixmap(":/images/mouse.png").scaled(128,128));
				}
				else
				{
					cursorQt.SetMoveDisable();
					cursorQt.SetClicDisable();
					windowActiveTool->setBackgroundBrush(QBrush(toolColorInactive, Qt::SolidPattern));
				}

				// Appel de la méthode pour déplacer le curseur
				cursorQt.MoveCursor(hP.HandPt());
			}

			// Sortie du mode souris
			else
			{
				lastState = currentState;
				currentState = 1;
				pix.operator[](currentTool)->setGeometry(QRectF( lastTool*128.0, iconIdlePt, 64.0, 64.0));
				currentTool = totalTools;
				lastTool = 0;
				windowActiveTool->hide();
                window->show();
//				for (int i=0; i<=totalTools; i++)
//				{
//					pix.operator[](i)->show();
				//	pix.operator[](currentTool)->setGeometry(QRectF( currentTool*128.0, iconIdlePt, 64.0, 64.0));
//				}
				
				//break;
			}
			break;
	}
	if (handDown)
	{
		telnet.deconnexion();
		sessionManager->EndSession();
		currentState=0;
		windowActiveTool->hide();
		viewLayouts->hide();
		currentTool=totalTools;
		lastTool=0;
		XnPoint3D ptTemp;
		ptTemp.X = hP.HandPt().X();
		ptTemp.Y = hP.HandPt().Y();
		ptTemp.Z = hP.HandPt().Z();
		lastPt = ptTemp;
		toolSelectable = false;
		for (int i=0; i<=totalTools; i++){
			pix.operator[](currentTool)->setGeometry(QRectF( currentTool*128.0, iconIdlePt, 64.0, 64.0));
		}
	}
}


void glutKeyboard (unsigned char key, int x, int y)
{
	static int test = 0;
	float tmp = 0.0;
	switch (key)
	{

	// Exit
	case 27 :
		#ifdef _OS_WIN_
			ChangeCursor(0);
		#endif
		CleanupExit();
		break;

	case 'i' :
		hP.IncrementSmooth(1,1,1);
		//hP.Smooth().Print();
		//hP.HandPt().Print();
		IcrWithLimits(test,3,10,0);
		cout << "test : " << test << endl;
		break;

	case 'o' :
		hP.IncrementSmooth(-1,-1,-1);
		//hP.Smooth().Print();
		IcrWithLimits(test,-3,10,0);
		cout << "test : " << test << endl;
		break;

	case 's' :
		// Toggle smoothing
		if (g_fSmoothing == 0)
			g_fSmoothing = 0.1;
		else 
			g_fSmoothing = 0;
		myHandsGenerator.SetSmoothing(g_fSmoothing);
		break;

	case 'a' :
		//show some data for debugging purposes
		cout << "x= " << hP.HandPt().X() << " ; y= " << hP.HandPt().Y() << " ; z= " << hP.HandPt().Z() << " ;   " << g_fSmoothing << " ;   " << currentState << endl;
		break;

	case 'y' :
		//show tools position
		for (int i=0; i<=totalTools; i++)
		{
			cout << "tool" << i << " : " << positionTool[i] << endl;
		}
		break;

	case 'e' :
		// end current session
		lastState = currentState;
		currentState = 0;
		sessionManager->EndSession();
		break;

	//case 't' :
	//	methodeMainFermeeSwitch = !methodeMainFermeeSwitch;
	//	cout << "Switch Methode main fermee (" << (methodeMainFermeeSwitch?2:1) << ")" << endl;
	//	break;

	case '1' :
		RepositionnementFenetre(1);
		break;
	case '2' :
		RepositionnementFenetre(2);
		break;
	case '3' :
		RepositionnementFenetre(3);
		break;
	case '4' :
		RepositionnementFenetre(4);
		break;
	}
}



void glutDisplay()
{
	static unsigned compteurFrame = 0; compteurFrame++;

	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	//clear the gl buffers
	status = context.WaitAnyUpdateAll();	//first update the context - refresh the depth/image data coming from the sensor
	
	// if the update failed, i.e. couldn't be read
	if(status != XN_STATUS_OK)
	{
		cout << "\nERROR:Read failed... Quitting!\n" << endl;	//print error message
		exit(0);	//exit the program
	}
	else
	{
		if(activeSession)
			sessionManager->Update(&context);
		dpGen.GetMetaData(dpMD);
		long xSize = dpMD.XRes();
		long ySize = dpMD.YRes();
		long totalSize = xSize * ySize;

		const XnDepthPixel*	depthMapData;
		depthMapData = dpMD.Data();

		int i, j, colorToSet;
		int depth;

		glLoadIdentity();
		glOrtho(0, xSize, ySize, 0, -1, 1);

		glBegin(GL_POINTS);
		for(i=0;i<xSize;i+=RES_WINDOW_GLUT)	// width
		{
			for(j=0;j<ySize;j+=RES_WINDOW_GLUT)	// height
			{
				depth = dpMD(i,j);
				colorToSet = MAX_COLOR - (depth/COLORS);

				if((depth < DP_FAR) && (depth > DP_CLOSE))
				{
					if (activeSession)
					{
						if (hP.HandPt().Z() < DISTANCE_MAX_DETECTION)
						{
							glColor3ub(0,colorToSet,0);
						}
						else
						{
							glColor3ub(colorToSet,0,0);
						}
					}
					else
						glColor3ub(colorToSet,colorToSet,colorToSet);
					glVertex2i(i,j);
				}
			}
		}
		glEnd();	// End drawing sequence



		if (hP.Steady2())
		{
			//cout << "  STEADY 02\n";
			toolSelectable = true;
		}
		if (hP.Steady10())
		{
			//cout << "  STEADY 1\n";
			if (currentState != 4)
			{
				// Mode souris
				if (currentState == 3)
				{
					cursorQt.SteadyDetected(10);
				}
				else
				{
					steadyState = true;
				}
			}
		}
		if (hP.Steady20())
		{
			//cout << "  STEADY 2\n";
			// Mode souris
			if (currentState == 3)
			{
				cursorQt.SteadyDetected(20);
			}

			// Autres outils
			else if (currentState == 2)
			{
				steady2 = true;
			}
		}
		if (hP.NotSteady())
		{
			//cout << "\n NOT STEADY \n";
			steadyState = false;

			// Mode souris
			if (currentState == 3)
			{
				//cursor.NotSteadyDetected();
			}
		}

		// Mise à jour de la detection de la main fermee
		if	( activeSession && (isHandPointNull() == false))
			UpdateHandClosed();

		if	( activeSession && (isHandPointNull() == false))
		{

			//cout << "Vitesse : " << hP.Speed() << endl;
			//cout << "handpt : " << hP.HandPt().Z() << endl;


			int size = 5;						// Size of the box
			glColor3f(255,255,255);	// Set the color to white
			glBegin(GL_QUADS);
				glVertex2i(hP.HandPtBrut().X()-size,hP.HandPtBrut().Y()-size);
				glVertex2i(hP.HandPtBrut().X()+size,hP.HandPtBrut().Y()-size);
				glVertex2i(hP.HandPtBrut().X()+size,hP.HandPtBrut().Y()+size);
				glVertex2i(hP.HandPtBrut().X()-size,hP.HandPtBrut().Y()+size);
			glEnd();

			size = 4;
			glColor3f(0,0,255);
			glBegin(GL_QUADS);
				glVertex2i(hP.HandPtBrutFiltre().X()-size,hP.HandPtBrutFiltre().Y()-size);
				glVertex2i(hP.HandPtBrutFiltre().X()+size,hP.HandPtBrutFiltre().Y()-size);
				glVertex2i(hP.HandPtBrutFiltre().X()+size,hP.HandPtBrutFiltre().Y()+size);
				glVertex2i(hP.HandPtBrutFiltre().X()-size,hP.HandPtBrutFiltre().Y()+size);
			glEnd();

			size = 5;
			glColor3f(255,0,0);
			glBegin(GL_QUADS);
				glVertex2i(hP.HandPt().X()-size,hP.HandPt().Y()-size);
				glVertex2i(hP.HandPt().X()+size,hP.HandPt().Y()-size);
				glVertex2i(hP.HandPt().X()+size,hP.HandPt().Y()+size);
				glVertex2i(hP.HandPt().X()-size,hP.HandPt().Y()+size);
			glEnd();
		}

		//========== HAND POINT ==========//
		if	( activeSession && (isHandPointNull() == false)
				&& (hCD.ROI_Pt().x() >= 0)
				&& (hCD.ROI_Pt().y() >= 0)
				&& (hCD.ROI_Pt().x() <= (RES_X - hCD.ROI_Size().width()))
				&& (hCD.ROI_Pt().y() <= (RES_Y - hCD.ROI_Size().height())) )
		{
			// Cadre de la main
			glColor3f(255,255,255);
			glBegin(GL_LINE_LOOP);
				glVertex2i(hCD.ROI_Pt().x(), hCD.ROI_Pt().y());
				glVertex2i(hCD.ROI_Pt().x()+hCD.ROI_Size().width(), hCD.ROI_Pt().y());
				glVertex2i(hCD.ROI_Pt().x()+hCD.ROI_Size().width(), hCD.ROI_Pt().y()+hCD.ROI_Size().height());
				glVertex2i(hCD.ROI_Pt().x(), hCD.ROI_Pt().y()+hCD.ROI_Size().height());
			glEnd();



			if (handStateChanged)
			{
				steadyState = false; //sd.Reset();
				steady2 = false; //sd2.Reset();
			}

			// mode Souris
			if ((currentState == 3) && (cursorQt.InCursorSession()))
			{
				// Souris SteadyClic
				if			(cursorQt.CursorType() == 1)
				{
					//if (cursor.CheckExitMouseMode())
					//if (cursorQt.ExitMouseMode())
						//cursor.ChangeState(0);
				}

				//Souris HandClosedClic
				else if ((cursorQt.CursorType() == 2) && (cursorQt.CursorInitialised()))
				{
					if (handFlancMont)
						cursorQt.SetHandClosed(true);
					else if (handFlancDesc)
						cursorQt.SetHandClosed(false);
				}
			}

			// Affichage des carrés de couleurs pour indiquer l'etat de la main
			if (handClosed)
				glColor3ub(255,0,0);
			else 
				glColor3ub(0,0,255);
			int cote = 50;
			int carreX = xSize-(cote+10), carreY = 10;
			glRecti(carreX,carreY,carreX+cote,carreY+cote);
		}
	}
	glutSwapBuffers();

#if TEST_FLUIDITE
	handleState();
	lastX = hP.HandPt().X();
	lastY = hP.HandPt().Y();
	lastZ = hP.HandPt().Z();
#else
	if (actualFrame >= nFrames)
	{
		handleState();
		actualFrame = -1;
	}
	else if(actualFrame == 0)
	{
		lastX = hP.HandPt().X();
		lastY = hP.HandPt().Y();
		lastZ = hP.HandPt().Z();
	}
	actualFrame = actualFrame+1;
#endif
}


void UpdateHandClosed(void)
{
	if (toolSelectable)
	{
		hCD.Update((methodeMainFermeeSwitch?2:1),dpMD,hP.HandPtBrut());
		handStateChanged = hCD.HandClosedStateChanged();
		handFlancMont = hCD.HandClosedFlancMont();
		handFlancDesc = hCD.HandClosedFlancDesc();
		lastHandClosed = handClosed;
		handClosed = hCD.HandClosed();
		handClic = hCD.HandClosedClic(19); //9

		//// Controle de detection de la main fermee //
		//if (handStateChanged)
		//	cout << endl << "\t\tChgmt d'etat de la main!" << endl;
		//if (handFlancMont)
		//	cout << endl << "\t\tFermeture de la main!" << endl;
		//if (handFlancDesc)
		//	cout << endl << "\t\tOuverture de la main!" << endl;
		////if (handClosed)
		////	cout << endl << "\t\tMain Fermee!" << endl;
		////else
		////	cout << endl << "\t\tMain Ouverte!" << endl;
		//if (handClic)
		//	cout << endl << "\t\tClic de la main!" << endl;
	}
}


void initGL(int argc, char *argv[])
{
	glutInit(&argc,argv);
	glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH);
	glutInitWindowSize(INIT_WIDTH_WINDOW, INIT_HEIGHT_WINDOW);

	// Fenêtre de données source
	glutCreateWindow(TITLE);
	RepositionnementFenetre(INIT_POS_WINDOW);
	glutKeyboardFunc(glutKeyboard);
	glutDisplayFunc(glutDisplay);

	// Idle callback (pour toutes les fenêtres)
	glutIdleFunc(glutDisplay);
	glDisable(GL_DEPTH_TEST);
	glEnable(GL_TEXTURE_2D);
}


//==========================================================================//
//================================= MAIN ===================================//

int main(int argc, char *argv[])
{
	Initialisation();

	//------ OPEN_NI / NITE / OPENGL ------//
	xn::EnumerationErrors errors;

    String path = argv[0];
    int p = path.find(".app");
    path = path.substr(0,p+4).append("/Contents/Resources/openni.xml");
    
	status = context.InitFromXmlFile(path.c_str());
	CHECK_ERRORS(status, errors, "InitFromXmlFile");
	CHECK_STATUS(status, "InitFromXml");

	//si le context a été initialisé correctement
	status = context.FindExistingNode(XN_NODE_TYPE_DEPTH, dpGen);
	CHECK_STATUS(status, "Find depth generator");
	status = context.FindExistingNode(XN_NODE_TYPE_HANDS, myHandsGenerator);
	CHECK_STATUS(status, "Find hands generator");

	// NITE 
	sessionManager = new XnVSessionManager();

	//Focus avec un coucou et Refocus avec "RaiseHand" 
	status = sessionManager->Initialize(&context,"Wave","Wave,RaiseHand");
	CHECK_STATUS(status,"Session manager");

	sessionManager->RegisterSession(&context,sessionStart,sessionEnd, FocusProgress);
	sessionManager->SetQuickRefocusTimeout(5000);

	g_pFlowRouter = new XnVFlowRouter;

	pointControl = new XnVPointControl("Point Tracker");
	pointControl->RegisterPrimaryPointCreate(&context,pointCreate);
	pointControl->RegisterPrimaryPointDestroy(&context,pointDestroy);
	pointControl->RegisterPrimaryPointUpdate(&context,pointUpdate);

	// Wave detector
	XnVWaveDetector waveDetect;
	waveDetect.RegisterWave(&context,&Wave_Detected);
	//waveDetect.SetFlipCount(10);
	//waveDetect.SetMaxDeviation(1);
	//waveDetect.SetMinLength(100);

	// Add Listener
	sessionManager->AddListener(pointControl);
	sessionManager->AddListener(g_pFlowRouter);
	sessionManager->AddListener(&waveDetect);
		
	nullifyHandPoint();
	myHandsGenerator.SetSmoothing(g_fSmoothing);

	// Initialization done. Start generating
	status = context.StartGeneratingAll();
	CHECK_STATUS(status, "StartGenerating");

	initGL(argc,argv);


	// Qt
#ifdef _OS_MAC_
	int qargc = 0;
	char **qargv = NULL;
	QApplication app(qargc,qargv);
#endif
    cursorQt = CursorQt(2);
	window = new GraphicsView(NULL);
	windowActiveTool = new GraphicsView(NULL);
	sceneActiveTool = new QGraphicsScene(0,0,128,128);
	viewLayouts = new GraphicsView(NULL);
	pixActive = new Pixmap(QPixmap()); //for activeTool




	//================== QT ===================//

	// Initialisation des ressources et création de la fenêtre avec les icônes
	Q_INIT_RESOURCE(images);

#if defined _OS_WIN_
	Pixmap *p1 = new Pixmap(QPixmap(":/images/layout.png").scaled(64,64));
	Pixmap *p2 = new Pixmap(QPixmap(":/images/move.png").scaled(64,64));
	Pixmap *p3 = new Pixmap(QPixmap(":/images/contrast.png").scaled(64,64)); 
	Pixmap *p4 = new Pixmap(QPixmap(":/images/zoom.png").scaled(64,64));
	Pixmap *p5 = new Pixmap(QPixmap(":/images/scroll.png").scaled(64,64));
	Pixmap *p6 = new Pixmap(QPixmap(":/images/mouse.png").scaled(64,64));
	Pixmap *p7 = new Pixmap(QPixmap(":/images/stop.png").scaled(64,64));
#elif defined _OS_MAC_
	Pixmap *p1 = new Pixmap(QPixmap(":/images/layout.png").scaled(64,64));
	Pixmap *p2 = new Pixmap(QPixmap(":/images/move.png").scaled(64,64));
	Pixmap *p3 = new Pixmap(QPixmap(":/images/contrast.png").scaled(64,64));
	Pixmap *p4 = new Pixmap(QPixmap(":/images/zoom.png").scaled(64,64));
	Pixmap *p5 = new Pixmap(QPixmap(":/images/scroll.png").scaled(64,64));
	Pixmap *p6 = new Pixmap(QPixmap(":/images/mouse.png").scaled(64,64));
	Pixmap *p7 = new Pixmap(QPixmap(":/images/stop.png").scaled(64,64));
#endif

	p1->setObjectName("layout");
	p2->setObjectName("move");
	p3->setObjectName("contrast");
	p4->setObjectName("zoom");
	p5->setObjectName("scroll");
	p6->setObjectName("mouse");
	p7->setObjectName("stop");

	p1->setGeometry(QRectF(  0.0, iconIdlePt, 64.0, 64.0));
	p2->setGeometry(QRectF(128.0, iconIdlePt, 64.0, 64.0));
	p3->setGeometry(QRectF(256.0, iconIdlePt, 64.0, 64.0));
	p4->setGeometry(QRectF(384.0, iconIdlePt, 64.0, 64.0));
	p5->setGeometry(QRectF(512.0, iconIdlePt, 64.0, 64.0));
	p6->setGeometry(QRectF(640.0, iconIdlePt, 64.0, 64.0));
	p7->setGeometry(QRectF(768.0, iconIdlePt, 64.0, 64.0));

	pix.push_back(p1);
	pix.push_back(p2);
	pix.push_back(p3);
	pix.push_back(p4);
	pix.push_back(p5);
	pix.push_back(p6);
	pix.push_back(p7);

	//window->setSize(1024,288);
	window->setSize(896,256);
	
	//window->setSize(548,window->getResY()-100);
	QGraphicsScene *scene = new QGraphicsScene(0,0,896,256);
	//QGraphicsScene *scene = new QGraphicsScene(0,(-window->getResY())+488,548,window->getResY()-100);
	scene->addItem(p1);
	scene->addItem(p2);
	scene->addItem(p3);
	scene->addItem(p4);
	scene->addItem(p5);
	scene->addItem(p6);
	scene->addItem(p7);
	window->setScene(scene);

	sceneActiveTool->addItem(pixActive);
	//windowActiveTool->setSize(126,126);
	windowActiveTool->setScene(sceneActiveTool);
	windowActiveTool->setGeometry(window->getResX()-128,window->getResY()-168,128,128);


	////////////// LAYOUT
#if defined _OS_WIN_
	Pixmap *l1 = new Pixmap(QPixmap(":/images/layouts/_1x1.png").scaled(64,64));
	Pixmap *l2 = new Pixmap(QPixmap(":/images/layouts/_1x2.png").scaled(64,64));
	Pixmap *l3 = new Pixmap(QPixmap(":/images/layouts/_2x1.png").scaled(64,64));
	Pixmap *l4 = new Pixmap(QPixmap(":/images/layouts/_3a.png").scaled(64,64));
	Pixmap *l5 = new Pixmap(QPixmap(":/images/layouts/_3b.png").scaled(64,64));
	Pixmap *l6 = new Pixmap(QPixmap(":/images/layouts/_2x2.png").scaled(64,64));
	Pixmap *l7 = new Pixmap(QPixmap(":/images/stop.png").scaled(64,64));
#elif defined _OS_MAC_
	Pixmap *l1 = new Pixmap(QPixmap(":/images/layouts/_1x1.png").scaled(64,64));
	Pixmap *l2 = new Pixmap(QPixmap(":/images/layouts/_1x2.png").scaled(64,64));
	Pixmap *l3 = new Pixmap(QPixmap(":/images/layouts/_2x1.png").scaled(64,64));
	Pixmap *l4 = new Pixmap(QPixmap(":/images/layouts/_3a.png").scaled(64,64));
	Pixmap *l5 = new Pixmap(QPixmap(":/images/layouts/_3b.png").scaled(64,64));
	Pixmap *l6 = new Pixmap(QPixmap(":/images/layouts/_2x2.png").scaled(64,64));
	Pixmap *l7 = new Pixmap(QPixmap(":/images/stop.png").scaled(64,64));
#endif

	l1->setObjectName("1x1");
	l2->setObjectName("1x2");
	l3->setObjectName("2x1");
	l4->setObjectName("3a");
	l5->setObjectName("3b");
	l6->setObjectName("2x2");
	l7->setObjectName("stop");
	
	l1->setGeometry(QRectF(  0.0, iconIdlePt, 64.0, 64.0));
	l2->setGeometry(QRectF(128.0, iconIdlePt, 64.0, 64.0));
	l3->setGeometry(QRectF(256.0, iconIdlePt, 64.0, 64.0));
	l4->setGeometry(QRectF(384.0, iconIdlePt, 64.0, 64.0));
	l5->setGeometry(QRectF(512.0, iconIdlePt, 64.0, 64.0));
	l6->setGeometry(QRectF(640.0, iconIdlePt, 64.0, 64.0));
	l7->setGeometry(QRectF(768.0, iconIdlePt, 64.0, 64.0));

	pixL.push_back(l1);
	pixL.push_back(l2);
	pixL.push_back(l3);
	pixL.push_back(l4);
	pixL.push_back(l5);
	pixL.push_back(l6);
	pixL.push_back(l7);

	viewLayouts->setSize(896,256);
	QGraphicsScene *sceneLayout = new QGraphicsScene(0,0,896,256);
	sceneLayout->addItem(l1);
	sceneLayout->addItem(l2);
	sceneLayout->addItem(l3);
	sceneLayout->addItem(l4);
	sceneLayout->addItem(l5);
	sceneLayout->addItem(l6);
	sceneLayout->addItem(l7);
	viewLayouts->setScene(sceneLayout);

	//viewLayouts->show();

	
	/*for(int i=0; i<=totalTools; i++){
		QString chemin = ":/images/Resources/_"+pix.operator[](i)->objectName()+".png";
		//printf("\n"+chemin.toAscii()+"\n");
		int posi = positionTool[i];
		pix.operator[](i)->setGeometry(QRectF( posi*60.0, posi*(-10.0), 128.0, 128.0));
		pix.operator[](i)->load(QPixmap(chemin).scaled(78+(posi*(10)),78+(posi*(10))));
	}*/

	// Boucle principale
	glutMainLoop();
	
	return app.exec();
}



/**** CALLBACK DEFINITIONS ****/

/**********************************************************************************
Session started event handler. Session manager calls this when the session begins
**********************************************************************************/
void XN_CALLBACK_TYPE sessionStart(const XnPoint3D& ptPosition, void* UserCxt)
{
	activeSession = true;
	cout << "Debut de la session " << currentState << endl;
	window->show();

	lastState = 0;
	currentState = 1;
	toolSelectable = false;
	//MenuTransparent();
	steadyState = false;
	steady2 = false;
	Steady2Enable();
	Steady10Disable();
	Steady20Disable();
	hCD.ResetCompteurFrame();
}

/**********************************************************************************
session end event handler. Session manager calls this when session ends
**********************************************************************************/
void XN_CALLBACK_TYPE sessionEnd(void* UserCxt)
{
	activeSession = false;
	cout << "Fin de la session" << endl;
	window->hide();
	viewLayouts->hide();
	lastState = currentState;
	currentState = 0;
	Steady2Disable();
	Steady10Disable();
	Steady20Disable();
}

/**********************************************************************************
point created event handler. this is called when the pointControl detects the creation
of the hand point. This is called only once when the hand point is detected
**********************************************************************************/
void XN_CALLBACK_TYPE pointCreate(const XnVHandPointContext *pContext, const XnPoint3D &ptFocus, void *cxt)
{
	XnPoint3D coords(pContext->ptPosition);
	dpGen.ConvertRealWorldToProjective(1,&coords,&handPt);
	lastPt = handPt;

	hP.Update(handPt);
}
/**********************************************************************************
Following the point created method, any update in the hand point coordinates are 
reflected through this event handler
**********************************************************************************/
void XN_CALLBACK_TYPE pointUpdate(const XnVHandPointContext *pContext, void *cxt)
{
	XnPoint3D coords(pContext->ptPosition);
	dpGen.ConvertRealWorldToProjective(1,&coords,&handPt);

	hP.Update(handPt);
}
/**********************************************************************************
when the point can no longer be tracked, this event handler is invoked. Here we 
nullify the hand point variable 
**********************************************************************************/
void XN_CALLBACK_TYPE pointDestroy(XnUInt32 nID, void *cxt)
{
	lastState = currentState;
	currentState = 0;
	windowActiveTool->hide();
//	for (int i=0; i<=totalTools; i++)
//	{
//		pix.operator[](i)->show();
//	}
	window->hide();
	nullifyHandPoint();
	cout << "Point detruit" << endl;
}


// Callback for no hand detected
void XN_CALLBACK_TYPE NoHands(void* UserCxt)
{
	cursorQt.EndCursorSession();
}

// Callback for when the focus is in progress
void XN_CALLBACK_TYPE FocusProgress(const XnChar* strFocus, 
		const XnPoint3D& ptPosition, XnFloat fProgress, void* UserCxt)
{
	//cout << "Focus progress: " << strFocus << " @(" << ptPosition.X << "," 
	//			<< ptPosition.Y << "," << ptPosition.Z << "): " << fProgress << "\n" << endl;

	/// Pour réafficher l'écran s'il s'est éteint
	SimulateCtrlBar();
}


// Callback for wave
void XN_CALLBACK_TYPE Wave_Detected(void *pUserCxt)
{
	cout << "\n WAVE \n";
}


void SimulateCtrlBar(void)
{
#if defined _OS_WIN_
	// Simulate a key press
	keybd_event(VK_LCONTROL,0x45,KEYEVENTF_EXTENDEDKEY | 0,0);
	// Simulate a key release
	keybd_event(VK_LCONTROL,0x45,KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP,0);
#endif
}


void MenuTransparent(void)
{
	window->setWindowOpacity(qreal(0.4));
}

void MenuOpaque(void)
{
	window->setWindowOpacity(qreal(1.0));
}


