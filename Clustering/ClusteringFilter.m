//
//  ClusteringFilter.m
//  Clustering
//
//  Copyright (c) 2006 Arnaud. All rights reserved.
//

#import "ClusteringFilter.h"

@class ClusteringController;

@implementation ClusteringFilter

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{	
	ClusteringController *cluster = [[ClusteringController alloc] init];
	[cluster showWindow:self];
	return 0;
}

@end
