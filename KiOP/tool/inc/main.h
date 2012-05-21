
#ifndef main_h
#define main_h


//==========================================================================//
//============================ FICHIERS INCLUS =============================//

#include "Parametres.h"

#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <vector>
#include <string>
#include <math.h>

#include <QtGui/QApplication>
#include <QtGui>
//#include <qcursor.h> 
#include <QtGui/QCursor> // test de curseur multi-plateforme
#include "pixmap.h"
#include "graphicsview.h"
#include "telnetclient.h"

//Headers for OpenNI
#include <XnOpenNI.h>
#include <XnCppWrapper.h>
#include <XnHash.h>
#include <XnLog.h>

//Headers for NITE
#include <XnVNite.h>
#include <XnVSteadyDetector.h>
#include <XnVPointControl.h>
#include <XnVHandPointContext.h>
#include "XnVDepthMessage.h"
#include <XnVPushDetector.h>
#include <XnVWaveDetector.h>

// local header
#include "Gestion_GLUT.h"
//#include "Cursor.h"
#ifdef _OS_WIN_
	#include "Gestion_Curseurs.h"
#endif

// KiOP
#include "Control_Cursor_Qt.h"
#include "Hand_Closed_Detection.h"

//OPENGL
//#include <GL\glut.h>
//#include <GL\GLU.h>
//#include <GL\gl.h>
#include <GL/glut.h>
#include <GL/GLU.h>
#include <GL/gl.h>

//#include "opencv2/opencv.h"
//#include "opencv2/imgproc/imgproc.hpp"
//#include "opencv2/highgui/highgui.hpp"
//#include "cv.h"
#include "imgproc/include/opencv2/imgproc/imgproc.hpp"
#include "highgui/include/opencv2/highgui/highgui.hpp"

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


#define nullifyHandPoint(){ \
	handPt.X = -1; \
	handPt.Y = -1; \
	handPt.Z = -1; \
}

/*
#define TEST_STEADY(){ \
	for (int i = 0; i<10; i++) \
		handPt.X = 0; \

}*/

#define CHECK_STATUS(rc, what)											\
	if (rc != XN_STATUS_OK)											\
{																\
		cout << what << " failed: " << xnGetStatusString(rc) << endl;	\
return rc;													\
}


#define CHECK_ERRORS(rc, errors, what)		\
	if (rc == XN_STATUS_NO_NODE_PRESENT)	\
{										\
	XnChar strError[1024];				\
	errors.ToString(strError, 1024);	\
	cout << strError << endl;			\
	return (rc);						\
}

#endif


/**
Callback routines
*/
void XN_CALLBACK_TYPE sessionStart(const XnPoint3D& ptPosition, void* UserCxt);					//session started event callback
void XN_CALLBACK_TYPE sessionEnd(void* UserCxt);												//session ended event callback

void XN_CALLBACK_TYPE pointCreate(const XnVHandPointContext *pContext, const XnPoint3D &ptFocus, void *cxt);	//point created callback
void XN_CALLBACK_TYPE pointUpdate(const XnVHandPointContext *pContext, void *cxt);								//point updated callback
void XN_CALLBACK_TYPE pointDestroy(XnUInt32 nID, void *cxt);													//point destroyed callback
void XN_CALLBACK_TYPE Steady_Detected(XnUInt32 nId, XnFloat fStdDev, void *pUserCxt);
void XN_CALLBACK_TYPE Steady_Detected2(XnUInt32 nId, XnFloat fStdDev, void *pUserCxt);
void XN_CALLBACK_TYPE Steady_Detected3(XnUInt32 nId, XnFloat fStdDev, void *pUserCxt);
void XN_CALLBACK_TYPE Steady_Detected02(XnUInt32 nId, XnFloat fStdDev, void *pUserCxt);
void XN_CALLBACK_TYPE NotSteady_Detected(XnUInt32 nId, XnFloat fStdDev, void *pUserCxt);
void XN_CALLBACK_TYPE NotSteady_Detected2(XnUInt32 nId, XnFloat fStdDev, void *pUserCxt);
void XN_CALLBACK_TYPE FocusProgress(const XnChar* strFocus, 
		const XnPoint3D& ptPosition, XnFloat fProgress, void* UserCxt);
void XN_CALLBACK_TYPE NoHands(void* UserCxt);
void XN_CALLBACK_TYPE Wave_Detected(void *pUserCxt);
//----------------------------------------------------------------------------


//Prototypes
inline bool isHandPointNull();
bool detectLeft();
bool detectRight();
bool detectClick();

void browse();
void handleState();
void glutKeyboard (unsigned char key, int x, int y);
void onTimerOut(int value);
void TimerTest(int value);
void glutDisplay();
void initGL(int argc, char *argv[]);
////
void Initialisation(void);
void ChangeCursorState(unsigned short newState);
void CleanupExit();

void TestChangeCursorState(unsigned int newState);
void TestNewCursorPos(int NewX, int NewY, int NewZ);






