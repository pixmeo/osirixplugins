/*=========================================================================
 Author: Chunliang Wang (chunliang.wang@imv.liu.se)
 
 
 Program:  CMIV CTA image processing Plugin for OsiriX
 
 This file is part of CMIV CTA image processing Plugin for OsiriX.
 
 Copyright (c) 2007,
 Center for Medical Image Science and Visualization (CMIV),
 Linköping University, Sweden, http://www.cmiv.liu.se/
 
 CMIV CTA image processing Plugin for OsiriX is free software;
 you can redistribute it and/or modify it under the terms of the
 GNU General Public License as published by the Free Software 
 Foundation, either version 3 of the License, or (at your option)
 any later version.
 
 CMIV CTA image processing Plugin for OsiriX is distributed in
 the hope that it will be useful, but WITHOUT ANY WARRANTY; 
 without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 =========================================================================*/


#import "CMIVAutoSeedingCore.h"
#import "CMIVBuketPirortyQueue.h"
#import "CMIV3DPoint.h"
#import <Accelerate/Accelerate.h>

#define id Id
#include "itkMultiThreader.h"
#include "itkImage.h"
#include "itkImportImageFilter.h"
#include "itkGradientAnisotropicDiffusionImageFilter.h"
#include "itkRecursiveGaussianImageFilter.h"
#include "itkHessianRecursiveGaussianImageFilter.h"
#include "itkHessian3DToVesselnessMeasureImageFilter.h"
#include "itkDanielssonDistanceMapImageFilter.h"
#include "itkHoughTransform2DCirclesImageFilter.h"
#include "itkCurvatureAnisotropicDiffusionImageFilter.h"
#include "itkFastMarchingImageFilter.h"
#include "itkBinaryThresholdImageFilter.h"
#include "itkThresholdSegmentationLevelSetImageFilter.h"


#include <vtkImageImport.h>
#include <vtkTransform.h>
#include <vtkImageReslice.h>
#include <vtkImageData.h>
#include <vtkMath.h>
#include <vtkContourFilter.h>
#include <vtkPolyDataConnectivityFilter.h>
#include <vtkPolyData.h>
#include "spline.h"


#undef id




static		float						deg2rad = 3.14159265358979/180.0;
@implementation CMIVAutoSeedingCore

#pragma mark-
#pragma mark 1 Rib Cage Removal
-(int)autoCroppingBasedOnLungSegment:(float*)inData :(unsigned char*)outData:(float)threshold:(float)diameter: (long*)origin:(long*)dimension:(float*)spacing:(float)zoomfactor
{
	//NSLog( @"lung segment ");
	int err=0;
	inputData=inData;
	imageWidth=dimension[0];
	imageHeight=dimension[1];
	imageAmount=dimension[2];
	xSpacing=spacing[0];
	ySpacing=spacing[1];
	zSpacing=spacing[2];
	xOrigin=origin[0];
	yOrigin=origin[1];
	zOrigin=origin[2];
	imageSize=imageWidth*imageHeight;
	zoomFactor=zoomfactor;
	//zoomFactor=1.0;
	curveWeightFactor=1;
	distanceWeightFactor=1;
	intensityWeightFactor=1;
	gradientWeightFactor=1;
	lungThreshold=(long)threshold;
	[self lungSegmentation:inData:outData:diameter];
	//NSLog( @"finding heart");
	[[NSNotificationCenter defaultCenter] postNotificationName: @"CMIVLeveIndicatorStep" object:self userInfo: nil];

	err=[self findingHeart:inData:outData:origin:dimension];
	[self smoothOutput:outData];
	if(err)
		return err;
	return err;
}
-(void)lungSegmentation:(float*)inData :(unsigned char*)outData:(float)diameter
{
	long size=imageAmount*imageSize;
	long i;
	for(i=0;i<size;i++)
	{
		if(inData[i]<lungThreshold)
			outData[i]=1;
	}
	int preLungSegNumber=0;
	long* buffer=(long*)malloc(4*imageSize*sizeof(long));
	unsigned char* preSlice=nil;
	
	for(i=imageAmount-1;i>=0;i--)
	{
		memset(buffer, 0x00, 2*imageSize*sizeof(long));
		preLungSegNumber=[self connectedComponetsLabeling2D:outData+i*imageSize:preSlice:buffer];
		preSlice=outData+i*imageSize;
	}
	free(buffer);
}
-(int)connectedComponetsLabeling2D:(unsigned char*)img2d8bit:(unsigned char*)preSlice:(long*)buffer
{
	long labebindex=1;
	long isconnected=0;
	
	long i,j,k,x,y,neighbor;
	long index1,index2;
	long* tempimg=buffer;
	long* connectingmap=buffer+imageSize;
	long* areaList=buffer+2*imageSize;

	for(j=0;j<imageHeight;j++)
		for(i=0;i<imageWidth;i++)
			if(*(img2d8bit+j*imageWidth+i))
			{
				isconnected=0;
				for(neighbor=0;neighbor<4;neighbor++)
				{
					switch(neighbor)
					{
						case 0:
							x=i-1;y=j-1;break;
						case 1:
							x=i;y=j-1;break;
						case 2:
							x=i+1;y=j-1;break;
						case 3:
							x=i-1;y=j;break;
					}
					if(x<0 || y<0 ||x>=imageWidth)
						continue;
					if(*(tempimg+y*imageWidth+x))
					{
						if(!isconnected)
						{
							*(tempimg+j*imageWidth+i)=*(tempimg+y*imageWidth+x);
							isconnected=1;
						}
						else
						{
							if(*(tempimg+j*imageWidth+i)!=*(tempimg+y*imageWidth+x))
							{
								index1=*(tempimg+j*imageWidth+i);
								index2=*(tempimg+y*imageWidth+x);
								if(connectingmap[index1]==0&&connectingmap[index2]==0)
								{

									connectingmap[index1]=index1;
									connectingmap[index2]=index1;
									
								}
								else if(connectingmap[index1]==0&&connectingmap[index2]!=0)
								{
									connectingmap[index1]=connectingmap[index2];
								}
								else if(connectingmap[index1]!=0&&connectingmap[index2]==0)
								{
									connectingmap[index2]=connectingmap[index1];
								}
								else
								{

									index1=connectingmap[index1];
									index2=connectingmap[index2];
									if(index1!=index2)
									for(k=1;k<labebindex;k++)
										if(connectingmap[k]==index2)
											connectingmap[k]=index1;
								}
								
	
							}
						}
					}
				}
				if(!*(tempimg+j*imageWidth+i))
				{
					*(tempimg+j*imageWidth+i)=labebindex;
					connectingmap[labebindex]=labebindex;
					labebindex++;
				}

				
			}

	// replace connected map with continuous number.
	index1=0;
	for(k=1;k<labebindex;k++)
	{
		if(connectingmap[k]>index1)
		{
			index1++;
			index2=connectingmap[k];
			for(i=k;i<labebindex;i++)
			{
				if(connectingmap[i]==index2)
					connectingmap[i]=index1;
					
			}
		}
	}
	index1++;
	//caculate the area of each object
	memset(areaList,0x00,index1*4*sizeof(long));
	for(i=0;i<index1;i++)
	{
		areaList[i*4]=imageWidth;
		areaList[i*4+1]=imageHeight;
		areaList[i*4+2]=0;
		areaList[i*4+3]=0;
	}
	index2=index1;
	
	for(j=0;j<imageHeight;j++)
		for(i=0;i<imageWidth;i++)
		{
			index1=connectingmap[tempimg[j*imageWidth+i]];
			tempimg[j*imageWidth+i]=index1;
			if(index1>0)
			{
				if(areaList[index1*4]>i)
					areaList[index1*4]=i;
				if(areaList[index1*4+1]>j)
					areaList[index1*4+1]=j;
				if(areaList[index1*4+2]<i)
					areaList[index1*4+2]=i;
				if(areaList[index1*4+3]<j)
					areaList[index1*4+3]=j;
			}
		}
	//try to remove air object in front of the patient and small air area
	long width,height;
	index1=1;
	for(i=1;i<index2;i++)//
	{
		connectingmap[i]=index1;
		index1++;
		x=areaList[i*4];
		y=areaList[i*4+1];

		width=areaList[i*4+2]-areaList[i*4];
		height=areaList[i*4+3]-areaList[i*4+1];
		//small air area
		if((width+height)<(imageWidth)/10)
		{
			connectingmap[i]=0;
			index1--;
		}
		else if(y==0 && height<imageHeight/2) //check for air area in front of patient on suspicous area.
		{
			int isconnectedToLung=0;
			if(preSlice)
			{
				long s,t;
				for(t=0;t<height&&!isconnectedToLung;t++)
					for(s=0;s<width&&!isconnectedToLung;s++)
					{
						if(*(tempimg+(t+y)*imageWidth+s+x)==connectingmap[i]&&*(preSlice+(t+y)*imageWidth+s+x))
							isconnectedToLung=1;
				
					}
			}

			if(!isconnectedToLung)
			{
				connectingmap[i]=0;
				index1--;

			}
		}
		
		
	}

	for(i=0;i<imageSize;i++)
	{
		
		img2d8bit[i]=connectingmap[tempimg[i]];
		
	}
	
		
	return index1;
	
}
-(void)closingVesselHoles:(unsigned char*)img2d8bit :(float)diameter
{
	
}
-(int)findingHeart:(float*)inData:(unsigned char*)outData:(long*)origin:(long*)dimension
{
	int err=0;

	float *precurve=(float*)malloc(360*sizeof(float));
	float *curve=(float*)malloc(360*sizeof(float));
	directorMapBuffer=(unsigned char*)malloc(360*1000*sizeof(unsigned char));
	weightMapBuffer=(long*)malloc(360*1000*sizeof(long));
	curSliceWeightMapBuffer=(float*)malloc(360*1000*sizeof(float));
	lastSliceWeightMapBuffer=(float*)malloc(360*1000*sizeof(float));
	costMapBuffer=(long*)malloc(360*1000*sizeof(long));
	*precurve=-1;
	long i;
	unsigned char* img8bit;
	float * image;
	long heartcenterx=imageWidth/2,heartcentery=imageHeight/2;
	heartcenterx=[self findFirstCenter:outData+(imageAmount-1)*imageSize];
	heartcentery=heartcenterx/imageWidth;
	heartcenterx=heartcenterx%imageWidth;
	
	for(i=imageAmount-1;i>=0;i--)
	{
		img8bit=outData+i*imageSize;
		image=inData+i*imageSize;
		memset(curve,0x00,360*sizeof(float));
		int localerr=0;

		//NSLog( @"starting curve");
		localerr=[self createParameterFunctionWithCenter:heartcenterx:heartcentery:10:img8bit:curve:precurve];
		//NSLog( @"closing curve");
		if(!localerr)
			localerr=[self convertParameterFunctionIntoCircle:heartcenterx:heartcentery:curve:precurve:img8bit:image];
		//NSLog( @"filling curve");
		
		if(localerr==2)
		{
			memset(outData,0x00,i*imageSize*sizeof(unsigned char));
			break;
		}
		[self fillAreaInsideCircle:&heartcenterx:&heartcentery:img8bit:curve:precurve];
		//NSLog( @"finished curve");

		if(localerr)
		{
			*precurve=-1;
			
		}
			/*for	for(j=0;j<360;j++)
		{
			long tempy=curve[j];
			if(tempy>511)tempy=511;
			*(img8bit+tempy*imageWidth+j)=1;
			*(image+tempy*imageWidth+j)=4000;
			
		}
		if(localerr)
			break;
		 test
	
			*/
	}
	free(curve);
	free(precurve);
	free(directorMapBuffer);
	free(weightMapBuffer);
	free(curSliceWeightMapBuffer);
	free(lastSliceWeightMapBuffer);
	free(costMapBuffer);
	return err;
}
-(int)createParameterFunctionWithCenter:(long)centerx:(long)centery:(float)diameter:(unsigned char*)img2d8bit:(float*)curve:(float*)precurve
{
	int i=0;
	long tempx=0,tempy=0,tempdiameter;

		for(i=0;i<360;i++)
		{
			tempdiameter=0;
			curve[i]=0;
			do
			{
				tempdiameter++;
				tempx=centerx+(float)tempdiameter*cos((float)i*deg2rad);
				tempy=centery+(float)tempdiameter*sin((float)i*deg2rad);
				if(tempx<0 || tempy<0 || tempx>=imageWidth || tempy>=imageHeight)
				{
					curve[i]=10000;
					break;
				}
					
			}while(*(img2d8bit+tempy*imageWidth+tempx)==0);
			if(curve[i]==0)
			{
				curve[i]=tempdiameter;
			}
		}

	/* doesn't help
	 if(*precurve==-1)
	 {
	 	}
	else
	{
		float distancethreshold=30/zoomFactor;
		for(i=0;i<360;i++)
		{
			tempdiameter=precurve[i]-distancethreshold;
			curve[i]=0;
			do
			{
				tempdiameter++;
				tempx=centerx+(float)tempdiameter*cos((float)i*deg2rad);
				tempy=centery+(float)tempdiameter*sin((float)i*deg2rad);
				if(tempx<0 || tempy<0 || tempx>=imageWidth || tempy>=imageHeight)
				{
					curve[i]=10000;
					break;
				}
				
			}while(*(img2d8bit+tempy*imageWidth+tempx)==0);
			if(curve[i]==0)
			{
				curve[i]=tempdiameter;
			}
		}
		
	}*/
	return 0;
	
}
-(int)convertParameterFunctionIntoCircle:(long)x:(long)y:(float*)curve:(float*)precurve:(unsigned char*)img2d8bit:(float*)image
{
	int i,j,segnum=0;
	int gapstart,gapend;
	int err=0;

	i=0;
	//first round check based on lung contour
	{

		while(i<360&&curve[i%360]==10000)i++;

		if(i>=360)
			return 2;
		
		for(j=0;j<360;j++)
		{
			if(curve[(i+j)%360]==10000)
			{ 
				segnum++;
				gapstart=(i+j)%360-1;
				while(j<360&&(curve[(i+j)%360]==10000))j++;
				if(j>360)
					return 2;

				gapend=(i+j)%360;
				//[self fillGapsInParameterFunction:curve:gapstart:gapend];
				err=[self finding2DMinimiumCostPath:x:y:curve:(float*)precurve:img2d8bit:image:gapstart:gapend];
				if(err)
					return err;
			}
		}
	}
	return 0;
	i=0;
	segnum=0;
	if(precurve[0]>0)
	{
		gapstart=abs(curve[i%360]-precurve[i%360]);
		while(i<360&&gapstart>30)
		{i++;gapstart=abs(curve[i%360]-precurve[i%360]);}
		
		if(i>=360)
			return 2;
		float distancethreshold=30/zoomFactor;
		for(j=0;j<360;j++)
		{
			if(abs(curve[(i+j)%360]-precurve[(i+j)%360])>distancethreshold)
			{ 
				segnum++;
				gapstart=(i+j)%360-1;
				while(j<360&&(abs(curve[(i+j)%360]-precurve[(i+j)%360])>distancethreshold))
				{
					curve[(i+j)%360]=10000;
					j++;
				}
				if(j>360)
					return 2;			
				gapend=(i+j)%360;
				
				err=[self finding2DMinimiumCostPath:x:y:curve:(float*)precurve:img2d8bit:image:gapstart:gapend];
				if(err)
					return err;
			}
		}	
	}
	
	return 0;
}
-(void)fillAreaInsideCircle:(long*)pcenterx:(long*)pcentery:(unsigned char*)img2d8bit:(float*)curve:(float*)precurve;
{
	int i,j;
	float angle;
	float x,y;
	long centerx=*pcenterx,centery=*pcentery;
	long newcenterx=0,newcentery=0;
	long tempx,tempy;
	int angleindex;

	int needchechx1=0;

	float slope;
	long x1,x2,y1,y2;
	unsigned char marker=0;
	long tempdiameter;
	for(i=1;i<361;i++)
		if(curve[i%360]==10000)
		{
			tempdiameter=0;
			curve[i%360]=0;
			do
			{
				tempdiameter++;
				tempx=centerx+(float)tempdiameter*cos((float)i*deg2rad);
				tempy=centery+(float)tempdiameter*sin((float)i*deg2rad);
				if(tempx==0 || tempy==0 || tempx==imageWidth-1 || tempy==imageHeight-1)
				{
					curve[i%360]=tempdiameter;
					break;
				}
				if(tempx<0 || tempy<0 || tempx>=imageWidth|| tempy>=imageHeight)
				{
					curve[i%360]=tempdiameter-1;
					break;
				}
				
			}while(*(img2d8bit+tempy*imageWidth+tempx)==0);
			if(curve[i%360]==0)
				curve[i%360]=tempdiameter;

		}
	
	//NSLog( @"clean memory");
	memset(img2d8bit,0x00,imageSize*sizeof(char));
	//NSLog( @"stroke curve");			
	for(i=1;i<361;i++)
		curve[i%360]=(curve[i%360]+curve[(i-1)%360]+curve[(i+1)%360])/3;
		
	for(i=1;i<362;i++)
	{
		needchechx1=0;
		x1=centerx+curve[(i-1)%360]*cos((float)(i-1)*deg2rad);
		y1=centery+curve[(i-1)%360]*sin((float)(i-1)*deg2rad);

		x2=centerx+curve[i%360]*cos((float)i*deg2rad);
		y2=centery+curve[i%360]*sin((float)i*deg2rad);
		if(x1<0)x1=0; if(x1>imageWidth-1)x1=imageWidth-1;
		if(x2<0)x2=0; if(x2>imageWidth-1)x2=imageWidth-1;
		if(y1<0)y1=0; if(y1>imageHeight-1)y1=imageHeight-1;
		if(y2<0)y2=0; if(y2>imageHeight-1)y2=imageHeight-1;
		if(x1<x2)
		{
			if(y1<y2)marker=1;
			if(y1>y2)marker=2;
			if(y1==y2)marker=3;
		
		}
		if(x1>x2)
		{
			if(y1<y2)marker=1;
			if(y1>y2)marker=2;
			if(y1==y2)marker=3;
			
		}
		if(x1==x2)
		{
			if(y1<y2)marker=1;
			if(y1>y2)marker=2;
			if(y1==y2)
			{
				continue;
			}
					
		}
		
		if(*(img2d8bit+y1*imageWidth+x1)!=0&&*(img2d8bit+y1*imageWidth+x1)!=marker)
		{
			if(*(img2d8bit+y1*imageWidth+x1)==3)
				*(img2d8bit+y1*imageWidth+x1)=marker;
			else if(marker!=3)
			{
				if(*(img2d8bit+y1*imageWidth+x1-1)==0x00&&*(img2d8bit+y1*imageWidth+x1+1)==0x00)
				{
					*(img2d8bit+y1*imageWidth+x1)=3;
					needchechx1=1;
				}
				else
					*(img2d8bit+y1*imageWidth+x1)=marker;
			}
		}
		
		if(x1!=x2)
		{
			if(x1>x2)
			{
				tempx=x1;x1=x2;x2=tempx;
				tempy=y1;y1=y2;y2=tempy;
			}
			slope=(float)(y2-y1)/(float)(x2-x1);
			for(j=x1;j<=x2;j++)
			{
				tempx=j;
				tempy=slope*(j-x1)+y1;

				if(*(img2d8bit+tempy*imageWidth+tempx)==0)
				{
						*(img2d8bit+tempy*imageWidth+tempx)=marker;
				}
				
			}
		}
		if(y1!=y2)
		{
			if(y1>y2)
			{
				tempx=x1;x1=x2;x2=tempx;
				tempy=y1;y1=y2;y2=tempy;
			}
			slope=(float)(x2-x1)/(float)(y2-y1);
			for(j=y1;j<=y2;j++)
			{
				tempx=slope*(j-y1)+x1;
				tempy=j;

				if(*(img2d8bit+tempy*imageWidth+tempx)==0)
				{

						*(img2d8bit+tempy*imageWidth+tempx)=marker;
				}
			}
		}
		
		if(needchechx1)
		{
			x1=centerx+curve[(i-1)%360]*cos((float)(i-1)*deg2rad);
			y1=centery+curve[(i-1)%360]*sin((float)(i-1)*deg2rad);
			if(*(img2d8bit+y1*imageWidth+x1-1)!=0x00||*(img2d8bit+y1*imageWidth+x1+1)!=0x00)
			{
				if(marker==1)
					*(img2d8bit+y1*imageWidth+x1)=2;
				else
					*(img2d8bit+y1*imageWidth+x1)=1;
			}
		}
	}
	
//NSLog( @"filling area");
	for(j=0;j<imageHeight;j++)
	{
		marker=0;
		for(i=0;i<imageWidth;i++)
		{

			if(*(img2d8bit+j*imageWidth+i)==3)
				*(img2d8bit+j*imageWidth+i)=0xff;
			else if(*(img2d8bit+j*imageWidth+i)==1)
			{
				marker=0x00;
				*(img2d8bit+j*imageWidth+i)=0xff;
			}
			else if(*(img2d8bit+j*imageWidth+i)==2)
			{
				marker=0xff;
				*(img2d8bit+j*imageWidth+i)=0xff;
			}
			else
				*(img2d8bit+j*imageWidth+i)=marker;
			
		}
	}
	//NSLog( @"creating pre curve");
	for(i=0;i<360;i++)
	{
		tempx=centerx+curve[i]*cos((float)i*deg2rad);
		tempy=centery+curve[i]*sin((float)i*deg2rad);
		newcenterx+=tempx;
		newcentery+=tempy;
	}

	newcenterx=newcenterx/360;
	newcentery=newcentery/360;
	*pcenterx=newcenterx;
	*pcentery=newcentery;
	memset(precurve,0x00,360*sizeof(float));
	for(i=0;i<360;i++)
	{
		tempx=centerx+curve[i]*cos((float)i*deg2rad);
		tempy=centery+curve[i]*sin((float)i*deg2rad);
		x=tempx-newcenterx;
		y=tempy-newcentery;
		if(x!=0)
		{
			angle=(atan(y/x)/ deg2rad);
			if(x<0)
				angle+=180;
			
		}
		else
		{
			if(y<=0)
				angle=270;
			else
				angle=90;
		}
		if(angle<0)
			angle+=360;
		angleindex=(int)angle;
		precurve[angleindex%360]=sqrt(x*x+y*y);
				
	}
	i=0;
	while(i<360&&precurve[i%360]==0)
	{
		i++;
	}
	long startangle,endangle;
	long starty,endy;
	
		
	if(i<360)
	{

		for(j=0;j<360;j++)
		{
			if(precurve[(i+j)%360]==0)
			{
				startangle=i+j-1;
				starty=precurve[(i+j-1)%360];
				while(j<=360&&precurve[(i+j)%360]==0)
					j++;
				endangle=i+j;
				endy=precurve[(i+j)%360];
				
				for(angleindex=startangle+1;angleindex<endangle;angleindex++)
					precurve[angleindex%360]=(i+j-startangle)*(endy-starty)/(endangle-startangle)+starty;
			}
		}
	}
	else
		precurve[0]=-1;
	
}
-(int)finding2DMinimiumCostPath:(long)centerx:(long)centery:(float*)curve:(float*)precurve:(unsigned char*)img2d8bit:(float*)image:(long)startangle:(long)endangle
{
	long minradius,maxradius,tempradius;
	long gapborderfactor=20;
	float gapatfactor=0.02;
	long gapattitude;
	long i;
	long searchareawidth,searchareaheight;
	long stepcostrange=1000;
	long endseedsangle;
	long tempx,tempy;
	if(endangle<startangle)endangle+=360;
	if(startangle<0){startangle+=360;endangle+=360;}
	minradius = maxradius =curve[(startangle+360)%360];
	if(*precurve!=-1)
		for(i=startangle;i<=endangle;i++)
		{
			tempradius=precurve[(i+360)%360];
			if(tempradius==10000)
			{
				i=gapborderfactor;
				continue;
			}
			if(tempradius>maxradius)
				maxradius=tempradius;
			if(tempradius<minradius)
				minradius=tempradius;
			
		}
	
	for(i=0;i<gapborderfactor;i++)
	{
		tempradius=curve[(startangle-i+360)%360];
		if(tempradius==10000)
		{
			i=gapborderfactor;
			break;
		}
		if(tempradius>maxradius)
			maxradius=tempradius;
		if(tempradius<minradius)
			minradius=tempradius;
	}
	startangle-=i-1;
	for(i=0;i<gapborderfactor;i++)
	{
		tempradius=curve[(endangle+i+360)%360];
		if(tempradius==10000)
		{
			i=gapborderfactor;
			break;
		}
		if(tempradius>maxradius)
			maxradius=tempradius;
		if(tempradius<minradius)
			minradius=tempradius;
	}	
	endangle+=i-1;
	endseedsangle=i;
	

	
	if(endangle<startangle)endangle+=360;
	if(*precurve!=-1)
		gapattitude=20/zoomFactor;//
	else
		gapattitude=(maxradius - minradius)*gapatfactor*(endangle-startangle);
	 minradius-=gapattitude;
	 maxradius+=gapattitude;
	
	// check min radius
	int ifneedchechminradius=1;
	while(ifneedchechminradius)
	{
		ifneedchechminradius=0;
		for(i=startangle;i<endangle;i++)
		{
			tempx=centerx+(float)tempradius*cos((float)i*deg2rad);
			tempy=centery+(float)tempradius*sin((float)i*deg2rad);

			if(tempx<0 || tempy<0 || tempx>=imageWidth || tempy>=imageHeight)
			{
				ifneedchechminradius=1;
			}
		}
		if(ifneedchechminradius)
			minradius-=20/zoomFactor;
		if(minradius<=0)
			break;

	}
	 if(minradius<=0)
	 minradius=1;
	if(maxradius>sqrt(imageWidth*imageWidth+imageHeight*imageHeight))
		maxradius=sqrt(imageWidth*imageWidth+imageHeight*imageHeight);
	
	searchareawidth=endangle-startangle;
	searchareaheight=maxradius-minradius;
	if(searchareaheight*searchareawidth<=0)
	{
		NSLog( @"width*height<");
		return 1;
	}

	unsigned char* directors=directorMapBuffer;
	long* weightmap= weightMapBuffer;
	float* curweightmap=curSliceWeightMapBuffer;
	float* lastweightmap=lastSliceWeightMapBuffer;
	memset(directors,0x00,searchareaheight*searchareawidth*sizeof(char));
	memset(weightmap,0x00,searchareaheight*searchareawidth*sizeof(long));
	memset(curweightmap,0x00,searchareaheight*searchareawidth*sizeof(float));
	memset(lastweightmap,0x00,searchareaheight*searchareawidth*sizeof(float));
	for(i=startangle;i<endangle;i++)
	{
		long islungreached=0;
		for(tempradius=minradius;tempradius<maxradius;tempradius++)
		{
			
			tempx=centerx+(float)tempradius*cos((float)i*deg2rad);
			tempy=centery+(float)tempradius*sin((float)i*deg2rad);
			
			long tempindex=(tempradius-minradius)*searchareawidth+i-startangle;
			
			
			if(tempx>=0 && tempy>=0 && tempx<imageWidth && tempy<imageHeight)
			{
				
				if(!islungreached)
				{
					*(weightmap+tempindex)=*(image+tempy*imageWidth+tempx);
					if(precurve[0]!=-1)
						*(lastweightmap+tempindex)=*(image+imageSize+tempy*imageWidth+tempx);
					//////////////////*********************************************************
					//need pay attention to this +imageSize / -imageSize according image search direction
				}
				else
				{
					*(weightmap+tempindex)=lungThreshold+2000;
					*(lastweightmap+tempindex)=lungThreshold+2000;
					*(directors+tempindex)=0x40;
				}
				if(*(img2d8bit+tempy*imageWidth+tempx))
				{
					*(directors+tempindex)=0x40;
					islungreached=1;
				}

			}
			else
			{
				*(weightmap+tempindex)=lungThreshold+2000;
				*(lastweightmap+tempindex)=lungThreshold+2000;
				*(directors+tempindex)=0x40;
			}
			
		}
		if(curve[(i+360)%360]!=10000)
		{
			long tempindex=(curve[(i+360)%360]-minradius)*searchareawidth+i-startangle;
			
			if(i>=endangle-endseedsangle)
				*(directors+tempindex)=0x90;
			else
				*(directors+tempindex)=0x80;
		}

	}
	
	[self intensityRelatedWeightMap:searchareawidth:searchareaheight:weightmap];
	long searchareasize=searchareaheight*searchareawidth;
	if(precurve[0]!=-1)
	{
		[self distanceReleatedWeightMap:startangle:minradius:searchareawidth:searchareaheight:precurve:lastweightmap];

		for(i=0;i<searchareasize;i++)
		{
			*(weightmap+i)+=*(lastweightmap+i);
		}
	}

	for(i=0;i<searchareasize;i++)
		if(*(directors+i)==0x40)
			*(weightmap+i)=999*distanceWeightFactor+999*intensityWeightFactor+999*gradientWeightFactor+3;
		else if(*(curweightmap+i)>lungThreshold+500)
			*(weightmap+i)=999*distanceWeightFactor+999*intensityWeightFactor+999*gradientWeightFactor;
		
	/*		*/	

			

	long endpoint=[self dijkstraAlgorithm:searchareawidth:searchareaheight:stepcostrange:weightmap:directors];
	if(endpoint!=-1)
	{
		unsigned char neighbor;
		tempy=endpoint/searchareawidth;
		tempx=endpoint%searchareawidth;
		while((neighbor=(*(directors+tempy*searchareawidth+tempx))&0x0f)!=0)
		{
			curve[(startangle+tempx+360)%360]=tempy+minradius;
			//*(weightmap+tempy*searchareawidth+tempx)=-10000; for test;
			switch(neighbor)
			{
				/*case 1:
					tempy++;break;
				case 2:
					tempx++;break;
				case 3:
					tempx--;break;
				case 4:
					tempy--;break;*/
				case 1:
					tempx++;tempy++;break;
				case 2:
					tempy++;break;
				case 3:
					tempx--;tempy++;break;
				case 4:
					tempx--; break;	
				case 5:
					tempx--;tempy--;break;
				case 6:
					tempy--;break;
				case 7:
					tempx++;tempy--;break;
				case 8:
					tempx++;break;
					
					
			}
		}
				
	}
	
 /* for 	 
	for(tempy=0;tempy<searchareaheight;tempy++)
		for(tempx=0;tempx<searchareawidth;tempx++)
		{
			*(image+(tempy+minradius)*imageWidth+tempx+startangle%360)=*(weightmap+tempy*searchareawidth+tempx);
		}
     test	*/
if(endpoint!=-1)
	return 0;
else
	return 1;
	
	
	
}
-(long)dijkstraAlgorithm:(long)width:(long)height:(long)costrange:(long*)weightmap:(unsigned char*)directormap
{//return the bridge point between two seeds
	
	long i,j;
	long x,y;
	long item;
	int neighbors;
	long directiondev;
	long directioncost;
	long directionweight[5]={0,10,100,999,1000};
	if(height*width<=0)
	{
		NSLog( @"width*height<");
		return -1;
	}
	
	long* costmap= costMapBuffer;
	memset(costmap,0x00,height*width*sizeof(long));
	CMIVBuketPirortyQueue* pirortyQueue=[[CMIVBuketPirortyQueue alloc] initWithParameter:1000*curveWeightFactor+1000*distanceWeightFactor+1000*intensityWeightFactor+1000*gradientWeightFactor+1 :width*height];
	
	
	for(j=0;j<height;j++)
		for(i=0;i<width;i++)
		{
			if((*(directormap+j*width+i))&0x80 && !((*(directormap+j*width+i))&0x10))//0x80 is seeds or checked point 0x10 is another side
			{
				for(neighbors=1;neighbors<9;neighbors++)
				{
					switch(neighbors)
					{/*
					 case 1:
					 x=i;y=j-1; break;
					 case 2:
					 x=i-1;y=j; break;
					 case 3:
					 x=i+1;y=j; break;
					 case 4:
					 x=i;y=j+1; break;*/
						case 1:
							x=i-1;y=j-1; break;
						case 2:
							x=i;y=j-1; break;
						case 3:
							x=i+1;y=j-1; break;
						case 4:
							x=i+1;y=j; break;	
						case 5:
							 x=i+1;y=j+1;break;
						case 6:
							x=i;y=j+1; break;
						case 7:
							 x=i-1;y=j+1;break;
						case 8:
							x=i-1;y=j; break;
					}
					if(x>=0 && y>=0 && x<width && y<height && !((*(directormap+y*width+x))&0x80) && !((*(directormap+y*width+x))&0x40)) //0x40 is border area
					{
						if((*(directormap+y*width+x))&0x20) // 0x20 is in queue
						{
							if((*(costmap+y*width+x))>(*(costmap+j*width+i))+(*(weightmap +y*width+x)))
							{
								(*(costmap+y*width+x))=(*(costmap+j*width+i))+(*(weightmap +y*width+x));
								(*(directormap+y*width+x))=0x20|neighbors;
								[pirortyQueue update:y*width+x:(*(weightmap +y*width+x))];
							}
						}
						else //not in queue
						{
							(*(costmap+y*width+x))=(*(costmap+j*width+i))+(*(weightmap +y*width+x));
							(*(directormap+y*width+x))=0x20|neighbors;
							[pirortyQueue push:y*width+x:(*(weightmap +y*width+x))];
						}
					}
						
				}
			}
		}

	while((item=[pirortyQueue pop])!=-1)
	{
		i=item%width;
		j=item/width;
		
		
/*for test		if(i==20&&j<97)
			i=20;

		long curcos=0;	
	curcos=(*(costmap+j*width+i));
		if(curcos==53199&&j==191)
			curcos=(*(costmap+j*width+i));*/
		
		*(directormap+j*width+i)=(*(directormap+j*width+i))|0x80;
		for(neighbors=1;neighbors<9;neighbors++)
		{
			switch(neighbors)
			{/*
			 case 1:
			 x=i;y=j-1; break;
			 case 2:
			 x=i-1;y=j; break;
			 case 3:
			 x=i+1;y=j; break;
			 case 4:
			 x=i;y=j+1; break;*/
				case 1:
					x=i-1;y=j-1; break;
				case 2:
					x=i;y=j-1; break;
				case 3:
					x=i+1;y=j-1; break;
				case 4:
					x=i+1;y=j; break;	
				case 5:
					x=i+1;y=j+1;break;
				case 6:
					x=i;y=j+1; break;
				case 7:
					x=i-1;y=j+1;break;
				case 8:
					x=i-1;y=j; break;
			}
			if(x>=0 && y>=0 && x<width && y<height) //0x40 is border area
			{
				if(!((*(directormap+y*width+x))&0x80) && !((*(directormap+y*width+x))&0x40))
				{
					directiondev=(*(directormap+j*width+i))&0x0f;
					if(directiondev==0)
						directioncost=0;
					else
					{
						directiondev-=neighbors;
						directiondev=abs(directiondev);
						if(directiondev>4)directiondev=8-directiondev;
						if(directiondev==4)
							directiondev=4;
						directioncost=directionweight[directiondev]*curveWeightFactor;
					}
					
					
					if((*(directormap+y*width+x))&0x20) // 0x20 is in queue
					{
						if((*(costmap+y*width+x))>(*(costmap+j*width+i))+directioncost+(*(weightmap +y*width+x)))
						{
							(*(costmap+y*width+x))=(*(costmap+j*width+i))+(*(weightmap +y*width+x));
							(*(directormap+y*width+x))=0x20|neighbors;
							[pirortyQueue update:y*width+x:(*(weightmap +y*width+x))];
						}
					}
					else //not in queue
					{
						(*(costmap+y*width+x))=(*(costmap+j*width+i))+directioncost+(*(weightmap +y*width+x));
						(*(directormap+y*width+x))=0x20|neighbors;
						[pirortyQueue push:y*width+x:(*(weightmap +y*width+x))];
					}
				}
				else if(((*(directormap+y*width+x))&0x80) && ((*(directormap+y*width+x))&0x10)) //0x10 stop area
				{
					(*(directormap+y*width+x))=neighbors;
					[pirortyQueue release];
					//memcpy(weightmap,costmap,height*width*sizeof(long));//for test//

					return y*width+x;
				}
			}
			
			
		}
	}
	[pirortyQueue release];
				//memcpy(weightmap,costmap,height*width*sizeof(long));//for test//
	return -1;
	
}
-(void)intensityRelatedWeightMap:(long)width:(long)height:(long*)weightmap
{

	if(width*height<=0)
	{
		NSLog( @"width*height<");
		return;
	}

	float* tempweightmap=(float*)malloc(width*height*sizeof(float));
	float* tempweightmap2=curSliceWeightMapBuffer;
	long i,j;
	long size=width*height;
/*	float  fkernel[25]={0.0192, 0.0192, 0.0385, 0.0192, 0.0192, 
						0.0192, 0.0385, 0.0769, 0.0385, 0.0192,
						0.0385, 0.0769, 0.1538, 0.0769, 0.0385,
						0.0192, 0.0385, 0.0769, 0.0385, 0.0192,
						0.0192, 0.0192, 0.0385, 0.0192, 0.0192};
	float  fkernel[25]={0.0030, 0.0133, 0.0219, 0.0133, 0.0030, 
						0.0133, 0.0591, 0.0983, 0.0591, 0.0133,
						0.0219, 0.0983, 0.1621, 0.0983, 0.0219,
						0.0133, 0.0591, 0.0983, 0.0591, 0.0133,
						0.0030, 0.0133, 0.0219, 0.0133, 0.0030};*/
	
	float  fkernel[49]={
	0.0049,    0.0092,    0.0134,    0.0152,    0.0134,    0.0092,    0.0049,
    0.0092,    0.0172,    0.0250,    0.0283,    0.0250,    0.0172,    0.0092,
    0.0134,    0.0250,    0.0364,    0.0412,    0.0364,    0.0250,    0.0134,
    0.0152,    0.0283,    0.0412,    0.0467,    0.0412,    0.0283,    0.0152,
    0.0134,    0.0250,    0.0364,    0.0412,    0.0364,    0.0250,    0.0134,
    0.0092,    0.0172,    0.0250,    0.0283,    0.0250,    0.0172,    0.0092,
    0.0049,    0.0092,    0.0134,    0.0152,    0.0134,    0.0092,    0.0049
	};

	
	for(i=0;i<size;i++)
		tempweightmap[i]=weightmap[i];
	vImage_Buffer dstf, srcf;
	
	srcf.height = height;
	srcf.width = width;
	srcf.rowBytes = width*sizeof(float);
	srcf.data = (void*) tempweightmap;
	
	dstf.height = height;
	dstf.width = width;
	dstf.rowBytes = width*sizeof(float);
	dstf.data=tempweightmap2;
	if( srcf.data)
	{
		short err;
		
		err = vImageConvolve_PlanarF( &srcf, &dstf, 0, 0, 0, fkernel, 7, 7, 0, kvImageEdgeExtend);
		if( err) NSLog(@"Error applyConvolutionOnImage = %d", err);
	}
		
	for(i=0;i<size;i++)
		weightmap[i]=tempweightmap2[i];
	
	for(j=0;j<height-1;j++)
	{
		for(i=0;i<width;i++)
		{
			
			*(tempweightmap+j*width+i)=*(weightmap+(j+1)*width+i)-*(weightmap+j*width+i);

		}
	}
	for(i=0;i<width;i++)
	{
		*(tempweightmap+(height-1)*width+i)=*(weightmap+(height-1)*width+i)-*(weightmap+(height-2)*width+i);
	}

// weight map from threshold and distance to ribs
	for(j=0;j<height;j++)
	{
		
		for(i=0;i<width;i++)
		{
			if(*(weightmap+j*width+i)>lungThreshold+400)
				*(weightmap+j*width+i)=1000;
			else if(*(weightmap+j*width+i)>lungThreshold+300)
				*(weightmap+j*width+i)=*(weightmap+j*width+i)-lungThreshold-299;
			else
				*(weightmap+j*width+i)=1;
		}
	}
	long edgedisweight[12]={0,2,4,8,16,32,64,128,256,512,999,999};
	for(i=0;i<width;i++)
	{
		
		for(j=0;j<height;j++)
		{
			if(*(weightmap+j*width+i)==1)
			{
				long fatrangestart=j;
				
				while(j<height&&*(weightmap+j*width+i)<1000)j++;
				if(j>=height)j=height-1;
				long fatrangeend=j;
				long k;
				float unitdelta;
				long x1,x2;
				for(k=fatrangeend-1;k>=fatrangestart;k--)
				{
					x1=(fatrangeend-k)*10/(fatrangeend-fatrangestart);
					x2=x1+1;
					unitdelta=(float)((fatrangeend-k)*10)/(float)(fatrangeend-fatrangestart);
					unitdelta-=x1;
					*(weightmap+k*width+i)+=edgedisweight[x1]+(edgedisweight[x2]-edgedisweight[x1])*unitdelta;
				}
				*(weightmap+(fatrangeend-1)*width+i)=999;
			}
		}
	}


	for(i=0;i<size;i++)
	{
		if(*(weightmap+i)>1000)
			*(weightmap+i)=1000;
		else if(*(weightmap+i)<0)
			*(weightmap+i)=1;
		*(weightmap+i)*=intensityWeightFactor;
	}


		
	for(i=0;i<size;i++)
	{
		if(*(tempweightmap+i)<-30)
			*(weightmap+i)+=1000*gradientWeightFactor;
		else if(*(tempweightmap+i)>-50&&*(tempweightmap+i)<50)
		{
			long x1,x2;
			x1=(50-(int)(*(tempweightmap+i)))/8;
			x2=x1+1;
			float unitdelta;
			unitdelta=(float)(50-(*(tempweightmap+i)))/8.0-x1;
			*(weightmap+i)+=gradientWeightFactor*(edgedisweight[x1]+(edgedisweight[x2]-edgedisweight[x1])*unitdelta);
		}
		
		else 
			*(weightmap+i)+=0;
				
	}	


	free(tempweightmap);

}
-(void)distanceReleatedWeightMap:(long)startangle:(long)minradius:(long)width:(long)height:(float*)precurve:(float*)lastweightmap
{
	float* tempweightmap=(float*)malloc(width*height*sizeof(float));
	//float* curweightmap=curSliceWeightMapBuffer;
	long size=width*height;
	/*	float  fkernel[25]={0.0192, 0.0192, 0.0385, 0.0192, 0.0192, 
	 0.0192, 0.0385, 0.0769, 0.0385, 0.0192,
	 0.0385, 0.0769, 0.1538, 0.0769, 0.0385,
	 0.0192, 0.0385, 0.0769, 0.0385, 0.0192,
	 0.0192, 0.0192, 0.0385, 0.0192, 0.0192};
	 float  fkernel[25]={0.0030, 0.0133, 0.0219, 0.0133, 0.0030, 
	 0.0133, 0.0591, 0.0983, 0.0591, 0.0133,
	 0.0219, 0.0983, 0.1621, 0.0983, 0.0219,
	 0.0133, 0.0591, 0.0983, 0.0591, 0.0133,
	 0.0030, 0.0133, 0.0219, 0.0133, 0.0030};*/
	
	float  fkernel[49]={
		0.0049,    0.0092,    0.0134,    0.0152,    0.0134,    0.0092,    0.0049,
		0.0092,    0.0172,    0.0250,    0.0283,    0.0250,    0.0172,    0.0092,
		0.0134,    0.0250,    0.0364,    0.0412,    0.0364,    0.0250,    0.0134,
		0.0152,    0.0283,    0.0412,    0.0467,    0.0412,    0.0283,    0.0152,
		0.0134,    0.0250,    0.0364,    0.0412,    0.0364,    0.0250,    0.0134,
		0.0092,    0.0172,    0.0250,    0.0283,    0.0250,    0.0172,    0.0092,
		0.0049,    0.0092,    0.0134,    0.0152,    0.0134,    0.0092,    0.0049
	};
	
	
	memcpy(tempweightmap, lastweightmap, size*sizeof(float));
	vImage_Buffer dstf, srcf;
	
	srcf.height = height;
	srcf.width = width;
	srcf.rowBytes = width*sizeof(float);
	srcf.data = tempweightmap;
	
	dstf.height = height;
	dstf.width = width;
	dstf.rowBytes = width*sizeof(float);
	dstf.data=lastweightmap;
	if( srcf.data)
	{
		short err;
		
		err = vImageConvolve_PlanarF( &srcf, &dstf, 0, 0, 0, fkernel, 7, 7, 0, kvImageEdgeExtend);
		if( err) NSLog(@"Error applyConvolutionOnImage = %d", err);
	}
	free(tempweightmap);
	
	long i,j;
	long prepoint;
	long differentscore;
	//long leastdiffscore,leastdiffscoreindex;
	/*
	for(i=0;i<width;i++)
	{
		prepoint=precurve[i+startangle]-minradius;
		if(prepoint>5&&height-prepoint>6)
		{
			differentscore=0;
			for(j=-2;j<=2;j++)
				differentscore+=abs(*(lastweightmap+(prepoint+j)*width+i)-*(curweightmap+(prepoint+j)*width+i));
			if(differentscore>100)
			{
				leastdiffscore=differentscore;
				leastdiffscoreindex=0;
				for(k=-3;k<=3;k++)
				{
					differentscore=0;
					for(j=-2;j<=2;j++)
						differentscore+=abs(*(lastweightmap+(prepoint+j+k)*width+i)-*(lastweightmap+(prepoint+j)*width+i));
					if(differentscore<leastdiffscore)
					{
						leastdiffscore=differentscore;
						leastdiffscoreindex=k;
					}
				}
				precurve[i+startangle]+=leastdiffscoreindex;

			}
		}
		
	}*/
	float curveshift[361];
	
	for(i=1;i<361;i++)
		curveshift[(i+360)%360]=0;
	for(i=0;i<width;i++)
	{
		prepoint=precurve[(i+startangle+360)%360]-minradius;
		if(prepoint>2&&height-prepoint>3)
		{
			float slope;
			slope=(*(lastweightmap+(prepoint-1)*width+i)+*(lastweightmap+(prepoint-2)*width+i))-(*(lastweightmap+(prepoint+1)*width+i)+*(lastweightmap+(prepoint+2)*width+i));
			differentscore=slope/25;
			if(differentscore>8)
				differentscore=8;
			if(differentscore<-8)
				differentscore=-8;
			curveshift[(i+startangle+360)%360]=differentscore;
		}
		
	}	
	for(i=1;i<361;i++)
		curveshift[(i+360)%360]=(curveshift[(i+360)%360]+curveshift[(i-1+360)%360]+curveshift[(i+1+360)%360])/3;
	for(i=0;i<width;i++)
		precurve[(i+startangle+360)%360]+=curveshift[(i+startangle+360)%360];
	

	
	memset(lastweightmap,0x00,size*sizeof(float));
	
	long distanceweight,distance;
	long disweight[11]={1,10,100,150,200,280,400,500,650,850,999};
	float distancethreshold=0;//5.0/zoomFactor+0.5;
	for(j=0;j<height;j++)
		for(i=0;i<width;i++)
		{
			distance=abs(j+minradius-precurve[(i+startangle+360)%360]);
			if(distance<distancethreshold)
				distanceweight=0;
			else if(distance>10+distancethreshold)
				distanceweight=1000;
			else
				distanceweight=disweight[(int)(distance-distancethreshold)];
				
			*(lastweightmap+j*width+i)+=distanceweight*distanceWeightFactor;
			if(*(lastweightmap+j*width+i)<0)
				*(lastweightmap+j*width+i)=1;
		}
}
-(void)smoothOutput:(unsigned char*)outData
{
	/*
	int i;
	unsigned char*temp2D8bit=(unsigned char*)malloc(imageSize*sizeof(char));
	for(i=0;i<imageAmount;i++)
	{
		vImage_Buffer dstf, srcf;
		
		srcf.height = imageHeight;
		srcf.width = imageWidth;
		srcf.rowBytes = imageWidth*sizeof(float);
		srcf.data = (void*) (outData+i*imageSize);
		
		dstf.height = imageHeight;
		dstf.width = imageWidth;
		dstf.rowBytes = imageWidth*sizeof(float);
		dstf.data=temp2D8bit;
		if( srcf.data)
		{
			short err;
			
			err = vImageConvolve_PlanarF( &srcf, &dstf, 0, 0, 0, fkernel, 5, 5, 0, kvImageEdgeExtend);
			if( err) NSLog(@"Error applyConvolutionOnImage = %d", err);
		}
		memcpy(temp2D8bit, imageSize
		
	}*/
}
#pragma mark-
#pragma mark 2 Aorta Detecting
-(float)findAorta:(float*)inData:(long*)origin:(long*)dimension:(float*)spacing
{
	NSLog( @" circle detection ");
	int err=0;
	inputData=inData;
	imageWidth=dimension[0];
	imageHeight=dimension[1];
	imageAmount=dimension[2];
	xSpacing=spacing[0];
	ySpacing=spacing[1];
	zSpacing=spacing[2];
	xOrigin=origin[0];
	yOrigin=origin[1];
	zOrigin=origin[2];
	imageSize=imageWidth*imageHeight;

	NSMutableArray* circlesArray=[NSMutableArray arrayWithCapacity:0];
	err=[self detectCircles:(NSMutableArray*) circlesArray:imageAmount/3];
	if(err)
		return -1.0;
	NSLog( @"remove useless circle");	

	err=[self removeUnrelatedCircles:circlesArray];
	if(err)
		return -1.0;
	//[self exportCircles:circlesArray];
	CMIV3DPoint* acircle=[circlesArray objectAtIndex:0];
	origin[0]=acircle.x;
	origin[1]=acircle.y;
	origin[2]=(acircle.z-zOrigin)/zSpacing;
	float radius=acircle.fValue;
	//float maxHu=[self caculateAortaMaxIntensity:circlesArray];
	[circlesArray removeAllObjects];
	return radius;
	
}
-(float)caculateAortaMaxIntensity:(float*)img:(int)imgwidth:(int)imgheight:(int)centerx:(int)centery:(int)radius
{
//	unsigned int i;
	int x1,y1,r;
	int x2,y2;
	int x,y;
	float maxhu=-10000;
//	for(i=0;i<[circles count]/3+1;i++)
	{

		r=radius;
		x2=centerx+r;
		y2=centery+r;		
		x1=centerx-r;
		y1=centery-r;
		if(x1<0)
			x1=0;
		if(y1<0)
			y1=0;

		if(x2>imgwidth-1)
			x2=imgwidth-1;
		if(y2>imgheight-1)
			y2=imgheight-1;
		for(y=y1;y<y2;y++)
			for(x=x1;x<x2;x++)
				if((x-centerx)*(x-centerx)+(y-centery)*(y-centery)<=r*r)
					if(maxhu<*(img+y*imgwidth+x))
						maxhu=*(img+y*imgwidth+x);
	}
	return maxhu;
	
}
-(void)exportCircles:(NSArray*)circles
{
	unsigned int i;
	int x1,y1,z1,r1;
	int x2,y2;
	int x,y;
	for(i=0;i<[circles count];i++)
	{
		CMIV3DPoint* acircle=[circles objectAtIndex:i];
		x1=acircle.x;
		y1=acircle.y;
		z1=(acircle.z-zOrigin)/zSpacing;
		r1=acircle.fValue;
		
		x=x1-r1;
		y=y1-r1;
		if(x<0)
			x=0;
		if(y<0)
			y=0;
		x2=x1+r1;
		y2=y1+r1;
		if(x2>imageWidth-1)
			x2=imageWidth-1;
		if(y2>imageHeight-1)
			y2=imageHeight-1;
		for(;x<x2;x++)
			*(inputData+(z1*imageSize)+y1*imageWidth+x)=3000;
		for(;y<y2;y++)
			*(inputData+(z1*imageSize)+y*imageWidth+x1)=3000;
		
	}
	
}
-(int)removeUnrelatedCircles:(NSMutableArray*)circles
{
	float centerxyDeltaThreshold=0.9;
	float centerzDeltaThreshold=3.0;
	NSMutableArray	*potentialVessels=[NSMutableArray arrayWithCapacity:0];
	
	unsigned int i,j,k;
	float x1,y1,r1,z1,x2,y2,r2,z2;
	for(i=0;i<[circles count];i++)
	{
		CMIV3DPoint* acircle=[circles objectAtIndex:i];
		x1=acircle.x;
		y1=acircle.y;
		z1=acircle.z;
		r1=acircle.fValue;
		
		for(j=0;j<[potentialVessels count]&&acircle;j++)
			for(k=0;k<[[potentialVessels objectAtIndex:j] count];k++)
			{
				CMIV3DPoint* bcircle=[[potentialVessels objectAtIndex:j] objectAtIndex:k];
				x2=bcircle.x;
				y2=bcircle.y;
				z2=bcircle.z;
				r2=bcircle.fValue;
				if(fabs(z2-z1)>centerzDeltaThreshold)
					continue;
				if((r1+r2-sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2)))/(r1+r2)<centerxyDeltaThreshold)
					continue;
				[[potentialVessels objectAtIndex:j] addObject:acircle];
				acircle=nil;
				break;
				
			}
		if(acircle)
		{
			NSMutableArray	*aVessel=[NSMutableArray arrayWithCapacity:0];
			[aVessel addObject:acircle];
			[potentialVessels addObject:aVessel];
		}
	}
	j=[potentialVessels count];
	float* scoreArray=(float*)malloc(j*sizeof(float));
	memset(scoreArray, 0x00, j*sizeof(float));
	for(j=0;j<[potentialVessels count];j++)
		for(k=0;k<[[potentialVessels objectAtIndex:j] count];k++)
		{
			CMIV3DPoint* bcircle=[[potentialVessels objectAtIndex:j] objectAtIndex:k];
			x2=bcircle.x;
			y2=bcircle.y;
			x1=imageWidth-x2;
			if(x1>x2)
				x1=x2;
			y1=imageHeight-y2;
			*(scoreArray+j)+=y1*4/imageHeight;
			i=[circles indexOfObject:bcircle ];
			*(scoreArray+j)+=2*(3-i%3);
			
		}
	float maxscore=*scoreArray;
	k=0;
	int secondcandidate=0;
	for(j=1;j<[potentialVessels count];j++)
		if(maxscore<*(scoreArray+j))
		{
			maxscore=*(scoreArray+j);
			secondcandidate=k;
			k=j;
		}
	
	
	if(maxscore-*(scoreArray+secondcandidate)<maxscore/5)
	{
		CMIV3DPoint* acircle=[[potentialVessels objectAtIndex:k] objectAtIndex:0];
		x1=acircle.x;
		acircle=[[potentialVessels objectAtIndex:secondcandidate] objectAtIndex:0];
		x2=acircle.x;
		if(x2<x1)
			k=secondcandidate;

	}
	
	[circles removeAllObjects];
	
	[circles addObjectsFromArray:[potentialVessels objectAtIndex:k]];
	[circles addObjectsFromArray:[potentialVessels objectAtIndex:secondcandidate]];

	for(j=0;j<[potentialVessels count];j++)
		[[potentialVessels objectAtIndex:j] removeAllObjects];
	[potentialVessels removeAllObjects];
	
	free(scoreArray);
	
	return 0;
	
	
	
}
-(int)detectCircles:(NSMutableArray*) circlesArray:(int)nslices
{
	

	
	const     unsigned int        Dimension       = 2;
	typedef   float               InputPixelType;
	typedef   float               OutputPixelType;
	
	typedef   itk::Image< InputPixelType, Dimension >   InputImageType;
	typedef   itk::Image< OutputPixelType, Dimension >  OutputImageType;
	typedef itk::ImportImageFilter< InputPixelType, Dimension > ImportFilterType;
	
	ImportFilterType::Pointer importFilter;
	
	importFilter = ImportFilterType::New();
	
	ImportFilterType::SizeType itksize;
	itksize[0] = imageWidth; // size along X
	itksize[1] = imageHeight; // size along Y

	
	ImportFilterType::IndexType start;
	start.Fill( 0 );
	
	ImportFilterType::RegionType region;
	region.SetIndex( start );
	region.SetSize( itksize );
	importFilter->SetRegion( region );
	
	double origin[ 2 ];
	origin[0] = xOrigin; // X coordinate
	origin[1] = yOrigin; // Y coordinate
	importFilter->SetOrigin( origin );
	
	double spacing[ 2 ];
	spacing[0] = xSpacing; // along X direction
	spacing[1] = ySpacing; // along Y direction

	importFilter->SetSpacing( spacing );
	
	typedef   itk::CurvatureAnisotropicDiffusionImageFilter< 	InputImageType, 	InputImageType >  SmoothingFilterType;
	SmoothingFilterType::Pointer smoothing = SmoothingFilterType::New();
	smoothing->SetTimeStep( 0.125 );
	smoothing->SetNumberOfIterations(  5 );
	smoothing->SetConductanceParameter( 9.0 );
	smoothing->SetInput( importFilter->GetOutput() );

	const bool importImageFilterWillOwnTheBuffer = false;
	typedef   float           AccumulatorPixelType;  
	typedef itk::HoughTransform2DCirclesImageFilter<InputPixelType,
	AccumulatorPixelType> HoughTransformFilterType;
	HoughTransformFilterType::Pointer houghFilter = HoughTransformFilterType::New();
	int i;
	houghFilter->SetInput( smoothing->GetOutput() );
	
	for(i=imageAmount-1;i>=imageAmount-nslices;i--)
	{
		importFilter->SetImportPointer( (inputData+imageSize*i), itksize[0] * itksize[1], importImageFilterWillOwnTheBuffer);
		
		
		
		houghFilter->SetNumberOfCircles( 3 );
		houghFilter->SetMinimumRadius(   7/xSpacing );
		houghFilter->SetMaximumRadius(  25/xSpacing );
		houghFilter->SetThreshold(100);
	
		 houghFilter->SetSweepAngle(3*deg2rad);
		 houghFilter->SetSigmaGradient( 3 );
		 houghFilter->SetVariance( 5 );
		 houghFilter->SetDiscRadiusRatio( 1.5 );
		
		houghFilter->Update(); 
		
		HoughTransformFilterType::CirclesListType circles;
		circles = houghFilter->GetCircles( 4 );
		typedef HoughTransformFilterType::CirclesListType CirclesListType;
		CirclesListType::const_iterator itCircles = circles.begin();
		
		while( itCircles != circles.end() )
		{
			float centerx,centery,radius;
			centerx=(*itCircles)->GetObjectToParentTransform()->GetOffset()[0];
			centery=(*itCircles)->GetObjectToParentTransform()->GetOffset()[1] ;
			radius=(*itCircles)->GetRadius()[0];
			CMIV3DPoint* aNewCircle=[[CMIV3DPoint alloc] init];
			aNewCircle.x=centerx;
			aNewCircle.y=centery;
			aNewCircle.z=zOrigin+i*zSpacing;
			aNewCircle.fValue=radius;
			[circlesArray addObject:aNewCircle];
			[aNewCircle release];
			itCircles++;
		}
	}
	


	return 0;
	
	
}
-(int)findFirstCenter:(unsigned char*)firstSlice
{
	unsigned char *tempSlice=(unsigned char*)malloc(imageSize*sizeof(char));
	memcpy(tempSlice, firstSlice, imageSize*sizeof(char));
	int i,j;
	int lungupborder=0,lunglowborder=0;
	for(i=0;i<imageSize;i++)
		if(*(firstSlice+i))
		{
			lungupborder=i/imageWidth;
			break;
		}
	for(i=imageSize-1;i>=0;i--)
		if(*(firstSlice+i))
		{
			lunglowborder=i/imageWidth;
			break;
		}	
	memset(tempSlice, 0x00, lungupborder*imageWidth*sizeof(char));

	//int buffersize=	imageWidth*imageHeight;
	typedef  unsigned char   InputPixelType;
	typedef  float  OutputPixelType;
	const     unsigned int    Dimension = 2;
	typedef itk::Image< InputPixelType,  2 >   InputImageType;
	typedef itk::Image< OutputPixelType, 2 >   OutputImageType;
	
	typedef itk::ImportImageFilter< InputPixelType, Dimension > ImportFilterType;
	
	ImportFilterType::Pointer importFilter;
	
	importFilter = ImportFilterType::New();
	
	ImportFilterType::SizeType itksize;
	itksize[0] = imageWidth; // size along X
	itksize[1] = imageHeight; // size along Y
	ImportFilterType::IndexType start;
	start.Fill( 0 );
	ImportFilterType::RegionType region;
	region.SetIndex( start );
	region.SetSize( itksize );
	importFilter->SetRegion( region );
	double origin[ 2 ];
	origin[0] = 0;
	origin[1] = 0;
	importFilter->SetOrigin( origin );
	
	double spacing[ 2 ];
	spacing[0] = 1.0;
	spacing[1] = 1.0;
	importFilter->SetSpacing( spacing );
	
	const bool importImageFilterWillOwnTheBuffer = false;
	importFilter->SetImportPointer( tempSlice, itksize[0] * itksize[1], importImageFilterWillOwnTheBuffer);
	
	typedef itk::DanielssonDistanceMapImageFilter<	InputImageType, OutputImageType >  FilterType;
	FilterType::Pointer filter = FilterType::New();
	
	filter->SetInput( importFilter->GetOutput() );
	filter->InputIsBinaryOn();
	
	try
	{
		filter->Update();
	}
	catch( itk::ExceptionObject & excep )
	{
		NSLog(@"ITK distance map failed!");
		return -1;
	}
	float* fsegresult=filter->GetOutput()->GetBufferPointer();	

		
	
	if(lungupborder<imageHeight/3)
		lungupborder=imageHeight/3;
	if(lunglowborder>imageHeight*2/3)
		lunglowborder=imageHeight*2/3;
	int centerx=imageWidth/2,centery=(lungupborder+lunglowborder)/2;
	float maxdis=*(fsegresult+centery*imageWidth+centerx);
	
	for(j=lungupborder;j<lunglowborder;j++)
	{

		for(i=imageWidth/3;i<imageWidth*2/3;i++)
		{
			if(*(fsegresult+j*imageWidth+i)>maxdis)
			{
				maxdis=*(fsegresult+j*imageWidth+i);
				centerx=i;
				centery=j;
			}
	
		}
	}
	
	free(tempSlice);
	return centery*imageWidth+centerx;

}
/*
-(void)noiseRemoveUsingOpeningAtHighResolution:(unsigned char*)imgdata:(int)width:(int)height:(int)amount:(int)kernelsize
{
	unsigned char* erodekernelbuf=(unsigned char*)calloc(kernelsize*kernelsize,sizeof(char));
	unsigned char* dilatekernelbuf=(unsigned char*)malloc(kernelsize*kernelsize*sizeof(char));
	unsigned char* tempimgbuf=(unsigned char*)malloc(width*height*sizeof(char));
	[self fillCirleKernel:erodekernelbuf:kernelsize];
	int i,bufsize=kernelsize*kernelsize;
	for(i=0;i<bufsize;i++)
		if(erodekernelbuf[i])
			dilatekernelbuf[i]=0x00;
		else
			dilatekernelbuf[i]=0xFF;
	int imagesize=width*height;
	for(i=0;i<amount;i++)
	{
		[self erode2DBinaryImage: imgdata+imagesize*i:tempimgbuf :width:height:erodekernelbuf:kernelsize];
		[self dilate2DBinaryImage: imgdata+imagesize*i:tempimgbuf  :width:height:dilatekernelbuf:kernelsize];
	}
	free(erodekernelbuf);
	free(dilatekernelbuf);
	free(tempimgbuf);
	
}
-(void)closeVesselHolesIn2D:(unsigned char*)imgdata:(int)width:(int)height:(int)amount:(int)kernelsize
{
	kernelsize=2*kernelsize+1;
	unsigned char* erodekernelbuf=(unsigned char*)calloc(kernelsize*kernelsize,sizeof(char));
	unsigned char* dilatekernelbuf=(unsigned char*)malloc(kernelsize*kernelsize*sizeof(char));
	unsigned char* tempimgbuf=(unsigned char*)malloc(width*height*sizeof(char));
	[self fillCirleKernel:erodekernelbuf:kernelsize];
	int i,bufsize=kernelsize*kernelsize;
	for(i=0;i<bufsize;i++)
		if(erodekernelbuf[i])
			dilatekernelbuf[i]=0x00;
		else
			dilatekernelbuf[i]=0xFF;
	int imagesize=width*height;
	for(i=0;i<amount;i++)
	{
		[self dilate2DBinaryImage: imgdata+imagesize*i:tempimgbuf  :width:height:dilatekernelbuf:kernelsize];
		[self erode2DBinaryImage: imgdata+imagesize*i:tempimgbuf :width:height:erodekernelbuf:kernelsize];
	}
	free(erodekernelbuf);
	free(dilatekernelbuf);
	free(tempimgbuf);
	
}
-(void)fillCirleKernel:(unsigned char*)buf:(int)size
{
	int		x,y;
	int		rad = size/2;
	int		inw = size-1;
	int		radsqr = (inw*inw)/4;
	
	for(x = 0; x < rad; x++)
	{
		for( y = 0 ; y < rad; y++)
		{
			if((x*x + y*y) <= radsqr)
			{
				buf[ rad+x + (rad+y)*size] = 0xFF;
				buf[ rad-x + (rad+y)*size] = 0xFF;
				buf[ rad+x + (rad-y)*size] = 0xFF;
				buf[ rad-x + (rad-y)*size] = 0xFF;
			}
		}
	}
	
}
-(void)erode2DBinaryImage:(unsigned char*)img:(unsigned char*)imgbuffer:(int)width:(int)height:(unsigned char*)kernel:(int)kernelsize
{
	vImage_Buffer	srcbuf, dstBuf;
	vImage_Error err;
	srcbuf.data = img;
	dstBuf.data = imgbuffer;
	dstBuf.height = srcbuf.height = height;
	dstBuf.width = srcbuf.width = width;
	dstBuf.rowBytes = srcbuf.rowBytes = width;
	err = vImageErode_Planar8( &srcbuf, &dstBuf, 0, 0, kernel, kernelsize, kernelsize, kvImageDoNotTile); 	
	if( err) NSLog(@"%d", err);
	memcpy(img, dstBuf.data, width*height);

	
}
-(void)dilate2DBinaryImage:(unsigned char*)img:(unsigned char*)imgbuffer:(int)width:(int)height:(unsigned char*)kernel:(int)kernelsize
{
	
	vImage_Buffer	srcbuf, dstBuf;
	vImage_Error err;
	srcbuf.data = img;
	dstBuf.data = imgbuffer;
	dstBuf.height = srcbuf.height = height;
	dstBuf.width = srcbuf.width = width;
	dstBuf.rowBytes = srcbuf.rowBytes = width;
	err = vImageDilate_Planar8( &srcbuf, &dstBuf, 0, 0, kernel, kernelsize, kernelsize, kvImageDoNotTile); 	
	if( err) NSLog(@"%d", err);
	memcpy(img, dstBuf.data, width*height);
	
	
}
-(int)closeVesselHoles:(unsigned char*)inData:(int)width:(int)height:(int)amount:(float*)samplespacing:(int)kenelsize
{
	
	

	const unsigned int Dimension = 3;
	
	typedef   unsigned char               InputPixelType;
	typedef   unsigned char               OutputPixelType;
	
	typedef   itk::Image< InputPixelType, Dimension >   InputImageType;
	typedef   itk::Image< OutputPixelType, Dimension >  OutputImageType;
	
	typedef itk::ImportImageFilter< InputPixelType, Dimension > ImportFilterType;
	
	ImportFilterType::Pointer importFilter;
	
	importFilter = ImportFilterType::New();
	
	ImportFilterType::SizeType itksize;
	itksize[0] = width; // size along X
	itksize[1] = height; // size along Y
	itksize[2] = amount;// size along Z
	
	ImportFilterType::IndexType start;
	start.Fill( 0 );
	
	ImportFilterType::RegionType region;
	region.SetIndex( start );
	region.SetSize( itksize );
	importFilter->SetRegion( region );
	
	double origin[ 3 ];
	origin[0] = 0; // X coordinate
	origin[1] = 0; // Y coordinate
	origin[2] = 0; // Z coordinate
	importFilter->SetOrigin( origin );
	
	double spacing[ 3 ];
	spacing[0] = samplespacing[0]; // along X direction
	spacing[1] = samplespacing[1]; // along Y direction
	spacing[2] = samplespacing[2]; // along Z direction
	importFilter->SetSpacing( spacing ); 
	
	const bool importImageFilterWillOwnTheBuffer = false;
	importFilter->SetImportPointer( inData, itksize[0] * itksize[1] * itksize[2], importImageFilterWillOwnTheBuffer);
	NSLog(@"ITK Image allocated");
	
	
	typedef itk::BinaryBallStructuringElement<InputPixelType,Dimension> StructuringElementType;
	typedef itk::BinaryErodeImageFilter<InputImageType, OutputImageType,StructuringElementType>ErodeFilterType;
	typedef itk::BinaryDilateImageFilter<InputImageType,OutputImageType, StructuringElementType> DilateFilterType;

	ErodeFilterType::Pointer  binaryErode  = ErodeFilterType::New();
	DilateFilterType::Pointer binaryDilate = DilateFilterType::New();
	

	StructuringElementType  structuringElement;
	
	structuringElement.SetRadius( kenelsize );  // 3x3 structuring element
	
	structuringElement.CreateStructuringElement();
	
	binaryErode->SetKernel(  structuringElement );
	binaryDilate->SetKernel( structuringElement );
	
	binaryDilate->SetInput( importFilter->GetOutput() );
	binaryErode->SetInput( binaryDilate->GetOutput() );
	
	binaryErode->SetErodeValue( 255 );
	binaryDilate->SetDilateValue( 255 );

	try
	{
		binaryErode->Update();
	}
	catch( itk::ExceptionObject & excep )
	{
		return 1;
	}
	unsigned char* closedOutput=binaryErode->GetOutput()->GetBufferPointer();
	memcpy(inData, closedOutput, width*height*amount*sizeof(char));
	
	return 0;
}
*/
#pragma mark-
#pragma mark 3 Vesselness Filter
- (int) vesselnessFilter:(float *)inData:(float*)outData:(long*)dimension:(float*)imgspacing:(float)startscale:(float)endscale:(float)scalestep
{
	
	imageWidth=dimension[0];
	imageHeight=dimension[1];
	imageAmount=dimension[2];
	
	long size = sizeof(float) * imageWidth * imageHeight * imageAmount;
	
	
	const     unsigned int        Dimension       = 3;
	typedef   float               InputPixelType;
	typedef   float               OutputPixelType;
	
	typedef   itk::Image< InputPixelType, Dimension >   InputImageType;
	typedef   itk::Image< OutputPixelType, Dimension >  OutputImageType;
	
	typedef   itk::HessianRecursiveGaussianImageFilter<InputImageType >  HessianFilterType;
	
	typedef   itk::Hessian3DToVesselnessMeasureImageFilter<OutputPixelType > VesselnessMeasureFilterType;
	
	typedef itk::ImportImageFilter< InputPixelType, Dimension > ImportFilterType;
	
	ImportFilterType::Pointer importFilter;
	
	itk::MultiThreader::SetGlobalDefaultNumberOfThreads( MPProcessors());
	
	importFilter = ImportFilterType::New();
	
	ImportFilterType::SizeType itksize;
	itksize[0] = imageWidth; // size along X
	itksize[1] = imageHeight; // size along Y
	itksize[2] = imageAmount;// size along Z
	
	ImportFilterType::IndexType start;
	start.Fill( 0 );
	
	ImportFilterType::RegionType region;
	region.SetIndex( start );
	region.SetSize( itksize );
	importFilter->SetRegion( region );
	
	double origin[ 3 ];
	origin[0] = 0; // X coordinate
	origin[1] = 0; // Y coordinate
	origin[2] = 0; // Z coordinate
	importFilter->SetOrigin( origin );
	
	double spacing[ 3 ];
	spacing[0] = imgspacing[0]; // along X direction
	spacing[1] = imgspacing[1]; // along Y direction
	spacing[2] = imgspacing[2]; // along Z direction
	importFilter->SetSpacing( spacing ); 
	
	const bool importImageFilterWillOwnTheBuffer = false;
	importFilter->SetImportPointer( inData, itksize[0] * itksize[1] * itksize[2], importImageFilterWillOwnTheBuffer);
	NSLog(@"ITK Image allocated");
	
	
	HessianFilterType::Pointer hessianFilter = HessianFilterType::New();
	VesselnessMeasureFilterType::Pointer vesselnessFilter =	VesselnessMeasureFilterType::New();
	hessianFilter->SetNormalizeAcrossScale(true);
	hessianFilter->SetInput( importFilter->GetOutput() );
	
	vesselnessFilter->SetInput( hessianFilter->GetOutput() );
	vesselnessFilter->SetAlpha1(0.5);
	vesselnessFilter->SetAlpha2(0.5);
	float m_sigma;
	size = imageWidth * imageHeight * imageAmount;//-4 to protect memory overflow when using vec_max
	for(m_sigma=startscale;m_sigma<=endscale;m_sigma+=scalestep)
	{
		hessianFilter->SetSigma(m_sigma);
		try
		{
			vesselnessFilter->Update();
		}
		catch( itk::ExceptionObject & excep )
		{
			return 1;
		}
		float* enhanceOutput=vesselnessFilter->GetOutput()->GetBufferPointer();
		int i;
		for(i=0;i<size;i++)
		{
			if(outData[i]<enhanceOutput[i])
				outData[i]=enhanceOutput[i];
		}
		
		NSLog(@"ITK vesselness file single scale finished");
		[[NSNotificationCenter defaultCenter] postNotificationName: @"CMIVLeveIndicatorStep" object:self userInfo: nil];
	}
	
	
	return 0;
	
	
}
#pragma mark-
#pragma mark 4 Cross Section Growing
-(int)crossectionGrowingWithinVolume:(float*)volumeData ToSeedVolume:(unsigned short*)seedData Dimension:(long*)dim Spacing:(float*)spacing StartPt:(float*)ptxyz Threshold:(float)threshold Diameter:(float)diameter
{


	float steplength=2.0;
	int pnums=10.0/steplength;
	int step=0;
	int postedIndicatorNotification=0;

	float minValueInSeries=threshold-2000;
	imageWidth=dim[0];
	imageHeight=dim[1];
	imageAmount=dim[2];
	imageSize=dim[0]*dim[1];

	//initilize vtk part

	vtkImageImport* reader = vtkImageImport::New();
	reader->SetWholeExtent(0, dim[0]-1, 0, dim[1]-1, 0, dim[2]-1);
	reader->SetDataSpacing(spacing[0],spacing[1],spacing[2]);
	reader->SetDataOrigin( 0,0,0 );
	reader->SetDataExtentToWholeExtent();
	reader->SetDataScalarTypeToFloat();
	reader->SetImportVoidPointer(volumeData);
	
	vtkTransform* translateTransform = vtkTransform::New();
	translateTransform->Translate(ptxyz[0]*spacing[0],ptxyz[1]*spacing[1],ptxyz[2]*spacing[2]);
	
	vtkTransform* rotationTransform = vtkTransform::New();
	rotationTransform->Identity ();
	rotationTransform->SetInput(translateTransform) ;

	
	vtkTransform* inverseTransform = (vtkTransform*)rotationTransform->GetLinearInverse();
	
	vtkImageReslice *imageSlice = vtkImageReslice::New();
	imageSlice->SetAutoCropOutput( true);
	imageSlice->SetInformationInput( reader->GetOutput());
	imageSlice->SetInput( reader->GetOutput());
	imageSlice->SetOptimization( true);
	imageSlice->SetResliceTransform( rotationTransform);
	imageSlice->SetResliceAxesOrigin( 0, 0, 0);
	imageSlice->SetInterpolationModeToCubic();//    >SetInterpolationModeToNearestNeighbor();
	imageSlice->SetOutputDimensionality( 2);
//	if(spacing[0]<0.5)
//	imageSlice->SetOutputSpacing(0.5,0.5,0.5);
	imageSlice->SetBackgroundLevel( -1024);
	
	vtkImageData	*tempIm;
	int	imSliceExtent[ 6];
	double imSliceSpacing[3],imSliceOrigin[3];
	tempIm = imageSlice->GetOutput();
	tempIm->Update();
	tempIm->GetWholeExtent( imSliceExtent);
	tempIm->GetSpacing( imSliceSpacing);
	tempIm->GetOrigin( imSliceOrigin);


	
	//creat buffer for levelset segmentation
	
	int costMapWidth,costMapHeight;
	vtkMatrix4x4* lastVTKTransformMatrix=nil;
	costMapWidth=diameter/imSliceSpacing[0];
	costMapHeight=diameter/imSliceSpacing[1];
	int regionSize=costMapWidth*costMapHeight;
	float* costMap=(float*)malloc(sizeof(float)*regionSize);
	unsigned char* segmentedRegion;//=(unsigned char*)malloc(sizeof(char)*regionSize);
	unsigned char* lastSegmentedRegion=(unsigned char*)malloc(sizeof(char)*regionSize);
	float* smoothedInputImg;
	//intilize itk part

	float curscale=40;
	const double initialDistance = 2.0;
	
	typedef   float           InternalPixelType;
	const     unsigned int    Dimension = 2;
	typedef itk::Image< InternalPixelType, Dimension >  InternalImageType;
	typedef unsigned char OutputPixelType;
	typedef itk::Image< OutputPixelType, Dimension > OutputImageType;	
	typedef itk::ImportImageFilter< InternalPixelType, Dimension > ImportFilterType;
	
	ImportFilterType::Pointer importFilter;
	
	//itk::MultiThreader::SetGlobalDefaultNumberOfThreads( MPProcessors());
	
	importFilter = ImportFilterType::New();
	
	ImportFilterType::SizeType itksize;
	itksize[0] = costMapWidth; // size along X
	itksize[1] = costMapHeight; // size along Y
	ImportFilterType::IndexType start;
	start.Fill( 0 );
	ImportFilterType::RegionType region;
	region.SetIndex( start );
	region.SetSize( itksize );
	importFilter->SetRegion( region );
	double origin[ 2 ];
	origin[0] = 0;
	origin[1] = 0;
	importFilter->SetOrigin( origin );
	
	double costMapSpacing[ 2 ];
	costMapSpacing[0] = imSliceSpacing[0];
	costMapSpacing[1] = imSliceSpacing[1];
	importFilter->SetSpacing( costMapSpacing );
	
	const bool importImageFilterWillOwnTheBuffer = false;
	importFilter->SetImportPointer( costMap, itksize[0] * itksize[1], importImageFilterWillOwnTheBuffer);
	
	typedef   itk::CurvatureAnisotropicDiffusionImageFilter< 	InternalImageType, 	InternalImageType >  SmoothingFilterType;
	SmoothingFilterType::Pointer smoothing = SmoothingFilterType::New();
	smoothing->SetTimeStep( 0.125 );
	smoothing->SetNumberOfIterations(  5 );
	smoothing->SetConductanceParameter( 9.0 );
	
	
	typedef itk::BinaryThresholdImageFilter<InternalImageType, OutputImageType>
	ThresholdingFilterType;
	
	ThresholdingFilterType::Pointer thresholder = ThresholdingFilterType::New();
	
	thresholder->SetLowerThreshold( -1000.0 );
	thresholder->SetUpperThreshold(     0.0 );
	
	thresholder->SetOutsideValue(  0  );
	thresholder->SetInsideValue(  255 );
	
	typedef  itk::FastMarchingImageFilter< InternalImageType, InternalImageType >
	FastMarchingFilterType;
	
	FastMarchingFilterType::Pointer  fastMarching = FastMarchingFilterType::New();
	
	typedef  itk::ThresholdSegmentationLevelSetImageFilter< InternalImageType, 
	InternalImageType > ThresholdSegmentationLevelSetImageFilterType;
	ThresholdSegmentationLevelSetImageFilterType::Pointer thresholdSegmentation =
	ThresholdSegmentationLevelSetImageFilterType::New();
	thresholdSegmentation->SetPropagationScaling( 1.0 );
	thresholdSegmentation->SetCurvatureScaling( curscale );
	thresholdSegmentation->SetMaximumRMSError( 0.02 );
	thresholdSegmentation->SetNumberOfIterations( 400 );
	
	smoothing->SetInput( importFilter->GetOutput() );
	
	thresholdSegmentation->SetUpperThreshold( 1000000 );
	thresholdSegmentation->SetLowerThreshold(threshold );
	thresholdSegmentation->SetIsoSurfaceValue(0.0);
	thresholdSegmentation->SetInput( fastMarching->GetOutput() );
	thresholdSegmentation->SetFeatureImage( smoothing->GetOutput() );

	thresholder->SetInput( thresholdSegmentation->GetOutput() );
	
	typedef FastMarchingFilterType::NodeContainer           NodeContainer;
	typedef FastMarchingFilterType::NodeType                NodeType;
	
	NodeContainer::Pointer seeds = NodeContainer::New();
	
	InternalImageType::IndexType  seedPosition;
	
	
	
	
	NodeType node;
	
	const double seedValue = - initialDistance;
	seeds->Initialize();

	
	seedPosition[0] = costMapWidth/2;//start from center
	seedPosition[1] = costMapWidth/2;//start from center	
	
	node.SetValue( seedValue );
	node.SetIndex( seedPosition );

	seeds->InsertElement( 0, node );

	fastMarching->SetTrialPoints(  seeds  );
	
	fastMarching->SetSpeedConstant( 1.0 );
	fastMarching->SetOutputSize( itksize);

	//start growing
	int reachAEndCondition=0;
	NSMutableArray* newCenterline=[NSMutableArray arrayWithCapacity:0];
	int costMapOrigin[2];
	do {
		//get cross-section image
		tempIm = imageSlice->GetOutput();
		tempIm->Update();
		tempIm->GetWholeExtent( imSliceExtent);
		tempIm->GetSpacing( imSliceSpacing);
		tempIm->GetOrigin( imSliceOrigin);
		float *im = (float*) tempIm->GetScalarPointer();
		//prepare cost map

		int x,y,width,height;
		width=imSliceExtent[ 1]-imSliceExtent[ 0]+1;
		height=imSliceExtent[ 3]-imSliceExtent[ 2]+1;
		costMapOrigin[0]=(int)((-diameter/2-imSliceOrigin[0])/imSliceSpacing[0]);
		costMapOrigin[1]=(int)((-diameter/2-imSliceOrigin[1])/imSliceSpacing[1]);
		for(y=0;y<costMapHeight;y++)
			for(x=0;x<costMapWidth;x++)
			{
				if(costMapOrigin[0]+x>=0 && costMapOrigin[0]+x<width && costMapOrigin[1]+y>=0 && costMapOrigin[1]+y<height)
					*(costMap+y*costMapWidth+x)
					=*(im+(y+costMapOrigin[1])*width+x+costMapOrigin[0]);
				else
					*(costMap+y*costMapWidth+x)=minValueInSeries;
			}
		

		
		
		//get threshold levelset segmentation
	
		try
		{
			importFilter->Modified();
			smoothing->SetInput( importFilter->GetOutput() );//should try without this line
			thresholder->Update();
		}
		catch( itk::ExceptionObject & excep )
		{
			NSLog(@"ITK region growing failed!");
			return 1;
		}
		
		
		segmentedRegion=thresholder->GetOutput()->GetBufferPointer();	
		smoothedInputImg=smoothing->GetOutput()->GetBufferPointer();
		//compare with last step cross-section, overlap percentage and radius
	//	if (step>2) {
//			if([self compareOverlappedRegion:segmentedRegion:lastSegmentedRegion:regionSize]<0.7)
//			{
//				reachAEndCondition=1;
//				break;
//			}
//		}
		
		//compare largest incircle center and gravity center (aortic valve have irregular segment results
		int incirclecenter[2],gravitycenter[2];
		float newCenter3D[3];
		float incircleradius;
		incircleradius=[self findingIncirleCenterOfRegion:segmentedRegion:costMapWidth:costMapHeight:incirclecenter];
		[self findingGravityCenterOfRegion:segmentedRegion:costMapWidth:costMapHeight:gravitycenter];
		
		if(incircleradius<=0)
		{
			NSLog(@"fail to location the center of the cross section");
			reachAEndCondition=2;
			break;
		}
		else
		{
			float centerdis=sqrt((incirclecenter[0]-gravitycenter[0])*(incirclecenter[0]-gravitycenter[0])+(incirclecenter[1]-gravitycenter[1])*(incirclecenter[1]-gravitycenter[1]));
			if(centerdis>incircleradius/2)
			{
				NSLog(@"irregular cross section found");
				reachAEndCondition=4;
				break;
			}
			if([self detectAorticValve:smoothedInputImg:segmentedRegion:costMapWidth:costMapHeight:incirclecenter:incircleradius:imSliceSpacing])
			{
				NSLog(@"found Aortic Valve");
				reachAEndCondition=5;
				break;
			}	
			
		}
		newCenter3D[0]=imSliceOrigin[0]+(incirclecenter[0]+costMapOrigin[0]) *imSliceSpacing[0];
		newCenter3D[1]=imSliceOrigin[1]+(incirclecenter[1]+costMapOrigin[1]) *imSliceSpacing[1];
		newCenter3D[2]=0;
		//plant seeds at this step
		if(incircleradius>0)
		{
			float curXSpacing,curYSpacing;
			float curOriginX,curOriginY;
			short unsigned int marker;
			marker=AORTAMARKER;
			curXSpacing=imSliceSpacing[0];
			curYSpacing=imSliceSpacing[1];

			curOriginX = (costMapOrigin[0]+incirclecenter[0]-incircleradius)*curXSpacing+imSliceOrigin[0];		
			curOriginY = (costMapOrigin[1]+incirclecenter[1]-incircleradius)*curYSpacing+imSliceOrigin[1];
			
			int i,j,seedheight,seedwidth;
			int x,y,z;
			float point[3];
			
			seedheight=3*incircleradius*2;
			seedwidth=3*incircleradius*2;
			float x0,y0,a,b;
			a=curXSpacing*incircleradius;
			b=curYSpacing*incircleradius;	
			x0= curOriginX+a;
			y0= curOriginY+b;
			a=a*a;
			b=b*b;
			
			//step=0.3 pixel!	
			for(j=0;j<seedheight;j++)
				for(i=0;i<seedwidth;i++)
				{
					point[0] = curOriginX + i * curXSpacing/3;
					point[1] = curOriginY + j * curYSpacing/3;
					point[2] = 0;
					if((point[0]-x0)*(point[0]-x0)*b+(point[1]-y0)*(point[1]-y0)*a<=a*b) //x^2/a+y^2/b<1
					{
						rotationTransform->TransformPoint(point,point);
						x=lround((point[0])/spacing[0]);
						y=lround((point[1])/spacing[1]);
						z=lround((point[2])/spacing[2]);
						if(x>=0 && x<dim[0] && y>=0 && y<dim[1] && z>=0 && z<dim[2])
						{
							*(seedData+ z*dim[1]*dim[0] + y*dim[0] + x) = AORTAMARKER;
							
							
						}
					}
					
				}				
			
		}
		//move reslice plane further on the centerline direction (correct every 10mm)
		lastVTKTransformMatrix=rotationTransform->GetMatrix();
		{
			step++;
			float oX,oY,oZ;
			oX=newCenter3D[0];
			oY=newCenter3D[1];
			oZ=-steplength;
			//NSLog(@"debug log check if need go further");
			if(step>2 && sqrt(oX*oX+oY*oY)>incircleradius*imSliceSpacing[0]/2)
			{
				NSLog(@"center shift too much");
				reachAEndCondition=3;
				break;
			}
			
			
			rotationTransform->TransformPoint(newCenter3D,newCenter3D);
			CMIV3DPoint* new3DPoint=[[CMIV3DPoint alloc] init] ;
			[new3DPoint setX: newCenter3D[0]];
			[new3DPoint setY: newCenter3D[1]];
			[new3DPoint setZ: newCenter3D[2]];
			[newCenterline insertObject:new3DPoint atIndex:0 ];
			[new3DPoint release];
			
			if(step%pnums!=0)
			{
					rotationTransform->Translate(oX,oY,oZ);
			}
			else
			{
				//NSLog(@"debug log correct z direction");
		
				double position[3],direction[3];
				//rotationTransform->TransformPoint(origin,position);	
	
				
				int ii;
				double zxdata[pnums*2],zydata[pnums*2];
				CMIV3DPoint* a3DPoint;
				double x1=0,y1=0,z1=0,x2=0,y2=0,z2=0,kx=0,bx=0,ky=0,by=0;
				for(ii=0;ii<pnums;ii++)
				{
					a3DPoint=[newCenterline objectAtIndex:ii];
					zxdata[2*ii]=[a3DPoint z];
					zxdata[2*ii+1]=[a3DPoint x];
					zydata[2*ii]=[a3DPoint z];
					zydata[2*ii+1]=[a3DPoint y];
					if(ii==0)
						z1=[a3DPoint z];
					z2=[a3DPoint z];
					
				}
				[self LinearRegression:zxdata :pnums:&bx:&kx];
				[self LinearRegression:zydata :pnums:&by:&ky];
				x1=kx*z1+bx;
				x2=kx*z2+bx;
				y1=ky*z1+by;
				y2=ky*z2+by;
				a3DPoint=[newCenterline objectAtIndex:0];
				position[0]=[a3DPoint x];
				position[1]=[a3DPoint y];
				position[2]=[a3DPoint z];
				
				direction[0]=x1-x2;
				direction[1]=y1-y2;
				direction[2]=z1-z2;
				
				translateTransform->Identity();
				rotationTransform->Identity();
				translateTransform->Translate(position);
				float anglex=0,angley=0;
				if(direction[2]==0)
				{
					if(direction[1]>0)
						anglex=90;
					if(direction[1]<0)
						anglex=-90;
					if(direction[1]==0)
						anglex=0;
				}
				else
				{
					anglex = atan(direction[1]/direction[2]) / deg2rad;
					if(direction[2]<0)
						anglex+=180;
				}
				
				
				angley = asin(direction[0]/sqrt(direction[0]*direction[0]+direction[1]*direction[1]+direction[2]*direction[2])) / deg2rad;
				rotationTransform->RotateX(-anglex);	
				rotationTransform->RotateY(angley);
				rotationTransform->RotateX(180);
				if(postedIndicatorNotification<3)
				{
					[[NSNotificationCenter defaultCenter] postNotificationName: @"CMIVLeveIndicatorStep" object:self userInfo: nil];
					postedIndicatorNotification++;
				}
				
			}
		}
		
		//prepare for go further
		memcpy(lastSegmentedRegion,segmentedRegion,regionSize);
		NSLog(@"try next step");
		
	} while (!reachAEndCondition);
	int iii;
	for(iii=postedIndicatorNotification;iii<3;iii++)
		[[NSNotificationCenter defaultCenter] postNotificationName: @"CMIVLeveIndicatorStep" object:self userInfo: nil];
	//plant seed for ventricle and put barrier in between	
	{
		if(reachAEndCondition<=3)
		{
			translateTransform->Identity();
			rotationTransform->Identity();
			translateTransform->SetMatrix(lastVTKTransformMatrix);
			tempIm = imageSlice->GetOutput();
			tempIm->Update();
			tempIm->GetWholeExtent( imSliceExtent);
			tempIm->GetSpacing( imSliceSpacing);
			tempIm->GetOrigin( imSliceOrigin);
			segmentedRegion=lastSegmentedRegion;
			costMapOrigin[0]=(int)((-diameter/2-imSliceOrigin[0])/imSliceSpacing[0]);
			costMapOrigin[1]=(int)((-diameter/2-imSliceOrigin[1])/imSliceSpacing[1]);

		}
		int gravitycenter[2];
		[self findingGravityCenterOfRegion:segmentedRegion:costMapWidth:costMapHeight:gravitycenter];
		float maxradius = [self findingMaxDistanceToGravityCenterOfRegion:segmentedRegion:costMapWidth:costMapHeight:gravitycenter];
		if(maxradius>0)
		{
			// clean aorta seeds cross barrier
			
			float maxSpacing=sqrt(spacing[0]*spacing[0]+spacing[1]*spacing[1]+spacing[2]*spacing[2]);
			
			int xx,yy,zz;	
			float point[3];
		
			for(zz=0;zz<dim[2];zz++)
				for(yy=0;yy<dim[1];yy++)
					for(xx=0;xx<dim[0];xx++)
						if(*(seedData+zz*imageSize+yy*imageWidth+xx))
						{
							point[0]=xx*spacing[0];
							point[1]=yy*spacing[1];
							point[2]=zz*spacing[2];
							inverseTransform->TransformPoint(point,point);
							if(point[2]<maxSpacing)
								*(seedData+zz*imageSize+yy*imageWidth+xx)=0;
							
						}
			//now plant the seeds
			maxradius+=1/imSliceSpacing[0];
			int i,j,height,width;
			int x,y,z;
			//for test
//			height=costMapHeight;
//			width=costMapWidth;
//	
//			for(j=0;j<height;j++)
//				for(i=0;i<width;i++)
//				{			
//					if(*(lastSegmentedRegion+costMapWidth*j+i))
//					{
//						
//						point[0] = imSliceOrigin[0] + costMapOrigin[0]* imSliceSpacing[0]+i * imSliceSpacing[0];
//						point[1] = imSliceOrigin[1] + costMapOrigin[1]* imSliceSpacing[0]+j * imSliceSpacing[1];
//						point[2] = 0;
//						rotationTransform->TransformPoint(point,point);
//						x=lround((point[0])/spacing[0]);
//						y=lround((point[1])/spacing[1]);
//						z=lround((point[2])/spacing[2]);
//						if(x>=0 && x<dim[0] && y>=0 && y<dim[1] && z>=0 && z<dim[2])
//						{
//							*(volumeData+z*imageSize+y*imageWidth+x) = -2000;
//							
//						}
//						
//					}
//				}

			int minx,maxx,miny,maxy,minz,maxz;
			minx=dim[0];
			maxx=0;
			miny=dim[1];
			maxy=0;
			minz=dim[2];
			maxz=0;
			height=3*costMapHeight;
			width=3*costMapWidth;
			//step=0.3 pixel!	
			for(j=0;j<height;j++)
				for(i=0;i<width;i++)
				{
				
					if((i/3.0-gravitycenter[0])*(i/3.0-gravitycenter[0])+(j/3.0-gravitycenter[1])*(j/3.0-gravitycenter[1])<=maxradius*maxradius)
					{
						point[0] = imSliceOrigin[0] + costMapOrigin[0]* imSliceSpacing[0]+i * imSliceSpacing[0]/3.0;
						point[1] = imSliceOrigin[1] + costMapOrigin[1]* imSliceSpacing[0]+j * imSliceSpacing[1]/3.0;
						point[2] = 0;
						rotationTransform->TransformPoint(point,point);
						x=lround((point[0])/spacing[0]);
						y=lround((point[1])/spacing[1]);
						z=lround((point[2])/spacing[2]);
						if(x>=0 && x<dim[0] && y>=0 && y<dim[1] && z>=0 && z<dim[2])
						{
							*(seedData+z*imageSize+y*imageWidth+x) = BARRIERMARKER;
							if(minx>x)
								minx=x;
							if(maxx<x)
								maxx=x;
							if(miny>y)
								miny=y;
							if(maxy<y)
								maxy=y;
							if(minz>z)
								minz=z;
							if(maxz<z)
								maxz=z;
							
						}
					}

				}
					
			[self fixHolesInBarrierInVolume:seedData: minx :maxx :miny :maxy :minz :maxz :BARRIERMARKER];
			maxradius/=2;
			for(j=0;j<height;j++)
				for(i=0;i<width;i++)
				{
					
					if((i/3.0-gravitycenter[0])*(i/3.0-gravitycenter[0])+(j/3.0-gravitycenter[1])*(j/3.0-gravitycenter[1])<=maxradius*maxradius)
					{
						point[0] = imSliceOrigin[0] + costMapOrigin[0]* imSliceSpacing[0]+i * imSliceSpacing[0]/3.0;
						point[1] = imSliceOrigin[1] + costMapOrigin[1]* imSliceSpacing[0]+j * imSliceSpacing[1]/3.0;
						point[2] = -maxSpacing;
						rotationTransform->TransformPoint(point,point);
						x=lround((point[0])/spacing[0]);
						y=lround((point[1])/spacing[1]);
						z=lround((point[2])/spacing[2]);
						if(x>=0 && x<dim[0] && y>=0 && y<dim[1] && z>=0 && z<dim[2])
						{
							*(seedData+z*imageSize+y*imageWidth+x) = OTHERMARKER;
							
						}
					}
				}
			
			
		}
		
		

	}

	
	
	imageSlice->Delete();
	rotationTransform->Delete();
	reader->Delete();
	
	free(costMap);
	//free(binaryRegionMap);
	free(lastSegmentedRegion);
	return 0;
}

-(float)compareOverlappedRegion:(unsigned char*)firstRegion:(unsigned char*)secondRegion:(int)regionSize
{
	int i;
	int matchCount=0;
	for(i=0;i<regionSize;i++)
		if(firstRegion[i]==secondRegion[i])
			matchCount++;
	return (float)matchCount/(float)regionSize;
}
-(float)findingIncirleCenterOfRegion:(unsigned char*)buffer:(int)width:(int)height:(int*)center
{
	int buffersize=	width*height;
	int i;
	for(i=0;i<buffersize;i++)
		buffer[i]=!buffer[i];
	
	typedef  unsigned char   InputPixelType;
	typedef  float  OutputPixelType;
	const     unsigned int    Dimension = 2;
	typedef itk::Image< InputPixelType,  2 >   InputImageType;
	typedef itk::Image< OutputPixelType, 2 >   OutputImageType;
	
	typedef itk::ImportImageFilter< InputPixelType, Dimension > ImportFilterType;
	
	ImportFilterType::Pointer importFilter;
	
	//itk::MultiThreader::SetGlobalDefaultNumberOfThreads( MPProcessors());
	
	importFilter = ImportFilterType::New();
	
	ImportFilterType::SizeType itksize;
	itksize[0] = width; // size along X
	itksize[1] = height; // size along Y
	ImportFilterType::IndexType start;
	start.Fill( 0 );
	ImportFilterType::RegionType region;
	region.SetIndex( start );
	region.SetSize( itksize );
	importFilter->SetRegion( region );
	double origin[ 2 ];
	origin[0] = 0;
	origin[1] = 0;
	importFilter->SetOrigin( origin );
	
	double spacing[ 2 ];
	spacing[0] = 1.0;
	spacing[1] = 1.0;
	importFilter->SetSpacing( spacing );
	
	const bool importImageFilterWillOwnTheBuffer = false;
	importFilter->SetImportPointer( buffer, itksize[0] * itksize[1], importImageFilterWillOwnTheBuffer);
	
	
	
	
	typedef itk::DanielssonDistanceMapImageFilter<	InputImageType, OutputImageType >  FilterType;
	FilterType::Pointer filter = FilterType::New();
	
	filter->SetInput( importFilter->GetOutput() );
	filter->InputIsBinaryOn();
	
	try
    {
		filter->Update();
    }
	catch( itk::ExceptionObject & excep )
    {
		NSLog(@"ITK distance map failed!");
		return -1;
    }
	float* fsegresult=filter->GetOutput()->GetBufferPointer();	
	int maxindex=0;
	float maxdis=*fsegresult;
	for(i=0;i<buffersize;i++)
		if(*(fsegresult+i)>maxdis)
		{
			maxindex=i;
			maxdis=*(fsegresult+i);
		}
	
	for(i=0;i<buffersize;i++)
		buffer[i]=!buffer[i];
	center[1]=maxindex/width;
	center[0]=maxindex-center[1]*width;
	
	
	return maxdis;
}
-(void)findingGravityCenterOfRegion:(unsigned char*)buffer:(int)width:(int)height:(int*)center
{
	int i,j;
	float totalx=0,totaly=0,totalpoint=0;
	for(j=0;j<height;j++)
		for(i=0;i<width;i++)
		{
			if(*(buffer+j*width+i))
			{
				totalx+=i;
				totaly+=j;
				totalpoint++;
			}
		}
	if(totalpoint)
	{
		center[0]=totalx/totalpoint;
		center[1]=totaly/totalpoint;
	}
	else
	{
		center[0]=0;
		center[1]=0;
	}
	return;
}
-(float)findingMaxDistanceToGravityCenterOfRegion:(unsigned char*)buffer:(int)width:(int)height:(int*)center
{
	int i,j;
	float furthestLength=0,lentocenter;
	for(j=0;j<height;j++)
		for(i=0;i<width;i++)
		{
			if(*(buffer+j*width+i))
			{
				lentocenter=sqrt((i-center[0])*(i-center[0])+(j-center[1])*(j-center[1]));
				if(lentocenter>furthestLength)
					furthestLength=lentocenter;
			}
		}
	return furthestLength;
	
}
-(int) LinearRegression:(double*)data :(int)rows:(double*)a:(double*)b
{
	int m;
	double *p,Lxx=0,Lxy=0,xa=0,ya=0;
	if(data==0||a==0||b==0||rows<1)
		return -1;
	for(p=data,m=0;m<rows;m++)
	{
		xa+=*p++;
		ya+=*p++;
	}
	xa/=rows;
	ya/=rows;
	for(p=data,m=0;m<rows;m++,p+=2)
	{
		Lxx+=((*p-xa)*(*p-xa));
		Lxy+=((*p-xa)*(*(p+1)-ya));
	}
	*b=Lxy/Lxx;
	*a=ya-*b*xa;
	return 0;
}
-(BOOL) detectAorticValve:(float*)inputimg:(unsigned char*)segmenresult:(int)width:(int)height:(int*)center:(float)radius:(double*)spacing
{
	int i,j;
	double totalsum=0,centersum=0;
	long totalpix=0,centerpix=0;
	radius=radius*radius;
	int lowestcenter[2];
	lowestcenter[0]=center[0];
	lowestcenter[1]=center[1];
	float lowestintensity=*(inputimg+center[1]*width+center[0]);
	float ftemp;
	
	for(j=0;j<height;j++)
		for(i=0;i<width;i++)
		{
			if((i-center[0])*(i-center[0])+(j-center[1])*(j-center[1])<radius)
			{
				ftemp=*(inputimg+j*width+i);
				totalsum+=ftemp;
				totalpix++;	   
				if((i-center[0])*(i-center[0])+(j-center[1])*(j-center[1])<(radius/4) && ftemp<lowestintensity)
				{
					lowestintensity=ftemp;
					lowestcenter[0]=i;
					lowestcenter[1]=j;
				}
			}
		}
	int centerradius=2/spacing[0];
	int centerxstar=lowestcenter[0]-centerradius;
	int centerxend=lowestcenter[0]+centerradius;
	int centerystar=lowestcenter[1]-centerradius;
	int centeryend=lowestcenter[1]+centerradius;
	if(centerxstar<0)
		centerxstar=0;
	if(centerystar<0)
		centerystar=0;
	if(centerxend>=width)
		centerxend=width-1;
	if(centeryend>=height)
		centeryend=height-1;
	centerradius=centerradius*centerradius;
	
	for(j=centerystar;j<centeryend;j++)
		for(i=centerxstar;i<centerxend;i++)
		{
			if((i-lowestcenter[0])*(i-lowestcenter[0])+(j-lowestcenter[1])*(j-lowestcenter[1])<centerradius)
			{
				ftemp=*(inputimg+j*width+i);
				centersum+=ftemp;
				centerpix++;	   
				
			}
		}
	if(totalsum/totalpix-centersum/centerpix>100)
		return YES;
	return NO;
}
- (void) fixHolesInBarrierInVolume:(unsigned short*)contrastVolumeData :(int)minx :(int)maxx :(int)miny :(int)maxy :(int)minz :(int)maxz :(short unsigned int) marker
{
	int x,y,z;
	if(minx<maxx&&miny<maxy&&minz<maxz)
	{
		for(z=minz;z<=maxz;z++)
			for(y=miny;y<=maxy;y++)
				for(x=minx;x<=maxx;x++)
					if(*(contrastVolumeData+z*imageSize+y*imageWidth+x) == marker)
					{
						//x,y direction
						if((y+1)<=maxy&& (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x) != marker))
						{
							if((x-1)>=minx && (*(contrastVolumeData+z*imageSize+y*imageWidth+x-1) != marker)  && (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x-1) == marker))
								*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x) = marker;
							
							
							else if( (x+1)<=maxx && (*(contrastVolumeData+z*imageSize+y*imageWidth+x+1) != marker)  && (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x+1) == marker))
								*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x) = marker;
						}
						
						//x,z direction
						if((z+1)<=maxz&& (*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) != marker))
						{
							if((x-1)>=minx && (*(contrastVolumeData+z*imageSize+y*imageWidth+x-1) != marker)  && (*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x-1) == marker))
								*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) = marker;
							
							
							else if( (x+1)<=maxx && (*(contrastVolumeData+z*imageSize+y*imageWidth+x+1) != marker)  && (*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x+1) == marker))
								*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) = marker;
						}		
						
						//y,z direction
						if((z+1)<=maxz&& (*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) != marker))
						{
							if((y-1)>=miny && (*(contrastVolumeData+z*imageSize+(y-1)*imageWidth+x) != marker)  && (*(contrastVolumeData+(z+1)*imageSize+(y-1)*imageWidth+x) == marker))
								*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) = marker;
							
							
							else if( (y+1)<=maxy && (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x) != marker)  && (*(contrastVolumeData+(z+1)*imageSize+(y+1)*imageWidth+x) == marker))
								*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) = marker;
						}	
						//x,y,z direction
						if((z+1)<=maxz&& (*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) != marker))
						{
							if((y-1)>=miny && (x-1)>minx && (*(contrastVolumeData+z*imageSize+(y-1)*imageWidth+x) != marker) && (*(contrastVolumeData+z*imageSize+y*imageWidth+x-1) != marker)  && (*(contrastVolumeData+(z+1)*imageSize+(y-1)*imageWidth+x-1) == marker))
								*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) = marker;
							
							
							else if( (y+1)<=maxy && (x-1)>minx && (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x) != marker) && (*(contrastVolumeData+z*imageSize+y*imageWidth+x-1) != marker) && (*(contrastVolumeData+(z+1)*imageSize+(y+1)*imageWidth+x-1) == marker))
								*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) = marker;
							else if((y-1)>=miny && (x+1)<maxx && (*(contrastVolumeData+z*imageSize+(y-1)*imageWidth+x) != marker) && (*(contrastVolumeData+z*imageSize+y*imageWidth+x+1) != marker)  && (*(contrastVolumeData+(z+1)*imageSize+(y-1)*imageWidth+x+1) == marker))
								*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) = marker;
							
							
							else if( (y+1)<=maxy && (x+1)<maxx && (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x) != marker) && (*(contrastVolumeData+z*imageSize+y*imageWidth+x+1) != marker) && (*(contrastVolumeData+(z+1)*imageSize+(y+1)*imageWidth+x+1) == marker))
								*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) = marker;
							
						}	
						//leak from vertex connection
						if((z-1)>=minz&& (*(contrastVolumeData+(z-1)*imageSize+y*imageWidth+x) != marker))
						{
							if((x-1)>=minx && (y-1)>=miny &&  (*(contrastVolumeData+z*imageSize+y*imageWidth+x-1) == marker) && (*(contrastVolumeData+z*imageSize+(y-1)*imageWidth+x) == marker) && (*(contrastVolumeData+z*imageSize+(y-1)*imageWidth+x-1) != marker) && (*(contrastVolumeData+(z-1)*imageSize+(y-1)*imageWidth+x-1) == marker) && (*(contrastVolumeData+(z-1)*imageSize+y*imageWidth+x-1) == marker) && (*(contrastVolumeData+(z-1)*imageSize+(y-1)*imageWidth+x) == marker))
								*(contrastVolumeData+(z-1)*imageSize+y*imageWidth+x) = marker;
							else if((x+1)<=maxx && (y-1)>=miny &&  (*(contrastVolumeData+z*imageSize+y*imageWidth+x+1) == marker) && (*(contrastVolumeData+z*imageSize+(y-1)*imageWidth+x) == marker) && (*(contrastVolumeData+z*imageSize+(y-1)*imageWidth+x+1) != marker) && (*(contrastVolumeData+(z-1)*imageSize+(y-1)*imageWidth+x+1) == marker) && (*(contrastVolumeData+(z-1)*imageSize+y*imageWidth+x+1) == marker) && (*(contrastVolumeData+(z-1)*imageSize+(y-1)*imageWidth+x) == marker))
								*(contrastVolumeData+(z-1)*imageSize+y*imageWidth+x) = marker;
							else if((x-1)>=minx && (y+1)<=maxy &&  (*(contrastVolumeData+z*imageSize+y*imageWidth+x-1) == marker) && (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x) == marker) && (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x-1) != marker) && (*(contrastVolumeData+(z-1)*imageSize+(y+1)*imageWidth+x-1) == marker) && (*(contrastVolumeData+(z-1)*imageSize+y*imageWidth+x-1) == marker) && (*(contrastVolumeData+(z-1)*imageSize+(y+1)*imageWidth+x) == marker))
								*(contrastVolumeData+(z-1)*imageSize+y*imageWidth+x) = marker;
							else if((x+1)<=maxx && (y+1)<=maxy &&  (*(contrastVolumeData+z*imageSize+y*imageWidth+x+1) == marker) && (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x) == marker) && (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x+1) != marker) && (*(contrastVolumeData+(z-1)*imageSize+(y+1)*imageWidth+x+1) == marker) && (*(contrastVolumeData+(z-1)*imageSize+y*imageWidth+x+1) == marker) && (*(contrastVolumeData+(z-1)*imageSize+(y+1)*imageWidth+x) == marker))
								*(contrastVolumeData+(z-1)*imageSize+y*imageWidth+x) = marker;
							
							
						}	
						
						
					}
	}
}

#pragma mark-
#pragma mark 5 smoothing Filter
- (int) smoothingFilter:(float *)inData:(float*)outData:(long*)dimension:(float*)imgspacing:(int)iteration
{
	
	imageWidth=dimension[0];
	imageHeight=dimension[1];
	imageAmount=dimension[2];
	
	long size = sizeof(float) * imageWidth * imageHeight * imageAmount;
	
	
	const     unsigned int        Dimension       = 3;
	typedef   float               InputPixelType;
	typedef   float               OutputPixelType;
	
	typedef   itk::Image< InputPixelType, Dimension >   InputImageType;
	typedef   itk::Image< OutputPixelType, Dimension >  OutputImageType;
	
	typedef itk::ImportImageFilter< InputPixelType, Dimension > ImportFilterType;
	
	ImportFilterType::Pointer importFilter;
	
	itk::MultiThreader::SetGlobalDefaultNumberOfThreads( MPProcessors());
	
	importFilter = ImportFilterType::New();
	
	ImportFilterType::SizeType itksize;
	itksize[0] = imageWidth; // size along X
	itksize[1] = imageHeight; // size along Y
	itksize[2] = imageAmount;// size along Z
	
	ImportFilterType::IndexType start;
	start.Fill( 0 );
	
	ImportFilterType::RegionType region;
	region.SetIndex( start );
	region.SetSize( itksize );
	importFilter->SetRegion( region );
	
	double origin[ 3 ];
	origin[0] = 0; // X coordinate
	origin[1] = 0; // Y coordinate
	origin[2] = 0; // Z coordinate
	importFilter->SetOrigin( origin );
	
	double spacing[ 3 ];
	spacing[0] = imgspacing[0]; // along X direction
	spacing[1] = imgspacing[1]; // along Y direction
	spacing[2] = imgspacing[2]; // along Z direction
	importFilter->SetSpacing( spacing ); 
	
	const bool importImageFilterWillOwnTheBuffer = false;
	importFilter->SetImportPointer( inData, itksize[0] * itksize[1] * itksize[2], importImageFilterWillOwnTheBuffer);
	NSLog(@"ITK Image allocated");
	

	typedef   itk::CurvatureAnisotropicDiffusionImageFilter< 	InputImageType, 	InputImageType >  SmoothingFilterType;
	SmoothingFilterType::Pointer smoothing = SmoothingFilterType::New();
	smoothing->SetTimeStep( 0.0625 );
	smoothing->SetNumberOfIterations(  iteration );
	smoothing->SetConductanceParameter( 3.0 );
	smoothing->SetInput( importFilter->GetOutput() );
	smoothing->Update();
	void* smoothedInputImg=smoothing->GetOutput()->GetBufferPointer();
	memcpy(outData, smoothedInputImg, sizeof(float) * imageWidth * imageHeight * imageAmount);
	return 0;
	
	
}

@end
