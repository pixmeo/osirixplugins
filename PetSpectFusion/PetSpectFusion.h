/**
 * \brief This class is the initial entry point called by osirix when the plugin starts
 *
 * \authors Brian Jensen
 *          <br>
 *          {jensen}\@cs.tum.edu
 * \ingroup PetSpectFusion
 * \version 1.0
 * \date 16.02.2009
 *
 * \par License:
 * Copyright (c) 2007 - 2009,
 * This programm was created as part of a student research project in cooperation
 * with the Department for Computer Science, Chair XVI
 * and the Nuklearmedizinische Klinik, Klinikum Rechts der Isar
 *
 * <br>
 * <br>
 * All rights reserved.
 * <br>
 * <br>
 * See <a href="COPYRIGHT.txt">COPYRIGHT.txt</a> for details.
 * <br>
 * <br>
 * This software is distributed WITHOUT ANY WARRANTY; without even 
 * <br>
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
 * <br>
 * PURPOSE.  See the <a href="COPYRIGHT.txt">COPYRIGHT.txt</a> notice
 * for more information.
 *
 */


#import <Foundation/Foundation.h>
#import "PluginFilter.h"

//This file has to be included by files that access any ITK functions, so that the namespace can correctly determined
#import "Project_defs.h"

//make sure any any itk definitons don't collide with objective-c keywords
#define id Id
#include "Typedefs.h"
#undef id

#import "ViewerController.h"

/**
 *	This is the main class that is responsible for launching the window controlling the registration
 *
 */
@interface PetSpectFusion : PluginFilter {

}

/**
 * Entry point called by OsiriX when the plugin is triggered
 */
- (long) filterImage:(NSString*) menuName;

/**
 *	Search through all open windows and make sure we don't create two settingsControllers for the same viewer pair
 */
+(id) getControllerForFixedViewer:(ViewerController*) fViewer movingViewer:(ViewerController*) mViewer;

@end
