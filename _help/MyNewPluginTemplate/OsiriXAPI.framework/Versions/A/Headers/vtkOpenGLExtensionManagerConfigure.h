/*=========================================================================

  Program:   Visualization Toolkit
  Module:    vtkOpenGLExtensionManagerConfigure.h.in

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/

/*
 * Copyright 2004 Sandia Corporation.
 * Under the terms of Contract DE-AC04-94AL85000, there is a non-exclusive
 * license for use of this work by or on behalf of the
 * U.S. Government. Redistribution and use in source and binary forms, with
 * or without modification, are permitted provided that this Notice and any
 * statement of authorship are reproduced on all copies.
 */

/* #undef VTK_USE_WGL_GET_PROC_ADDRESS */
#define VTK_USE_APPLE_LOADER
/* #undef VTK_USE_GLX_GET_PROC_ADDRESS */
/* #undef VTK_USE_GLX_GET_PROC_ADDRESS_ARB */
/* #undef VTK_USE_VTK_DYNAMIC_LOADER */
/* #undef VTK_NO_EXTENSION_LOADING */

/* #undef VTK_DEFINE_GLX_GET_PROC_ADDRESS_PROTOTYPE */

// If using vtkDynamicLoader, we need to know where the libraries are.
#define OPENGL_LIBRARIES "/System/Library/Frameworks/AGL.framework;/System/Library/Frameworks/OpenGL.framework"

