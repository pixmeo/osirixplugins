//
//  MEDACTATemplate.mm
//  Arthroplasty Templating II
//
//  Created by Alessandro Volz on 07.09.09.
//  Copyright (c) 2009 OsiriX Team. All rights reserved.
//

#import "MEDACTATemplate.h"

@implementation MEDACTATemplate

+(NSArray*)templatesAtPath:(NSString*)path {
	return [ZimmerTemplate templatesAtPath:path usingClass:[self class]];
}

@end
