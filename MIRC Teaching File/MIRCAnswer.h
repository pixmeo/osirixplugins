//
//  MIRCAnswer.h
//  TeachingFile
//
//  Created by Lance Pysher on 8/18/05.
//  Copyright 2005 Macrad, LLC_. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSXMLElement (MIRCAnswer) 

+ (id)answerWithString:(NSString *)answer;
- (void)setAnswerIsCorrect: (BOOL)isCorrect;
- (void)setAnswerString:(NSString *)answer;
- (NSString *)answerString;
- (NSString *)answerResponse;
- (BOOL)answerIsCorrect;



 
@end
