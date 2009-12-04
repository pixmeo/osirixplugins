/**
 * \brief NMSegmentation.h, the main class for the NMSegmentation Osirix plugin.  
 *
 * \authors Brian Jensen
 *          <br>
 *          {jensen}\@in.tum.de
 * \ingroup NMSegmentation
 * \version 1.01
 * \date 01.05.2008
 *
 *	\description This is the class that is intantiated when OsiriX loads the plugin. This class is
 *				responsible for instantiating the segmentation controller while searching for any
 *				open instances to prevent multiple instances being run.
 *
 *
 * \par License:
 * Copyright (c) 2008 - 2009,
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

#import "Project_defs.h"

#import "PluginFilter.h"
#import "NMRegionGrowingController.h"

@class SettingsWindowController;

@interface NMSegmentationFilter: PluginFilter {

}

/**
 *	Plugin entry point
 */
- (long) filterImage:(NSString*) menuName;

/**
 *	Function tries to find a valid instance of the plugin controller for the given registered and main viewers
 */
+ (id) getControllerForMainViewer:(ViewerController*) mViewer registeredViewer:(ViewerController*) rViewer; 

@end
