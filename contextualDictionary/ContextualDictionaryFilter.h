//
//  ContextualDictionaryFilter.h
//  ContextualDictionary
//
//  Copyright (c) 2007 jacques.fauquex@opendicom.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@interface ContextualDictionaryFilter : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;

@end
