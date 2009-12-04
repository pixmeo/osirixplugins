//
//  MIRCQuestion.h
//  TeachingFile
//
//  Created by Lance Pysher on 8/13/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSXMLElement (MIRCQuestion) 

+ (id)questionWithString:(NSString *)question;
- (NSArray *)answers;
- (void)addAnswer:(NSXMLElement *)answer;
- (void)setQuestionString:(NSString *)question;
- (NSString *)questionString;
- (void)setAnswers:(NSArray *)answers;

 


@end
