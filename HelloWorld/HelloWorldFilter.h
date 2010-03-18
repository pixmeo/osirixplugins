//
//  HelloWorldFilter.h
//  HelloWorld
//
//  Copyright (c) 2008 Joris Heuberger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriX Headers/PluginFilter.h>

@interface HelloWorldFilter : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;

- (void) loopTroughImages;

@end
