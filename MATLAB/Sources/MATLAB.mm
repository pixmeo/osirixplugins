//
//  MATLABEngine.mm
//  Mindstorming
//
//  Created by Alessandro Volz on 21.12.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "MATLAB.h"
#import <OsiriX Headers/DCMPix.h>
#include <dlfcn.h>

@implementation MATLAB
@synthesize engine = _engine;

-(id)init {
	return [self initWithPath:[[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"MATLAB"]];
}

-(id)initWithPath:(NSString*)path {
	self = [super init];
	
	if (!dlopen("/Applications/MATLAB_R2008a/bin/maci/libeng.dylib", RTLD_NOW))
		[NSException raise:NSGenericException format:[NSString stringWithCString:dlerror() encoding:NSUTF8StringEncoding]];
	if (!dlopen("/Applications/MATLAB_R2008a/bin/maci/libmx.dylib", RTLD_NOW))
		[NSException raise:NSGenericException format:[NSString stringWithCString:dlerror() encoding:NSUTF8StringEncoding]];
	
	if (!(_engine = engOpen("/Applications/MATLAB_R2008a/bin/matlab")))
		[NSException raise:NSGenericException format:@"Can't start MATLAB engine"];
	
	// TODO: make /Applications/MATLAB_R2008a/ a variable, evtl autodetect anything matching MATLAB* in /Applications
	
	[self evalString:[NSString stringWithFormat:@"addpath('%@')", [MATLAB quote:path]]];
	
	return self;
}

-(void)dealloc {
	engClose(_engine);
	[super dealloc];
}

+(NSString*)quote:(NSString*)string {
	string = [string stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
	string = [string stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
	return string;
}

-(void)putMxArray:(mxArray*)mx name:(NSString*)name {
	int e = engPutVariable(_engine, [name UTF8String], mx);
	if (e) [NSException raise:NSGenericException format:@"MATLAB put variable failed with error %d", e];
}

-(void)putDCMPix:(DCMPix*)pix name:(NSString*)name {
	mwSize dims[] = {[pix pheight], [pix pwidth]};
	mxArray* mx = mxCreateNumericArray(2, dims, mxSINGLE_CLASS, mxREAL);
	float* mxp = (float*)mxGetPr(mx);

	int i = 0;
	for (mwSize d1 = 0; d1 < dims[1]; d1++) // x
		for (mwSize d0 = 0; d0 < dims[0]; d0++) // y
			mxp[i++] = [pix getPixelValueX:d1 Y:d0];
	
	[self putMxArray:mx name:name];
}

-(mxArray*)getMxArray:(NSString*)name {
	return engGetVariable(_engine, [name UTF8String]);
}

-(DCMPix*)getDCMPix:(NSString*)name {
	mxArray* mx = [self getMxArray:name];
	
	if (mxGetNumberOfDimensions(mx) != 2)
		[NSException raise:NSGenericException format:@"Invalid number of dimensions in mxArray for DCMPix"];
	const mwSize* dims = mxGetDimensions(mx);
	
	size_t pixelsCount = dims[0]*dims[1];
	float* pixelData = (float*)malloc(pixelsCount*sizeof(float));
	switch (mxGetClassID(mx)) {
		case mxDOUBLE_CLASS: {
			const double* mxData = mxGetPr(mx);
			for (mwSize d1 = 0; d1 < dims[1]; d1++)
				for (mwSize d0 = 0; d0 < dims[0]; d0++)
					pixelData[d1*dims[0]+d0] = mxData[d0*dims[1]+d1];
		} break;
		case mxSINGLE_CLASS: {
			const float* mxData = (float*)mxGetPr(mx);
			for (mwSize d1 = 0; d1 < dims[1]; d1++)
				for (mwSize d0 = 0; d0 < dims[0]; d0++)
					pixelData[d1*dims[0]+d0] = mxData[d0*dims[1]+d1];
		} break;
		default: [NSException raise:NSGenericException format:@"Invalid mxClassID for DCMPix"];
	}
	
	DCMPix* pix = [[DCMPix alloc] initWithData:pixelData :32 :dims[1] :dims[0] :dims[1] :dims[0] :0 :0 :0 :YES];
	[pix freefImageWhenDone:YES];
	
	mxDestroyArray(mx);
	return [pix autorelease];
}

-(void)evalString:(NSString*)string {
	int e = engEvalString(_engine, [string UTF8String]);
	if (e) [NSException raise:NSGenericException format:@"MATLAB eval string failed with error %d", e];
}

@end
