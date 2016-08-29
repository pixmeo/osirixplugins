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

@interface DCMTKFileFormat : NSObject
{
    void *dcmtkDcmFileFormat;
}
@property void *dcmtkDcmFileFormat;

+ (NSArray*) prepareDICOMFieldsArrays;

+(NSString*) getNameForGroupAndElement:(int) gp element:(int) el;
+(int) getGroupAndElementForName:(NSString*) name group:(int*) gp element:(int*) el;

- (id) initWithFile: (NSString*) file;

@end
