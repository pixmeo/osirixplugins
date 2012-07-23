//
//  AuditTrailRecord.h
//  AuditTrailServer
//
//  Created by Joël Spaltenstein on 7/8/12.
//  Copyright (c) 2012 Spaltenstein Natural Image. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface AuditTrailRecord : NSManagedObject

@property (nonatomic, retain) NSString * clientIP;
@property (nonatomic, retain) NSString * action;
@property (nonatomic, retain) NSString * userName;
@property (nonatomic, retain) NSString * patientName;
@property (nonatomic, retain) NSString * note;
@property (nonatomic, retain) NSDate * reportDate;

@end
