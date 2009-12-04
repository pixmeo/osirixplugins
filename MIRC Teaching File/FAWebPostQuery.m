//
//  FAWebPostQuery.m
//  TeachingFile
//
//  Created by Lance Pysher on 3/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "FAWebPostQuery.h"
#import   "httpFlattening.h"
#define   READ_SIZE         1024
NSString * const   FAWebPostAlreadyPosted
               = @"FAWebPostAlreadyPosted";
static CFTimeInterval   sPostTimeout = 15.0;
//   A template for HTTP stream-client contexts
static CFStreamClientContext   sContext = {
   0, nil,
   CFClientRetain, 
   CFClientRelease, 
   CFClientDescribeCopy
};
   
class FAWebPostQuery
@implementation FAWebPostQuery

/*
timeoutInterval
A class method that returns the interval, in seconds, after which an HTTP connection is considered to 
have timed out. When a query is posted, the reply must begin arriving within this time interval, and 
gaps between batches of data may not last longer. If the timer runs out, the connection is closed and 
the query fails with the error status FAWebPostTimedOut.
*/

+ (CFTimeInterval) timeoutInterval
{ return sPostTimeout; }

/*
setTimeoutInterval
Sets the length, in seconds, for all timeout intervals beginning after this class method is called.
*/

+ (void) setTimeoutInterval: (CFTimeInterval) newInterval
{
   sPostTimeout = newInterval;
}

/*
CFClientRetain
A glue function bridging the Objective-C FAWebPostQuery object to Core Foundation. A pointer to this 
function goes into the retain field of the client context for the HTTP CFStream that services the 
reply to the query.
*/
void *
CFClientRetain(void *   selfPtr)
{
   FAWebPostQuery *   object
            = (FAWebPostQuery *) selfPtr;
            
   return [object retain];
}

/*
CFClientRelease
A glue function bridging the Objective-C FAWebPostQuery object to Core Foundation. A pointer to this 
function goes into the release field of the client context for the HTTP CFStream that services the
reply to the query.
*/

void
CFClientRelease(void *   selfPtr)
{
   FAWebPostQuery *   object
            = (FAWebPostQuery *) selfPtr;
            
   [object release];
}

/*
CFClientDescribeCopy
A glue function bridging the Objective-C FAWebPostQuery object to Core Foundation. A pointer to this 
function goes into the copyDescription field of the client context for the HTTP CFStream that 
services the reply to the query.
*/

CFStringRef
CFClientDescribeCopy(void *   selfPtr)
{
   FAWebPostQuery *   object
            = (FAWebPostQuery *) selfPtr;
            
   return (CFStringRef) [[object description] retain];
}

/*
getResultCode
An internal-use method, called when the reply stream has indicated that it has either finished or 
experienced a fatal error. Retrieves the http header from the reply stream, if possible, and the 
http result code from the header. Sets the FAWebPostQuery's status code to the result code.
*/

- (void) getResultCode
{
   if (replyStream) {
      //   Get the reply headers
      CFHTTPMessageRef   reply =
         (CFHTTPMessageRef) CFReadStreamCopyProperty(
            replyStream,
            kCFStreamPropertyHTTPResponseHeader);
                  
      //   Pull the status code from the headers
      if (reply) {
         statusCode = 
            CFHTTPMessageGetResponseStatusCode(reply);
         CFRelease(reply);
      }
   }
}

/*
closeOutMessaging
An internal-use method, called when the CFReadStream that manages the queery reply is no longer 
needed--either because the whole reply has been received or because the request has failed. This 
method tears down the stream, the original POST query, and the timeout timer.
*/

- (void) closeOutMessaging
{
   if (replyStream) {
      //   Close the read stream.
      CFReadStreamClose(replyStream);
      //   Deregister the callback client (learned this from WWDC session 805)
      CFReadStreamSetClient(replyStream, 0, NULL, NULL);
      //   Take the stream out of the run loop
      CFReadStreamUnscheduleFromRunLoop(
               replyStream,
               CFRunLoopGetCurrent(),
               kCFRunLoopCommonModes);
      //   Deallocate the stream pointer
      CFRelease(replyStream);
      //   Throw the spent pointer away
      replyStream = NULL;
   }
   
   if (timeoutTimer) {
      [timeoutTimer invalidate];
      [timeoutTimer release];
      timeoutTimer = nil;
   }
}

/*
informDelegateOfCompletion
This method gets called when the query has completed, successfully or not, after the network streams 
have been torn down. If this object's client has set a delegate, inform the delegate of completion 
through the method webPostQuery:completedWithResult:.
*/


- (void) informDelegateOfCompletion
{
   if (delegate) {
      NSAssert(
         [delegate respondsToSelector:
            @selector(webPostQuery:completedWithResult:)],
         @"A web-POST query delegate must implement "
         @"webPostQuery:completedWithResult:");
      [delegate webPostQuery: self 
         completedWithResult: statusCode];
   }
}

/*
appendContentCString:
An internal method called by MyReadCallback. It appends the C string it is passed to the 
CFMutableString that keeps the body of the reply to the query. Passing this message sets this 
object's status to in-progress, and restarts the timeout timer.
*/

- (void) appendContentCString: (char *) cString
{
   CFStringAppendCString(cfReplyContent,
                                 cString,
                                 kCFStringEncodingASCII);
statusCode = FAWebPostReplyInProgress;
   //   Refresh the timeout timer.
   [timeoutTimer setFireDate:
         [NSDate dateWithTimeIntervalSinceNow:
                     sPostTimeout]];
}

/*
MyReadCallback
This is the registered event callback for the CFReadStream that manages sending the query and 
receiving the reply. If data has arrived in the reply, the data is taken from the stream and 
accumulated. If the transaction ends because of error or success, a final result code is set, 
the CFReadStream is torn down, and the registered client, if any is informed.*
*/

void
MyReadCallback(CFReadStreamRef   stream,
                               CFStreamEventType   type,
                               void *            userData)
{
   FAWebPostQuery *   object = 
                     (FAWebPostQuery *) userData;
   
   switch (type) {
   case kCFStreamEventHasBytesAvailable: {
      UInt8      buffer[READ_SIZE];
      CFIndex   bytesRead = CFReadStreamRead(stream,
                                                 buffer, READ_SIZE-1);
      //   leave 1 byte for a trailing null.
      
      if (bytesRead > 0) {
         //   Convert what was read to a C-string
         buffer[bytesRead] = 0;
         //   Append it to the reply string
         [object appendContentCString: buffer];
      }      
   }
      break;
   case kCFStreamEventErrorOccurred:
   case kCFStreamEventEndEncountered:
      [object getResultCode];
      [object closeOutMessaging];
      [object informDelegateOfCompletion];
      break;
   default:
      break;
   }
}

/*
messageTimedOut:
The callback for the internal timeout timer. This method gets called only in the exceptional case of 
the remote server not responding within the specified time. It's a fatal error, and causes the 
connection to be torn down and the delegate (if any) notified.
*/

- (void) messageTimedOut: (NSTimer *) theTimer
{
   statusCode = FAWebPostTimedOut;
   [self closeOutMessaging];
   [self informDelegateOfCompletion];
}
- (id) initWithServerURL: (NSURL *) server
{
   return [self initWithServerURL: server postData: nil];
}
- (id) initWithServerURL: (NSURL *) server
                        postData: (NSDictionary *) initialData
{
   replyStream = NULL;
   cfReplyContent = CFStringCreateMutable(
                                       kCFAllocatorDefault, 0);
   statusCode = FAWebPostIncomplete;
   cfContext = sContext;
   cfContext.info = self;
   timeoutTimer = nil;
   if (initialData)
      postData = [[NSMutableDictionary alloc]
                              initWithDictionary: initialData];
   else
      postData = [[NSMutableDictionary alloc]
                                                initWithCapacity: 8];
   if (!postData) {
      [self release];
      return nil;
      }
   
   //   Set up the POST message and its headers
   message = CFHTTPMessageCreateRequest(
                                    kCFAllocatorDefault,
                                    CFSTR("POST"),
                                    (CFURLRef) server,
                                    kCFHTTPVersion1_1);
   if (!message) {
      [self release];
      return nil;
      }
   CFHTTPMessageSetHeaderFieldValue(message,
                        CFSTR("User-Agent"),
                        CFSTR("Generic/1.0 (Mac_PowerPC)"));
   CFHTTPMessageSetHeaderFieldValue(message,
               CFSTR("Content-Type"),
               CFSTR("application/x-www-form-urlencoded"));
   CFHTTPMessageSetHeaderFieldValue(message,
               CFSTR("Host"), (CFStringRef) [server host]);
   CFHTTPMessageSetHeaderFieldValue(message,
                        CFSTR("Accept"), CFSTR("text/html"));
   return self;
}
- (void) setPostString: (NSString *) string
                     forKey: (NSString *) key
{
   [postData setObject: string forKey: key];
}
- (void) dealloc
{
   if (message) {
      CFRelease(message);
      message = NULL;
   }
   
   [postData release];
   if (cfReplyContent) {
      CFRelease(cfReplyContent);
      cfReplyContent = NULL;
   }
   
   if (timeoutTimer) {
      [timeoutTimer invalidate];
      [timeoutTimer dealloc];
      timeoutTimer = nil;
   }
}
- (void) post
{
   if (statusCode != FAWebPostIncomplete)
      [NSException raise:   FAWebPostAlreadyPosted
            format: @"This query has already been posted "
                        @"and either answered or refused."];
   statusCode = FAWebPostNotReplied;
   //   String-out the postData dictionary
   NSString *   postString = [postData webFormEncoded];
   NSData *   postStringData = [postString
               dataUsingEncoding: kCFStringEncodingASCII
               allowLossyConversion: YES];
   //   Put the post data in the body of the query
   CFHTTPMessageSetBody(message, 
                   (CFDataRef) postStringData);
   //   Now that we know how long the query body is, put the length in the header
   CFHTTPMessageSetHeaderFieldValue(message,
                                           CFSTR("Content-Length"),
       (CFStringRef) [NSString stringWithFormat: @"%d",
                                            [postStringData length]]);
           
   //   Initialize the CFReadStream that will make the request and manage the reply
   replyStream = CFReadStreamCreateForHTTPRequest(
                                 kCFAllocatorDefault, message);
   //   I have no further business with message
   CFRelease(message);
   message = NULL;
   
   //   Register the CFReadStream's callback client
   BOOL   enqueued = CFReadStreamSetClient(replyStream,
                     kCFStreamEventHasBytesAvailable |
                        kCFStreamEventErrorOccurred |
                        kCFStreamEventEndEncountered,
                     MyReadCallback,
                     &cfContext);
   //      Schedule the CFReadStream for service by the current run loop
   CFReadStreamScheduleWithRunLoop(replyStream,
                       CFRunLoopGetCurrent(),
                       kCFRunLoopCommonModes);
   //   Fire off the request
   CFReadStreamOpen(replyStream);
   //   Watch for timeout
   timeoutTimer = [NSTimer
                     scheduledTimerWithTimeInterval: sPostTimeout
                     target: self
                     selector: @selector(messageTimedOut:)
                     userInfo: nil
                     repeats: NO];
   [timeoutTimer retain];
}
- (void) cancel
{
   NSAssert(replyStream,
               @"The program should prevent cancelling "
               @"when no query is in progress.");
   [self closeOutMessaging];
   statusCode = FAWebPostInvalid;
}
- (int) statusCode { return statusCode; }
- (NSString *) replyContent {
   return (NSString *) cfReplyContent;
}
- (NSObject *) delegate { return delegate; }
- (void) setDelegate: (NSObject *) aDelegate
{ delegate = aDelegate; }

@end
