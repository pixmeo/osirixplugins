/*
 *  Proejct_defs.h
 *  NMSegmentation, an osirix plugin
 *
 *	File contains default values and definitions used throughout the plugin
 *
 *  Created by Brian Jensen on 12.04.09.
 *  Copyright 2009. All rights reserved.
 *
 */

//This variable controls the current itk namespace used by the plugin so that it doesn't collide with Osirix's itk own version, see documentation

#import <Foundation/NSDebug.h>

#define ITKNS nmITK

//Make sure debug output is enabled when compiling in development mode, and activated in deployment mode when NSDebugEnabled is set
#ifdef DEBUG
#define DebugLog(...) NSLog(__VA_ARGS__)
#define DebugEnable(...) __VA_ARGS__
#else
#define DebugLog(...) if(NSDebugEnabled) NSLog(__VA_ARGS__)
#define DebugEnable(...) if(NSDebugEnabled) __VA_ARGS__
#endif