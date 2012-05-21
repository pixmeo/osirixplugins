
//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "main.h"


//==========================================================================//
//=========================== VARIABLES GLOBALES ===========================//

// 0: Inactive; 1: in menu; 2: tool chosen
int currentState = 0;
int lastState = 0;
int moveCounter = 0;

// 0: Zoom; 1: Contrast; 2: Move
int currentTool = 0; 
int lastTool = 0;
int totalTools = 6; // +1
int positionTool[7]; //position des outils dans le menu
int afficheTool[7]; //affichage des outils

//Layout
int totalLayoutTools = 5; //+1
int currentLayout = 0;
int currentLayoutTool = 0;
int lastLayoutTool = 0;

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
//
float handSurfaceThreshold = 50.0;
bool handDown = false;
bool mainFermee = false;
int cptHand = 0;
int handFrames = 5;
bool handClosed = false;
bool toolSelectable = false;

//HWND hwnd;

XnFloat g_fSmoothing = 0.2f;

//NITE
XnVSessionManager *sessionManager;
XnVPointControl *pointControl;
bool activeSession = false;
XnPoint3D handPt;
XnPoint3D lastPt;
	// Steady
XnVSteadyDetector sd;
XnVSteadyDetector sd2;
XnVSteadyDetector sd3;
XnVSteadyDetector sd02;
bool steadyState = false;
bool steady2 = false;

//Qt
int qargc = 0;
char **qargv = NULL;
QApplication app(qargc,NULL);
GraphicsView *window = new GraphicsView(NULL);
GraphicsView *windowActiveTool = new GraphicsView(NULL);
QGraphicsScene *sceneActiveTool = new QGraphicsScene(0,0,128,128);
GraphicsView *viewLayouts = new GraphicsView(NULL);

TelnetClient telnet;

vector<Pixmap*> pix; //for main tools
vector<Pixmap*> pixL; //for layouts
Pixmap* pixActive = new Pixmap(QPixmap()); //for activeTool

//--------------

/*NITE objects*/
XnVFlowRouter* g_pFlowRouter;

/*Cursor objects*/
//Cursor cursor(2);

/*KiOP*/
CursorQt cursorQt(2);
HandClosedDetection handClosedDetection;



bool timerOut = false;


//==========================================================================//
//============================== FONCTIONS =================================//

// Fonction d'initialisation
void Initialisation(void)
{
	printf("\n= = = = = = = = = = = = = = = =\n\tINITIALISATION\n");
	printf("\nResolution d'ecran : %ix%i\n",SCRSZW,SCRSZH);
	//printf("\nNombre de moniteurs : %i\n",GetSystemMetrics(SM_CMONITORS));
	printf("\nDimensions de la fenetre : %ix%i\n\n",WIN_WIDTH,WIN_HEIGHT);

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



inline bool isHandPointNull()
{
	return ((handPt.X == -1) ? true : false);
}

bool detectLeft()
{
	return (((lastX-handPt.X) > moveThreshold) ? true : false);
}

bool detectRight()
{
	return (((lastX-handPt.X) < (-moveThreshold)) ? true : false);
}

bool detectForward()
{
	return (((lastZ-handPt.Z) > (moveThreshold)) ? true : false);
}

bool detectBackward()
{
	return (((lastZ-handPt.Z) < (-moveThreshold)) ? true : false);
}

bool detectClick()
{
	return (((lastZ-handPt.Z) > (5*moveThreshold)) ? true : false);
}


void chooseTool(int &currentTool, int &lastTool, int &totalTools){
	if ((lastX-handPt.X)>0){
		if(moveCounter>0) 
			moveCounter = 0;
		moveCounter=moveCounter-(lastX-handPt.X);//+(handPt.Z/1000);
	}
	else if((lastX-handPt.X)<0){
		if(moveCounter<0) 
			moveCounter = 0;
		moveCounter=moveCounter-(lastX-handPt.X);//+(handPt.Z/1000);
	}

	//cout << handPt.Z << endl;
	if (moveCounter<=-10){//-(3-(handPt.Z/1000))){
		//go left in the menu
		lastTool=currentTool;
		if (currentTool-1<0)
			currentTool = 0;
		else
			currentTool--;
		moveCounter = 0;
	}
	else if(moveCounter>=10){//+(3-(handPt.Z/1000))){
		//go right in the menu
		lastTool=currentTool;
		if (currentTool+1>totalTools)
			currentTool = totalTools;
		else
			currentTool++;
		moveCounter = 0;
	}
	else{
		//do nothing
	}
}

void browse(int currentTool, int lastTool, vector<Pixmap*> pix){
	//only set the pixmap geometry when needed 
	if (lastTool != currentTool){
		if (currentTool == 0)
			pix.operator[](currentTool)->setGeometry(QRectF( (currentTool*128.0), iconIdlePt-64, 128.0, 128.0));//for zooming on the tool
		else
			pix.operator[](currentTool)->setGeometry(QRectF( (currentTool*128.0)-32, iconIdlePt-64, 128.0, 128.0));//for zooming on the tool
		pix.operator[](lastTool)->setGeometry(QRectF( lastTool*128.0, iconIdlePt, 64.0, 64.0));
	}
}

void handleState(){
	//cout << currentState << endl;

	bool inIntervalleX = (handPt.X < handSurfaceLimit+handSurfaceThreshold)&&(handPt.X > handSurfaceLimit-handSurfaceThreshold); // Booléen pour indiquer si la main est dans le bon intervelle de distance en X
	bool inIntervalleZ = (handPt.Z < handDepthLimit+handDepthThreshold); // Booléen pour indiquer si la main est dans le bon intervelle de distance en Z

	switch(currentState)
	{
		case -2:
			if (!mainFermee) //(!steadyState) //1 
			{
				currentState = 1;
			}
		case -1: //L'outil a été sélectionné
			if (lastState == 1)
			{
				for (int i=0; i<=totalTools; i++){
					pix.operator[](i)->hide();
				} 
				windowActiveTool->show();
				//pixActive->show();
				//pixActive->load(QPixmap(":/images/Resources/_"+pix.operator[](currentTool)->objectName()+".png").scaled(128,128));
				pixActive->load(QPixmap(":/images/Resources/"+pix.operator[](currentTool)->objectName()+".png").scaled(128,128));
				windowActiveTool->setStyleSheet("background-color: gray");
				if (currentTool==totalTools)
					currentState=2;
				lastTool = currentTool;
				lastState = currentState;

				if ((currentTool != 1) || (currentTool != 6)){
					glutTimerFunc(1500,onTimerOut,12345);
				}
			}
			//if (!steadyState)
			if (timerOut)
			{
				windowActiveTool->hide();
				currentState = 2;
				windowActiveTool->show();
				//pixActive->load(QPixmap(":/images/Resources/activeTool/_"+pix.operator[](currentTool)->objectName()+".png").scaled(128,128));
				windowActiveTool->setStyleSheet("background-color: green");
				timerOut = false;
				handDepthLimit = handPt.Z;
				handSurfaceLimit = handPt.X;
			}
			//if (!mainFermee) //1
			//	currentState=2;
			break;
		case 0: //en attente d'un wave
			steady2 = false;
			steadyState = false;
			break;
		case 1: //coucou effectué, afficher le menu
			//cout << "x= " << handPt.X << " ; y= " << handPt.Y << " ; z= " << handPt.Z << " ;   " << endl;
			if (lastState == 0)
			{
				viewLayouts->hide();
				windowActiveTool->hide();
				for (int i=0; i<=totalTools; i++)
				{
					pix.operator[](i)->setGeometry(QRectF( i*128.0, iconIdlePt, 64.0, 64.0));
					pix.operator[](i)->show();
						
					//cout << "Show " << i << endl;
				}
				lastState = currentState;
				telnet.connexion();
			}

			if (!mainFermee)
			{
				chooseTool(currentTool, lastTool, totalTools);
				browse(currentTool,lastTool, pix);
			}
			

			if (mainFermee) 
			{
				//cout<<"bijour"<<endl;
				
				lastState = currentState;
				currentState = -1;
				nFrames = 2;
				moveThreshold = 4;
				cout << "Tool selected" << endl;
				telnet.connexion();
				
				steadyState = false;
			}

			//code à ameliorer/////////////////////////////
			//quitter la session lorsqu'on baisse la main
			handDown = false;
			if (handPt.Z < 1500){
				if (handPt.Y > lastPt.Y+150){
					handDown = true;
				}
			}
			else if((handPt.Z < 2100)&&(handPt.Z>=1500)){
				if (handPt.Y > lastPt.Y+130){
					handDown = true;
				}
			}
			else if(handPt.Z > 2100){
				if (handPt.Y > lastPt.Y+100){
					handDown = true;	
				}
			}
			if (handDown){
				telnet.deconnexion();
				sessionManager->EndSession();
				currentState=0;
			}

			break;
		case 2:
			//if (handPt.Z < handDepthLimit-40){

			//if (mainFermee)
			switch(currentTool)
			{
				case 3: // Zoom
					//if ((handPt.X < handSurfaceLimit+handSurfaceThreshold)&&(handPt.X > handSurfaceLimit-handSurfaceThreshold)) { //&& (handDepthLimit-40 < handPt.Z)){
					//if (handPt.Z < handDepthLimit+handDepthThreshold) 
					if (inIntervalleX && mainFermee)
					{
						if (detectForward()){
							for (int i=0; i<3; i++){
								telnet.sendCommand(QString("\r\ndcmview2d:zoom -i 1\r\n"));
							}
						}
						else if(detectBackward()){
							for (int i=0; i<3; i++){
								telnet.sendCommand(QString("\r\ndcmview2d:zoom -d 1\r\n"));
							}
						}
						else { }
					}
					break;
				case 5: // Contraste
					if (inIntervalleZ && mainFermee)
					{
						telnet.sendCommand(QString("\r\ndcmview2d:wl -- %1 %2\r\n").arg((int)(lastX-handPt.X)*6).arg((int)(lastY-handPt.Y)*6));
					}
					break;
				case 2: // Translation
					if (inIntervalleZ && mainFermee)
					{
						telnet.sendCommand(QString("\r\ndcmview2d:move -- %1 %2\r\n").arg((int)(lastX-handPt.X)*6).arg((int)(lastY-handPt.Y)*6));
					}
					break;
				case 4: // Scroll
					//if (handPt.Z < handSurfaceLimit+handSurfaceThreshold) //&& (handDepthLimit-40 < handPt.Z)){
					//if (handPt.Z < handDepthLimit+handDepthThreshold) {
					if (inIntervalleX && mainFermee)
					{
						if ((lastZ-handPt.Z)<0)
						{
							for (int i=0; i<-(lastZ-handPt.Z)/6; i++)
							{
								telnet.sendCommand(QString("\r\ndcmview2d:scroll -i 1\r\n"));
							}
						}
						else if((lastZ-handPt.Z)>0)
						{
							for (int i=0; i<(lastZ-handPt.Z)/6; i++)
							{
								telnet.sendCommand(QString("\r\ndcmview2d:scroll -d 1\r\n"));
							}
						}
						else { }
					}
					break;

				case 0: // Souris
					if (!mainFermee)
					{
						lastState = currentState;
						currentState = 3;						// MODE SOURIS
						//cursor.NewCursorSession();
					}

					break;

				case 1: // Layouts (currentTool = 5 , -5, -55)
					//printf("IN!!!!!!!!!!!!");
					//window->hide();
					pix.operator[](currentTool)->hide();
					windowActiveTool->hide();
					viewLayouts->show();
					if (!mainFermee){
						currentTool = -5;
					}
					
					break;

				case -5:
					chooseTool(currentLayoutTool, lastLayoutTool, totalLayoutTools);
					browse(currentLayoutTool,lastLayoutTool, pixL);
					//printf("IN!!!!!!!!!!!!");
					//if (steadyState)
					if (mainFermee)
					{
						viewLayouts->hide();
						switch(currentLayoutTool)
						{
							case 0:
								telnet.sendCommand(QString("\r\ndcmview2d:layout -i 1x1\r\n"));
								printf("0");
								break;
							case 1:
								telnet.sendCommand(QString("\r\ndcmview2d:layout -i 1x2\r\n"));
								printf("1");
								break;
							case 2:
								telnet.sendCommand(QString("\r\ndcmview2d:layout -i 2x1\r\n"));
								printf("2");
								break;
							case 3:
								telnet.sendCommand(QString("\r\ndcmview2d:layout -i layout_c1x2\r\n"));
								break;
							case 4:
								telnet.sendCommand(QString("\r\ndcmview2d:layout -i layout_c2x1\r\n"));
								break;
							case 5:
								telnet.sendCommand(QString("\r\ndcmview2d:layout -i 2x2\r\n"));
								break;	
						}
						
					}
					break;

				case 6:
					cout << lastTool << endl;
					sessionManager->EndSession();
					telnet.deconnexion();
					windowActiveTool->hide();
					viewLayouts->hide();
					windowActiveTool->hide();
					//currentTool = 0;
					//currentState = 0;
					//switch(currentLayoutTool)
					break;

			}

			//if ( (steadyState && (!mainFermee) && ((currentState != 3) && (currentState != 5))) )
			if ( ( steadyState && (!mainFermee) && (currentState != 3) && (currentTool != -5) ) 
					|| ((currentTool == -5) && (mainFermee)) )
			{
				lastState = currentState;
				currentState = 1;
				nFrames = 2;
				moveThreshold = 4;
				windowActiveTool->hide();
				viewLayouts->hide();
				for (int i=0; i<=totalTools; i++)
				{
					pix.operator[](i)->setGeometry(QRectF( i*128.0, iconIdlePt, 64.0, 64.0));
					pix.operator[](i)->show();
					//cout << "Show " << i << endl;
				}
				//sessionManager->EndSession();
				//cout << "End session" << endl;
				currentTool=totalTools;
				lastTool=0;
				//mainFermee = false; //1
				steadyState = false;
				lastPt = handPt;
				mainFermee = false;
			}

			break;

		// Mouse control
		case 3 :
            /*
			if (cursor.GetState() == 0) // Sortie du mode souris
			{
				lastState = currentState;
				currentState = 1;
				currentTool = totalTools; //4;
				lastTool = 0;
				windowActiveTool->hide();
				for (int i=0; i<=totalTools; i++)
				{
					pix.operator[](i)->show();
					//cout << "Show " << i << endl;
				}
				break;
			}

			if (handPt.Z < handDepthLimit+handDepthThreshold)
			{
				cursor.MoveEnable();
				cursor.ClicEnable();
			}
			else
			{
				cursor.MoveDisable();
				cursor.ClicDisable();
			}

			cursor.NewCursorVirtualPos((int)(handPt.X),(int)(handPt.Y),(int)(handPt.Z));

            */
			break;
             
	}
}


void glutKeyboard (unsigned char key, int x, int y)
{
	float tmp = 0.0;
	switch (key)
	{
	case 27:
		// Exit
		#ifdef _OS_WIN_
			ChangeCursor(0);
		#endif
		context.Shutdown();
		break;
	case 'i':
		//increase smoothing
		tmp = g_fSmoothing + 0.1;
		g_fSmoothing = tmp;
		myHandsGenerator.SetSmoothing(g_fSmoothing);
		break;
	case 'o':
		//decrease smoothing
		tmp = g_fSmoothing - 0.1;
		g_fSmoothing = tmp;
		myHandsGenerator.SetSmoothing(g_fSmoothing);
		break;
	case 's':
		// Toggle smoothing
		if (g_fSmoothing == 0)
			g_fSmoothing = 0.1;
		else 
			g_fSmoothing = 0;
		myHandsGenerator.SetSmoothing(g_fSmoothing);
		break;
	case 'a':
		//show some data for debugging purposes
		cout << "x= " << handPt.X << " ; y= " << handPt.Y << " ; z= " << handPt.Z << " ;   " << g_fSmoothing << " ;   " << currentState << endl;
		break;
	case 'y':
		//show tools position
		for(int i=0; i<=totalTools; i++){
			cout << "tool" << i << " : " << positionTool[i] << endl;
		}
		//cout << "x= " << handPt.X << " ; y= " << handPt.Y << " ; z= " << handPt.Z << " ;   " << g_fSmoothing << " ;   " << currentState << endl;
		break;
	case 'e':
		// end current session
		lastState = currentState;
		currentState = 0;
		sessionManager->EndSession();
		telnet.deconnexion();
		break;

		break;
	case '1' : 
		//RepositionnementFenetre(1);
		break;
	case '2' : 
		//RepositionnementFenetre(2);
		break;
	case '3' : 
		//RepositionnementFenetre(3);
		break;
	case '4' : 
		//RepositionnementFenetre(4);
		break;

	case '5' :

		// Enclenchement du timer
		glutTimerFunc(1000,TimerTest,12345);
				// Paramètre1 : nombre de miliseconde
				// Paramètre2 : nom de la fonction à appeler
				// Paramètre3 : valeur passée en paramètre (p.ex numéro de l'outil?)

		break;

	}
}


void onTimerOut(int value){
	timerOut = true;
}

void TimerTest(int value)
{
	cout << "\n TIMER : " << value << endl;
}



void glutDisplay()
{
	static unsigned compteurFrame = 0; compteurFrame++;

	static int xBox = 0, yBox = 0;
	static int /*boxSize = 100,*/ boxWidth = 100, boxHeight = 100;
	static const int maxBoxSize = 300;
	static const float x1 = 500, x2 = 2500;
	static const float y1 = 250, y2 = 50;

	// Droite décroissante
	static const float boxPente = (y2-y1)/(x2-x1);
	static const float boxOrdonnee = y1 - boxPente*x1;

	// 1/x
	static const int boxSizeOffset = 60;
	static const float boxSizeCoeffA = (x1*x2) * (y1-y2)/(x2-x1);
	static const float boxSizeCoeffB = y1 - boxSizeCoeffA/x1 + boxSizeOffset;

	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	//clear the gl buffers
	
	status = context.WaitAnyUpdateAll();	//first update the context - refresh the depth/image data coming from the sensor
	
	if(status != XN_STATUS_OK) //if the update failed, i.e. couldn't be read
	{
		printf("\nERROR:Read failed... Quitting!\n");	//print error message
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

		// Dimensions du cadre ROI
		//boxWidth = boxPente*handPt.Z + boxOrdonnee;				// Droite décroissante
		boxWidth = boxSizeCoeffA/handPt.Z + boxSizeCoeffB;	// 1/x
		boxHeight = boxWidth * 0.8;
		//cout << " *** boxWidth : " << boxWidth << "boxHeight : " << boxHeight << endl;

		// Coordonnées haut-gauche du cadre
		//xBox = handPt.X - boxWidth/2;
		//yBox = handPt.Y - boxHeight/2;

		xBox = (handPt.X > boxWidth/2 ? handPt.X - boxWidth/2 : 0);
		yBox = (handPt.Y > boxHeight/2 ? handPt.Y - boxHeight/2 : 0);

		xBox = (handPt.X < (RES_X - boxWidth/2) ? xBox : RES_X - boxWidth);
		yBox = (handPt.Y < (RES_Y - boxHeight/2) ? yBox : RES_Y - boxHeight);


		glBegin(GL_POINTS);
		for(i=0;i<xSize;i+=RES_WINDOW_GLUT)	//width
		{
			for(j=0;j<ySize;j+=RES_WINDOW_GLUT)	//height
			{
				depth = dpMD(i,j);
				colorToSet = MAX_COLOR - (depth/COLORS);
			 
				if((depth < DP_FAR) && (depth > DP_CLOSE)) 
				{	
					if (activeSession)
						glColor3ub(0,colorToSet,0);
					else
						glColor3ub(colorToSet,colorToSet,colorToSet);
					glVertex2i(i,j);
				}
				if ( (activeSession) && ( (currentState == 2) || (currentState == 3) || (currentState == 4) ) )
				{
					if (((i>xBox)&&(i<xBox+boxWidth)) && ((j>yBox)&&(j<yBox+boxHeight)))
					{
						if ((currentTool==1) || (currentTool==2) || (currentTool==4))
						{
							if (handPt.Z > handDepthLimit+handDepthThreshold)
							{
								glColor3ub(colorToSet,0,0);
								glVertex2i(i,j);
							}
						}
						else if ((currentTool==0) || (currentTool==3))
						{
							if ((handPt.X > handSurfaceLimit+handSurfaceThreshold)||(handPt.X < handSurfaceLimit-handSurfaceThreshold))
							{
								glColor3ub(colorToSet,0,0);
								glVertex2i(i,j);
							}
						}
					}
				}
			}
		}
		glEnd();	//end drawing sequence


		handClosedDetection.SetHandPt(handPt);
		handClosedDetection.SetDepthLimits(handPt.Z);
		handClosedDetection.SetROI_Size();
		handClosedDetection.SetROI_Pt();

		
		//cout << " *** boxWidth : " << boxWidth << "boxHeight : " << boxHeight << endl;
		//cout << "xBox : " << xBox << "yBox : " << yBox << endl;

		//---------------------------------- HAND POINT ------------------------------------------------
		//if( activeSession && (isHandPointNull() == false) && (xBox >= 0 && yBox >= 0 && xBox <= (640-boxWidth) && yBox <= (480-boxHeight)) )
		if( activeSession && (isHandPointNull() == false) && (handClosedDetection.ROI_Pt().x() >= 0 && handClosedDetection.ROI_Pt().y() >= 0 && handClosedDetection.ROI_Pt().x() <= (RES_X-boxWidth) && handClosedDetection.ROI_Pt().y() <= (RES_Y-boxHeight)) )
		{
			glColor3f(255,255,255);	//set the color to white
			glBegin(GL_QUADS);		//start drawing the polygon
			int xCo = handPt.X;
			int yCo = handPt.Y;
			int size = 4;						//size of the box
				glVertex2i(xCo-size,yCo-size);
				glVertex2i(xCo+size,yCo-size);
				glVertex2i(xCo+size,yCo+size);
				glVertex2i(xCo-size,yCo+size);
			glEnd();
		
			// Cadre de la main
			glColor3f(255,255,255);
			glBegin(GL_LINE_LOOP);
				//glVertex2i(xBox,					yBox);
				//glVertex2i(xBox+boxWidth,	yBox);
				//glVertex2i(xBox+boxWidth,	yBox+boxHeight);
				//glVertex2i(xBox,					yBox+boxHeight);
				glVertex2i(handClosedDetection.ROI_Pt().x(),					handClosedDetection.ROI_Pt().y());
				glVertex2i(handClosedDetection.ROI_Pt().x()+boxWidth,	handClosedDetection.ROI_Pt().y());
				glVertex2i(handClosedDetection.ROI_Pt().x()+boxWidth,	handClosedDetection.ROI_Pt().y()+boxHeight);
				glVertex2i(handClosedDetection.ROI_Pt().x(),					handClosedDetection.ROI_Pt().y()+boxHeight);
			glEnd();



			//Mat A;
			//A = dpMD;
			//Mat D (A, Rect(10, 10, 100, 100) );

			//cursorQt.MoveCursor(handPt.X,handPt.Y); // KiOP

// ___b5___

			int depthTresMin = handPt.Z-80;
			int depthTresMax = handPt.Z+80;
			unsigned char imBin[maxBoxSize][maxBoxSize] = {0};

			for (i = 0; i<boxWidth; i++)
				for (j = 0; j<boxHeight; j++)
				{
					depth = dpMD(i+xBox,j+yBox);
					imBin[j][i] = 255*(int)((depth > depthTresMin) && (depth < depthTresMax));

					//unsigned int valDepth = 255*(int)((dpMD(i+xBox,j+yBox) > depthTresMin) && (dpMD(i+xBox,j+yBox) < depthTresMax));
					//imBin[j][i] = valDepth;
				}

			Mat imProfM, contours, Aff;
			imProfM = Mat(maxBoxSize,maxBoxSize,CV_8UC1,imBin);
			handClosedDetection.AfficheTest(dpMD, Aff);

			//namedWindow("test14");
			//imshow("test14", Aff);

			unsigned int gaucheX = 0, gaucheY = 0, hautX = 0, hautY = boxHeight, droiteX = 0, droiteY = 0, basX = 0, basY = 0;;

			for (i = 0; i<boxWidth; i++)
				for (j = 0; j<boxHeight; j++)
					if (imProfM.at<unsigned char>(j,i))
					{
						// gauche
						if (!gaucheX)
						{
							gaucheX = i; gaucheY = j;
						}

						// droite
						if (droiteX<i)
						{
							droiteX = i; droiteY = j;
						}

						// haut
						if (hautY>j)
						{
							hautX = i; hautY = j;
						}
					}
			basX = hautX; basY = boxHeight * 0.6 + hautY * 0.8;

		/*	
			const unsigned short nbPoints = 51;
			//unsigned int gauche[2][nbPoints] = {0};
			unsigned int compteur = 0;
			Point gauche[nbPoints] = {0};
			
			for (i = 0; i<(boxWidth/2); i++)
				for (j = 0; j<boxHeight; j++)
				{
					if (imProfM.at<unsigned char>(j,i) && (compteur<nbPoints-1))
					{
						//cout << "compteur : " << compteur << endl;
						gauche[compteur].y = j;
						gauche[compteur].x = i;
						compteur++;
					}
				}

			Point somme = 0;
			for (int n=0;n<nbPoints;n++)
			{
				somme+=gauche[n];
			}

			//Point temp = somme/nbPoints;
			unsigned int gaucheMoyX = somme.x/nbPoints;
			unsigned int gaucheMoyY = somme.y/nbPoints;
        */

			int largeurSurface = (droiteX - gaucheX);
			int hauteurSurface = 2*(gaucheY-hautY);

			static int surface1 = 0, surface2 = 0, surface3 = 0, surface4 = 0, surfacePrec = 0, surfaceMoy = 0, surfaceMoyPrec = 0;;
			surfacePrec = surface4;
			surface4 = surface3;
			surface3 = surface2;
			surface2 = surface1;
			surface1 = largeurSurface * hauteurSurface;

			if (!(compteurFrame%4))
			{
				surfaceMoyPrec = surfaceMoy;
				surfaceMoy = (surface1+surface2+surface3+surface4)/4;
			}
			//cout << "SurfMoy : " << surfaceMoy;

			
			// Affichage des 3 points
			int color = 127, taille = 8;
			for (i=0; i<taille; i++)
				for (j=0; j<taille; j++)
				{
					imProfM.at<unsigned char>(gaucheY+j,gaucheX+i) = color;
					imProfM.at<unsigned char>(droiteY+j,droiteX+i) = color;
					imProfM.at<unsigned char>(hautY+j  ,hautX+i  ) = color;
					imProfM.at<unsigned char>(basY+j   ,basX+i   ) = color;

					//imProfM.at<unsigned char>(gaucheMoyY+j,gaucheMoyX+i) = color;
					//imProfM.at<unsigned char>(gaucheMoyY-j,gaucheMoyX-i) = color;
				}

			// Affichage du cadre
			for (i=0; i<maxBoxSize; i++)
				for (j=0; j<maxBoxSize; j++)
				{
					if ( (j==hautY) || (j==basY) || (i==gaucheX) || (i==droiteX) )
						imProfM.at<unsigned char>(j,i) = color;
				}

			//namedWindow("test5");
			//cvNamedWindow("test5",0);
			//cvResizeWindow("test5",500,500);
			//cvShowImage("test5", imProfM);
			//imshow("test5", imProfM);

			
			
// ___e5___

			//
			static int profS1 = 0, profS2 = 0, profS3 = 0, profS4 = 0, profSPrec = 0;
			profSPrec = profS4;
			profS4 = profS3;
			profS3 = profS2;
			profS2 = profS1;
			profS1 = handPt.Z;
			int deltaZ = profS1 - profSPrec;
			//cout << "DeltaZ : " << deltaZ;

			float rapport = ( (abs(deltaZ)>40) ? 1.0 : float(surfaceMoy)/float(surfaceMoyPrec) );
			static const float seuilBas = 0.5, seuilHaut = 1/seuilBas;
			//cout << "Z : " << handPt.Z << "\taire : " << aireS1 << endl;

			static bool mainFermeePrec = false;
			mainFermeePrec = mainFermee;

			// Détection de main fermée
			if			 ( (rapport < seuilBas ) && (!mainFermee) && toolSelectable )
				mainFermee = true;
			else if	 ( (rapport > seuilHaut) && ( mainFermee) )
				mainFermee = false;

			//cout << "\tRaprt : " << rapport << ( (mainFermee && !mainFermeePrec) || (!mainFermee && mainFermeePrec) ? "\tSeuil" : "" ) << endl;

            /*
			// mode Souris
			if ((currentState == 3) && (cursor.GetState() != 0)) 
			{
				if			(cursor.GetCursorType() == 1) // Souris SteadyClic
				{
					if (cursor.CheckExitMouseMode())
						cursor.ChangeState(0);
				}
				else if ((cursor.GetCursorType() == 2) && (cursor.GetCursorInitialised())) //Souris HandClosedClic
				{
					cursor.SetMainFermee(mainFermee);
				}
			}

			
			if (mainFermee)
			{
				glColor3ub(255,0,0);
			}
			else
			{
				glColor3ub(0,0,255);
			}
			int cote = 50;
			int carreX = xSize-cote-10, carreY = 10;
			glRecti(carreX,carreY,carreX+cote,carreY+cote);
			if (cursor.GetCursorType() == 2)
				glRecti(carreX,carreY+10+cote,carreX+cote,carreY+10+2*cote);
				//glRecti(carreX,carreY+10+cote,500+cote,cote+10+cote);
            */
			
// ___e1___
//


		}
	}
	glutSwapBuffers();

	if (actualFrame >= nFrames)
	{
		handleState();
		actualFrame = -1;
	}
	else if(actualFrame == 0)
	{
		lastX = handPt.X;
		lastY = handPt.Y;
		lastZ = handPt.Z;
	}
	actualFrame = actualFrame+1;
}



void initGL(int argc, char *argv[]){
	glutInit(&argc,argv);
	glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH);
	glutInitWindowSize(WIN_WIDTH, WIN_HEIGHT);

	// Fenêtre de données source
	glutCreateWindow(TITLE);
	//RepositionnementFenetre(INIT_POS_WINDOW);
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

	/////////////////////////////////////////    QT         /////////////////////////
	// Initialisation des ressources et création de la fenêtre avec les icônes
	Q_INIT_RESOURCE(images);
	
	Pixmap *p1 = new Pixmap(QPixmap(":/images/Resources/mouse.png").scaled(64,64));
	Pixmap *p2 = new Pixmap(QPixmap(":/images/Resources/layout.png").scaled(64,64));
	Pixmap *p3 = new Pixmap(QPixmap(":/images/Resources/move.png").scaled(64,64));
	Pixmap *p4 = new Pixmap(QPixmap(":/images/Resources/zoom.png").scaled(64,64));
	Pixmap *p5 = new Pixmap(QPixmap(":/images/Resources/scroll.png").scaled(64,64));
	Pixmap *p6 = new Pixmap(QPixmap(":/images/Resources/contrast.png").scaled(64,64));
	Pixmap *p7 = new Pixmap(QPixmap(":/images/Resources/stop.png").scaled(64,64));
	

	p1->setObjectName("mouse");
	p2->setObjectName("layout");
	p3->setObjectName("move");
	p4->setObjectName("zoom");
	p5->setObjectName("scroll");
	p6->setObjectName("contrast");
	p7->setObjectName("stop");
	
	p1->setGeometry(QRectF(  0.0,   192.0, 64.0, 64.0));
	p2->setGeometry(QRectF(  128.0,   192.0, 64.0, 64.0));
	p3->setGeometry(QRectF(  256.0,   192.0, 64.0, 64.0));
	p4->setGeometry(QRectF(  384.0,   192.0, 64.0, 64.0));
	p5->setGeometry(QRectF(  512.0,   192.0, 64.0, 64.0));
	p6->setGeometry(QRectF(  640.0,   192.0, 64.0, 64.0));
	p7->setGeometry(QRectF(  768.0,   192.0, 64.0, 64.0));


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

	//window->show();
	/////////////////////////////////////////////////////////////////////////////////////



	////////////// LAYOUT
	Pixmap *l1 = new Pixmap(QPixmap(":/images/Resources/layouts/_1x1.png").scaled(64,64));
	Pixmap *l2 = new Pixmap(QPixmap(":/images/Resources/layouts/_1x2.png").scaled(64,64));
	Pixmap *l3 = new Pixmap(QPixmap(":/images/Resources/layouts/_2x1.png").scaled(64,64));
	Pixmap *l4 = new Pixmap(QPixmap(":/images/Resources/layouts/_3a.png").scaled(64,64));
	Pixmap *l5 = new Pixmap(QPixmap(":/images/Resources/layouts/_3b.png").scaled(64,64));
	Pixmap *l6 = new Pixmap(QPixmap(":/images/Resources/layouts/_2x2.png").scaled(64,64));
	

	l1->setObjectName("1x1");
	l2->setObjectName("1x2");
	l3->setObjectName("2x1");
	l4->setObjectName("3a");
	l5->setObjectName("3b");
	l6->setObjectName("2x2");
	
	l1->setGeometry(QRectF(  0.0,   192.0,	64.0, 64.0));
	l2->setGeometry(QRectF(  128.0, 192.0,	64.0, 64.0));
	l3->setGeometry(QRectF(  256.0, 192.0,	64.0, 64.0));
	l4->setGeometry(QRectF(  384.0, 192.0,	64.0, 64.0));
	l5->setGeometry(QRectF(  512.0, 192.0,	64.0, 64.0));
	l6->setGeometry(QRectF(  640.0, 192.0,	64.0, 64.0));

	pixL.push_back(l1);
	pixL.push_back(l2);
	pixL.push_back(l3);
	pixL.push_back(l4);
	pixL.push_back(l5);
	pixL.push_back(l6);

	viewLayouts->setSize(768,256);
	QGraphicsScene *sceneLayout = new QGraphicsScene(0,0,768,256);
	sceneLayout->addItem(l1);
	sceneLayout->addItem(l2);
	sceneLayout->addItem(l3);
	sceneLayout->addItem(l4);
	sceneLayout->addItem(l5);
	sceneLayout->addItem(l6);
	viewLayouts->setScene(sceneLayout);

	//viewLayouts->show();

	
	/*for(int i=0; i<=totalTools; i++){
		QString chemin = ":/images/Resources/_"+pix.operator[](i)->objectName()+".png";
		//printf("\n"+chemin.toAscii()+"\n");
		int posi = positionTool[i];
		pix.operator[](i)->setGeometry(QRectF( posi*60.0, posi*(-10.0), 128.0, 128.0));
		pix.operator[](i)->load(QPixmap(chemin).scaled(78+(posi*(10)),78+(posi*(10))));
	}*/

	Initialisation();

	/////////////////////////////////////////// OPEN_NI / NITE / OPENGL ////////////////
	xn::EnumerationErrors errors;

	status = context.InitFromXmlFile(XML_FILE);
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

/*======================= STEADY ================================*/
	// Steady
	sd.RegisterSteady(NULL,&Steady_Detected);
	sd.RegisterNotSteady(NULL,&NotSteady_Detected);
	sd.SetDetectionDuration(1200);
	sd.SetMaximumStdDevForSteady(MAX_STD_DEV_FOR_STEADY);
	sd.SetMinimumStdDevForNotSteady(MAX_STD_DEV_FOR_NOT_STEADY);

	// Steady 2
	sd2.RegisterSteady(NULL,&Steady_Detected2);
	sd2.RegisterNotSteady(NULL,&NotSteady_Detected2);
	sd2.SetDetectionDuration(2000);
	sd2.SetMaximumStdDevForSteady(MAX_STD_DEV_FOR_STEADY);
	sd2.SetMinimumStdDevForNotSteady(MAX_STD_DEV_FOR_NOT_STEADY);

	// Steady 3
	sd3.RegisterSteady(NULL,&Steady_Detected3);
	sd3.SetDetectionDuration(3000);
	sd3.SetMaximumStdDevForSteady(MAX_STD_DEV_FOR_STEADY);
	sd3.SetMinimumStdDevForNotSteady(MAX_STD_DEV_FOR_NOT_STEADY);

		// Steady 02
	sd02.RegisterSteady(NULL,&Steady_Detected02);
	sd02.SetDetectionDuration(800);
	sd02.SetMaximumStdDevForSteady(MAX_STD_DEV_FOR_STEADY);
	sd02.SetMinimumStdDevForNotSteady(MAX_STD_DEV_FOR_NOT_STEADY);


	// Wave detector
	XnVWaveDetector waveDetect;
	waveDetect.RegisterWave(&context,&Wave_Detected);
	//waveDetect.SetFlipCount(10);
	//waveDetect.SetMaxDeviation(1);
	//waveDetect.SetMinLength(100);

	// Add Listener
	sessionManager->AddListener(pointControl);
	sessionManager->AddListener(&sd);
	sessionManager->AddListener(&sd2);
	sessionManager->AddListener(&sd3);
	sessionManager->AddListener(&sd02);
	sessionManager->AddListener(g_pFlowRouter);
	sessionManager->AddListener(&waveDetect);
		
	nullifyHandPoint();
	myHandsGenerator.SetSmoothing(g_fSmoothing);

	// Initialization done. Start generating
	status = context.StartGeneratingAll();
	CHECK_STATUS(status, "StartGenerating");

	initGL(argc,argv);
	
	//app.exec();
	//cout << "BIJOUR" << endl;
	glutMainLoop();
	//cout << "ADIEU" << endl;
	
	return app.exec();
	//return 0;
}



/**** CALLBACK DEFINITIONS ****/

/**********************************************************************************
Session started event handler. Session manager calls this when the session begins
**********************************************************************************/
void XN_CALLBACK_TYPE sessionStart(const XnPoint3D& ptPosition, void* UserCxt){
	activeSession = true;
	printf("\nin session");
	window->show();	
	lastState = currentState;
	currentState = 1;
}

/**********************************************************************************
session end event handler. Session manager calls this when session ends
**********************************************************************************/
void XN_CALLBACK_TYPE sessionEnd(void* UserCxt){
	activeSession = false;
	printf("\nnot in session");
	window->hide();
	viewLayouts->hide();
	lastState = currentState;
	currentState = 0;
	toolSelectable = false;
	mainFermee = false;
}

/**********************************************************************************
point created event handler. this is called when the pointControl detects the creation
of the hand point. This is called only once when the hand point is detected
**********************************************************************************/
void XN_CALLBACK_TYPE pointCreate(const XnVHandPointContext *pContext, const XnPoint3D &ptFocus, void *cxt){
	XnPoint3D coords(pContext->ptPosition);
	dpGen.ConvertRealWorldToProjective(1,&coords,&handPt);
	lastPt = handPt;
	mainFermee = false; // La main est ouverte lors d'un wave
}
/**********************************************************************************
Following the point created method, any update in the hand point coordinates are 
reflected through this event handler
**********************************************************************************/
void XN_CALLBACK_TYPE pointUpdate(const XnVHandPointContext *pContext, void *cxt){
	XnPoint3D coords(pContext->ptPosition);
	dpGen.ConvertRealWorldToProjective(1,&coords,&handPt);
}
/**********************************************************************************
when the point can no longer be tracked, this event handler is invoked. Here we 
nullify the hand point variable 
**********************************************************************************/
void XN_CALLBACK_TYPE pointDestroy(XnUInt32 nID, void *cxt){
	lastState = currentState;
	currentState = 0;
	windowActiveTool->hide();
	for (int i=0; i<=totalTools; i++){
		pix.operator[](i)->show();
		//cout << "Show " << i << endl;
	}
	window->hide();
	nullifyHandPoint();
	printf("\nDead");
}


// Callback for no hand detected
void XN_CALLBACK_TYPE NoHands(void* UserCxt)
{
	//cursor.ChangeState(0);
}

// Callback for when the focus is in progress
void XN_CALLBACK_TYPE FocusProgress(const XnChar* strFocus, 
		const XnPoint3D& ptPosition, XnFloat fProgress, void* UserCxt)
{
	//printf("Focus progress: %s @(%f,%f,%f): %f\n", strFocus, 
	//		ptPosition.X, ptPosition.Y, ptPosition.Z, fProgress);

/*
	/// Pour réafficher l'écran s'il s'est éteint lors d'un wave
	POINT temp;
	GetCursorPos(&temp);
	int test = ((temp.x < SCRSZW/2) ? 1 : -1);
	for (int i=1; i<50; i++)
		SetCursorPos(temp.x + i*test, temp.y);
	//SetCursorPos(temp.x, temp.y);
	//cout << "AAAAAAAAA" << endl;
 */
}


// Callback for wave
void XN_CALLBACK_TYPE Wave_Detected(void *pUserCxt)
{
	printf("\n WAVE \n");
	

	//g_pSessionManager->EndSession();
}



// Callback for steady
void XN_CALLBACK_TYPE Steady_Detected(XnUInt32 nId, XnFloat fStdDev, void *pUserCxt)
{
	
	printf("  STEADY 1\n");

	if (currentState != 4)
	{
		if (currentState == 3) // mode souris
		{
			//cursor.SteadyDetected(1);
			//sd.Reset();
		}
		else
			steadyState = true;

	}
}


void XN_CALLBACK_TYPE Steady_Detected2(XnUInt32 nId, XnFloat fStdDev, void *pUserCxt)
{
	printf("  STEADY 2\n");

	if (currentState == 3) // mode souris
	{
		//cursor.SteadyDetected(2);
	}
	else if (currentState == 2)
	{
		steady2 = true;
	}
}


void XN_CALLBACK_TYPE Steady_Detected3(XnUInt32 nId, XnFloat fStdDev, void *pUserCxt)
{
	printf("  STEADY 3\n");

	if (currentState == 3) // mode souris
	{
		//cursor.SteadyDetected(3);
	}
}

void XN_CALLBACK_TYPE Steady_Detected02(XnUInt32 nId, XnFloat fStdDev, void *pUserCxt)
{
	printf("  STEADY 02\n");

	toolSelectable = true;
}


// Callback for not steady
void XN_CALLBACK_TYPE NotSteady_Detected(XnUInt32 nId, XnFloat fStdDev, void *pUserCxt)
{
	printf("\n NOT STEADY \n");

	if (currentState == 3) // mode souris
		//cursor.NotSteadyDetected();

	steadyState = false;
}

void XN_CALLBACK_TYPE NotSteady_Detected2(XnUInt32 nId, XnFloat fStdDev, void *pUserCxt)
{

	steady2 = false;
}





