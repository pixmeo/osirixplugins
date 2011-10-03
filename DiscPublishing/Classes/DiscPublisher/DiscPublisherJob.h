//
//  DiscPublisherJob.h
//  Primiera
//
//  Created by Alessandro Volz on 2/19/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <JobProcessor/JobProcessor.h>


@class DiscPublisher;

@interface DiscPublisherJob : NSObject {
	DiscPublisher* _discPublisher;
	UInt32 _uid;
	JobStatus _status;
	
	NSString* _xmlFilePath;

	// job properties
	NSString* _author;
	UInt32 _numCopies;
	UInt32 _type;
	UInt32 _discType;
	UInt32 _robotId;
	// recording
	//     settings
	UInt32 _writeSpeed;
	NSString* _volumeName;
	BOOL _verify;
	BOOL _closeDisc;
	UInt32 _fileSys;
	BOOL _printFirst;
	BOOL _printReject;
	//     source
	//         files
	NSMutableArray* _files;
	// printing
	UInt32 _innerDiameter;
	UInt32 _outerMargin;
	UInt32 _printQuality;
	NSString* _printFile;
	NSString* _printMergeFile;
    UInt32 _colorType, _colorTable, _saturation, _cartType;
}

@property(readonly, assign) DiscPublisher* discPublisher;
@property UInt32 uid;

@property(retain) NSString* xmlFilePath;

@property(retain) NSString* author;
@property UInt32 numCopies;
@property UInt32 type;
@property UInt32 discType;
@property UInt32 robotId;

@property UInt32 writeSpeed;
@property(retain) NSString* volumeName;
@property BOOL verify;
@property BOOL closeDisc;
@property UInt32 fileSys;
@property BOOL printFirst;
@property BOOL printReject;
@property(readonly) NSMutableArray* files;

@property UInt32 innerDiameter;
@property UInt32 outerMargin;
@property UInt32 printQuality;
@property(retain) NSString* printFile;
@property(retain) NSString* printMergeFile;

@property UInt32 colorType, colorTable, saturation, cartType;

@property(readonly) const JobStatus& status;
@property(readonly) const JobStatus& refreshStatus;
@property(readonly) NSString* statusString;
@property(readonly) NSXMLNode* xmlStatus;

-(id)initWithDiscPublisher:(DiscPublisher*)discPublisher;
-(void)start;
-(void)abort;

+(NSString*)DiscType:(UInt32)type;

@end
