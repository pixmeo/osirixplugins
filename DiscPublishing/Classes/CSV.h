//
//  CSV.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 4/14/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CSV : NSObject {
}

+(NSString*)quote:(NSString*)str;
+(NSString*)stringFromArray:(NSArray*)array;

@end
