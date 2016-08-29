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

@class DCMAttributeTag;
@class DICOMFieldMenu;

@interface AnonymizationTagsPopUpButton : NSButton {
	DCMAttributeTag* selectedTag;
    DICOMFieldMenu *DICOMField;
}

@property(retain,nonatomic) DCMAttributeTag* selectedTag;
@property (retain) DICOMFieldMenu *DICOMField;

@end
