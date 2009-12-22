//
//  EjectionFraction.h
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 7/20/09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import <OsiriX Headers/PluginFilter.h>

@interface MATLABPlugin : PluginFilter {
	NSTimer* _timer;
	NSLock* _lock;
	NSMutableArray* _series;
}

@end
