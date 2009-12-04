/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "ROICorrectDisplayTextualDataFilter.h"

@implementation ROICorrectDisplayTextualDataFilter

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{
	NSArray *viewers = [ViewerController getDisplayed2DViewers];
	for (ViewerController *viewer in viewers)
	{
		for (int i=0; i<[viewer maxMovieIndex]; i++)
		{
			NSArray *roisForAllImages = [viewer roiList:i];
			for (NSArray *rois in roisForAllImages)
			{
				for (ROI *roi in rois)
				{
					[roi setDisplayTextualData:YES];
				}
			}
		}
	}
	return 0;
}

@end
