
//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Parametres.h"
#include "main.h"


//==========================================================================//
//=========================== VARIABLES GLOBALES ===========================//

// 0: Inactive; 1: Hand calibrating; 2: Main menu; 3: Normal tool mode; 4: Layout mode; 5: Mouse mode; 9: Return to main menu.
int g_currentState = 0;
int g_lastState = 0;
int g_stateBackup = 0;
int g_moveCounter = 0;

// 0: Layout; 1: Move; 2: Contrast; 3: Zoom; 4: Scroll; 5: Mouse; 6: RedCross.
int g_currentTool = 3;
int g_lastTool = 3;
int g_toolToChoose = -1;
int g_totalTools = 7; // +1
int g_positionTool[7]; //position des outils dans le menu

// Layout
int g_totalLayoutTools = 6; //+1
int g_currentLayoutTool = 0;
int g_lastLayoutTool = 0;
bool g_layoutSelected = false;

float g_iconIdlePt = 192.0;
//float g_iconActivePt = 64.0; // ?
xn::Context g_context;
xn::DepthGenerator g_dpGen;
xn::DepthMetaData g_dpMD;
xn::HandsGenerator g_myHandsGenerator;
XnStatus g_status;

// Paramètre de profondeur de la main
//float g_handDepthLimit;
//float g_handDepthThreshold = 50.0;

bool g_handClosed = false;
bool g_handStateChanged = false;
bool g_handFlancMont = false;
bool g_handFlancDesc = false;
bool g_handClic = false;
bool g_lastHandClosed = false;

bool g_toolSelectable = false;
bool g_methodeMainFermeeSwitch = false;

// NITE
bool g_activeSession = false;
XnVSessionManager *gp_sessionManager;
XnVPointControl *gp_pointControl;
XnPoint3D g_handPt;
XnPoint3D g_lastPt;
XnVFlowRouter* g_pFlowRouter;
XnFloat g_fSmoothing = 0.0f;

// Qt
#ifdef _OS_WIN_
	int qargc = 0;
	char **qargv = NULL;
	QApplication app(qargc,qargv);
#endif
GraphicsView *gp_window;
GraphicsView *gp_windowActiveTool;
QGraphicsScene *gp_sceneActiveTool;
GraphicsView *gp_viewLayouts;
vector<Pixmap*> g_pix; //for main tools
vector<Pixmap*> g_pixL; //for layouts
Pixmap* gp_pixActive; //for activeTool
QColor g_toolColorActive = Qt::green;
QColor g_toolColorInactive = Qt::gray;
ToolDock mainTools(g_totalTools+1);
ToolDock layoutTools(g_totalLayoutTools+1);
int pixSize = mainTools.getItemSize();
int pixSizeActive = mainTools.getItemSizeActive();

#ifdef _OS_WIN_
	TelnetClient g_telnet;
#endif

// KiOP //
CursorQt g_cursorQt;
HandClosedDetection g_hCD;
HandPoint g_hP;

string g_openNi_XML_FilePath;


unsigned int g_handDepthAtToolSelection = 0;
const unsigned int g_handDepthThreshold = 40;
const unsigned int g_handDepthMarge = 300;

bool g_tropPres = false;
bool g_tropLoin = false;
bool g_depthIntervalOK = true;


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
	cout << "\tINIATISILATION" << endl;
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
	g_context.Shutdown();
	exit(1);
}


// Incrémente une valeur sans jamais dépasser les bornes sup et inf
void IcrWithLimits(int &val, int icr, int limDown, int limUp)
{
	val += icr;
	if (val > limUp) val = limUp;
	if (val < limDown) val = limDown;
}


inline bool isHandPointNull()
{
	return ((g_handPt.X == -1) ? true : false);
}


void chooseTool(int &currentTool, int &lastTool, int &totalTools)
{
	if (g_hP.DetectLeft())
	{
		if (g_moveCounter > 0)
			g_moveCounter = 0;
		g_moveCounter += g_hP.DeltaHandPt().X();
	}
	else if (g_hP.DetectRight())
	{
		if (g_moveCounter < 0)
			g_moveCounter = 0;
		g_moveCounter += g_hP.DeltaHandPt().X();
	}

	//vitesse dans le menu en fonction de la distance
	int seuil = 20 - (abs(g_hP.Speed().X())+(g_hP.HandPt().Z()/300))/3;

	//cout << "Seuil : " << seuil << endl;
	if (g_moveCounter <= -seuil)
	{
		// Go left in the menu
		lastTool = currentTool;
		IcrWithLimits(currentTool,-1,0,totalTools);
		g_moveCounter = 0;

		g_toolSelectable = true;
		g_pix[g_totalTools]->setOpacity(1.0);
	}
	else if (g_moveCounter >= seuil)
	{
		// Go right in the menu
		lastTool = currentTool;
		IcrWithLimits(currentTool,1,0,totalTools);
		g_moveCounter = 0;
	}
}



//void browse(int currentTool, int lastTool, vector<Pixmap*> pix)
void browse(int currentTool, int lastTool, ToolDock &tools)
{
	//only set the pixmap geometry when needed
	if (lastTool != currentTool)
	{
		// On réduit l'outil précédent
		//pix.operator[](lastTool)->setGeometry(QRectF(lastTool*128.0, g_iconIdlePt, 64.0, 64.0));
		tools.setItemIdle(lastTool);

		// On aggrandi l'outil courant
		//pix.operator[](currentTool)->setGeometry(QRectF( (currentTool*128.0)-(currentTool==0?0:32), g_iconIdlePt-64, 128.0, 128.0));
		tools.setItemActive(currentTool);
	}
}


void CheckHandDown()
{
	if (g_currentState >= 2)
	{
		if (g_hP.Speed().Y() > 24)
		{
			cout << "-- Main baissee, vitesse : " << g_hP.Speed().Y() << endl;
			gp_sessionManager->EndSession();
		}
	}
}

void CheckBaffe()
{
	if (g_currentState >= 2)
	{
		int vitesseBaffe = abs(g_hP.Speed().X()) + abs(g_hP.HandPt().Z()/300);
		if (vitesseBaffe > 34)
		{
			cout << "-- Baffe detectee, vitesse : " << vitesseBaffe << endl;
			gp_sessionManager->EndSession();
		}
	}
}

void CheckDepthIntervals()
{

	unsigned int dMin = DISTANCE_MIN, dMax = DISTANCE_MAX;

	if (g_handDepthAtToolSelection + g_handDepthMarge > DISTANCE_MAX)
		dMax = g_handDepthAtToolSelection + g_handDepthMarge;

	if (g_handDepthAtToolSelection - g_handDepthMarge < DISTANCE_MIN)
		dMin = g_handDepthAtToolSelection - g_handDepthMarge;

	g_tropPres = (g_hP.HandPt().Z() < dMin);
	g_tropLoin = (g_hP.HandPt().Z() > dMax);
	g_depthIntervalOK = !(g_tropPres || g_tropLoin);




	if (!g_depthIntervalOK && g_toolSelectable && g_currentState!=0)
	{
		cout << endl << "-- Main en dehors de l'intervalle" << " distance : " << g_hP.HandPt().Z() << endl << endl;
		g_stateBackup = g_currentState;
			ChangeState(0);
	}
}



bool SelectionDansUnMenu(short currentIcon)
{
	bool temp = false;

	if (g_hP.Steady10())
	{
		temp = true;
		g_hP.SignalResetSteadies();
	}

	return temp;
}



bool ConditionActiveTool()
{
	return (g_hP.HandPt().Z() < g_handDepthAtToolSelection + g_handDepthThreshold);
}

bool ConditionExitTool()
{
	return (g_hP.Steady15() && g_hP.HandPt().Z() > g_handDepthAtToolSelection + g_handDepthThreshold);
}


bool ConditionLeftClicPress()
{
	return (g_hP.Steady15());
}
bool ConditionLeftClicRelease()
{
	return (g_hP.Steady10());
}


void ChangeState(int newState)
{
	if (newState != g_currentState)
	{
		g_lastState = g_currentState;
		g_currentState = newState;

		cout << "- Entree dans l'etat no" << g_currentState << endl;
	}
}


void handleState()
{
#ifdef _OS_MAC_
	static TelnetClient g_telnet;
#endif

	CheckHandDown();
	CheckBaffe();
	CheckDepthIntervals();

	switch (g_currentState)
	{
	// Session inactive
	case -1 :

		break; // case -1

	// Aucune action possible
	case 0 :
		
		if (g_depthIntervalOK)
		{
			ChangeState(g_stateBackup);
			gp_window->setWindowOpacity(qreal(1.0));
		}
		else
		{
			gp_window->setWindowOpacity(qreal(0.4));
			gp_windowActiveTool->setBackgroundBrush(QBrush(Qt::red, Qt::SolidPattern));
			gp_windowActiveTool->setWindowOpacity(0.7);
		}

		break; // case 0

	// Coucou effectué, passage par sessionStart, calibrage de la main (200ms)
	case 1 :

		if (g_hP.Steady2())
		{
			ChangeState(2);

			gp_window->setWindowOpacity(qreal(1.0));
			g_pix[g_totalTools]->setOpacity(0.4);
		}
		break; // case 1

	// Après le calibrage de la main, menu des outils
	case 2 :

		chooseTool(g_currentTool, g_lastTool, g_totalTools);
		browse(g_currentTool, g_lastTool, mainTools);

		g_handDepthAtToolSelection = 0;

		if (SelectionDansUnMenu(g_currentTool) && g_toolSelectable)
		{
			g_telnet.connexion();
			switch(g_currentTool)
			{
			case RESETALL:
				g_telnet.sendCommand(QString("\r\ndcmview2d:reset all\r\n"));
				g_telnet.sendCommand(QString("\r\ndcmview2d:mouseLeftAction resetall\r\n"));
				break;
			case LAYOUT:
				g_telnet.sendCommand(QString("\r\ndcmview2d:mouseLeftAction layoutTool\r\n"));
				break;
			case MOVE:
				g_telnet.sendCommand(QString("\r\ndcmview2d:mouseLeftAction pan\r\n"));
				break;
			case CONTRAST:
				g_telnet.sendCommand(QString("\r\ndcmview2d:mouseLeftAction winLevel\r\n"));
				break;
			case ZOOM:
				g_telnet.sendCommand(QString("\r\ndcmview2d:mouseLeftAction zoom\r\n"));
				break;
			case SCROLL:
				g_telnet.sendCommand(QString("\r\ndcmview2d:mouseLeftAction sequence\r\n"));
				break;
			case MOUSE:
				g_telnet.sendCommand(QString("\r\ndcmview2d:mouseLeftAction cursorTool\r\n"));
				break;
			case CROSS:
				g_telnet.sendCommand(QString("\r\ndcmview2d:mouseLeftAction exit\r\n"));
				break;
			}

			// Si un des outils "normaux" a été selectionné
			if ( (g_currentTool == MOVE) || (g_currentTool == CONTRAST) || (g_currentTool == ZOOM) || (g_currentTool == SCROLL) )
			{
				ChangeState(3);
				cout << "--- Selection de l'outil : " << g_currentTool << endl;

				g_handDepthAtToolSelection = g_hP.HandPt().Z();
				cout << "\nhandDepthAtToolSelection : " << g_handDepthAtToolSelection << endl << endl;

				gp_window->hide();
				gp_windowActiveTool->show();
				gp_windowActiveTool->setBackgroundBrush(QBrush(g_toolColorInactive, Qt::SolidPattern));
				gp_pixActive->load(QPixmap(":/images/"+g_pix.operator[](g_currentTool)->objectName()+".png").scaled(pixSizeActive,pixSizeActive));
			}
			
			// Si l'outil layout a été selectionné
			else if (g_currentTool == LAYOUT)
			{
				ChangeState(4);
				g_currentLayoutTool = 0;
				g_lastLayoutTool = 6;
			}

			// Si l'outil souris a été selectionné
			else if (g_currentTool == MOUSE)
			{
				ChangeState(5);
				g_cursorQt.NewCursorSession();

				g_handDepthAtToolSelection = g_hP.HandPt().Z();

				gp_window->hide();
				gp_windowActiveTool->show();
				gp_pixActive->load(QPixmap(":/images/mouse.png").scaled(pixSizeActive,pixSizeActive));
			}

			// Si la croix a été selectionnée
			else if (g_currentTool == CROSS)
			{
				cout << "-- Croix selectionnee" << endl;
				gp_sessionManager->EndSession();
			}

			// Si le bouton ResetAll a été selectionné
			else if (g_currentTool == RESETALL)
			{
				ChangeState(9);
			}
		}

		break; // case 2

	// Outil "normal" selectionné
	case 3 :

		if (ConditionActiveTool())
		{
			gp_windowActiveTool->setBackgroundBrush(QBrush(g_toolColorActive, Qt::SolidPattern));
			gp_windowActiveTool->setWindowOpacity(1.0);

			switch (g_currentTool)
			{
			// Move
			case MOVE :
				g_telnet.sendCommand(QString("\r\ndcmview2d:move -- %1 %2\r\n")
				.arg(-SENSIBILITE_MOVE_X*g_hP.DeltaHandPt().X()).arg(-SENSIBILITE_MOVE_Y*g_hP.DeltaHandPt().Y()));
				break;

			// Contrast
			case CONTRAST :
				g_telnet.sendCommand(QString("\r\ndcmview2d:wl -- %1 %2\r\n")
				.arg(-SENSIBILITE_CONTRAST_X*g_hP.DeltaHandPt().X()).arg(-SENSIBILITE_CONTRAST_Y*g_hP.DeltaHandPt().Y()));
				break;

			// Zoom
			case ZOOM :
				if (g_hP.DetectRight())
					g_telnet.sendCommand(QString("\r\ndcmview2d:zoom -i %1\r\n").arg(SENSIBILITE_ZOOM));
				if (g_hP.DetectLeft())
					g_telnet.sendCommand(QString("\r\ndcmview2d:zoom -d %1\r\n").arg(SENSIBILITE_ZOOM));
				break;

			// Scroll
			case SCROLL :
				if (g_hP.DetectRight())
					g_telnet.sendCommand(QString("\r\ndcmview2d:scroll -i %1\r\n").arg(SENSIBILITE_SCROLL));
				if (g_hP.DetectLeft())
					g_telnet.sendCommand(QString("\r\ndcmview2d:scroll -d %1\r\n").arg(SENSIBILITE_SCROLL));
				break;

			} // end switch (g_currentTool)
		}

		// Si l'outil est désactivé
		else
		{
			gp_windowActiveTool->setBackgroundBrush(QBrush(g_toolColorInactive, Qt::SolidPattern));
			gp_windowActiveTool->setWindowOpacity(0.7);
		}

		if (ConditionExitTool())
		{
			ChangeState(9); // Préparation pour le retour au menu
		}

		break; // case 3

	// Outil layout selectionné
	case 4 :

		gp_window->hide();
		gp_windowActiveTool->hide();
		gp_viewLayouts->show();

		chooseTool(g_currentLayoutTool, g_lastLayoutTool, g_totalLayoutTools);
		browse(g_currentLayoutTool,g_lastLayoutTool, layoutTools);

		if (SelectionDansUnMenu(g_currentLayoutTool))
		{
			switch(g_currentLayoutTool)
			{
			case 0 :
				g_telnet.sendCommand(QString("\r\ndcmview2d:layout -i 1x1\r\n"));
				break;
			case 1 :
				g_telnet.sendCommand(QString("\r\ndcmview2d:layout -i 1x2\r\n"));
				break;
			case 2 :
				g_telnet.sendCommand(QString("\r\ndcmview2d:layout -i 2x1\r\n"));
				break;
			case 3 :
				g_telnet.sendCommand(QString("\r\ndcmview2d:layout -i layout_c1x2\r\n"));
				break;
			case 4 :
				g_telnet.sendCommand(QString("\r\ndcmview2d:layout -i layout_c2x1\r\n"));
				break;
			case 5 :
				g_telnet.sendCommand(QString("\r\ndcmview2d:layout -i 2x2\r\n"));
				break;
			case 6 :
				ChangeState(9);
				break;
			}
		}

		break; // case 4

	// Outil souris selectionné
	case 5 :

		if (g_cursorQt.InCursorSession())
		{
			// Distance limite de la main au capteur
			if (g_hP.HandPt().Z() < (g_handDepthAtToolSelection + g_handDepthThreshold))
			{
				g_cursorQt.SetMoveEnable();
				g_cursorQt.SetClicEnable();
				gp_windowActiveTool->setBackgroundBrush(QBrush(g_toolColorActive, Qt::SolidPattern));
				gp_windowActiveTool->setWindowOpacity(1.0);

				if (ConditionLeftClicPress())
				{
					if (!g_cursorQt.LeftClicPressed())
					{
						g_hP.SignalResetSteadies();
						g_cursorQt.PressLeftClic();
						gp_pixActive->load(QPixmap(":/images/mouse_fermee.png").scaled(pixSizeActive,pixSizeActive));
					}
				}
				if (ConditionLeftClicRelease())
				{
					if (g_cursorQt.LeftClicPressed())
					{
						g_hP.SignalResetSteadies();
						g_cursorQt.ReleaseLeftClic();
						gp_pixActive->load(QPixmap(":/images/mouse.png").scaled(pixSizeActive,pixSizeActive));
					}
				}
			}
			else
			{
				g_cursorQt.SetMoveDisable();
				g_cursorQt.SetClicDisable();
				gp_windowActiveTool->setBackgroundBrush(QBrush(g_toolColorInactive, Qt::SolidPattern));
				gp_windowActiveTool->setWindowOpacity(0.7);

				if (g_hP.Steady20())
					g_cursorQt.EndCursorSession();
			}

			// Appel de la méthode pour déplacer le curseur
			g_cursorQt.MoveCursor(g_hP.HandPt());
		}

		// Sortie du mode souris
		else
		{
			ChangeState(9);
		}

		break; // case 5

	// Préparation pour le retour au menu
	case 9 :

		ChangeState(2);
		g_telnet.deconnexion();

		g_hP.SignalResetSteadies();

		g_lastTool = g_currentTool;
		g_currentTool = g_totalTools;

		browse(g_currentTool,g_lastTool,mainTools);

		gp_window->show();
		gp_viewLayouts->hide();
		gp_windowActiveTool->hide();

		break; // case 9

	} // end switch (g_currentState)
}


void glutKeyboard (unsigned char key, int x, int y)
{
	static int test = 0;

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
		g_hP.IncrementSmooth(1,1,1);
		//g_hP.Smooth().Print();
		//g_hP.HandPt().Print();
		IcrWithLimits(test,3,0,10);
		cout << "-- test : " << test << endl;
		break;

	case 'o' :
		g_hP.IncrementSmooth(-1,-1,-1);
		//g_hP.Smooth().Print();
		IcrWithLimits(test,-3,0,10);
		cout << "-- test : " << test << endl;
		break;

	case 's' :
		// Toggle smoothing
		if (g_fSmoothing == 0)
			g_fSmoothing = 0.1;
		else 
			g_fSmoothing = 0;
		g_myHandsGenerator.SetSmoothing(g_fSmoothing);
		break;

	case 'a' :
		//show some data for debugging purposes
		cout << "x= " << g_hP.HandPt().X() << " ; y= " << g_hP.HandPt().Y() << " ; z= " << g_hP.HandPt().Z() << " ;   " << g_fSmoothing << " ;   " << g_currentState << endl;
		break;

	case 'y' :
		//show tools position
		for (int i=0; i<=g_totalTools; i++)
		{
			cout << "tool" << i << " : " << g_positionTool[i] << endl;
		}
		break;

	case 'e' :
		// end current session
		gp_sessionManager->EndSession();
		break;

	case 'q' :
		g_pix[0]->setScale(0.9);
		mainTools.setItemActive(0);
		break;
	case 'w' :
		g_pix[1]->setScale(0.9);
		break;
	//case 't' :
	//	g_methodeMainFermeeSwitch = !g_methodeMainFermeeSwitch;
	//	cout << "-- Switch Methode main fermee (" << (g_methodeMainFermeeSwitch?2:1) << ")" << endl;
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
	g_status = g_context.WaitAnyUpdateAll();	//first update the g_context - refresh the depth/image data coming from the sensor
	
	// if the update failed, i.e. couldn't be read
	if(g_status != XN_STATUS_OK)
	{
		cout << "\nERROR:Read failed... Quitting!\n" << endl;	//print error message
		exit(0);	//exit the program
	}
	else
	{
		if(g_activeSession)
			gp_sessionManager->Update(&g_context);
		g_dpGen.GetMetaData(g_dpMD);
		long xSize = g_dpMD.XRes();
		long ySize = g_dpMD.YRes();
		long totalSize = xSize * ySize;

		const XnDepthPixel* depthMapData;
		depthMapData = g_dpMD.Data();

		int i, j, colorToSet;
		int depth;

		glLoadIdentity();
		glOrtho(0, xSize, ySize, 0, -1, 1);

		glBegin(GL_POINTS);
		for (i=0;i<xSize;i+=RES_WINDOW_GLUT) // width
		{
			for (j=0;j<ySize;j+=RES_WINDOW_GLUT) // height
			{
				depth = g_dpMD(i,j);
				colorToSet = MAX_COLOR - (depth/COLORS);

				if((depth < DP_FAR) && (depth > DP_CLOSE))
				{
					if (g_activeSession)
						glColor3ub(0,colorToSet,0);
					else
						glColor3ub(colorToSet,colorToSet,colorToSet);
					glVertex2i(i,j);
				}
			}
		}
		glEnd();	// End drawing sequence

		// Mise à jour de la detection de la main fermee
		//if	( g_activeSession && (isHandPointNull() == false))
		//	UpdateHandClosed();

		if	( g_activeSession && (isHandPointNull() == false))
		{
			int size = 5;						// Size of the box
			glColor3f(255,255,255);	// Set the color to white
			glBegin(GL_QUADS);
				glVertex2i(g_hP.HandPtBrut().X()-size,g_hP.HandPtBrut().Y()-size);
				glVertex2i(g_hP.HandPtBrut().X()+size,g_hP.HandPtBrut().Y()-size);
				glVertex2i(g_hP.HandPtBrut().X()+size,g_hP.HandPtBrut().Y()+size);
				glVertex2i(g_hP.HandPtBrut().X()-size,g_hP.HandPtBrut().Y()+size);
			glEnd();

			size = 4;
			glColor3f(0,0,255);
			glBegin(GL_QUADS);
				glVertex2i(g_hP.HandPtBrutFiltre().X()-size,g_hP.HandPtBrutFiltre().Y()-size);
				glVertex2i(g_hP.HandPtBrutFiltre().X()+size,g_hP.HandPtBrutFiltre().Y()-size);
				glVertex2i(g_hP.HandPtBrutFiltre().X()+size,g_hP.HandPtBrutFiltre().Y()+size);
				glVertex2i(g_hP.HandPtBrutFiltre().X()-size,g_hP.HandPtBrutFiltre().Y()+size);
			glEnd();

			size = 5;
			glColor3f(255,0,0);
			glBegin(GL_QUADS);
				glVertex2i(g_hP.HandPt().X()-size,g_hP.HandPt().Y()-size);
				glVertex2i(g_hP.HandPt().X()+size,g_hP.HandPt().Y()-size);
				glVertex2i(g_hP.HandPt().X()+size,g_hP.HandPt().Y()+size);
				glVertex2i(g_hP.HandPt().X()-size,g_hP.HandPt().Y()+size);
			glEnd();
		}

		//========== HAND POINT ==========//
		if	( g_activeSession && (isHandPointNull() == false)
				&& (g_hCD.ROI_Pt().x() >= 0)
				&& (g_hCD.ROI_Pt().y() >= 0)
				&& (g_hCD.ROI_Pt().x() <= (RES_X - g_hCD.ROI_Size().width()))
				&& (g_hCD.ROI_Pt().y() <= (RES_Y - g_hCD.ROI_Size().height())) )
		{
			// Cadre de la main
			glColor3f(255,255,255);
			glBegin(GL_LINE_LOOP);
				glVertex2i(g_hCD.ROI_Pt().x(), g_hCD.ROI_Pt().y());
				glVertex2i(g_hCD.ROI_Pt().x()+g_hCD.ROI_Size().width(), g_hCD.ROI_Pt().y());
				glVertex2i(g_hCD.ROI_Pt().x()+g_hCD.ROI_Size().width(), g_hCD.ROI_Pt().y()+g_hCD.ROI_Size().height());
				glVertex2i(g_hCD.ROI_Pt().x(), g_hCD.ROI_Pt().y()+g_hCD.ROI_Size().height());
			glEnd();

		}
	}
	glutSwapBuffers();

	// Si la main change d'état, on envoie un signal pour réinitialiser les steadys
	// !! Doit être placé juste avant l'appel de handleState() !!
	if (g_handStateChanged)
		g_hP.SignalResetSteadies();

	// Gestion des états
	handleState();
}


void UpdateHandClosed(void)
{
	if (g_toolSelectable)
	{
		g_hCD.Update((g_methodeMainFermeeSwitch?2:1),g_dpMD,g_hP.HandPtBrut());
		g_handStateChanged = g_hCD.HandClosedStateChanged();
		g_handFlancMont = g_hCD.HandClosedFlancMont();
		g_handFlancDesc = g_hCD.HandClosedFlancDesc();
		g_lastHandClosed = g_handClosed;
		g_handClosed = g_hCD.HandClosed();
		g_handClic = g_hCD.HandClosedClic(19); //9

		//// Controle de detection de la main fermee //
		//if (g_handStateChanged)
		//	cout << endl << "---- Chgmt d'etat de la main!" << endl;
		//if (g_handFlancMont)
		//	cout << endl << "---- Fermeture de la main!" << endl;
		//if (g_handFlancDesc)
		//	cout << endl << "---- Ouverture de la main!" << endl;
		//if (g_handClosed)
		//	cout << endl << "---- Main Fermee!" << endl;
		//else
		//	cout << endl << "---- Main Ouverte!" << endl;
		//if (g_handClic)
		//	cout << endl << "---- Clic de la main!" << endl;
	}
}


void initGL(int argc, char *argv[])
{
	glutInit(&argc,argv);
	glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH);
	glutInitWindowSize(INIT_WIDTH_WINDOW, INIT_HEIGHT_WINDOW);

	// Fenêtre de données source
	string titre = TITLE;
	titre += " | ";
	titre += __DATE__;
	titre += " à ";
	titre += __TIME__;

	const char *windowName;
	windowName = titre.c_str();

	glutCreateWindow(windowName);
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

	g_openNi_XML_FilePath = argv[0];
#if defined _OS_WIN_
	int p = g_openNi_XML_FilePath.find(".exe");
	g_openNi_XML_FilePath = g_openNi_XML_FilePath.substr(0,p-4).append("openni.xml");
#elif defined _OS_MAC_
	int p = g_openNi_XML_FilePath.find(".app");
	g_openNi_XML_FilePath = g_openNi_XML_FilePath.substr(0,p+4).append("/Contents/Resources/openni.xml");
#endif

	cout << "Chemin de openni.xml : " << g_openNi_XML_FilePath << endl << endl;

	//------ OPEN_NI / NITE / OPENGL ------//
	xn::EnumerationErrors errors;

	g_status = g_context.InitFromXmlFile(g_openNi_XML_FilePath.c_str());
	CHECK_ERRORS(g_status, errors, "InitFromXmlFile");
	CHECK_STATUS(g_status, "InitFromXml");

	//si le g_context a été initialisé correctement
	g_status = g_context.FindExistingNode(XN_NODE_TYPE_DEPTH, g_dpGen);
	CHECK_STATUS(g_status, "Find depth generator");
	g_status = g_context.FindExistingNode(XN_NODE_TYPE_HANDS, g_myHandsGenerator);
	CHECK_STATUS(g_status, "Find hands generator");

	// NITE 
	gp_sessionManager = new XnVSessionManager();

	//Focus avec un coucou et Refocus avec "RaiseHand" 
	g_status = gp_sessionManager->Initialize(&g_context,"Wave","Wave,RaiseHand");
	CHECK_STATUS(g_status,"Session manager");

	gp_sessionManager->RegisterSession(&g_context,sessionStart,sessionEnd,FocusProgress);
	gp_sessionManager->SetQuickRefocusTimeout(3000);

	g_pFlowRouter = new XnVFlowRouter;

	gp_pointControl = new XnVPointControl("Point Tracker");
	gp_pointControl->RegisterPrimaryPointCreate(&g_context,pointCreate);
	gp_pointControl->RegisterPrimaryPointDestroy(&g_context,pointDestroy);
	gp_pointControl->RegisterPrimaryPointUpdate(&g_context,pointUpdate);

	// Wave detector
	XnVWaveDetector waveDetect;
	waveDetect.RegisterWave(&g_context,&Wave_Detected);
	//waveDetect.SetFlipCount(10);
	//waveDetect.SetMaxDeviation(1);
	//waveDetect.SetMinLength(100);

	// Add Listener
	gp_sessionManager->AddListener(gp_pointControl);
	gp_sessionManager->AddListener(g_pFlowRouter);
	gp_sessionManager->AddListener(&waveDetect);
		
	nullifyHandPoint();
	g_myHandsGenerator.SetSmoothing(g_fSmoothing);

	// Initialization done. Start generating
	g_status = g_context.StartGeneratingAll();
	CHECK_STATUS(g_status, "StartGenerating");

	initGL(argc,argv);


	// Qt
#ifdef _OS_MAC_
	int qargc = 0;
	char **qargv = NULL;
	QApplication app(qargc,qargv);
#endif

	g_cursorQt = CursorQt(1);
	gp_window = new GraphicsView(NULL);
	gp_windowActiveTool = new GraphicsView(NULL);
	gp_sceneActiveTool = new QGraphicsScene(0,0,pixSizeActive,pixSizeActive);
	gp_viewLayouts = new GraphicsView(NULL);
	gp_pixActive = new Pixmap(QPixmap()); //for activeTool
	//mainTools.init(g_totalTools+1);
	//layoutTools.init(g_totalLayoutTools+1);



	//================== QT ===================//

	// Initialisation des ressources et création de la fenêtre avec les icônes
	Q_INIT_RESOURCE(images);
	
	mainTools.addItem("reset", ":/images/reset.png");
	mainTools.addItem("layout", ":/images/layout.png");
	mainTools.addItem("move", ":/images/move.png");
	mainTools.addItem("contrast", ":/images/contrast.png");
	mainTools.addItem("zoom", ":/images/zoom.png");
	mainTools.addItem("scroll", ":/images/scroll.png");
	mainTools.addItem("mouse", ":/images/mouse.png");
	mainTools.addItem("stop", ":/images/stop.png");

	mainTools.createView();
	gp_window = mainTools.getWindow();
	g_pix = mainTools.getItems();

	/*Pixmap *p1 = new Pixmap(QPixmap(":/images/layout.png").scaled(64,64));
	Pixmap *p2 = new Pixmap(QPixmap(":/images/move.png").scaled(64,64));
	Pixmap *p3 = new Pixmap(QPixmap(":/images/contrast.png").scaled(64,64));
	Pixmap *p4 = new Pixmap(QPixmap(":/images/zoom.png").scaled(64,64));
	Pixmap *p5 = new Pixmap(QPixmap(":/images/scroll.png").scaled(64,64));
	Pixmap *p6 = new Pixmap(QPixmap(":/images/mouse.png").scaled(64,64));
	Pixmap *p7 = new Pixmap(QPixmap(":/images/stop.png").scaled(64,64));

	p1->setObjectName("layout");
	p2->setObjectName("move");
	p3->setObjectName("contrast");
	p4->setObjectName("zoom");
	p5->setObjectName("scroll");
	p6->setObjectName("mouse");
	p7->setObjectName("stop");

	p1->setGeometry(QRectF(  0.0, g_iconIdlePt, 64.0, 64.0));
	p2->setGeometry(QRectF(128.0, g_iconIdlePt, 64.0, 64.0));
	p3->setGeometry(QRectF(256.0, g_iconIdlePt, 64.0, 64.0));
	p4->setGeometry(QRectF(384.0, g_iconIdlePt, 64.0, 64.0));
	p5->setGeometry(QRectF(512.0, g_iconIdlePt, 64.0, 64.0));
	p6->setGeometry(QRectF(640.0, g_iconIdlePt, 64.0, 64.0));
	p7->setGeometry(QRectF(768.0, g_iconIdlePt, 64.0, 64.0));

	g_pix.push_back(p1);
	g_pix.push_back(p2);
	g_pix.push_back(p3);
	g_pix.push_back(p4);
	g_pix.push_back(p5);
	g_pix.push_back(p6);
	g_pix.push_back(p7);*/

	//gp_window->setSize(1024,288);
	//gp_window->setSize(896,256);
	//
	////gp_window->setSize(548,gp_window->getResY()-100);
	//QGraphicsScene *scene = new QGraphicsScene(0,0,896,256);
	////QGraphicsScene *scene = new QGraphicsScene(0,(-gp_window->getResY())+488,548,gp_window->getResY()-100);
	//scene->addItem(p1);
	//scene->addItem(p2);
	//scene->addItem(p3);
	//scene->addItem(p4);
	//scene->addItem(p5);
	//scene->addItem(p6);
	//scene->addItem(p7);
	//gp_window->setScene(scene);

	gp_sceneActiveTool->addItem(gp_pixActive);
	//gp_windowActiveTool->setSize(126,126);
	gp_windowActiveTool->setScene(gp_sceneActiveTool);
	gp_windowActiveTool->setGeometry(gp_window->getResX()-pixSizeActive,gp_window->getResY()-pixSizeActive-40,pixSizeActive,pixSizeActive);


	////////////// LAYOUT
	layoutTools.addItem("1x1", ":/images/layouts/_1x1.png");
	layoutTools.addItem("1x2", ":/images/layouts/_1x2.png");
	layoutTools.addItem("2x1", ":/images/layouts/_2x1.png");
	layoutTools.addItem("3a", ":/images/layouts/_3a.png");
	layoutTools.addItem("3b", ":/images/layouts/_3b.png");
	layoutTools.addItem("2x2", ":/images/layouts/_2x2.png");
	layoutTools.addItem("stop", ":/images/stop.png");

	layoutTools.createView();
	gp_viewLayouts = layoutTools.getWindow();////////////////////////////////////////////////////////////////////
	g_pixL = layoutTools.getItems();

	/*Pixmap *l1 = new Pixmap(QPixmap(":/images/layouts/_1x1.png").scaled(64,64));
	Pixmap *l2 = new Pixmap(QPixmap(":/images/layouts/_1x2.png").scaled(64,64));
	Pixmap *l3 = new Pixmap(QPixmap(":/images/layouts/_2x1.png").scaled(64,64));
	Pixmap *l4 = new Pixmap(QPixmap(":/images/layouts/_3a.png").scaled(64,64));
	Pixmap *l5 = new Pixmap(QPixmap(":/images/layouts/_3b.png").scaled(64,64));
	Pixmap *l6 = new Pixmap(QPixmap(":/images/layouts/_2x2.png").scaled(64,64));
	Pixmap *l7 = new Pixmap(QPixmap(":/images/stop.png").scaled(64,64));

	l1->setObjectName("1x1");
	l2->setObjectName("1x2");
	l3->setObjectName("2x1");
	l4->setObjectName("3a");
	l5->setObjectName("3b");
	l6->setObjectName("2x2");
	l7->setObjectName("stop");
	
	l1->setGeometry(QRectF(  0.0, g_iconIdlePt, 64.0, 64.0));
	l2->setGeometry(QRectF(128.0, g_iconIdlePt, 64.0, 64.0));
	l3->setGeometry(QRectF(256.0, g_iconIdlePt, 64.0, 64.0));
	l4->setGeometry(QRectF(384.0, g_iconIdlePt, 64.0, 64.0));
	l5->setGeometry(QRectF(512.0, g_iconIdlePt, 64.0, 64.0));
	l6->setGeometry(QRectF(640.0, g_iconIdlePt, 64.0, 64.0));
	l7->setGeometry(QRectF(768.0, g_iconIdlePt, 64.0, 64.0));

	g_pixL.push_back(l1);
	g_pixL.push_back(l2);
	g_pixL.push_back(l3);
	g_pixL.push_back(l4);
	g_pixL.push_back(l5);
	g_pixL.push_back(l6);
	g_pixL.push_back(l7);

	gp_viewLayouts->setSize(896,256);
	QGraphicsScene *sceneLayout = new QGraphicsScene(0,0,896,256);
	sceneLayout->addItem(l1);
	sceneLayout->addItem(l2);
	sceneLayout->addItem(l3);
	sceneLayout->addItem(l4);
	sceneLayout->addItem(l5);
	sceneLayout->addItem(l6);
	sceneLayout->addItem(l7);
	gp_viewLayouts->setScene(sceneLayout);*/

	//gp_viewLayouts->show();

	
	/*for(int i=0; i<=g_totalTools; i++){
		QString chemin = ":/images/Resources/_"+g_pix.operator[](i)->objectName()+".png";
		//printf("\n"+chemin.toAscii()+"\n");
		int posi = g_positionTool[i];
		g_pix.operator[](i)->setGeometry(QRectF( posi*60.0, posi*(-10.0), 128.0, 128.0));
		g_pix.operator[](i)->load(QPixmap(chemin).scaled(78+(posi*(10)),78+(posi*(10))));
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
	ChangeState(1);

	g_activeSession = true;
	g_toolSelectable = false;

	g_currentTool = g_totalTools;
	g_lastTool = 0;

	for (int i=0; i<g_totalTools; i++)
		//g_pix.operator[](i)->setGeometry(QRectF(i*128.0, g_iconIdlePt, 64.0, 64.0));
		mainTools.setItemIdle(i);

	gp_window->show();
	gp_window->setWindowOpacity(qreal(0.4));
	gp_viewLayouts->hide();
	gp_windowActiveTool->hide();

	SteadyAllEnable();
	//Steady2Enable();
	//Steady10Enable();
	//Steady20Enable();

	g_hCD.ResetCompteurFrame();

	static int compteurSession = 1;
	cout << endl << "Debut de la session : " << compteurSession++ 
		<< "e" << (compteurSession==1?"re":"") << " fois" << endl << endl;
	
	g_telnet.sendCommand(QString("\r\ndcmview2d:mouseLeftAction sessionStart\r\n"));
}

/**********************************************************************************
session end event handler. Session manager calls this when session ends
**********************************************************************************/
void XN_CALLBACK_TYPE sessionEnd(void* UserCxt)
{
	ChangeState(-1);

	g_activeSession = false;
	g_toolSelectable = false;

	g_currentTool = g_totalTools;
	g_lastTool = 0;

	// On réduit tous les outils et layouts
	for (int i=0; i<=g_totalTools; i++)
		//g_pix.operator[](i)->setGeometry(QRectF(i*128.0, g_iconIdlePt, 64.0, 64.0));
		mainTools.setItemIdle(i);
	for (int i=0; i<=g_totalLayoutTools; i++)
		//g_pixL.operator[](i)->setGeometry(QRectF(i*128.0, g_iconIdlePt, 64.0, 64.0));
		layoutTools.setItemIdle(i);

	gp_window->hide();
	gp_viewLayouts->hide();
	gp_windowActiveTool->hide();
	
	SteadyAllDisable();
	//Steady2Disable();
	//Steady10Disable();
	//Steady20Disable();

	XnPoint3D ptTemp;
	ptTemp.X = g_hP.HandPt().X();
	ptTemp.Y = g_hP.HandPt().Y();
	ptTemp.Z = g_hP.HandPt().Z();
	g_lastPt = ptTemp;
	
	cout << endl << "Fin de la session" << endl << endl;
	g_telnet.sendCommand(QString("\r\ndcmview2d:mouseLeftAction sessionStop\r\n"));
}


/**********************************************************************************
point created event handler. this is called when the gp_pointControl detects the creation
of the hand point. This is called only once when the hand point is detected
**********************************************************************************/
void XN_CALLBACK_TYPE pointCreate(const XnVHandPointContext *pContext, const XnPoint3D &ptFocus, void *cxt)
{
	XnPoint3D coords(pContext->ptPosition);
	g_dpGen.ConvertRealWorldToProjective(1,&coords,&g_handPt);
	g_lastPt = g_handPt;

	g_hP.Update(g_handPt);
}
/**********************************************************************************
Following the point created method, any update in the hand point coordinates are 
reflected through this event handler
**********************************************************************************/
void XN_CALLBACK_TYPE pointUpdate(const XnVHandPointContext *pContext, void *cxt)
{
	XnPoint3D coords(pContext->ptPosition);
	g_dpGen.ConvertRealWorldToProjective(1,&coords,&g_handPt);

	g_hP.Update(g_handPt);
}
/**********************************************************************************
when the point can no longer be tracked, this event handler is invoked. Here we 
nullify the hand point variable 
**********************************************************************************/
void XN_CALLBACK_TYPE pointDestroy(XnUInt32 nID, void *cxt)
{
	cout << "\nPoint detruit -------------------------------------------------" 
		<< endl << endl;

	nullifyHandPoint();
	//gp_sessionManager->EndSession();
}


// Callback for no hand detected
void XN_CALLBACK_TYPE NoHands(void* UserCxt)
{
	cout << "No Hands" << endl;
	g_cursorQt.EndCursorSession();
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
	cout << "-- Wave detected" << endl;
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


