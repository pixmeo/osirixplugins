/*=========================================================================

  Program:   Visualization Toolkit
  Module:    vtkShaderCodeLibraryMacro.h.in

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/

#include "vtkGLSLShaderLibrary.h"

#define vtkShaderCodeLibraryMacro(name) \
 if (strcmp(name, "GLSLTestAppVarFrag") == 0)\
        {\
        return vtkShaderGLSLTestAppVarFragGetCode();\
        }\
 if (strcmp(name, "GLSLTestVertex") == 0)\
        {\
        return vtkShaderGLSLTestVertexGetCode();\
        }\
 if (strcmp(name, "GLSLTestVtkPropertyFrag") == 0)\
        {\
        return vtkShaderGLSLTestVtkPropertyFragGetCode();\
        }\
 if (strcmp(name, "GLSLTestMatrixFrag") == 0)\
        {\
        return vtkShaderGLSLTestMatrixFragGetCode();\
        }\
 if (strcmp(name, "GLSLTestScalarVectorFrag") == 0)\
        {\
        return vtkShaderGLSLTestScalarVectorFragGetCode();\
        }\
 if (strcmp(name, "GLSLTwisted") == 0)\
        {\
        return vtkShaderGLSLTwistedGetCode();\
        }\


// Null terminated pointers to all shader code names.
static const char* ListOfShaderNames[] = {
  
    "GLSLTestAppVarFrag",
    "GLSLTestVertex",
    "GLSLTestVtkPropertyFrag",
    "GLSLTestMatrixFrag",
    "GLSLTestScalarVectorFrag",
    "GLSLTwisted",
  0};
