//
//  MIRCQuiz.h
//  TeachingFile
//
//  Created by Lance Pysher on 8/13/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSXMLElement (MIRCQuiz) 


+ (id)quiz;

- (NSArray *)questions;
- (void)addQuestion:(NSXMLElement *)question;
- (void)setQuestions:(NSArray *)questions;

@end
