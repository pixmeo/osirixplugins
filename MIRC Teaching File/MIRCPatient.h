//
//  MIRCPatient.h
//  TeachingFile
//
//  Created by Lance Pysher on 8/12/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface  NSXMLElement  (MIRCPatient)

 + (id)patient;

 - (NSString *)patientAge;
 - (void)setPatientAge:(NSString *)age;
 /*
 - (NSString *ageType;
 - (void)setAgeType:(NSString *) type;
*/ 
 - (NSString *)sex;
 - (void)setSex:(NSString *)sex;
 
 - (NSString *)race;
 - (void)setRace:(NSString *)race;
 

@end
