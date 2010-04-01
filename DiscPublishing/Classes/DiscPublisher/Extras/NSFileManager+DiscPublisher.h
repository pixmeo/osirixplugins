//
//  NSFileManager+DiscPublisher.h
//  Primiera
//
//  Created by Alessandro Volz on 2/22/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSFileManager (DiscPublisher)

-(NSString*)findSystemFolderOfType:(int)folderType forDomain:(int)domain;
-(NSString*)tmpFilePathInDir:(NSString*)dirPath;
-(NSString*)tmpFilePathInTmp;
-(NSString*)confirmDirectoryAtPath:(NSString*)dirPath;
-(NSUInteger)sizeAtPath:(NSString*)path;
-(NSUInteger)sizeAtFSRef:(FSRef*)theFileRef;
	
@end
