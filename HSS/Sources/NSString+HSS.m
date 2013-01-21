//
//  NSString+HSS.m
//  HSS
//
//  Created by Alessandro Volz on 03.09.12.
//
//

#import "NSString+HSS.h"

@implementation NSString (HSS)

- (NSComparisonResult)caseDiacriticInsensitiveNumericCompare:(NSString*)str {
    return [self compare:str options:NSCaseInsensitiveSearch|NSNumericSearch|NSDiacriticInsensitiveSearch];
}

@end
