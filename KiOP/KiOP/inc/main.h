
#ifndef __MAIN_H__
#define __MAIN_H__


//==========================================================================//
//============================ FICHIERS INCLUS =============================//

// Local headers
#include "Parametres.h"
#include "Gestion_GLUT.h"
#include "Control_Cursor_Qt.h"
#include "Hand_Closed_Detection.h"
#include "Hand_Point.h"
#include "Point_3D.h"
#include "Point_2D.h"

#ifdef _OS_WIN_
	#include "Gestion_Curseurs.h"
#endif
#include "graphicsview.h"
#include "pixmap.h"
#include "telnetclient.h"
#include "tooldock.h"

// Headers de base
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <vector>
#include <string>
#include <math.h>

// Headers for OpenGL
//#include <GL/glut.h>
//#include <GL/GLU.h>
//#include <GL/gl.h>
#include <GLUT/glut.h>

// Headers for OpenNI
#include <XnOpenNI.h>
#include <XnCppWrapper.h>
#include <XnHash.h>
#include <XnLog.h>

// Headers for NITE
#include <XnVNite.h>
#include <XnVSteadyDetector.h>
#include <XnVPointControl.h>
#include <XnVHandPointContext.h>
#include "XnVDepthMessage.h"
#include <XnVPushDetector.h>
#include <XnVWaveDetector.h>

// Headers for OpenCV
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/highgui/highgui.hpp"

// Headers for Qt
#include <QtCore>
#include <QtGui>
#include <QtGui/QApplication>
#include <QtGui/QCursor>

// Namespaces
using namespace std;
using namespace cv;


//==========================================================================//
//============================== CONSTANTES ================================//

#define TITLE "KiOP v1.0.0-beta"

#define DP_FAR 5000
#define DP_CLOSE 0
#define MAX_COLOR 255
#define COLORS 20

#if 1
	#define DISTANCE_MIN 800
	#define DISTANCE_MAX 2000
#else
	#define DISTANCE_MIN 1200
	#define DISTANCE_MAX 1600
#endif

#if defined _OS_WIN_
	#define SENSIBILITE_MOVE 2
	#define SENSIBILITE_MOVE_X (SENSIBILITE_MOVE)
	#define SENSIBILITE_MOVE_Y (SENSIBILITE_MOVE)
	#define SENSIBILITE_CONTRAST 8
	#define SENSIBILITE_CONTRAST_X (SENSIBILITE_CONTRAST)
	#define SENSIBILITE_CONTRAST_Y (SENSIBILITE_CONTRAST)
	#define SENSIBILITE_ZOOM 1
	#define SENSIBILITE_SCROLL 1
#elif defined _OS_MAC_
	#define SENSIBILITE_MOVE 5
	#define SENSIBILITE_MOVE_X (SENSIBILITE_MOVE)
	#define SENSIBILITE_MOVE_Y (SENSIBILITE_MOVE)
	#define SENSIBILITE_CONTRAST 2
	#define SENSIBILITE_CONTRAST_X (SENSIBILITE_CONTRAST)
	#define SENSIBILITE_CONTRAST_Y (SENSIBILITE_CONTRAST)
	#define SENSIBILITE_ZOOM 1
	#define SENSIBILITE_SCROLL 1
#endif

#define nullifyHandPoint()	\
{														\
	g_handPt.X = -1;						\
	g_handPt.Y = -1;						\
	g_handPt.Z = -1;						\
}

#define CHECK_STATUS(rc, what)																	\
if (rc != XN_STATUS_OK)																					\
{																																\
	cout << what << " failed: " << xnGetStatusString(rc) << endl;	\
	return rc;																										\
}

#define CHECK_ERRORS(rc, errors, what)	\
if (rc == XN_STATUS_NO_NODE_PRESENT)		\
{																				\
	XnChar strError[1024];								\
	errors.ToString(strError, 1024);			\
	cout << strError << endl;							\
	return (rc);													\
}


//==========================================================================//
//============================== PROTOTYPES ================================//

void Initialisation(void);
void CleanupExit();

void IcrWithLimits(int &val, int icr, int limUp, int limDown);

inline bool isHandPointNull();

void chooseTool(int &currentTool, int &lastTool, int &totalTools);
//void browse(int currentTool, int lastTool, vector<Pixmap*> pix);
void browse(int currentTool, int lastTool, ToolDock &tools);

void CheckHandDown();
void CheckBaffe();

bool SelectionDansUnMenu(short currentIcon);

bool ConditionActiveTool();
bool ConditionExitTool();

bool ConditionLeftClicPress();
bool ConditionLeftClicRelease();

void ChangeState(int newState);
void handleState();

void glutKeyboard (unsigned char key, int x, int y);
void glutDisplay();
void UpdateHandClosed(void);
void initGL(int argc, char *argv[]);

void XN_CALLBACK_TYPE sessionStart(const XnPoint3D& ptPosition, void* UserCxt);
void XN_CALLBACK_TYPE sessionEnd(void* UserCxt);
void XN_CALLBACK_TYPE pointCreate(const XnVHandPointContext *pContext, const XnPoint3D &ptFocus, void *cxt);
void XN_CALLBACK_TYPE pointUpdate(const XnVHandPointContext *pContext, void *cxt);
void XN_CALLBACK_TYPE pointDestroy(XnUInt32 nID, void *cxt);
void XN_CALLBACK_TYPE NoHands(void* UserCxt);
void XN_CALLBACK_TYPE FocusProgress(const XnChar* strFocus, const XnPoint3D& ptPosition, XnFloat fProgress, void* UserCxt);
void XN_CALLBACK_TYPE Wave_Detected(void *pUserCxt);
void SimulateCtrlBar(void);

#endif //========================== FIN ====================================//










