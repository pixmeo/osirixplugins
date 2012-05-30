
#ifndef __MAIN_H__
#define __MAIN_H__


//==========================================================================//
//============================ FICHIERS INCLUS =============================//

// Local headers
#include "Parametres.h"
#include "Gestion_GLUT.h"
#include "Control_Cursor_Qt.h"
#include "Hand_Closed_Detection.h"
#ifdef _OS_WIN_
	#include "Cursor.h"
	#include "Gestion_Curseurs.h"
#endif
#include "graphicsview.h"
#include "pixmap.h"
#include "telnetclient.h"

// Headers de base
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <vector>
#include <string>
#include <math.h>

// Headers for OpenGL
#include <GL/glut.h>
#include <GL/GLU.h>
#include <GL/gl.h>

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

#define XML_FILE "openni.xml"
#define TITLE "KinectOP"

#define DP_FAR 5000
#define DP_CLOSE 0
#define MAX_COLOR 255
#define COLORS 20


#define nullifyHandPoint()	\
{														\
	handPt.X = -1;						\
	handPt.Y = -1;						\
	handPt.Z = -1;						\
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

inline bool isHandPointNull();
bool detectLeft();
bool detectRight();
bool detectForward();
bool detectBackward();
bool detectClick();

void chooseTool(int &currentTool, int &lastTool, int &totalTools);
void browse(int currentTool, int lastTool, vector<Pixmap*> pix);
void handleState();

void glutKeyboard (unsigned char key, int x, int y);
void onTimerOut(int value);
void TimerTest(int value);
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
void XN_CALLBACK_TYPE Steady_Detected(XnUInt32 nId, XnFloat fStdDev, void *pUserCxt);
void XN_CALLBACK_TYPE Steady_Detected2(XnUInt32 nId, XnFloat fStdDev, void *pUserCxt);
void XN_CALLBACK_TYPE Steady_Detected3(XnUInt32 nId, XnFloat fStdDev, void *pUserCxt);
void XN_CALLBACK_TYPE Steady_Detected02(XnUInt32 nId, XnFloat fStdDev, void *pUserCxt);
void XN_CALLBACK_TYPE NotSteady_Detected(XnUInt32 nId, XnFloat fStdDev, void *pUserCxt);
void XN_CALLBACK_TYPE NotSteady_Detected2(XnUInt32 nId, XnFloat fStdDev, void *pUserCxt);


#endif //========================== FIN ====================================//










