//
//  CMIVBuketPirortyQueue.m
//  CMIV_CTA_TOOLS
//
//  Created by chuwa on 3/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CMIVBuketPirortyQueue.h"


@implementation CMIVBuketPirortyQueue
- (id) initWithParameter: (long) costrange :(long) imageSize
{
	self=[super init];
	buketNumber=costrange;
	listSize=imageSize;
	qBukets=(long*)malloc(costrange*sizeof(long));
	biList=(long*)malloc(2*listSize*sizeof(long));
	[self cleanQueue];

	return self;
}
- (void) dealloc
{
	if(qBukets) free(qBukets);
	if(biList) free(biList);
	
	[super dealloc];
}
-(void)push:(long )item: (long )stepcost
{
	long curnextpt;
	long buketpt;
	buketpt=(curBuket+stepcost)%buketNumber;
	curnextpt=qBukets[buketpt];
	qBukets[buketpt]=item;
	biList[item+item]=-2-buketpt;
	biList[item+item+1]=curnextpt;
}
-(long)pop
{
	long testBuket=curBuket;
	long item=-1;
	long nextitem;
	do{
		if(qBukets[testBuket]==-1)
		{
			testBuket=(testBuket+1)%buketNumber;
		}
		else
		{
			item=qBukets[testBuket];	
			nextitem=biList[item+item+1];
			if(nextitem!=-1)
				biList[nextitem+nextitem]=biList[item+item];
			qBukets[testBuket]=nextitem;
			
			biList[item+item]=-1;
			biList[item+item+1]=-1;

			curBuket=testBuket;
		}
	}while(testBuket!=curBuket);
	return item;
}
-(void)update:(long )item: (long )stepcost
{
	long preitem,nextitem;
	preitem=biList[item+item];
	nextitem=biList[item+item+1];
	if(preitem!=-1)
	{
		if(preitem>=0)
		{
			biList[preitem+preitem+1]=nextitem;
		}
		else
		{
			qBukets[-preitem-2]=nextitem;
		}
		if(nextitem>=0)
		{
			biList[nextitem+nextitem]=preitem;
		}
		biList[item+item]=-1;
		biList[item+item+1]=-1;
	}
	[self push:item:stepcost];
	
}
-(void)cleanQueue
{
	curBuket=0;
	long i;
	for(i=0;i<listSize*2;i++)
		biList[i]=-1;
	for(i=0;i<buketNumber;i++)
		qBukets[i]=-1;
}
-(void)finalize
{
	if(qBukets) free(qBukets);
	if(biList) free(biList);
	
	[super finalize];
}
@end
