/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Cocoa/Cocoa.h>
#import "XMLController.h"

/** \brief DCMTK calls for xml */

@interface XMLController (XMLControllerDCMTKCategory)


+ (NSString*) dcmFindNameOfUID: (NSString*) string;
+ (int) modifyDicom:(NSArray*) params encoding: (NSStringEncoding) encoding;
+ (int) modifyDicom:(NSArray*) params files: (NSArray*) files encoding: (NSStringEncoding) encoding;
//+ (NSString*) stringForElement: (int) element group: (int) group vr: (NSString*) vrString string: (NSString*) string encoding: (NSStringEncoding) encoding;
- (void) prepareDictionaryArray;
- (int) getGroupAndElementForName:(NSString*) name group:(int*) gp element:(int*) el;

@end
