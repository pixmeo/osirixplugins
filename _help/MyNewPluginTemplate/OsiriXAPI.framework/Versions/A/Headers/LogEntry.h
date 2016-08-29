/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface LogEntry : NSManagedObject

- (NSString *) countryDestinationHostname;
- (NSString *) countryOriginHostname;
- (NSString *) countryOriginName;

@end

NS_ASSUME_NONNULL_END

#import "LogEntry+CoreDataProperties.h"
