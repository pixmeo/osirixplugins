//
//  MEDACTATemplate.mm
//  Arthroplasty Templating II
//
//  Created by Alessandro Volz on 07.09.09.
//  Copyright (c) 2009 OsiriX Team. All rights reserved.
//

#import "MEDACTATemplate.h"

@implementation MEDACTATemplate

+(NSArray*)bundledTemplates {
	return [self templatesAtPath:[[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"MEDACTA Templates"] usingClass:[self class]];
}

+(NSArray*)templatesAtPath:(NSString*)path {
	return [ZimmerTemplate templatesAtPath:path usingClass:[self class]];
}

@end
