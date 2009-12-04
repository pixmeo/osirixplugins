/*
 *  Defaults.h
 *  PetSpectFusion, an osirix plugin
 *
 *	File contains default values used by the registration
 *
 *  Created by Brian Jensen on 12.04.09.
 *  Copyright 2009. All rights reserved.
 *
 */

//This variable controls the current itk namespace used by the plugin so that it doesn't collide with Osirix's itk own version, see documentation
#define ITKNS psfITK

//Make sure debug output is enabled when compiling in development mode, and activated in deployment mode when NSDebugEnabled is set
#ifdef DEBUG
#define DebugLog(...) NSLog(__VA_ARGS__)
#define DebugEnable(...) __VA_ARGS__
#else
#define DebugLog(...) if(NSDebugEnabled) NSLog(__VA_ARGS__)
#define DebugEnable(...) if(NSDebugEnabled) __VA_ARGS__
#endif

#define DEFAULT_BINS 75
#define DEFAULT_MINSTEP 0.2
#define DEFAULT_MAXSTEP 2.3
#define DEFAULT_MAXITER 250
#define DEFAULT_SAMPLERATE 0.7
#define DEFAULT_XTRANS_SCALE 1.0 / 200000.0
#define DEFAULT_YTRANS_SCALE 1.0 / 200000.0
#define DEFAULT_ZTRANS_SCALE 1.0 / 200000.0
#define DEFAULT_XROT_SCALE 1.0
#define DEFAULT_YROT_SCALE 1.0
#define DEFAULT_ZROT_SCALE 10.0
#define DEFAULT_DO_MULTIRES false
#define DEFAULT_MULTIRES_LEVELS 3

