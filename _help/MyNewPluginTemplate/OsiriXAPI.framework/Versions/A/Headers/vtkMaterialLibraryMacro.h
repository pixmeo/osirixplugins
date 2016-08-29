/*=========================================================================

  Program:   Visualization Toolkit
  Module:    vtkMaterialLibraryMacro.h.in

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/

#include "vtkMaterialXMLLibrary.h"

#define vtkMaterialLibraryMacro(name) \
 if (strcmp(name, "GLSLTwisted") == 0)\
      {\
      return vtkMaterialGLSLTwistedGetXML();\
      }\



// Null terminated pointers to all materials available.
static const char* ListOfMaterialNames[] = {
   
    "GLSLTwisted",
  0};

