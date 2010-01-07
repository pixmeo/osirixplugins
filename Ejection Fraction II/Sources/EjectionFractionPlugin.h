//
//  EjectionFraction.h
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 7/20/09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import <OsiriX Headers/PluginFilter.h>
#import "EjectionFractionAlgorithm.h"

extern NSString* EjectionFractionAlgorithmAddedNotification;
extern NSString* EjectionFractionAlgorithmRemovedNotification;

@interface EjectionFractionPlugin : PluginFilter {
	NSMutableArray* _wfs;
	NSMutableArray* _algorithms;
}

@property(readonly) NSArray* algorithms;

+(NSColor*)diasColor;
+(NSColor*)systColor;

-(void)addAlgorithm:(EjectionFractionAlgorithm*)algorithm;
-(void)removeAlgorithm:(EjectionFractionAlgorithm*)algorithm;	

@end
