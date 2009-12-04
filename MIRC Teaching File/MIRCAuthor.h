//
//  MIRCAuthor.h
//  TeachingFile
//
//  Created by Lance Pysher on 8/10/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MIRCAuthor : NSXMLElement{

}
+ (id)author;


@end

@interface NSXMLElement (AuthorCategory) 

- (NSString *)authorName;
- (void)setAuthorName:(NSString *)authorName;
- (NSString *)affiliation;
- (void)setAffiliation:(NSString *)affiliation;
- (NSArray *)contacts;
- (void)setContacts:(NSArray *)contacts;
- (NSString *)email;
- (void)setEmail:(NSString *)email;
- (NSString *)phone;
- (void)setPhone:(NSString *)phone;
- (NSString *)address1;
- (void)setAddress1:(NSString *)address;
- (NSString *)address2;
- (void)setAddress2:(NSString *)address;

@end
