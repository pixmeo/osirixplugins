//
//  FAWebPostQuery.h
//  TeachingFile
//
//  Created by Lance Pysher on 3/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


//
//  FAWebPostQuery.h
//


#import <Foundation/Foundation.h>
enum {
   FAWebPostIncomplete = -1,
   FAWebPostNotReplied = -2,
   FAWebPostReplyInProgress = -3,
   FAWebPostInvalid = -4,
   FAWebPostTimedOut = -5
};

/*
FAWebPostAlreadyPosted
An exception that is thrown if an attempt is made to dispatch an FAWebPostQuery that has already sent 
its query.
*/
extern NSString * const   FAWebPostAlreadyPosted;
class FAWebPostQuery
@interface FAWebPostQuery : NSObject {
   CFHTTPMessageRef            message;
   CFReadStreamRef            replyStream;
   NSMutableDictionary *   postData;
   int                              statusCode;
   CFMutableStringRef         cfReplyContent;
   NSTimer *                     timeoutTimer;
   NSObject *                     delegate;
   CFStreamClientContext   cfContext;
}
- (id) initWithServerURL: (NSURL *) server;
- (id) initWithServerURL: (NSURL *) server 
                     postData: (NSDictionary *) initialData;
- (void) setPostString: (NSString *) string
                        forKey: (NSString *) key;
- (void) post;
- (void) cancel;
- (int) statusCode;
- (NSString *) replyContent;
- (NSObject *) delegate;
- (void) setDelegate: (NSObject *) aDelegate;
@end

/*
FAWebPostDelegate
This is an informal protocol that must be implemented by any object that is passed to the 
setDelegate: method of an FAWebPostQuery. It declares the signature of the callback message that is 
sent to the delegate object when the query either completes or fails.
*/
@interface NSObject (FAWebPostDelegate)
- (void) webPostQuery: (FAWebPostQuery *) query
   completedWithResult: (int) code;
@end
