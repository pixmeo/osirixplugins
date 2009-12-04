/*=========================================================================
Author: Chunliang Wang (chunliang.wang@imv.liu.se)


Program:  CMIV CTA image processing Plugin for OsiriX

This file is part of CMIV CTA image processing Plugin for OsiriX.

Copyright (c) 2007,
Center for Medical Image Science and Visualization (CMIV),
Linkšping University, Sweden, http://www.cmiv.liu.se/

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

#import "CMIVSegmentCore.h"
#import "CMIV3DPoint.h"
#define id Id
#include "itkMultiThreader.h"
#include "itkImage.h"
#include "itkImportImageFilter.h"
#include "itkHessianRecursiveGaussianImageFilter.h"
#include "itkHessian3DToVesselnessMeasureImageFilter.h"

#undef id


@implementation CMIVSegmentCore
- (void) setImageWidth:(long) width Height:(long) height Amount: (long) amount Spacing:(float*)spacing
{

	imageWidth=width;
	imageHeight=height;
	imageAmount=amount;
	imageSize=width*height;
	xSpacing=spacing[0],ySpacing=spacing[1],zSpacing=spacing[2];
  
  return;
  
}  

- (void) startShortestPathSearchAsFloat:(float *) pIn Out:(float *) pOut :(unsigned char*) pMarker Direction: (unsigned char*) pPointers
{

	long i,j,k;
	int changed;
	float maxvalue;
	unsigned char maxcolorindex;

	
	long itemp;
	long ilong,iwidth,iheight;
	long position_i1,position_i2,position_j1,position_j2,position_j3;
	
	
	ilong=imageWidth;
	iwidth=imageHeight;
	iheight=imageAmount;
	

	inputData=pIn;
	outputData=pOut;
	directionOfData=pPointers;
	
	unsigned char* marker=pMarker;
	long long* longmarker=(long long*)marker;

	if(!marker)
		return;

	
	[self runFirstRoundFasterWith26Neigbhorhood];
	memset(marker,0xff,imageSize*imageAmount/8+1);
		
	do
	{
		changed=0;
		
//**********************positive direction*****************************
		for(i=1;i<iheight-1;i++)
		{
			position_i1 = (i-1)*imageSize;
			position_i2 = i*imageSize;
			
			for(j=1;j<iwidth-1;j++)
			{
				position_j1 = (j-1)*ilong;
				position_j2 = j*ilong;
				position_j3 = (j+1)*ilong;
				
				for(k=1;k<ilong-1;k++)
				{
					itemp= position_i2+position_j2+k;
					if(!(*(longmarker+(itemp>>6))))
					{
						itemp=itemp>>6;
						do
						{
							itemp++;
						}while(!(*(longmarker+itemp)));
						itemp=itemp<<6;
						k=itemp-position_i2-position_j2;
						
						if(k>=ilong-1)
							continue;
						
					}

					if(!(*(marker+(itemp>>3))))
					{
						itemp=itemp>>3;
						do
						{
							itemp++;
						}while(!(*(marker+itemp)));
						itemp=itemp<<3;
						k=itemp-position_i2-position_j2;
						
						if(k>=ilong-1)
							continue;
	
					}
						
					if((*(marker+(itemp>>3)))&(0x01<<(itemp&0x07)))//if this point need to be check again
					{
						if(*(directionOfData + itemp)&0xc0)//if this is a seed point or saturated point
							*(marker+(itemp>>3))=*(marker+(itemp>>3))&(~(0x01<<(itemp&0x07)));
						else
						{
		//1
							itemp=position_i1+position_j1+k-1;
							maxvalue=*(outputData+itemp);
							maxcolorindex=1;
		//2
							itemp++;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=2;
							}
		//3
							itemp++;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=3;
							}
		//4
							itemp=position_i1+position_j2+k-1;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=4;
							}
		//5
							itemp++;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=5;
							}

		//6
							itemp++;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=6;
							}
		//7					
							itemp=position_i1+position_j3+k-1;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=7;
							}
		//8	
							itemp++;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=8;
							}

		//9					
							itemp++;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=9;
							}
		//10	
							itemp=position_i2+position_j1+k-1;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=10;
							}
		//11
							itemp++;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=11;
							}
		//12
							itemp++;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=12;
							}
		//13
							itemp=position_i2+position_j2+k-1;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=13;
							}
		//update g
	
							itemp=position_i2+position_j2+k;
							if(maxvalue>*(outputData+itemp))
							{
								if(*(inputData+itemp)>*(outputData+itemp))
								{
									//*(outputData+itemp)=min(maxvalue,*(inputData+itemp));
									if(maxvalue>*(inputData+itemp))
									{
										*(outputData+itemp)=*(inputData+itemp);
										*(directionOfData+itemp)=maxcolorindex|0x40;
									}
									else 
									{
										*(outputData+itemp)=maxvalue;
										*(directionOfData+itemp)=maxcolorindex;
									}
									
									int ii,jj,kk;
									itemp=position_i1+position_j1+k-1;
									for(ii=0;ii<3;ii++)
									{
										for(jj=0;jj<3;jj++)
										{
											for(kk=0;kk<3;kk++)
											{
												
												*(marker+(itemp>>3))|=(0x01<<(itemp&0x07));
												itemp++;
											}
											itemp=itemp-3+ilong;
											
										}
										itemp=itemp-ilong-ilong-ilong+imageSize;
									}
									
									changed++;				
								}
							
								else
									*(marker+(itemp>>3))&=(~(0x01<<(itemp&0x07)));
									
							}
							else 
								*(marker+(itemp>>3))&=(~(0x01<<(itemp&0x07)));

						}
					}
				}
			}
		}
				
//*******************************negitive direction*************************
		for(i=iheight-2;i>0;i--)
		{
			position_i1 = (i+1)*imageSize;
			position_i2 = i*imageSize;
			
			for(j=iwidth-2;j>0;j--)
			{
				position_j1 = (j-1)*ilong;
				position_j2 = j*ilong;
				position_j3 = (j+1)*ilong;
				
				for(k=ilong-2;k>0;k--)
				{	
					itemp= position_i2+position_j2+k;
					
					
					if(!(*(longmarker+(itemp>>6))))
					{
						itemp=itemp>>6;
						do
						{
							itemp--;
						}while(!(*(longmarker+itemp)));
						
						itemp=(itemp<<6)+63;
						k=itemp-position_i2-position_j2;
						
						if(k<1)
							continue;
						
					}
					
					if(!(*(marker+(itemp>>3))))
					{
						itemp=itemp>>3;
						do
						{
							itemp--;
						}while(!(*(marker+itemp)));
						itemp=(itemp<<3)+7;
						k=itemp-position_i2-position_j2;
						
						if(k<1)
							continue;
						
					}
					if((*(marker+(itemp>>3)))&(0x01<<(itemp&0x07)))//if this point need to be check again
					{
						if(*(directionOfData + itemp)&0xc0)//if this is a seed point or saturated point
							*(marker+(itemp>>3))=*(marker+(itemp>>3))&(~(0x01<<(itemp&0x07)));
						else
						{
				//1
									itemp=position_i1+position_j3+k+1;
									maxvalue=*(outputData+itemp);
									maxcolorindex=27;
				//2
									itemp--;
									if(*(outputData+itemp)>maxvalue)
									{
										maxvalue=*(outputData+itemp);
										maxcolorindex=26;
									}
				//3
									itemp--;
									if(*(outputData+itemp)>maxvalue)
									{
										maxvalue=*(outputData+itemp);
										maxcolorindex=25;
									}
				//4
									itemp=position_i1+position_j2+k+1;
									if(*(outputData+itemp)>maxvalue)
									{
										maxvalue=*(outputData+itemp);
										maxcolorindex=24;
									}
				//5
									itemp--;
									if(*(outputData+itemp)>maxvalue)
									{
										maxvalue=*(outputData+itemp);
										maxcolorindex=23;
									}

				//6
									itemp--;
									if(*(outputData+itemp)>maxvalue)
									{
										maxvalue=*(outputData+itemp);
										maxcolorindex=22;
									}
				//7					
									itemp=position_i1+position_j1+k+1;
									if(*(outputData+itemp)>maxvalue)
									{
										maxvalue=*(outputData+itemp);
										maxcolorindex=21;
									}
				//8	
									itemp--;
									if(*(outputData+itemp)>maxvalue)
									{
										maxvalue=*(outputData+itemp);
										maxcolorindex=20;
									}
				//9					
									itemp--;
									if(*(outputData+itemp)>maxvalue)
									{
										maxvalue=*(outputData+itemp);
										maxcolorindex=19;
									}
				//10	
									itemp=position_i2+position_j3+k+1;
									if(*(outputData+itemp)>maxvalue)
									{
										maxvalue=*(outputData+itemp);
										maxcolorindex=18;
									}
				//11
									itemp--;
									if(*(outputData+itemp)>maxvalue)
									{
										maxvalue=*(outputData+itemp);
										maxcolorindex=17;
									}
				//12
									itemp--;
									if(*(outputData+itemp)>maxvalue)
									{
										maxvalue=*(outputData+itemp);
										maxcolorindex=16;
									}
				//13
									itemp=position_i2+position_j2+k+1;
									if(*(outputData+itemp)>maxvalue)
									{
										maxvalue=*(outputData+itemp);
										maxcolorindex=15;
									}
				//update g
			
									itemp=position_i2+position_j2+k;
									if(maxvalue>*(outputData+itemp))
									{
										if(*(inputData+itemp)>*(outputData+itemp))
										{
																	//*(outputData+itemp)=min(maxvalue,*(inputData+itemp));
											if(maxvalue>*(inputData+itemp))
											{
												*(outputData+itemp)=*(inputData+itemp);
												*(directionOfData+itemp)=maxcolorindex|0x40;
											}
											else 
											{
												*(outputData+itemp)=maxvalue;
												*(directionOfData+itemp)=maxcolorindex;
											}
											
											int ii,jj,kk;
											itemp=position_i2-imageSize+position_j1+k-1;
											for(ii=0;ii<3;ii++)
											{
												for(jj=0;jj<3;jj++)
												{
													for(kk=0;kk<3;kk++)
													{
														
														*(marker+(itemp>>3))|=(0x01<<(itemp&0x07));
														itemp++;
													}
													itemp=itemp-3+ilong;
													
												}
												itemp=itemp-ilong-ilong-ilong+imageSize;
											}														
											
											changed++;
										}
										else
											*(marker+(itemp>>3))&=(~(0x01<<(itemp&0x07)));
							

									}
									else 
										*(marker+(itemp>>3))&=(~(0x01<<(itemp&0x07)));

							}
					}
				}
			}
		}

	}while(changed);
	
	[self checkSaturatedPoints];
	

}
- (void) runFirstRoundFasterWith26Neigbhorhood
{

	long i,j,k;
	float maxvalue;
	unsigned char maxcolorindex;
	long itemp;
	long ilong,iwidth,iheight;
	long position_i1,position_i2,position_j1,position_j2,position_j3;
	int countNum=0;
	
	
	ilong=imageWidth;
	iwidth=imageHeight;
	iheight=imageAmount;


	
	
	//**********************positive direction*****************************


	for(i=1;i<iheight-1;i++)
	{
		position_i1 = (i-1)*imageSize;
		position_i2 = i*imageSize;
		
		for(j=1;j<iwidth-1;j++)
		{
			position_j1 = (j-1)*ilong;
			position_j2 = j*ilong;
			position_j3 = (j+1)*ilong;
			for(k=1;k<ilong-1;k++)
				if(!(*(directionOfData + position_i2+position_j2+k)&0xc0))
				{
					countNum++;
					//1
					itemp=position_i1+position_j1+k-1;
					maxvalue=*(outputData+itemp);
					maxcolorindex=1;
					//2
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=2;
					}
					//3
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=3;
					}
					//4
					itemp=position_i1+position_j2+k-1;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=4;
					}
					//5
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=5;
					}
					
					//6
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=6;
					}
					//7					
					itemp=position_i1+position_j3+k-1;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=7;
					}
					//8	
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=8;
					}
					
					//9					
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=9;
					}
					//10	
					itemp=position_i2+position_j1+k-1;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=10;
					}
					//11
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=11;
					}
					//12
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=12;
					}
					//13
					itemp=position_i2+position_j2+k-1;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=13;
					}
					//update g
					itemp=position_i2+position_j2+k;
					if(maxvalue>*(outputData+itemp))
					{
						if(*(inputData+itemp)>*(outputData+itemp))
						{
							//*(outputData+itemp)=min(maxvalue,*(inputData+itemp));
							if(maxvalue>*(inputData+itemp))
							{
								*(outputData+itemp)=*(inputData+itemp);
								*(directionOfData+itemp)=maxcolorindex|0x40;
							}
							else 
							{
								*(outputData+itemp)=maxvalue;
								*(directionOfData+itemp)=maxcolorindex;
							}
							
									
						}
	
					}
										
				}
		}
	}
		countNum=0;
		
	//*******************************negitive direction*************************
	for(i=iheight-2;i>0;i--)
	{
		position_i1 = (i+1)*imageSize;
		position_i2 = i*imageSize;
		
		for(j=iwidth-2;j>0;j--)
		{
			position_j1 = (j-1)*ilong;
			position_j2 = j*ilong;
			position_j3 = (j+1)*ilong;
			
			for(k=ilong-2;k>0;k--)
				if(!(*(directionOfData + position_i2+position_j2+k)&0xc0))
				{
					countNum++;
					//1
					itemp=position_i1+position_j3+k+1;
					maxvalue=*(outputData+itemp);
					maxcolorindex=27;
					//2
					itemp--;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=26;
					}
					//3
					itemp--;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=25;
					}
					//4
					itemp=position_i1+position_j2+k+1;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=24;
					}
					//5
					itemp--;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=23;
					}
					
					//6
					itemp--;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=22;
					}
					//7					
					itemp=position_i1+position_j1+k+1;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=21;
					}
					//8	
					itemp--;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=20;
					}
					//9					
					itemp--;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=19;
					}
					//10	
					itemp=position_i2+position_j3+k+1;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=18;
					}
					//11
					itemp--;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=17;
					}
					//12
					itemp--;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=16;
					}
					//13
					itemp=position_i2+position_j2+k+1;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=15;
					}
					//update g
					
					itemp=position_i2+position_j2+k;
					if(maxvalue>*(outputData+itemp))
					{
						//*(outputData+itemp)=min(maxvalue,*(inputData+itemp));
						if(maxvalue>*(inputData+itemp))
						{
							*(outputData+itemp)=*(inputData+itemp);
							*(directionOfData+itemp)=maxcolorindex|0x40;
						}
						else 
						{
							*(outputData+itemp)=maxvalue;
							*(directionOfData+itemp)=maxcolorindex;
						}
						
						
					}

					
				}
		}
	}
		countNum++;
			

}
- (void) checkSaturatedPoints
{
	long i,j,k;
	float maxvalue, oldmaxvalue;
	unsigned char maxcolorindex,oldcolorindex;
	long itemp;
	long ilong,iwidth,iheight;
	long position_i1,position_i2,position_i3,position_j1,position_j2,position_j3;
	ilong=imageWidth;
	iwidth=imageHeight;
	iheight=imageAmount;


	for(i=1;i<iheight-1;i++)
	{
		position_i1 = (i-1)*imageSize;
		position_i2 = i*imageSize;
		position_i3 = (i+1)*imageSize;
		for(j=1;j<iwidth-1;j++)
		{
			position_j1 = (j-1)*ilong;
			position_j2 = j*ilong;
			position_j3 = (j+1)*ilong;
			for(k=1;k<ilong-1;k++)
				if((!(*(directionOfData + position_i2+position_j2+k)&0x80))&&(*(directionOfData + position_i2+position_j2+k)&0x40))
				{
					oldcolorindex=*(directionOfData + position_i2+position_j2+k)&0x3f;
					
					//1
					itemp=position_i1+position_j1+k-1;
					maxvalue=*(outputData+itemp);
					maxcolorindex=1;
					oldmaxvalue=maxvalue;
					//2
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=2;
					}
					if(oldcolorindex==2)
						oldmaxvalue=*(outputData+itemp);
					//3
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=3;
					}
					if(oldcolorindex==3)
						oldmaxvalue=*(outputData+itemp);
					//4
					itemp=position_i1+position_j2+k-1;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=4;
					}
					if(oldcolorindex==4)
						oldmaxvalue=*(outputData+itemp);
					//5
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=5;
					}
					if(oldcolorindex==5)
						oldmaxvalue=*(outputData+itemp);
					//6
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=6;
					}
					if(oldcolorindex==6)
						oldmaxvalue=*(outputData+itemp);
					//7					
					itemp=position_i1+position_j3+k-1;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=7;
					}
					if(oldcolorindex==7)
						oldmaxvalue=*(outputData+itemp);
					//8	
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=8;
					}
					if(oldcolorindex==8)
						oldmaxvalue=*(outputData+itemp);
					//9					
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=9;
					}
					if(oldcolorindex==9)
						oldmaxvalue=*(outputData+itemp);
					//10	
					itemp=position_i2+position_j1+k-1;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=10;
					}
					if(oldcolorindex==10)
						oldmaxvalue=*(outputData+itemp);
					//11
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=11;
					}
					if(oldcolorindex==11)
						oldmaxvalue=*(outputData+itemp);
					//12
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=12;
					}
					if(oldcolorindex==12)
						oldmaxvalue=*(outputData+itemp);
					//13
					itemp=position_i2+position_j2+k-1;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=13;
					}
					if(oldcolorindex==13)
						oldmaxvalue=*(outputData+itemp);
					//15
					itemp+=2;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=15;
					}
					if(oldcolorindex==15)
						oldmaxvalue=*(outputData+itemp);
					//16
					itemp=position_i2+position_j3+k-1;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=16;
					}
					if(oldcolorindex==16)
						oldmaxvalue=*(outputData+itemp);
					//17
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=17;
					}
					if(oldcolorindex==17)
						oldmaxvalue=*(outputData+itemp);
					//18
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=18;
					}
					if(oldcolorindex==18)
						oldmaxvalue=*(outputData+itemp);
					//19
					itemp=position_i3+position_j1+k-1;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=19;
					}
					if(oldcolorindex==19)
						oldmaxvalue=*(outputData+itemp);
					//20
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=20;
					}
					if(oldcolorindex==20)
						oldmaxvalue=*(outputData+itemp);
					//21
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=21;
					}
					if(oldcolorindex==21)
						oldmaxvalue=*(outputData+itemp);
					//22
					itemp=position_i3+position_j2+k-1;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=22;
					}
					if(oldcolorindex==22)
						oldmaxvalue=*(outputData+itemp);
					//23
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=23;
					}
					if(oldcolorindex==23)
						oldmaxvalue=*(outputData+itemp);
					//24
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=24;
					}	
					if(oldcolorindex==24)
						oldmaxvalue=*(outputData+itemp);
					//25
					itemp=position_i3+position_j3+k-1;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=25;
					}
					if(oldcolorindex==25)
						oldmaxvalue=*(outputData+itemp);
					//26
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=26;
					}
					if(oldcolorindex==26)
						oldmaxvalue=*(outputData+itemp);
					//27
					itemp++;
					if(*(outputData+itemp)>maxvalue)
					{
						maxvalue=*(outputData+itemp);
						maxcolorindex=27;
					}	
					if(oldcolorindex==27)
						oldmaxvalue=*(outputData+itemp);
					//update direction
					itemp=position_i2+position_j2+k;
					if(maxvalue>oldmaxvalue)
						*(directionOfData+itemp)=maxcolorindex;
					else
						*(directionOfData+itemp)=oldcolorindex;
						
		
						
				}
		}
	}
		
	
}
- (void) optimizedContinueLoop:(float *) pIn Out:(float *) pOut :(unsigned char*) pMarker Direction: (unsigned char*) pPointers
{
	
	long i,j,k;
	int changed;
	float maxvalue;
	unsigned char maxcolorindex;
	
	
	long itemp;
	long ilong,iwidth,iheight;
	long position_i1,position_i2,position_j1,position_j2,position_j3;
	
	
	ilong=imageWidth;
	iwidth=imageHeight;
	iheight=imageAmount;
	
	
	inputData=pIn;
	outputData=pOut;
	directionOfData=pPointers;
	
	unsigned char* marker=pMarker;
	long long* longmarker=(long long*)marker;
	int longmarkerlen=imageSize*imageAmount/(sizeof(long long)*8)-1;
	int markerlen=imageSize*imageAmount/8-1;
	do
	{
		changed=0;
		
		//**********************positive direction*****************************
		for(i=1;i<iheight-1;i++)
		{
			position_i1 = (i-1)*imageSize;
			position_i2 = i*imageSize;
			
			for(j=1;j<iwidth-1;j++)
			{
				position_j1 = (j-1)*ilong;
				position_j2 = j*ilong;
				position_j3 = (j+1)*ilong;
				
				for(k=1;k<ilong-1;k++)
				{
					itemp= position_i2+position_j2+k;
					
					if(!(*(longmarker+(itemp>>6))))
					{
						itemp=itemp>>6;
						do
						{
							itemp++;
						}while(itemp<longmarkerlen&&!(*(longmarker+itemp)));
						itemp=itemp<<6;
						k=itemp-position_i2-position_j2;
						if(k>ilong-1)
						{
							i=itemp/imageSize;
							position_i2=i*imageSize;
							position_i1=position_i2-imageSize;
							j=(itemp-position_i2)/ilong;
							position_j2=ilong*j;
							position_j1=position_j2-ilong;
							position_j3=position_j2+ilong;
							k=itemp-position_i2-position_j2;
						}
						if(i>=iheight-1)
							j=iwidth-1;
						if(j>=iwidth-1||j<1)
							k=ilong-1;
						
						if(k>=ilong-1||k<1)
							continue;
						
					}
					if(!(*(marker+(itemp>>3))))
					{
						itemp=itemp>>3;
						do
						{
							itemp++;
						}while(itemp<markerlen&&!(*(marker+itemp)));
						itemp=itemp<<3;
						k=itemp-position_i2-position_j2;
						
						if(k>ilong-1)
						{
							i=itemp/imageSize;
							position_i2=i*imageSize;
							position_i1=position_i2-imageSize;
							j=(itemp-position_i2)/ilong;
							position_j2=ilong*j;
							position_j1=position_j2-ilong;
							position_j3=position_j2+ilong;
							k=itemp-position_i2-position_j2;
						}
						if(i>=iheight-1)
							j=iwidth-1;
						if(j>=iwidth-1||j<1)
							k=ilong-1;
						
						if(k>=ilong-1||k<1)
							continue;
						
					}/*
					
					if(!(*(longmarker+(itemp>>6))))
					{
						itemp=itemp>>6;
						do
						{
							itemp++;
						}while(!(*(longmarker+itemp)));
						itemp=itemp<<6;
						k=itemp-position_i2-position_j2;
						
						if(k>=ilong-1)
							continue;
						
					}
					
					if(!(*(marker+(itemp>>3))))
					{
						itemp=itemp>>3;
						do
						{
							itemp++;
						}while(!(*(marker+itemp)));
						itemp=itemp<<3;
						k=itemp-position_i2-position_j2;
						
						if(k>=ilong-1)
							continue;
						
					}*/
					
					if((*(marker+(itemp>>3)))&(0x01<<(itemp&0x07)))//if this point need to be check again
					{
						if(*(directionOfData + itemp)&0x80)//if this is a seed point 
							*(marker+(itemp>>3))=*(marker+(itemp>>3))&(~(0x01<<(itemp&0x07)));
						else
						{
							//1
							itemp=position_i1+position_j1+k-1;
							maxvalue=*(outputData+itemp);
							maxcolorindex=1;
							//2
							itemp++;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=2;
							}
							//3
							itemp++;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=3;
							}
							//4
							itemp=position_i1+position_j2+k-1;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=4;
							}
							//5
							itemp++;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=5;
							}
							
							//6
							itemp++;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=6;
							}
							//7					
							itemp=position_i1+position_j3+k-1;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=7;
							}
							//8	
							itemp++;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=8;
							}
							
							//9					
							itemp++;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=9;
							}
							//10	
							itemp=position_i2+position_j1+k-1;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=10;
							}
							//11
							itemp++;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=11;
							}
							//12
							itemp++;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=12;
							}
							//13
							itemp=position_i2+position_j2+k-1;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=13;
							}
							//update g
							
							itemp=position_i2+position_j2+k;
							if(maxvalue>*(outputData+itemp))
							{
								if(*(inputData+itemp)>*(outputData+itemp))
								{
									//*(outputData+itemp)=min(maxvalue,*(inputData+itemp));
									if(maxvalue>*(inputData+itemp))
									{
										*(outputData+itemp)=*(inputData+itemp);
										*(directionOfData+itemp)=maxcolorindex;
									}
									else 
									{
										*(outputData+itemp)=maxvalue;
										*(directionOfData+itemp)=maxcolorindex;
									}
									
									int ii,jj,kk;
									itemp=position_i1+position_j1+k-1;
									for(ii=0;ii<3;ii++)
									{
										for(jj=0;jj<3;jj++)
										{
											for(kk=0;kk<3;kk++)
											{
												
												*(marker+(itemp>>3))|=(0x01<<(itemp&0x07));
												itemp++;
											}
											itemp=itemp-3+ilong;
											
										}
										itemp=itemp-ilong-ilong-ilong+imageSize;
									}
									
									changed++;				
								}
								
								else
								{
								 if(((*(directionOfData+itemp))&0x3f) != (maxcolorindex&0x3f))
								 {
									 int direction=*(directionOfData+itemp)&0x3f;
									 switch(direction)
									 {
										 case 1: direction =  (-imageSize-imageWidth-1);
											 break;
										 case 2: direction =  (-imageSize-imageWidth);
											 break;
										 case 3: direction = (-imageSize-imageWidth+1);
											 break;
										 case 4: direction = (-imageSize-1);
											 break;
										 case 5: direction = (-imageSize);
											 break;
										 case 6: direction = (-imageSize+1);
											 break;
										 case 7: direction = (-imageSize+imageWidth-1);
											 break;
										 case 8: direction = (-imageSize+imageWidth);
											 break;
										 case 9: direction = (-imageSize+imageWidth+1);
											 break;
										 case 10: direction = (-imageWidth-1);
											 break;
										 case 11: direction = (-imageWidth);
											 break;
										 case 12: direction = (-imageWidth+1);
											 break;
										 case 13: direction = (-1);
											 break;
										 case 14: direction = 0;
											 break;
										 case 15: direction = 1;
											 break;
										 case 16: direction = imageWidth-1;
											 break;
										 case 17: direction = imageWidth;
											 break;
										 case 18: direction = imageWidth+1;
											 break;
										 case 19: direction = imageSize-imageWidth-1;
											 break;
										 case 20: direction = imageSize-imageWidth;
											 break;
										 case 21: direction = imageSize-imageWidth+1;
											 break;
										 case 22: direction = imageSize-1;
											 break;
										 case 23: direction = imageSize;
											 break;
										 case 24: direction = imageSize+1;
											 break;
										 case 25: direction = imageSize+imageWidth-1;
											 break;
										 case 26: direction = imageSize+imageWidth;
											 break;
										 case 27: direction = imageSize+imageWidth+1;
											 break;
									 }
									 if(*(outputData+itemp+direction)<maxvalue)
										 *(directionOfData+itemp)=maxcolorindex;
								 }
									*(marker+(itemp>>3))&=(~(0x01<<(itemp&0x07)));
								}
								
								
							}
							else 
								*(marker+(itemp>>3))&=(~(0x01<<(itemp&0x07)));
							
						}
					}
				}
			}
		}
		
		//*******************************negitive direction*************************
		for(i=iheight-2;i>0;i--)
		{
			position_i1 = (i+1)*imageSize;
			position_i2 = i*imageSize;
			
			for(j=iwidth-2;j>0;j--)
			{
				position_j1 = (j-1)*ilong;
				position_j2 = j*ilong;
				position_j3 = (j+1)*ilong;
				
				for(k=ilong-2;k>0;k--)
				{	
					itemp= position_i2+position_j2+k;
					
					if(!(*(longmarker+(itemp>>6))))
					{
						itemp=itemp>>6;
						do
						{
							itemp--;
							
						}while(itemp>=0&&!(*(longmarker+itemp)));
						
						itemp=(itemp<<6)+63;
						k=itemp-position_i2-position_j2;
						if(k<0)
						{
							i=itemp/imageSize;
							position_i2=i*imageSize;
							position_i1=position_i2+imageSize;
							j=(itemp-position_i2)/ilong;
							position_j2=ilong*j;
							position_j1=position_j2-ilong;
							position_j3=position_j2+ilong;
							k=itemp-position_i2-position_j2;
						}
						
						if(i<1)
							j=0;
						if(j>=iwidth-1||j<1)
							k=0;
						
						if(k>=ilong-1||k<1)
							continue;					
						
					}
					if(!(*(marker+(itemp>>3))))
					{
						itemp=itemp>>3;
						do
						{
							itemp--;
						}while(itemp>=0&&!(*(marker+itemp)));
						itemp=(itemp<<3)+7;
						k=itemp-position_i2-position_j2;
						
						if(k<0)
						{
							i=itemp/imageSize;
							position_i2=i*imageSize;
							position_i1=position_i2+imageSize;
							j=(itemp-position_i2)/ilong;
							position_j2=ilong*j;
							position_j1=position_j2-ilong;
							position_j3=position_j2+ilong;
							k=itemp-position_i2-position_j2;
						}
						
						if(i<1)
							j=0;
						if(j>=iwidth-1||j<1)
							k=0;
						
						if(k>=ilong-1||k<1)
							continue;	
						
					}
					/*
					
					
					if(!(*(longmarker+(itemp>>6))))
					{
						itemp=itemp>>6;
						do
						{
							itemp--;
						}while(!(*(longmarker+itemp)));
						
						itemp=(itemp<<6)+63;
						k=itemp-position_i2-position_j2;
						
						if(k<1)
							continue;
						
					}
					
					if(!(*(marker+(itemp>>3))))
					{
						itemp=itemp>>3;
						do
						{
							itemp--;
						}while(!(*(marker+itemp)));
						itemp=(itemp<<3)+7;
						k=itemp-position_i2-position_j2;
						
						if(k<1)
							continue;
						
					}*/
					if((*(marker+(itemp>>3)))&(0x01<<(itemp&0x07)))//if this point need to be check again
					{
						if(*(directionOfData + itemp)&0x80)//if this is a seed point 
							*(marker+(itemp>>3))=*(marker+(itemp>>3))&(~(0x01<<(itemp&0x07)));
						else
						{
							//1
							itemp=position_i1+position_j3+k+1;
							maxvalue=*(outputData+itemp);
							maxcolorindex=27;
							//2
							itemp--;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=26;
							}
							//3
							itemp--;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=25;
							}
							//4
							itemp=position_i1+position_j2+k+1;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=24;
							}
							//5
							itemp--;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=23;
							}
							
							//6
							itemp--;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=22;
							}
							//7					
							itemp=position_i1+position_j1+k+1;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=21;
							}
							//8	
							itemp--;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=20;
							}
							//9					
							itemp--;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=19;
							}
							//10	
							itemp=position_i2+position_j3+k+1;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=18;
							}
							//11
							itemp--;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=17;
							}
							//12
							itemp--;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=16;
							}
							//13
							itemp=position_i2+position_j2+k+1;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=15;
							}
							//update g
							
							itemp=position_i2+position_j2+k;
							if(maxvalue>*(outputData+itemp))
							{
								if(*(inputData+itemp)>*(outputData+itemp))
								{
									//*(outputData+itemp)=min(maxvalue,*(inputData+itemp));
									if(maxvalue>*(inputData+itemp))
									{
										*(outputData+itemp)=*(inputData+itemp);
										*(directionOfData+itemp)=maxcolorindex;
									}
									else 
									{
										*(outputData+itemp)=maxvalue;
										*(directionOfData+itemp)=maxcolorindex;
									}
									
									int ii,jj,kk;
									itemp=position_i2-imageSize+position_j1+k-1;
									for(ii=0;ii<3;ii++)
									{
										for(jj=0;jj<3;jj++)
										{
											for(kk=0;kk<3;kk++)
											{
												
												*(marker+(itemp>>3))|=(0x01<<(itemp&0x07));
												itemp++;
											}
											itemp=itemp-3+ilong;
											
										}
										itemp=itemp-ilong-ilong-ilong+imageSize;
									}														
									
									changed++;
								}
								else
								{
								 if(((*(directionOfData+itemp))&0x3f) != (maxcolorindex&0x3f))
								 {
									 int direction=*(directionOfData+itemp)&0x3f;
									 switch(direction)
									 {
										 case 1: direction =  (-imageSize-imageWidth-1);
											 break;
										 case 2: direction =  (-imageSize-imageWidth);
											 break;
										 case 3: direction = (-imageSize-imageWidth+1);
											 break;
										 case 4: direction = (-imageSize-1);
											 break;
										 case 5: direction = (-imageSize);
											 break;
										 case 6: direction = (-imageSize+1);
											 break;
										 case 7: direction = (-imageSize+imageWidth-1);
											 break;
										 case 8: direction = (-imageSize+imageWidth);
											 break;
										 case 9: direction = (-imageSize+imageWidth+1);
											 break;
										 case 10: direction = (-imageWidth-1);
											 break;
										 case 11: direction = (-imageWidth);
											 break;
										 case 12: direction = (-imageWidth+1);
											 break;
										 case 13: direction = (-1);
											 break;
										 case 14: direction = 0;
											 break;
										 case 15: direction = 1;
											 break;
										 case 16: direction = imageWidth-1;
											 break;
										 case 17: direction = imageWidth;
											 break;
										 case 18: direction = imageWidth+1;
											 break;
										 case 19: direction = imageSize-imageWidth-1;
											 break;
										 case 20: direction = imageSize-imageWidth;
											 break;
										 case 21: direction = imageSize-imageWidth+1;
											 break;
										 case 22: direction = imageSize-1;
											 break;
										 case 23: direction = imageSize;
											 break;
										 case 24: direction = imageSize+1;
											 break;
										 case 25: direction = imageSize+imageWidth-1;
											 break;
										 case 26: direction = imageSize+imageWidth;
											 break;
										 case 27: direction = imageSize+imageWidth+1;
											 break;
									 }
									 if(*(outputData+itemp+direction)<maxvalue)
										 *(directionOfData+itemp)=maxcolorindex;
								 }
									*(marker+(itemp>>3))&=(~(0x01<<(itemp&0x07)));
								}
									
								
								
							}
							else 
								*(marker+(itemp>>3))&=(~(0x01<<(itemp&0x07)));
							
						}
					}
				}
			}
		}
		
	}while(changed);

	
}
- (void) startShortestPathSearchAsFloatWith6Neighborhood:(float *) pIn Out:(float *) pOut Direction: (unsigned char*) pPointers
{
	
	long i,j,k;
	int changed;
	float maxvalue;
	unsigned char maxcolorindex;
	
	
	long itemp;
	long ilong,iwidth,iheight;
	long position_i1,position_i2,position_j1,position_j2,position_j3;
	
	
	ilong=imageWidth;
	iwidth=imageHeight;
	iheight=imageAmount;

	
	inputData=pIn;
	outputData=pOut;
	directionOfData=pPointers;
	
	
	
	
	do
	{
		changed=0;
		
		//**********************positive direction*****************************
		for(i=1;i<iheight-1;i++)
		{
			position_i1 = (i-1)*imageSize;
			position_i2 = i*imageSize;
			
			for(j=1;j<iwidth-1;j++)
			{
				position_j1 = (j-1)*ilong;
				position_j2 = j*ilong;
				position_j3 = (j+1)*ilong;
				for(k=1;k<ilong-1;k++)
					if((!(*(directionOfData + position_i2+position_j2+k)&0x80))&&(*(directionOfData + position_i2+position_j2+k)&0x40))
					{

						//5
						itemp=position_i1+position_j2+k;
						maxvalue=*(outputData+itemp);
						maxcolorindex=5;


						//11
						itemp=position_i2+position_j1+k;
						if(*(outputData+itemp)>maxvalue)
						{
							maxvalue=*(outputData+itemp);
							maxcolorindex=11;
						}
						//13
						itemp=position_i2+position_j2+k-1;
						if(*(outputData+itemp)>maxvalue)
						{
							maxvalue=*(outputData+itemp);
							maxcolorindex=13;
						}
						//update g
						//((*(inputData+itemp)>*(outputData+itemp))||(((*(directionOfData+maxcolorindex))&0x3f) != ((*(directionOfData+itemp))&0x3f)))
						itemp=position_i2+position_j2+k;
						if(maxvalue>*(outputData+itemp))
						{
							if(*(inputData+itemp)>*(outputData+itemp))
							{
								//*(outputData+itemp)=min(maxvalue,*(inputData+itemp));
								if(maxvalue>*(inputData+itemp))
									*(outputData+itemp)=*(inputData+itemp);
								else 
									*(outputData+itemp)=maxvalue;
								*(directionOfData+itemp)=maxcolorindex&0x3f;
								*(directionOfData+position_i1+position_j2+k) = (*(directionOfData+position_i1+position_j2+k)) | 0x40;
								*(directionOfData+position_i2+position_j1+k) = (*(directionOfData+position_i2+position_j1+k)) | 0x40;
								*(directionOfData+position_i2+position_j2+k-1) = (*(directionOfData+position_i2+position_j2+k-1)) | 0x40;
								*(directionOfData+position_i2+position_j2+k+1) = (*(directionOfData+position_i2+position_j2+k+1)) | 0x40;
								*(directionOfData+position_i2+position_j3+k) = (*(directionOfData+position_i2+position_j3+k)) | 0x40;
								*(directionOfData+(i+1)*imageSize+position_j2+k) = (*(directionOfData+(i+1)*imageSize+position_j2+k)) | 0x40;

								changed++;				
							}
							else if(((*(directionOfData+itemp))&0x3f) != (maxcolorindex&0x3f))// connect value won't change, only direction will change, so no need to notice neighbors to check update.
							{
								// to check 26 neighbors to find the highest connectedness( actually 13 has been checked so check the rest 13)
								float recheckmax=maxvalue;
								int   recheckmaxindex=maxcolorindex;

								float ftemp;

								ftemp=*(outputData+position_i2+position_j2+k+1);
								if(ftemp>=recheckmax)
								{
									recheckmax=ftemp;
									recheckmaxindex=15;
								}
								ftemp=*(outputData+position_i2+position_j3+k);
								if(ftemp>=recheckmax)
								{
									recheckmax=ftemp;
									recheckmaxindex=17;
								}
								ftemp=*(outputData+(i+1)*imageSize+position_j2+k);
								if(ftemp>=recheckmax)
								{
									recheckmax=ftemp;
									recheckmaxindex=23;
								}
											//there is difference between maxcolorindex and recheckmaxindex
											//maxcolorindex is the first maxinium of forward 13 neighbors
											//recheckmaxindex is the last maxinium of backward 13 neighbors
											//recheckmaxindex will not be 14!
								if(recheckmaxindex<14 ) 
									*(directionOfData+itemp)=maxcolorindex&0x3f;
						
								else 
									*(directionOfData+itemp)=(recheckmaxindex&0x3f);
									
								//above sentence also change the "change" status marker to "no change"			
							}
							else
								*(directionOfData+itemp) = (*(directionOfData+itemp))&0x3f;
							
						}
						else 
							*(directionOfData+itemp) = (*(directionOfData+itemp))&0x3f;
						
					}
			}
		}
			
			//*******************************negitive direction*************************
			for(i=iheight-2;i>0;i--)
			{
				position_i1 = (i+1)*imageSize;
				position_i2 = i*imageSize;
				
				for(j=iwidth-2;j>0;j--)
				{
					position_j1 = (j-1)*ilong;
					position_j2 = j*ilong;
					position_j3 = (j+1)*ilong;
					
					for(k=ilong-2;k>0;k--)
						if(!(*(directionOfData + position_i2+position_j2+k)&0x80)&&(*(directionOfData + position_i2+position_j2+k)&0x40))
						{

							//5
							itemp=position_i1+position_j2+k;
							maxvalue=*(outputData+itemp);
							maxcolorindex=23;


							//11
							itemp=position_i2+position_j3+k;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=17;
							}
							//13
							itemp=position_i2+position_j2+k+1;
							if(*(outputData+itemp)>maxvalue)
							{
								maxvalue=*(outputData+itemp);
								maxcolorindex=15;
							}
							//update g
							//((*(inputData+itemp)>*(outputData+itemp))||(((*(directionOfData+maxcolorindex))&0x3f) != ((*(directionOfData+itemp))&0x3f)))
							itemp=position_i2+position_j2+k;
							if(maxvalue>*(outputData+itemp))
							{
								if(*(inputData+itemp)>*(outputData+itemp))
								{
									//*(outputData+itemp)=min(maxvalue,*(inputData+itemp));
									if(maxvalue>*(inputData+itemp))
										*(outputData+itemp)=*(inputData+itemp);
									else 
										*(outputData+itemp)=maxvalue;
									*(directionOfData+itemp)=maxcolorindex&0x3f;
									*(directionOfData+position_i1+position_j2+k) = (*(directionOfData+position_i1+position_j2+k)) | 0x40;
									*(directionOfData+position_i2+position_j3+k) = (*(directionOfData+position_i2+position_j3+k)) | 0x40;
									*(directionOfData+position_i2+position_j2+k-1) = (*(directionOfData+position_i2+position_j2+k-1)) | 0x40;
									*(directionOfData+position_i2+position_j2+k+1) = (*(directionOfData+position_i2+position_j2+k+1)) | 0x40;
									*(directionOfData+position_i2+position_j1+k) = (*(directionOfData+position_i2+position_j1+k)) | 0x40;
									*(directionOfData+(i-1)*imageSize+position_j2+k) = (*(directionOfData+(i-1)*imageSize+position_j2+k)) | 0x40;
									
									
									
									changed++;
								}
								else if(((*(directionOfData+itemp))&0x3f) != (maxcolorindex&0x3f))// connect value won't change, only direction will change, so no need to notice neighbors to check update.
								{
									// to check 26 neighbors to find the highest connectedness( actually 13 has been checked so check the rest 13)
									float recheckmax=maxvalue;
									int   recheckmaxindex=maxcolorindex;
									float ftemp;
									
									ftemp=*(outputData+position_i2+position_j2+k-1);
									if(ftemp>=recheckmax)
									{
										recheckmax=ftemp;
										recheckmaxindex=13;
									}
									ftemp=*(outputData+position_i2+position_j1+k);
									if(ftemp>=recheckmax)
									{
										recheckmax=ftemp;
										recheckmaxindex=11;
									}
									ftemp=*(outputData+(i-1)*imageSize+position_j2+k);
									if(ftemp>=recheckmax)
									{
										recheckmax=ftemp;
										recheckmaxindex=5;
									}
						
									//there is difference between maxcolorindex and recheckmaxindex
									//maxcolorindex is the lase maxinium of backward 13 neighbors
									//recheckmaxindex is the first maxinium of forward 13 neighbors
									//recheckmaxindex will not be 14!
									if(recheckmaxindex>14 ) 
										*(directionOfData+itemp)=maxcolorindex&0x3f;
									else 
										*(directionOfData+itemp)=(recheckmaxindex&0x3f);
									
								}
								else
									*(directionOfData+itemp) = (*(directionOfData+itemp))&0x3f;
								
								
							}
							else 
								*(directionOfData+itemp) = (*(directionOfData+itemp))&0x3f;
							
						}
				}
			}
				
	}while(changed);
			
}
- (void) caculatePathLength:(unsigned short *) pDistanceMap Pointer: (unsigned char*) pPointers
{

	distanceMap=pDistanceMap;
	directionOfData=pPointers;
	int totalvoxel=imageSize*(imageAmount-1);
	int i;
	for(i=imageSize;i<totalvoxel;i++)
	{
		
		if((!((*(directionOfData+i))&0x80))&&(*(distanceMap+i)==0))
		{
			int direction=*(directionOfData+i)&0x3f;
			if(direction)
			{
				int itemp;
				switch(direction)
				{
					case 1: itemp =  (-imageSize-imageWidth-1);
						break;
					case 2: itemp =  (-imageSize-imageWidth);
						break;
					case 3: itemp = (-imageSize-imageWidth+1);
						break;
					case 4: itemp = (-imageSize-1);
						break;
					case 5: itemp = (-imageSize);
						break;
					case 6: itemp = (-imageSize+1);
						break;
					case 7: itemp = (-imageSize+imageWidth-1);
						break;
					case 8: itemp = (-imageSize+imageWidth);
						break;
					case 9: itemp = (-imageSize+imageWidth+1);
						break;
					case 10: itemp = (-imageWidth-1);
						break;
					case 11: itemp = (-imageWidth);
						break;
					case 12: itemp = (-imageWidth+1);
						break;
					case 13: itemp = (-1);
						break;
					case 14: itemp = 0;
						break;
					case 15: itemp = 1;
						break;
					case 16: itemp = imageWidth-1;
						break;
					case 17: itemp = imageWidth;
						break;
					case 18: itemp = imageWidth+1;
						break;
					case 19: itemp = imageSize-imageWidth-1;
						break;
					case 20: itemp = imageSize-imageWidth;
						break;
					case 21: itemp = imageSize-imageWidth+1;
						break;
					case 22: itemp = imageSize-1;
						break;
					case 23: itemp = imageSize;
						break;
					case 24: itemp = imageSize+1;
						break;
					case 25: itemp = imageSize+imageWidth-1;
						break;
					case 26: itemp = imageSize+imageWidth;
						break;
					case 27: itemp = imageSize+imageWidth+1;
						break;
				}
				
				itemp+=i;
				*(distanceMap+i)=[self lengthOfParent:itemp]+1;
			}
		}
		
	}
	

}
- (unsigned short ) lengthOfParent:(int)pointer
{

	if(*(distanceMap+pointer)==0)
	{
		int direction=*(directionOfData+pointer)&0x3f;
		if(direction)
		{
			int itemp;
			switch(direction)
			{
				case 1: itemp =  (-imageSize-imageWidth-1);
					break;
				case 2: itemp =  (-imageSize-imageWidth);
					break;
				case 3: itemp = (-imageSize-imageWidth+1);
					break;
				case 4: itemp = (-imageSize-1);
					break;
				case 5: itemp = (-imageSize);
					break;
				case 6: itemp = (-imageSize+1);
					break;
				case 7: itemp = (-imageSize+imageWidth-1);
					break;
				case 8: itemp = (-imageSize+imageWidth);
					break;
				case 9: itemp = (-imageSize+imageWidth+1);
					break;
				case 10: itemp = (-imageWidth-1);
					break;
				case 11: itemp = (-imageWidth);
					break;
				case 12: itemp = (-imageWidth+1);
					break;
				case 13: itemp = (-1);
					break;
				case 14: itemp = 0;
					break;
				case 15: itemp = 1;
					break;
				case 16: itemp = imageWidth-1;
					break;
				case 17: itemp = imageWidth;
					break;
				case 18: itemp = imageWidth+1;
					break;
				case 19: itemp = imageSize-imageWidth-1;
					break;
				case 20: itemp = imageSize-imageWidth;
					break;
				case 21: itemp = imageSize-imageWidth+1;
					break;
				case 22: itemp = imageSize-1;
					break;
				case 23: itemp = imageSize;
					break;
				case 24: itemp = imageSize+1;
					break;
				case 25: itemp = imageSize+imageWidth-1;
					break;
				case 26: itemp = imageSize+imageWidth;
					break;
				case 27: itemp = imageSize+imageWidth+1;
					break;
			}
			
			itemp+=pointer;
			*(distanceMap+pointer) = [self lengthOfParent:itemp]+1;
			if((*(distanceMap+pointer))>=0xffff)
					*(distanceMap+pointer)=0xfffe;
		}
		else
			return 1;
	}
	return(*(distanceMap+pointer));
	
}
- (int) caculatePathLengthWithWeightFunction:(float *) pIn:(float *) pOut Pointer: (unsigned char*) pPointers:(float) threshold: (float)wholeValue
{
	outputData=pOut;
	directionOfData=pPointers;
	weightThreshold=threshold;
	weightWholeValue=1.0/wholeValue;
	float maxvalue=0;
	int   maxindex=0;

	int totalvoxel=imageSize*(imageAmount-1);
	int i;
	for(i=imageSize;i<totalvoxel;i++)
	{
		
		if(*(outputData+i)==0)
		{
			int direction=*(directionOfData+i)&0x3f;
			if(direction)
			{
				int itemp;
				switch(direction)
				{
					case 1: itemp =  (-imageSize-imageWidth-1);
						break;
					case 2: itemp =  (-imageSize-imageWidth);
						break;
					case 3: itemp = (-imageSize-imageWidth+1);
						break;
					case 4: itemp = (-imageSize-1);
						break;
					case 5: itemp = (-imageSize);
						break;
					case 6: itemp = (-imageSize+1);
						break;
					case 7: itemp = (-imageSize+imageWidth-1);
						break;
					case 8: itemp = (-imageSize+imageWidth);
						break;
					case 9: itemp = (-imageSize+imageWidth+1);
						break;
					case 10: itemp = (-imageWidth-1);
						break;
					case 11: itemp = (-imageWidth);
						break;
					case 12: itemp = (-imageWidth+1);
						break;
					case 13: itemp = (-1);
						break;
					case 14: itemp = 0;
						break;
					case 15: itemp = 1;
						break;
					case 16: itemp = imageWidth-1;
						break;
					case 17: itemp = imageWidth;
						break;
					case 18: itemp = imageWidth+1;
						break;
					case 19: itemp = imageSize-imageWidth-1;
						break;
					case 20: itemp = imageSize-imageWidth;
						break;
					case 21: itemp = imageSize-imageWidth+1;
						break;
					case 22: itemp = imageSize-1;
						break;
					case 23: itemp = imageSize;
						break;
					case 24: itemp = imageSize+1;
						break;
					case 25: itemp = imageSize+imageWidth-1;
						break;
					case 26: itemp = imageSize+imageWidth;
						break;
					case 27: itemp = imageSize+imageWidth+1;
						break;
				}
				
				itemp+=i;
				*(outputData+i)=[self lengthOfParentWithWeightFunction:itemp] + ((*(inputData+i)-weightThreshold)*weightWholeValue);
			}
		}
		if(maxvalue<*(outputData+i))
		{
			maxvalue=*(outputData+i);
			maxindex=i;
		}
		
	}
	return maxindex;
				
				
				
}
- (float) lengthOfParentWithWeightFunction:(int)pointer
{
	if(*(outputData+pointer)==0)
	{
		int direction=*(directionOfData+pointer)&0x3f;
		if(direction)
		{
			int itemp;
			switch(direction)
			{
				case 1: itemp =  (-imageSize-imageWidth-1);
					break;
				case 2: itemp =  (-imageSize-imageWidth);
					break;
				case 3: itemp = (-imageSize-imageWidth+1);
					break;
				case 4: itemp = (-imageSize-1);
					break;
				case 5: itemp = (-imageSize);
					break;
				case 6: itemp = (-imageSize+1);
					break;
				case 7: itemp = (-imageSize+imageWidth-1);
					break;
				case 8: itemp = (-imageSize+imageWidth);
					break;
				case 9: itemp = (-imageSize+imageWidth+1);
					break;
				case 10: itemp = (-imageWidth-1);
					break;
				case 11: itemp = (-imageWidth);
					break;
				case 12: itemp = (-imageWidth+1);
					break;
				case 13: itemp = (-1);
					break;
				case 14: itemp = 0;
					break;
				case 15: itemp = 1;
					break;
				case 16: itemp = imageWidth-1;
					break;
				case 17: itemp = imageWidth;
					break;
				case 18: itemp = imageWidth+1;
					break;
				case 19: itemp = imageSize-imageWidth-1;
					break;
				case 20: itemp = imageSize-imageWidth;
					break;
				case 21: itemp = imageSize-imageWidth+1;
					break;
				case 22: itemp = imageSize-1;
					break;
				case 23: itemp = imageSize;
					break;
				case 24: itemp = imageSize+1;
					break;
				case 25: itemp = imageSize+imageWidth-1;
					break;
				case 26: itemp = imageSize+imageWidth;
					break;
				case 27: itemp = imageSize+imageWidth+1;
					break;
			}
			
			itemp+=pointer;
			*(outputData+pointer) = [self lengthOfParentWithWeightFunction:itemp] + ((*(inputData+pointer)-weightThreshold)*weightWholeValue);
		}
		else
			return 0;
	}
	return(*(outputData+pointer));
}
- (void) caculateColorMapFromPointerMap: (unsigned char*) pColor: (unsigned char*) pPointers
{
	colorOfData=pColor;
	directionOfData=pPointers;
	int totalvoxel=imageSize*(imageAmount-1);
	int i;
	for(i=imageSize;i<totalvoxel;i++)
	{
			
		if(*(colorOfData+i)==0)
		{
			if(!((*(directionOfData+i))&0x80))
			{
				int direction=*(directionOfData+i)&0x3f;
				if(direction)
				{
					int itemp;
					switch(direction)
					{
						case 1: itemp =  (-imageSize-imageWidth-1);
							break;
						case 2: itemp =  (-imageSize-imageWidth);
							break;
						case 3: itemp = (-imageSize-imageWidth+1);
							break;
						case 4: itemp = (-imageSize-1);
							break;
						case 5: itemp = (-imageSize);
							break;
						case 6: itemp = (-imageSize+1);
							break;
						case 7: itemp = (-imageSize+imageWidth-1);
							break;
						case 8: itemp = (-imageSize+imageWidth);
							break;
						case 9: itemp = (-imageSize+imageWidth+1);
							break;
						case 10: itemp = (-imageWidth-1);
							break;
						case 11: itemp = (-imageWidth);
							break;
						case 12: itemp = (-imageWidth+1);
							break;
						case 13: itemp = (-1);
							break;
						case 14: itemp = 0;
							break;
						case 15: itemp = 1;
							break;
						case 16: itemp = imageWidth-1;
							break;
						case 17: itemp = imageWidth;
							break;
						case 18: itemp = imageWidth+1;
							break;
						case 19: itemp = imageSize-imageWidth-1;
							break;
						case 20: itemp = imageSize-imageWidth;
							break;
						case 21: itemp = imageSize-imageWidth+1;
							break;
						case 22: itemp = imageSize-1;
							break;
						case 23: itemp = imageSize;
							break;
						case 24: itemp = imageSize+1;
							break;
						case 25: itemp = imageSize+imageWidth-1;
							break;
						case 26: itemp = imageSize+imageWidth;
							break;
						case 27: itemp = imageSize+imageWidth+1;
							break;
					}
					
					itemp+=i;
					*(colorOfData+i)=[self colorOfParent:itemp];
				}
			}
			else
				*(colorOfData+i)=(*(directionOfData+i))&0x3f;
		}
			
			
	}
				
}
- (unsigned char) colorOfParent:(int)pointer
{
	if(*(colorOfData+pointer)==0)
	{
		if(!((*(directionOfData+pointer))&0x80))
		{

				int direction=*(directionOfData+pointer)&0x3f;
				if(direction)
				{
					int itemp;
					switch(direction)
					{
						case 1: itemp =  (-imageSize-imageWidth-1);
							break;
						case 2: itemp =  (-imageSize-imageWidth);
							break;
						case 3: itemp = (-imageSize-imageWidth+1);
							break;
						case 4: itemp = (-imageSize-1);
							break;
						case 5: itemp = (-imageSize);
							break;
						case 6: itemp = (-imageSize+1);
							break;
						case 7: itemp = (-imageSize+imageWidth-1);
							break;
						case 8: itemp = (-imageSize+imageWidth);
							break;
						case 9: itemp = (-imageSize+imageWidth+1);
							break;
						case 10: itemp = (-imageWidth-1);
							break;
						case 11: itemp = (-imageWidth);
							break;
						case 12: itemp = (-imageWidth+1);
							break;
						case 13: itemp = (-1);
							break;
						case 14: itemp = 0;
							break;
						case 15: itemp = 1;
							break;
						case 16: itemp = imageWidth-1;
							break;
						case 17: itemp = imageWidth;
							break;
						case 18: itemp = imageWidth+1;
							break;
						case 19: itemp = imageSize-imageWidth-1;
							break;
						case 20: itemp = imageSize-imageWidth;
							break;
						case 21: itemp = imageSize-imageWidth+1;
							break;
						case 22: itemp = imageSize-1;
							break;
						case 23: itemp = imageSize;
							break;
						case 24: itemp = imageSize+1;
							break;
						case 25: itemp = imageSize+imageWidth-1;
							break;
						case 26: itemp = imageSize+imageWidth;
							break;
						case 27: itemp = imageSize+imageWidth+1;
							break;
					}
					
					itemp += pointer;
					*(colorOfData+pointer) = [self colorOfParent:itemp];
				}
				else
					return 0;
			
		}
		else if(*(colorOfData+pointer)==0)
			*(colorOfData+pointer)=(*(directionOfData+pointer))&0x3f;
	}

	return(*(colorOfData+pointer));
	
}

- (void) localOptmizeConnectednessTree:(float *)pIn :(float *)pOut:(unsigned short*)pDistanceMap Pointer:(unsigned char*) pPointers :(float)minAtEdge needSmooth:(BOOL)isNeedSmooth
{
	inputData=pIn;
	float* psmoothed=pOut;
	distanceMap=pDistanceMap;
	directionOfData=pPointers;
	minValueInCurSeries=minAtEdge;
	unsigned char pointerToUpper;
	float maxUpper;
	unsigned short currentLength;
	int itemp;
	float tempfloat;
	int x,y,z;
	int needchangedis=0;
	imageSize=imageWidth*imageHeight;
	
	[self caculatePathLength:pDistanceMap Pointer:pPointers];
	if(isNeedSmooth)
	{
		itemp=0;
		
		for(z=0;z<imageAmount;z++)
			for(y=0;y<imageHeight;y++)
				for(x=0;x<imageWidth;x++)
				{
					if(!((*(directionOfData + itemp))&0x80))
					{
						int ii,jj,kk;
						float sum=0;
						int xx,yy,zz;
						int iitemp=itemp-imageSize-imageWidth-1;

						for(ii=-1;ii<2;ii++)
						{
							for(jj=-1;jj<2;jj++)
							{
								for(kk=-1;kk<2;kk++)
								{
									zz=z+ii;
									yy=y+jj;
									xx=x+kk;
									if(xx>=0 && xx<imageWidth && yy>=0 && yy<imageHeight && zz>=0 && zz<imageAmount && (!((*(directionOfData + iitemp))&0x80)))
										sum+=*(inputData + iitemp);
									else
										sum+=minValueInCurSeries;
									iitemp++;
								}
								iitemp=iitemp-3+imageWidth;
							}
							iitemp=iitemp-imageWidth-imageWidth-imageWidth+imageSize;
							
						}
								
						*(psmoothed+itemp)+=sum/27.0;
					}
					else
						*(psmoothed+itemp)+=minValueInCurSeries;
					itemp++;
				}
	}
	/* 
	long volumesize=imageWidth*imageHeight*imageAmount;
	for(itemp=0;itemp<volumesize;itemp++)
		if(!((*(directionOfData + itemp))&0x80))
			*(psmoothed+itemp)=*(inputData + itemp);
		else
			*(psmoothed+itemp)=-100;
	[self enhanceInputData:psmoothed];*/
	
	itemp=	imageSize+imageWidth+1;
	for(z=1;z<imageAmount-1;z++)
	{
		for(y=1;y<imageHeight-1;y++)
		{
			for(x=1;x<imageWidth-1;x++)
			{
				if(!((*(directionOfData + itemp))&0x80))
				{
					
					pointerToUpper = ((*(directionOfData + itemp))&0x3f);
					
					
					int xx,yy,zz,iitemp,ipointer;
					if(pointerToUpper==0)
						continue;
					switch(pointerToUpper)
					{
						case 1: iitemp =  (-imageSize-imageWidth-1);
							break;
						case 2: iitemp =  (-imageSize-imageWidth);
							break;
						case 3: iitemp = (-imageSize-imageWidth+1);
							break;
						case 4: iitemp = (-imageSize-1);
							break;
						case 5: iitemp = (-imageSize);
							break;
						case 6: iitemp = (-imageSize+1);
							break;
						case 7: iitemp = (-imageSize+imageWidth-1);
							break;
						case 8: iitemp = (-imageSize+imageWidth);
							break;
						case 9: iitemp = (-imageSize+imageWidth+1);
							break;
						case 10: iitemp = (-imageWidth-1);
							break;
						case 11: iitemp = (-imageWidth);
							break;
						case 12: iitemp = (-imageWidth+1);
							break;
						case 13: iitemp = (-1);
							break;
						case 14: iitemp = 0;
							break;
						case 15: iitemp = 1;
							break;
						case 16: iitemp = imageWidth-1;
							break;
						case 17: iitemp = imageWidth;
							break;
						case 18: iitemp = imageWidth+1;
							break;
						case 19: iitemp = imageSize-imageWidth-1;
							break;
						case 20: iitemp = imageSize-imageWidth;
							break;
						case 21: iitemp = imageSize-imageWidth+1;
							break;
						case 22: iitemp = imageSize-1;
							break;
						case 23: iitemp = imageSize;
							break;
						case 24: iitemp = imageSize+1;
							break;
						case 25: iitemp = imageSize+imageWidth-1;
							break;
						case 26: iitemp = imageSize+imageWidth;
							break;
						case 27: iitemp = imageSize+imageWidth+1;
							break;
					}
					
					
					iitemp+=itemp;
					maxUpper =  *(psmoothed+iitemp);
					currentLength = *(distanceMap + itemp);
					iitemp=itemp-imageSize-imageWidth-1;
					ipointer=1;
					needchangedis=0;
					for(zz=-1;zz<2;zz++)
					{
						for(yy=-1;yy<2;yy++)
						{
							for(xx=-1;xx<2;xx++)
							{
								if(*(distanceMap+iitemp)>1)
								{
									if((*(distanceMap+iitemp)<currentLength))
									{
										tempfloat=*(psmoothed+iitemp);
										
										if(tempfloat>maxUpper)
										{
											maxUpper=tempfloat;

											//optmize the local pointer
											pointerToUpper=ipointer;
											needchangedis=0;
										}
									}
									
									else if((*(distanceMap+iitemp)==currentLength)&&itemp!=iitemp)
									{
										tempfloat=*(psmoothed+iitemp);
										if(tempfloat>maxUpper&&tempfloat>*(psmoothed+itemp))
										{
											maxUpper=tempfloat;
											
											//optmize the local pointer
											pointerToUpper=ipointer;
											needchangedis=1;
										}
									}
									/*
									else if((*(distanceMap+iitemp)==currentLength+1)&&(*(directionOfData+iitemp)+ipointer!=28))
									{
										tempfloat=*(psmoothed+iitemp);
										if(tempfloat>maxUpper&&tempfloat>*(psmoothed+itemp))
										{
											int deepth=0;
											if(![self checkForCircle:iitemp:itemp:&deepth])
											{
												maxUpper=tempfloat;
												
												//optmize the local pointer
												pointerToUpper=ipointer;
												needchangedis=2;
											}
										}
									}*/
									
									
								}
								iitemp++;
								ipointer++;

							}
							iitemp=iitemp-3+imageWidth;
						}
						iitemp=iitemp-imageWidth-imageWidth-imageWidth+imageSize;
						
					}
					*(distanceMap + itemp)=currentLength+needchangedis;		
					*(directionOfData + itemp)=pointerToUpper;					
				}
				itemp++;
				
			}
			itemp=itemp+2;
			
					
		}
		itemp=itemp+imageWidth+imageWidth;
		
	}
	
}

- (int) enhanceInputData:(float *)inData
{
	
		
	long size = sizeof(float) * imageWidth * imageHeight * imageAmount;
	
	
	//float* inputData=[originalViewController volumePtr:0];
	
	// edge preserving smooth filter part
	
	// Input image
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
	spacing[0] = xSpacing; // along X direction
	spacing[1] = ySpacing; // along Y direction
	spacing[2] = zSpacing; // along Z direction
	importFilter->SetSpacing( spacing ); 
	
	const bool importImageFilterWillOwnTheBuffer = false;
	importFilter->SetImportPointer( inData, itksize[0] * itksize[1] * itksize[2], importImageFilterWillOwnTheBuffer);
	NSLog(@"ITK Image allocated");
	
	
	HessianFilterType::Pointer hessianFilter = HessianFilterType::New();
	VesselnessMeasureFilterType::Pointer vesselnessFilter =	VesselnessMeasureFilterType::New();
	
	hessianFilter->SetInput( importFilter->GetOutput() );
	hessianFilter->SetSigma(5);
	vesselnessFilter->SetInput( hessianFilter->GetOutput() );
	vesselnessFilter->SetAlpha1(0.5);
	vesselnessFilter->SetAlpha2(2.0);
	try
	{
		vesselnessFilter->Update();
	}
	catch( itk::ExceptionObject & excep )
	{
		return 1;
	}
	float* enhanceOutput=vesselnessFilter->GetOutput()->GetBufferPointer();
	memcpy(inData, enhanceOutput, size);
	
	
	return 0;
	
	
}

-(BOOL)checkForCircle:(int)pointer:(int)targetindex:(int*)deepth
{
	(*deepth)++;
	if(*deepth>4)
		return NO;
	int direction=*(directionOfData+pointer)&0x3f;
	if(direction)
	{
		int itemp;
		switch(direction)
		{
			case 1: itemp =  (-imageSize-imageWidth-1);
				break;
			case 2: itemp =  (-imageSize-imageWidth);
				break;
			case 3: itemp = (-imageSize-imageWidth+1);
				break;
			case 4: itemp = (-imageSize-1);
				break;
			case 5: itemp = (-imageSize);
				break;
			case 6: itemp = (-imageSize+1);
				break;
			case 7: itemp = (-imageSize+imageWidth-1);
				break;
			case 8: itemp = (-imageSize+imageWidth);
				break;
			case 9: itemp = (-imageSize+imageWidth+1);
				break;
			case 10: itemp = (-imageWidth-1);
				break;
			case 11: itemp = (-imageWidth);
				break;
			case 12: itemp = (-imageWidth+1);
				break;
			case 13: itemp = (-1);
				break;
			case 14: itemp = 0;
				break;
			case 15: itemp = 1;
				break;
			case 16: itemp = imageWidth-1;
				break;
			case 17: itemp = imageWidth;
				break;
			case 18: itemp = imageWidth+1;
				break;
			case 19: itemp = imageSize-imageWidth-1;
				break;
			case 20: itemp = imageSize-imageWidth;
				break;
			case 21: itemp = imageSize-imageWidth+1;
				break;
			case 22: itemp = imageSize-1;
				break;
			case 23: itemp = imageSize;
				break;
			case 24: itemp = imageSize+1;
				break;
			case 25: itemp = imageSize+imageWidth-1;
				break;
			case 26: itemp = imageSize+imageWidth;
				break;
			case 27: itemp = imageSize+imageWidth+1;
				break;
		}
		
		itemp+=pointer;
		if(targetindex==itemp)
			return YES;
		else
			return [self checkForCircle:itemp:targetindex:deepth];

	}
	else
		return NO;
	
}
-(int)dungbeetleSearching:(NSMutableArray*)apath:(float*)weightmap Pointer:(unsigned char*) pPointers
{

	CMIV3DPoint* apoint;
	outputData=weightmap;
	apoint=[apath objectAtIndex:0];
	directionOfData=pPointers;
	int x,y,z;
	x=[apoint x];
	y=[apoint y];
	z=[apoint z];
	int firstpoint,lastpoint,nextneighbor;
	int itemp=z*imageWidth*imageHeight+y*imageWidth+x;
	int locmaxindex1=[self searchLocalMaximum:itemp];
	int locmaxindex2=locmaxindex1;

	nextneighbor=itemp;
	while (locmaxindex2==locmaxindex1&&(!(directionOfData[nextneighbor]&0x80))) 
	{
		

		nextneighbor=[self findNextUpperNeighborInDirectionMap:nextneighbor];
		locmaxindex2=[self searchLocalMaximum:nextneighbor];
		
		
	}
	
	while (!(directionOfData[nextneighbor]&0x80)) 
	{
		firstpoint=lastpoint=nextneighbor;
		locmaxindex1=locmaxindex2=[self searchLocalMaximum:nextneighbor];
		while (locmaxindex2==locmaxindex1&&(!(directionOfData[nextneighbor]&0x80))) 
		{
			
			lastpoint=nextneighbor;
			nextneighbor=[self findNextUpperNeighborInDirectionMap:nextneighbor];
			locmaxindex2=[self searchLocalMaximum:nextneighbor];
			
			
		}
		
		NSMutableArray* firsthalfpath=[self pathToLocalMaximun:firstpoint reverse:NO];
	
		NSMutableArray* lasthalfpath=[self pathToLocalMaximun:lastpoint reverse:YES];
		if([firsthalfpath count])
			[firsthalfpath removeLastObject];
		NSArray*newpath=[firsthalfpath arrayByAddingObjectsFromArray:lasthalfpath];
		if([newpath count])
			[apath addObjectsFromArray:newpath];
		[firsthalfpath release];
		[lasthalfpath release];
		
		
	}
	unsigned i;
	for(i=1;i<[apath count]-1;i++)
	{
		apoint=[apath objectAtIndex:i-1];
		x=[apoint x];
		y=[apoint y];
		z=[apoint z];
		firstpoint=z*imageWidth*imageHeight+y*imageWidth+x;
		apoint=[apath objectAtIndex:i+1];
		x=[apoint x];
		y=[apoint y];
		z=[apoint z];
		lastpoint=z*imageWidth*imageHeight+y*imageWidth+x;
		if([self ifTwoPointsIsNeighbors:firstpoint:lastpoint])
		{
			[apath removeObjectAtIndex:i];
			i--;
		}
	}
	for(i=0;i<[apath count];i++)
	{
		apoint=[apath objectAtIndex:i];
		x=[apoint x];
		y=[apoint y];
		z=[apoint z];
		lastpoint=z*imageWidth*imageHeight+y*imageWidth+x;
		if(directionOfData)
			directionOfData[lastpoint]=(directionOfData[lastpoint]&0x3f)|0x40;

	}
	
	return lastpoint;
	
	
}
-(int)findNextUpperNeighborInDirectionMap:(int)index
{
	index+=[self onedimensionIndexLookUp:(int)(directionOfData[index]&0x3f)];
	return index;
}
-(void)refineCenterline:(NSMutableArray*)apath:(float*)weightmap
{
	CMIV3DPoint* startpoint;
	CMIV3DPoint* endpoint;
	CMIV3DPoint* apoint;
	outputData=weightmap;
	startpoint=endpoint=apoint=[apath objectAtIndex:0];
	int x,y,z;
	x=[startpoint x];
	y=[startpoint y];
	z=[startpoint z];
	int startindex=0,endindex=1;
	int itemp=z*imageWidth*imageHeight+y*imageWidth+x;
	int locmaxindex1=[self searchLocalMaximum:itemp];
	int locmaxindex2=locmaxindex1;
	int isneighbors=0;
	while (locmaxindex2==locmaxindex1&&endindex<(signed)[apath count]) 
	{
		
		endpoint=apoint;
		apoint=[apath objectAtIndex:endindex];
		x=[apoint x];
		y=[apoint y];
		z=[apoint z];
		itemp=z*imageWidth*imageHeight+y*imageWidth+x;
		locmaxindex2=[self searchLocalMaximum:itemp];
		endindex++;

	}
	
	while(endindex<(signed)[apath count])
	{
		startpoint=endpoint=apoint;
		endindex=[apath indexOfObject:endpoint]+1;
		x=[apoint x];
		y=[apoint y];
		z=[apoint z];
		itemp=z*imageWidth*imageHeight+y*imageWidth+x;
		locmaxindex1=locmaxindex2=[self searchLocalMaximum:itemp];
		while ((isneighbors=[self ifTwoPointsIsNeighbors:locmaxindex1:locmaxindex2])&&(endindex<(signed)[apath count])) 
		{
			
			endpoint=apoint;
			apoint=[apath objectAtIndex:endindex];
			x=[apoint x];
			y=[apoint y];
			z=[apoint z];
			itemp=z*imageWidth*imageHeight+y*imageWidth+x;
			locmaxindex2=[self searchLocalMaximum:itemp];
			endindex++;
			
		}
		if(endindex<(signed)[apath count])
		{
			startindex=[apath indexOfObject:startpoint];
			x=[startpoint x];
			y=[startpoint y];
			z=[startpoint z];
			itemp=z*imageWidth*imageHeight+y*imageWidth+x;
			NSMutableArray* firsthalfpath=[self pathToLocalMaximun:itemp reverse:NO];
			endindex=[apath indexOfObject:endpoint];
			x=[endpoint x];
			y=[endpoint y];
			z=[endpoint z];
			itemp=z*imageWidth*imageHeight+y*imageWidth+x;
			NSMutableArray* lasthalfpath=[self pathToLocalMaximun:itemp reverse:YES];
			if(isneighbors==1)
				[firsthalfpath removeLastObject];
			NSArray*newpath=[firsthalfpath arrayByAddingObjectsFromArray:lasthalfpath];
			NSRange arange;
			arange.location=startindex;
			arange.length=endindex-startindex;
			if([newpath count]*2<3*arange.length)
				[apath replaceObjectsInRange:arange withObjectsFromArray: newpath];
			//[newpath release];
			[firsthalfpath release];
			[lasthalfpath release];
			
		}
	
	}
	int x1,y1,z1;
	apoint=[apath objectAtIndex:0];
	x1=[apoint x];
	y1=[apoint y];
	z1=[apoint z];
	unsigned i;
	for(i=1;i<[apath count];i++)
	{
		apoint=[apath objectAtIndex:i];
		x=[apoint x];
		y=[apoint y];
		z=[apoint z];
		if(x==x1&&y==y1&&z==z1)
		{
			[apath removeObjectAtIndex:i];
			i--;
		}
		x1=x;
		y1=y;
		z1=z;
		
	}

}
-(int)searchLocalMaximum:(int)index
{
	int maxindex;
	float maxweight;
	maxindex=index;
	maxweight=outputData[maxindex];
	
	do
	{
		index=maxindex;
		int i,itemp;
		for(i=1;i<28;i++)
		{
			itemp=index+[self onedimensionIndexLookUp:i];
			if(itemp>=imageSize*imageAmount||itemp<imageSize)
				continue;
			if(outputData[itemp]>maxweight)
			{
				maxweight=outputData[itemp];
				maxindex=itemp;
			}
		}
	}while(maxindex!=index);

	return maxindex;
	
}
-(NSMutableArray*) pathToLocalMaximun:(int)index reverse:(BOOL)needreverse
{
	NSMutableArray* path=[[NSMutableArray alloc] initWithCapacity:0];
	int maxindex;
	float maxweight;
	maxindex=index;
	maxweight=outputData[maxindex];
	
	do
	{
		index=maxindex;
		int x,y,z;
		z=index/imageSize;
		y=(index-z*imageSize)/imageWidth;
		x=index-z*imageSize-y*imageWidth;
		//if(directionOfData)
		//	directionOfData[index]=directionOfData[index]|0x40;
		CMIV3DPoint* apoint=[[CMIV3DPoint alloc] init];
		[apoint setX:x];
		[apoint setY:y];
		[apoint setZ:z];
		[path addObject:apoint];
		[apoint release];
		int i,itemp;
		for(i=1;i<28;i++)
		{
			itemp=index+[self onedimensionIndexLookUp:i];
			if(itemp>=imageSize*imageAmount||itemp<imageSize)
				continue;
			if(outputData[itemp]>maxweight)
			{
				maxweight=outputData[itemp];
				maxindex=itemp;
			}
		}
	}while(maxindex!=index);
	
	if(needreverse)
	{
		unsigned i;
		for(i=0;i<[path count];i++)
		{
			[path insertObject:[path lastObject] atIndex:i];
			[path removeLastObject];
		}
	}
	
	
	return path;
}
-(int)ifTwoPointsIsNeighbors:(int)index1:(int)index2
{
	int x1,x2,y1,y2,z1,z2;
	z1=index1/imageSize;
	y1=(index1-imageSize*z1)/imageWidth;
	x1=index1-z1*imageSize-y1*imageWidth;
	
	z2=index2/imageSize;
	y2=(index2-imageSize*z2)/imageWidth;
	x2=index2-z2*imageSize-y2*imageWidth;
	if((x1-x2)==0&&(y1-y2)==0&&(z1-z2)==0)
		return 1;
	else if((x1-x2)*(x1-x2)<2&&(y1-y2)*(y1-y2)<2&&(z1-z2)*(z1-z2)<2)
		return 2;
	else
		return 0;
}
-(int)onedimensionIndexLookUp:(int)direction
{
	int itemp;
	switch(direction)
	{
		case 1: itemp =  (-imageSize-imageWidth-1);
			break;
		case 2: itemp =  (-imageSize-imageWidth);
			break;
		case 3: itemp = (-imageSize-imageWidth+1);
			break;
		case 4: itemp = (-imageSize-1);
			break;
		case 5: itemp = (-imageSize);
			break;
		case 6: itemp = (-imageSize+1);
			break;
		case 7: itemp = (-imageSize+imageWidth-1);
			break;
		case 8: itemp = (-imageSize+imageWidth);
			break;
		case 9: itemp = (-imageSize+imageWidth+1);
			break;
		case 10: itemp = (-imageWidth-1);
			break;
		case 11: itemp = (-imageWidth);
			break;
		case 12: itemp = (-imageWidth+1);
			break;
		case 13: itemp = (-1);
			break;
		case 14: itemp = 0;
			break;
		case 15: itemp = 1;
			break;
		case 16: itemp = imageWidth-1;
			break;
		case 17: itemp = imageWidth;
			break;
		case 18: itemp = imageWidth+1;
			break;
		case 19: itemp = imageSize-imageWidth-1;
			break;
		case 20: itemp = imageSize-imageWidth;
			break;
		case 21: itemp = imageSize-imageWidth+1;
			break;
		case 22: itemp = imageSize-1;
			break;
		case 23: itemp = imageSize;
			break;
		case 24: itemp = imageSize+1;
			break;
		case 25: itemp = imageSize+imageWidth-1;
			break;
		case 26: itemp = imageSize+imageWidth;
			break;
		case 27: itemp = imageSize+imageWidth+1;
			break;
		default:
			//NSLog(@"point to no where");
			itemp=0;
	}
	return itemp;
}
-(void)calculateFuzzynessMap:(float*)inData Out:(float*)outData  withDirection:(unsigned char*) dData Minimum:(float)minf
{
	inputData=inData;
	outputData=outData;
	directionOfData=dData;
	minValueInCurSeries=minf;

	int i;
	int x,y,z;
	for(z=1;z<imageAmount-1;z++)
		for(y=1;y<imageHeight-1;y++)
			for(x=1;x<imageWidth-1;x++)
	
	{
		i=z*imageSize+y*imageWidth+x;
		if(directionOfData[i]&0x80)
		{
			if(directionOfData[i]&0x3f)
				outputData[i]=inputData[i];
			else
				outputData[i]=minValueInCurSeries;
			
		}
		else if(outputData[i]<minValueInCurSeries)
		{
			float upperneighborvalue=[self getUpperNeighborValueOf:i];
			outputData[i]=(upperneighborvalue>inputData[i])?inputData[i]:upperneighborvalue;
		}
	}
}
-(float)getUpperNeighborValueOf:(int)index
{
	int itemp=[self onedimensionIndexLookUp:(int)(directionOfData[index]&0x3f)];
	if(itemp)
		index+=itemp;
	else
		return minValueInCurSeries;
	if(directionOfData[index]&0x80)
	{
		if(directionOfData[index]&0x3f)
			outputData[index]=inputData[index];
		else
			outputData[index]=minValueInCurSeries;
		
	}
	else if(outputData[index]<minValueInCurSeries)
	{
		float upperneighborvalue=[self getUpperNeighborValueOf:index];
		outputData[index]=(upperneighborvalue>inputData[index])?inputData[index]:upperneighborvalue;
	}
	return outputData[index];
	
}
@end
