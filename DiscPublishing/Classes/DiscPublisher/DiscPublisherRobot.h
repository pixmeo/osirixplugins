//
//  PrimeraBravoSEDiscPublisher.h
//  Primiera
//
//  Created by Alessandro Volz on 2/5/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <JobProcessor/JobProcessor.h>


@class DiscPublisher;

@interface DiscPublisherRobot : NSObject {
	UInt32 _handle;
	BOOL _active;
	DiscPublisher* _discPublisher;
	PTRobotInfo _info;
	PTRobotInfo2 _info2;
	PTRobotInfoEx _infoEx;
	PTRobotStatus _status;
	PTRobotStatus2 _status2;
}

@property(readonly) UInt32 handle;
@property(retain, readonly) DiscPublisher* discPublisher;
@property(getter=isActive) BOOL active;

@property(readonly) const PTRobotInfo& info;
@property(readonly) const PTRobotInfo& refreshInfo;
@property(readonly) const PTRobotInfo2& info2;
@property(readonly) const PTRobotInfo2& refreshInfo2;
@property(readonly) const PTRobotInfoEx& infoEx;
@property(readonly) const PTRobotInfoEx& refreshInfoEx;
@property(readonly) const PTRobotStatus& status;
@property(readonly) const PTRobotStatus& refreshStatus;
@property(readonly) const PTRobotStatus2& status2;
@property(readonly) const PTRobotStatus2& refreshStatus2;

-(id)initWithDiscPublisher:(DiscPublisher*)discPublisher handle:(UInt32)handle;
-(id)invalidate;

-(void)blockWhileSystemState:(UInt32)state;
-(void)blockWhileSystemStateError:(UInt32)error;

-(void)systemAction:(UInt32)action;

-(void)unloadPrinterToLocation:(UInt32)location;
-(void)requestNewJob;
-(void)killSystemErrorAndResetPrinter;

-(NSString*)infoDescription;
-(NSString*)statusDescription;

+(NSString*)descriptionForInfo:(const PTRobotInfo&)info;
+(NSString*)descriptionForInfo2:(const PTRobotInfo2&)info2;
+(NSString*)descriptionForInfoEx:(const PTRobotInfoEx&)infoEx;
+(NSString*)descriptionForStatus:(const PTRobotStatus&)status;
+(NSString*)descriptionForStatus2:(const PTRobotStatus2&)status2 numBins:(UInt32)numBins numCartridges:(UInt32)numCartridges;

@end


