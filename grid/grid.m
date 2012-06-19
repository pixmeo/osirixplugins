#import "grid.h"
#import <OsiriXAPI/AppController.h>
#import <OsiriXAPI/BrowserController.h>

@implementation grid

static NSArray *gridMenuNames;
- (void) initPlugin
{
    NSDictionary *infoPlist = [[NSBundle bundleForClass:[self class]] infoDictionary];
	gridMenuNames = [[infoPlist objectForKey:@"MenuTitles"]retain];	
}

- (long) filterImage:(NSString*) menuName
{
    if ([gridMenuNames indexOfObject:menuName] <5)
    {
        NSMutableArray  *pixList;
        NSMutableArray  *roiSeriesList;
        NSMutableArray  *roiImageList;
        DCMPix			*curPix;

        pixList = [viewerController pixList];		
        curPix = [pixList objectAtIndex: [[viewerController imageView] curImage]];// All rois contained in the current series
        roiSeriesList = [viewerController roiList];// All rois contained in the current image
        roiImageList = [roiSeriesList objectAtIndex: [[viewerController imageView] curImage]];		

        // find the roiImageIndex of the first selected ROI of current image
        long roiImageIndex=-1;
        for( long i = 0; i < [roiImageList count]; i++)
        {
            if( [[roiImageList objectAtIndex: i] ROImode] == ROI_selected)
            {
                roiImageIndex = i;	
                i=[roiImageList count];
            }
        }
        if (roiImageIndex==-1)
        {
            NSRunInformationalAlertPanel(@"grid", @"You need to create and select a ROI rectangle!", @"OK", 0L, 0L);
        }
        else
        {
            ROI *roi=[roiImageList objectAtIndex: roiImageIndex];
            int roiType= [roi type];
            if (roiType!=6) NSLog(@"roi type=%d is not equal a rectangle(=6)",roiType);
            else 
            {
                NSRect roiRect = [roi rect];
                NSUInteger x = floor(roiRect.origin.x);
                NSUInteger y = floor(roiRect.origin.y);
                NSUInteger w = ceil(roiRect.size.width);
                NSUInteger h = ceil(roiRect.size.height);
                NSUInteger pwidth = [curPix pwidth];
                NSUInteger pheight = [curPix pheight];
                //NSLog(@"\rx:%lu y:%lu\rw:%lu h:%lu\rpwidth:%lu pheight:%lu",(unsigned long)x,(unsigned long)y,(unsigned long)w,(unsigned long)h,(unsigned long)pwidth,(unsigned long)pheight);
                
                // Loop through all images contained in the current series
                for(NSUInteger i = 0; i < [pixList count]; i++)
                {
                    // fImage is a pointer on the pixels, ALWAYS represented in float (float*) or in ARGB (unsigned char*)                 
                    curPix = [pixList objectAtIndex: i];                
                    if( [curPix isRGB])
                    {
                        uint32   *argb;                    
                        argb = (uint32*) [curPix fImage];
                        switch ([menuName intValue]) 
                        {
                            case 1:
                                //horizontal
                                for( NSUInteger yy=y%h; yy < pheight; yy+=h)
                                {
                                    NSUInteger y1 = pwidth*yy;
                                    for(NSUInteger xx=0; xx<pwidth; xx++) 
                                    {
                                        argb[y1+xx] = 0xFFFFFFFF;
                                    }
                                }
                                //vertical
                                for( NSUInteger xx=x%w; xx < pwidth; xx+=w)
                                {
                                    NSUInteger x1=xx;
                                    for(NSUInteger yy=0; yy < pheight; yy++) 
                                    {
                                        argb[(pwidth*yy)+x1] = 0xFFFFFFFF;
                                    }
                                }
                                break;
                                
                            case 2:;
                                //horizontal
                                for( NSUInteger yy=y%h; yy < (pheight-1); yy+=h)
                                {
                                    NSUInteger y1 = pwidth*yy;
                                    NSUInteger y2 = y1 + pwidth;
                                    for(NSUInteger xx=0; xx < pwidth; xx++) 
                                    {
                                        argb[y1+xx] = 0xFFFFFFFF;
                                        argb[y2+xx] = 0xFFFFFFFF;
                                    }
                                }
                                //vertical
                                for( NSUInteger xx=x%w; xx < (pwidth-1); xx+=w)
                                {
                                    NSUInteger x1=xx;
                                    NSUInteger x2=xx+1;
                                    for(NSUInteger yy=0; yy < pheight; yy++) 
                                    {
                                        argb[(pwidth*yy)+x1] = 0xFFFFFFFF;
                                        argb[(pwidth*yy)+x2] = 0xFFFFFFFF;
                                    }
                                }
                                break;
                                
                            case 3:;
                                //horizontal
                                for( NSUInteger yy=(y%h)+1; yy < (pheight-2); yy+=h)
                                {
                                    NSUInteger y1 = pwidth*yy;
                                    NSUInteger y2 = y1 + pwidth;
                                    NSUInteger y3 = y1 - pwidth;
                                    for(NSUInteger xx=1; xx < pwidth; xx++) 
                                    {
                                        argb[y1+xx] = 0xFFFFFFFF;
                                        argb[y2+xx] = 0xFFFFFFFF;
                                        argb[y3+xx] = 0xFFFFFFFF;
                                    }
                                }
                                //vertical
                                for( NSUInteger xx=(x%w)+1; xx < (pwidth-2); xx+=w)
                                {
                                    NSUInteger x1=xx;
                                    NSUInteger x2=xx+1;
                                    NSUInteger x3=xx-1;
                                    for(NSUInteger yy=0; yy < pheight; yy++) 
                                    {
                                        argb[(pwidth*yy)+x1] = 0xFFFFFFFF;
                                        argb[(pwidth*yy)+x2] = 0xFFFFFFFF;
                                        argb[(pwidth*yy)+x3] = 0xFFFFFFFF;
                                    }
                                }
                                break;
                                
                            case 4:;
                                //horizontal
                                for( NSUInteger yy=(y%h)+1; yy < (pheight-3); yy+=h)
                                {
                                    NSUInteger y1 = pwidth*yy;
                                    NSUInteger y2 = y1 + pwidth;
                                    NSUInteger y3 = y1 - pwidth;
                                    NSUInteger y4 = y1 + pwidth + pwidth;
                                    for(NSUInteger xx=1; xx < pwidth; xx++) 
                                    {
                                        argb[y1+xx] = 0xFFFFFFFF;
                                        argb[y2+xx] = 0xFFFFFFFF;
                                        argb[y3+xx] = 0xFFFFFFFF;
                                        argb[y4+xx] = 0xFFFFFFFF;
                                    }
                                }
                                //vertical
                                for( NSUInteger xx=(x%w)+1; xx < (pwidth-3); xx+=w)
                                {
                                    NSUInteger x1=xx;
                                    NSUInteger x2=xx+1;
                                    NSUInteger x3=xx-1;
                                    NSUInteger x4=xx+2;
                                    for(NSUInteger yy=0; yy < pheight; yy++) 
                                    {
                                        argb[(pwidth*yy)+x1] = 0xFFFFFFFF;
                                        argb[(pwidth*yy)+x2] = 0xFFFFFFFF;
                                        argb[(pwidth*yy)+x3] = 0xFFFFFFFF;
                                        argb[(pwidth*yy)+x4] = 0xFFFFFFFF;
                                    }
                                }
                                break;
                                
                            case 5:;
                                for( NSUInteger yy=(y%h)+2; yy < (pheight-4); yy+=h)
                                {
                                    NSUInteger y1 = pwidth*yy;
                                    NSUInteger y2 = y1 + pwidth;
                                    NSUInteger y3 = y1 - pwidth;
                                    NSUInteger y4 = y1 + pwidth + pwidth;
                                    NSUInteger y5 = y1 - pwidth - pwidth;
                                    for(NSUInteger xx=1; xx < pwidth; xx++) 
                                    {
                                        argb[y1+xx] = 0xFFFFFFFF;
                                        argb[y2+xx] = 0xFFFFFFFF;
                                        argb[y3+xx] = 0xFFFFFFFF;
                                        argb[y4+xx] = 0xFFFFFFFF;
                                        argb[y5+xx] = 0xFFFFFFFF;
                                    }
                                }
                                //vertical
                                for( NSUInteger xx=(x%w)+2; xx < (pwidth-4); xx+=w)
                                {
                                    NSUInteger x1=xx;
                                    NSUInteger x2=xx+1;
                                    NSUInteger x3=xx-1;
                                    NSUInteger x4=xx+2;
                                    NSUInteger x5=xx-2;
                                    for(NSUInteger yy=0; yy < pheight; yy++) 
                                    {
                                        argb[(pwidth*yy)+x1] = 0xFFFFFFFF;
                                        argb[(pwidth*yy)+x2] = 0xFFFFFFFF;
                                        argb[(pwidth*yy)+x3] = 0xFFFFFFFF;
                                        argb[(pwidth*yy)+x4] = 0xFFFFFFFF;
                                        argb[(pwidth*yy)+x5] = 0xFFFFFFFF;
                                    }
                                }
                                break;
                                
                            default:
                                break;
                        }
                         
                    }
                    else
                    {
                        float *fImage = [curPix fImage];
                        switch ([menuName intValue]) 
                        {
                            case 1:
                                //horizontal
                                for( NSUInteger yy=y%h; yy < pheight; yy+=h)
                                {
                                    NSUInteger y1 = pwidth*yy;
                                    for(NSUInteger xx=0; xx<pwidth; xx++) 
                                    {
                                        fImage[y1+xx] = 1;
                                    }
                                }
                                //vertical
                                for( NSUInteger xx=x%w; xx < pwidth; xx+=w)
                                {
                                    NSUInteger x1=xx;
                                    for(NSUInteger yy=0; yy < pheight; yy++) 
                                    {
                                        fImage[(pwidth*yy)+x1] = 1;
                                    }
                                }
                                break;

                            case 2:;
                                //horizontal
                                for( NSUInteger yy=y%h; yy < (pheight-1); yy+=h)
                                {
                                    NSUInteger y1 = pwidth*yy;
                                    NSUInteger y2 = y1 + pwidth;
                                    for(NSUInteger xx=0; xx < pwidth; xx++) 
                                    {
                                        fImage[y1+xx] = 1;
                                        fImage[y2+xx] = 1;
                                    }
                                }
                                //vertical
                                for( NSUInteger xx=x%w; xx < (pwidth-1); xx+=w)
                                {
                                    NSUInteger x1=xx;
                                    NSUInteger x2=xx+1;
                                    for(NSUInteger yy=0; yy < pheight; yy++) 
                                    {
                                        fImage[(pwidth*yy)+x1] = 1;
                                        fImage[(pwidth*yy)+x2] = 1;
                                    }
                                }
                                break;
                                
                            case 3:;
                                //horizontal
                                for( NSUInteger yy=(y%h)+1; yy < (pheight-2); yy+=h)
                                {
                                    NSUInteger y1 = pwidth*yy;
                                    NSUInteger y2 = y1 + pwidth;
                                    NSUInteger y3 = y1 - pwidth;
                                    for(NSUInteger xx=1; xx < pwidth; xx++) 
                                    {
                                        fImage[y1+xx] = 1;
                                        fImage[y2+xx] = 1;
                                        fImage[y3+xx] = 1;
                                    }
                                }
                                //vertical
                                for( NSUInteger xx=(x%w)+1; xx < (pwidth-2); xx+=w)
                                {
                                    NSUInteger x1=xx;
                                    NSUInteger x2=xx+1;
                                    NSUInteger x3=xx-1;
                                    for(NSUInteger yy=0; yy < pheight; yy++) 
                                    {
                                        fImage[(pwidth*yy)+x1] = 1;
                                        fImage[(pwidth*yy)+x2] = 1;
                                        fImage[(pwidth*yy)+x3] = 1;
                                    }
                                }
                                break;
                                
                            case 4:;
                                //horizontal
                                for( NSUInteger yy=(y%h)+1; yy < (pheight-3); yy+=h)
                                {
                                    NSUInteger y1 = pwidth*yy;
                                    NSUInteger y2 = y1 + pwidth;
                                    NSUInteger y3 = y1 - pwidth;
                                    NSUInteger y4 = y1 + pwidth + pwidth;
                                    for(NSUInteger xx=1; xx < pwidth; xx++) 
                                    {
                                        fImage[y1+xx] = 1;
                                        fImage[y2+xx] = 1;
                                        fImage[y3+xx] = 1;
                                        fImage[y4+xx] = 1;
                                    }
                                }
                                //vertical
                                for( NSUInteger xx=(x%w)+1; xx < (pwidth-3); xx+=w)
                                {
                                    NSUInteger x1=xx;
                                    NSUInteger x2=xx+1;
                                    NSUInteger x3=xx-1;
                                    NSUInteger x4=xx+2;
                                    for(NSUInteger yy=0; yy < pheight; yy++) 
                                    {
                                        fImage[(pwidth*yy)+x1] = 1;
                                        fImage[(pwidth*yy)+x2] = 1;
                                        fImage[(pwidth*yy)+x3] = 1;
                                        fImage[(pwidth*yy)+x4] = 1;
                                    }
                                }
                                break;
                                
                            case 5:;
                                for( NSUInteger yy=(y%h)+2; yy < (pheight-4); yy+=h)
                                {
                                    NSUInteger y1 = pwidth*yy;
                                    NSUInteger y2 = y1 + pwidth;
                                    NSUInteger y3 = y1 - pwidth;
                                    NSUInteger y4 = y1 + pwidth + pwidth;
                                    NSUInteger y5 = y1 - pwidth - pwidth;
                                    for(NSUInteger xx=1; xx < pwidth; xx++) 
                                    {
                                        fImage[y1+xx] = 1;
                                        fImage[y2+xx] = 1;
                                        fImage[y3+xx] = 1;
                                        fImage[y4+xx] = 1;
                                        fImage[y5+xx] = 1;
                                    }
                                }
                                //vertical
                                for( NSUInteger xx=(x%w)+2; xx < (pwidth-4); xx+=w)
                                {
                                    NSUInteger x1=xx;
                                    NSUInteger x2=xx+1;
                                    NSUInteger x3=xx-1;
                                    NSUInteger x4=xx+2;
                                    NSUInteger x5=xx-2;
                                    for(NSUInteger yy=0; yy < pheight; yy++) 
                                    {
                                        fImage[(pwidth*yy)+x1] = 1;
                                        fImage[(pwidth*yy)+x2] = 1;
                                        fImage[(pwidth*yy)+x3] = 1;
                                        fImage[(pwidth*yy)+x4] = 1;
                                        fImage[(pwidth*yy)+x5] = 1;
                                    }
                                }
                                break;
                                
                            default:
                                break;
                        }
                        
                    }
                }
                [viewerController deleteROI:roi];            
                // We modified the pixels: OsiriX please update the display!
                [viewerController needsDisplayUpdate];

            }        
        }
    }
    else 
    {
        //export modified series
        //exportDICOMFileInt tag: 0=As stored in memory in 16-bit BW, 1=As displayed in 8-bit RGB,with ROIs, (2) As displayed in 16-bit BW
        NSDictionary* s = [viewerController exportDICOMFileInt:0 withName:menuName allViewers:NSOffState]; 

        if(s)
        {
            BrowserController *bc = [BrowserController currentBrowser];
            //NSArray *objects = 
            [BrowserController addFiles: [NSArray arrayWithObject:[s valueForKey: @"file"]]
                                                 toContext: [bc managedObjectContext]
                                                toDatabase: bc
                                                 onlyDICOM: YES 
                                          notifyAddedFiles: YES
                                       parseExistingObject: YES
                                                  dbFolder: [bc documentsDirectory]
                                         generatedByOsiriX: YES
                                ];
            //[bc selectServer: objects];
            [viewerController adjustSlider];
            
        }
        
    }
	return 0;   // No Errors
}

@end
