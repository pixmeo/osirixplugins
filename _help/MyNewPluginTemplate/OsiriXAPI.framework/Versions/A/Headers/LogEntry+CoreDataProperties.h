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

#import "LogEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface LogEntry (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *destinationName;
@property (nullable, nonatomic, retain) NSString *destinationPort;
@property (nullable, nonatomic, retain) NSString *message;
@property (nullable, nonatomic, retain) NSString *destinationHostname;
@property (nullable, nonatomic, retain) NSString *originName;
@property (nullable, nonatomic, retain) NSString *originHostname;
@property (nullable, nonatomic, retain) NSString *type;
@property (nullable, nonatomic, retain) NSString *studyName;
@property (nullable, nonatomic, retain) NSNumber *numberError;
@property (nullable, nonatomic, retain) NSString *patientName;
@property (nullable, nonatomic, retain) NSNumber *numberPending;
@property (nullable, nonatomic, retain) NSDate *endTime;
@property (nullable, nonatomic, retain) NSNumber *numberImages;
@property (nullable, nonatomic, retain) NSNumber *numberSent;
@property (nullable, nonatomic, retain) NSDate *startTime;
@property (nullable, nonatomic, retain) NSString *originPort;
@property (nullable, nonatomic, retain) NSString *status;

@end

NS_ASSUME_NONNULL_END
