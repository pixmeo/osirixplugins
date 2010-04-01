//
//  PrimeraBravoSEDiscPublisher.mm
//  Primiera
//
//  Created by Alessandro Volz on 2/5/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublisherRobot.h"
#import "DiscPublisher.h"
#import "DiscPublisher+Constants.h"


@implementation DiscPublisherRobot

@synthesize discPublisher = _discPublisher;
@synthesize handle = _handle;
@synthesize active = _active;
@synthesize info = _info;
@synthesize info2 = _info2;
@synthesize infoEx = _infoEx;
@synthesize status = _status;
@synthesize status2 = _status2;

-(id)initWithDiscPublisher:(DiscPublisher*)discPublisher handle:(UInt32)handle {
	self = [super init];
	
	_discPublisher = [discPublisher retain];
	_handle = handle;
	
	[self refreshInfo];
	[self refreshInfo2];
	[self refreshInfoEx];
	[self refreshStatus];
	[self refreshStatus2];
	
	while (![[NSThread currentThread] isCancelled]) {
		NSLog(@"DiscPublisherRobot status:\n%@", [DiscPublisherRobot descriptionForStatus:self.status]);
		
		@try {
			if (self.status2.dwPrinterTrayStatus == PRINT_TRAY_IN_WITH_DISC) {
				[self unloadPrinterToLocation:LOCATION_AUTO];
			} else
			if (self.status.dwSystemState == SYSSTATE_ERROR)
				switch (self.status.dwSystemError) {
					case SYSERR_ALIGNNEEDED: {
						[self systemAction:PTACT_ALIGNPRINTER];
						[self blockWhileSystemStateError:SYSERR_ALIGNNEEDED];
					} break;
					default:
						[NSException raise:DiscPublisherException format:@"Robot is in error state, error is %@", [DiscPublisher PTSystemError:self.status.dwSystemError]];
				}
			else break;
		} @catch (NSException* e) {
			NSLog(@"eeeee %@", e);
		}
		
		[self blockWhileSystemState:SYSSTATE_BUSY];
		[self refreshStatus];
		[self refreshStatus2];
	}
	
	return self;
}

-(id)invalidate {
	return self;
}

-(void)dealloc {
	[_discPublisher release];
	[super dealloc];
}

#pragma mark -
#pragma mark Wrapper methods for c functions

-(const PTRobotInfo&)refreshInfo {
	UInt32 err = PTRobot_GetRobotInfo(_handle, &_info);
	ConditionalDiscPublisherException(err, PTROBOT_SEQUENCE, DiscPublisherErrorCommandOutOfSequence);
	ConditionalDiscPublisherException(err, PTROBOT_INTERNAL, DiscPublisherErrorInternalErrorOccurred);
	ConditionalDiscPublisherException(err, PTROBOT_INVALID_ROBOT, DiscPublisherErrorInvalidRobotHandle);
	ConditionalDiscPublisherPTErrorException(err);
	return _info;
}

-(const PTRobotInfo2&)refreshInfo2 {
	UInt32 err = PTRobot_GetRobotInfo2(_handle, &_info2);
	ConditionalDiscPublisherException(err, PTROBOT_SEQUENCE, DiscPublisherErrorCommandOutOfSequence);
	ConditionalDiscPublisherException(err, PTROBOT_INTERNAL, DiscPublisherErrorInternalErrorOccurred);
	ConditionalDiscPublisherException(err, PTROBOT_INVALID_ROBOT, DiscPublisherErrorInvalidRobotHandle);
	ConditionalDiscPublisherPTErrorException(err);
	return _info2;
}

-(const PTRobotInfoEx&)refreshInfoEx {
	UInt32 err = PTRobot_GetRobotInfoEx(_handle, &_infoEx);
	ConditionalDiscPublisherException(err, PTROBOT_SEQUENCE, DiscPublisherErrorCommandOutOfSequence);
	ConditionalDiscPublisherException(err, PTROBOT_INTERNAL, DiscPublisherErrorInternalErrorOccurred);
	ConditionalDiscPublisherException(err, PTROBOT_INVALID_ROBOT, DiscPublisherErrorInvalidRobotHandle);
	ConditionalDiscPublisherPTErrorException(err);
	return _infoEx;
}

-(const PTRobotStatus&)refreshStatus {
	UInt32 err = PTRobot_GetRobotStatus(_handle, &_status);
	ConditionalDiscPublisherException(err, PTROBOT_SEQUENCE, DiscPublisherErrorCommandOutOfSequence);
	ConditionalDiscPublisherException(err, PTROBOT_INTERNAL, DiscPublisherErrorInternalErrorOccurred);
	ConditionalDiscPublisherException(err, PTROBOT_INVALID_ROBOT, DiscPublisherErrorInvalidRobotHandle);
	ConditionalDiscPublisherPTErrorException(err);
	return _status;
}

-(const PTRobotStatus2&)refreshStatus2 {
	UInt32 err = PTRobot_GetRobotStatus2(_handle, &_status2);
	ConditionalDiscPublisherException(err, PTROBOT_SEQUENCE, DiscPublisherErrorCommandOutOfSequence);
	ConditionalDiscPublisherException(err, PTROBOT_INTERNAL, DiscPublisherErrorInternalErrorOccurred);
	ConditionalDiscPublisherException(err, PTROBOT_INVALID_ROBOT, DiscPublisherErrorInvalidRobotHandle);
	ConditionalDiscPublisherException(err, PTROBOT_BUSY, DiscPublisherErrorNoResponseFromRobot);
	ConditionalDiscPublisherPTErrorException(err);
	return _status2;
}

-(void)systemAction:(UInt32)action {
	UInt32 err = PTRobot_SystemAction(_handle, action);
	ConditionalDiscPublisherException(err, PTROBOT_SEQUENCE, DiscPublisherErrorCommandOutOfSequence);
	ConditionalDiscPublisherException(err, PTROBOT_INTERNAL, DiscPublisherErrorInternalErrorOccurred);
	ConditionalDiscPublisherException(err, PTROBOT_INVALID_ROBOT, DiscPublisherErrorInvalidRobotHandle);
	ConditionalDiscPublisherException(err, PTROBOT_INVALID_ACTION, DiscPublisherErrorInvalidRobotAction);
	ConditionalDiscPublisherPTErrorException(err);
}

-(void)blockWhileSystemStateError:(UInt32)error {
	BOOL first = YES;
	do {
		NSLog(@"status:\n%@",[self statusDescription]);
		if (!first) [NSThread sleepForTimeInterval:1]; first = NO;
		[self refreshStatus];
	} while (self.status.dwSystemState == SYSSTATE_ERROR && self.status.dwSystemError == SYSERR_ALIGNNEEDED);
}

-(void)blockWhileSystemState:(UInt32)state {
	BOOL first = YES;
	do {
		NSLog(@"status:\n%@",[self statusDescription]);
		if (!first) [NSThread sleepForTimeInterval:1]; first = NO;
		[self refreshStatus];
	} while (self.status.dwSystemState == state);
}

-(void)unloadPrinterToLocation:(UInt32)location {
	UInt32 err = PTRobot_UnLoadPrinter(_handle, location);
//	UInt32 err = PTRobot_MoveDiscBetweenLocations(_handle, 1, 200);
	ConditionalDiscPublisherException(err, PTROBOT_SEQUENCE, DiscPublisherErrorCommandOutOfSequence);
	ConditionalDiscPublisherException(err, PTROBOT_INTERNAL, DiscPublisherErrorInternalErrorOccurred);
	ConditionalDiscPublisherException(err, PTROBOT_INVALID_ROBOT, DiscPublisherErrorInvalidRobotHandle);
	ConditionalDiscPublisherException(err, PTROBOT_NO_PRINTER, DiscPublisherErrorNoPrinter);
	ConditionalDiscPublisherException(err, PTROBOT_INVALID_LOCATION, DiscPublisherErrorInvalidLocation);
	ConditionalDiscPublisherPTErrorException(err);
}

-(void)requestNewJob {
	UInt32 err = JP_RequestNewJob(_handle);
	ConditionalDiscPublisherException(err, JOBERR_NOT_READY, DiscPublisherErrorNotReadyToAcceptNewJob);
	ConditionalDiscPublisherPTErrorException(err);
}

-(void)killSystemErrorAndResetPrinter {
	UInt32 err = PTRobot_KillSystemError(_handle, YES);
	ConditionalDiscPublisherException(err, PTROBOT_SEQUENCE, DiscPublisherErrorCommandOutOfSequence);
	ConditionalDiscPublisherException(err, PTROBOT_INTERNAL, DiscPublisherErrorInternalErrorOccurred);
	ConditionalDiscPublisherException(err, PTROBOT_INVALID_ROBOT, DiscPublisherErrorInvalidRobotHandle);
	ConditionalDiscPublisherPTErrorException(err);
}

#pragma mark -
#pragma mark Descriptions for instance values


-(NSString*)infoDescription {
	NSMutableString* desc = [[NSMutableString alloc] initWithCapacity:512];
	
	[desc appendString:[DiscPublisherRobot descriptionForInfo:[self refreshInfo]]];
	[desc appendString:[DiscPublisherRobot descriptionForInfo2:[self refreshInfo2]]];
	[desc appendString:[DiscPublisherRobot descriptionForInfoEx:[self refreshInfoEx]]];
	
	return [desc autorelease];
}

-(NSString*)statusDescription {
	NSMutableString* desc = [[NSMutableString alloc] initWithCapacity:512];
	
	[self refreshInfo];
	[self refreshInfo2];
	[self refreshStatus];
	[self refreshStatus2];
	
	BOOL numDiscsInBinsIsUnknown = NO; 
	for (UInt32 i = 0; i < _info.dwNumBins; ++i)
		if (_status2.dwNumDiscsInBins[i] == UNKNOWN_NUM_DISCS)
			numDiscsInBinsIsUnknown = YES;
	
	if (numDiscsInBinsIsUnknown && (_info.dwSupportedActions&PTACT_CHECKDISCS)) {
		[self systemAction:PTACT_CHECKDISCS];
		[self blockWhileSystemState:SYSSTATE_BUSY];
	}
	
	[self refreshStatus2];
	
	[desc appendString:[DiscPublisherRobot descriptionForStatus:_status]];
	[desc appendString:[DiscPublisherRobot descriptionForStatus2:_status2 numBins:_info.dwNumBins numCartridges:_info2.dwNumCartridges]];
	
	return [desc autorelease];
}

#pragma mark -
#pragma mark Descriptions for PTRobot structures

+(NSString*)descriptionForInfo:(const PTRobotInfo&)robotInfo {
	NSMutableString* desc = [[NSMutableString alloc] initWithCapacity:512];
	
	[desc appendFormat:@"                hRobot = %u\n", robotInfo.hRobot];
	[desc appendFormat:@"          tszRobotDesc = %s\n", robotInfo.tszRobotDesc];
	[desc appendFormat:@"           dwRobotType = %@\n", [DiscPublisher PTRobotType:robotInfo.dwRobotType]];
	[desc appendFormat:@"           dwNumDrives = %u\n", robotInfo.dwNumDrives];
	[desc appendFormat:@"         dwNumPrinters = %u\n", robotInfo.dwNumPrinters];
	[desc appendFormat:@"             dwNumBins = %u\n", robotInfo.dwNumBins];
	[desc appendFormat:@"        dwDriveColumns = %u\n", robotInfo.dwDriveColumns];
	[desc appendFormat:@"           dwDriveRows = %u\n", robotInfo.dwDriveRows];
	[desc appendFormat:@"      tszRobotFirmware = %s\n", robotInfo.tszRobotFirmware];
	[desc appendFormat:@"    dwSupportedOptions = %@\n", [DiscPublisher PTRobotOptions:robotInfo.dwSupportedOptions]];
	[desc appendFormat:@"    dwSupportedActions = %@\n", [DiscPublisher PTRobotActions:robotInfo.dwSupportedActions]];
	
	for (UInt32 i = 0; i < robotInfo.dwNumDrives; ++i) {
		[desc appendFormat:@"                      [%d]\n", i];
		[desc appendFormat:@"                 hDrives = %u\n", robotInfo.hDrives[i]];
		[desc appendFormat:@"                dwLocRow = %u\n", robotInfo.dwLocRow[i]];
		[desc appendFormat:@"                dwLocCol = %u\n", robotInfo.dwLocCol[i]];
	}
	
	[desc appendFormat:@"        dwDriveBusType = %@\n", [DiscPublisher PTRobotBusType:robotInfo.dwDriveBusType]];
	
	return [desc autorelease];
}

+(NSString*)descriptionForInfo2:(const PTRobotInfo2&)robotInfo2 {
	NSMutableString* desc = [[NSMutableString alloc] initWithCapacity:512];
	
	[desc appendFormat:@"       dwNumCartridges = %u\n", robotInfo2.dwNumCartridges];
	
	for (UInt32 i = 0; i < robotInfo2.dwNumCartridges; ++i)
		[desc appendFormat:@"    dwCartridgeType[%u] = %@\n", i, [DiscPublisher PTCartridgeType:robotInfo2.dwCartridgeType[i]]];
	
	[desc appendFormat:@"       dwFirmware2Code = %u\n", robotInfo2.dwFirmware2Code];
	[desc appendFormat:@"                 dwPGA = %u\n", robotInfo2.dwPGA];
	[desc appendFormat:@"               dwModel = %u\n", robotInfo2.dwModel];
	[desc appendFormat:@"        dwUSBSerialNum = %u\n", robotInfo2.dwUSBSerialNum];
	[desc appendFormat:@"      dwMaxDiscsPerBin = %u\n", robotInfo2.dwMaxDiscsPerBin];
	
	return [desc autorelease];
}

+(NSString*)descriptionForInfoEx:(const PTRobotInfoEx&)robotInfoEx {
	NSMutableString* desc = [[NSMutableString alloc] initWithCapacity:512];
	
	[desc appendFormat:@"         fHasFlashChip = %u\n", robotInfoEx.fHasFlashChip];
	[desc appendFormat:@"       fFlashDataAvail = %u\n", robotInfoEx.fFlashDataAvail];
	[desc appendFormat:@"          tszAlignFile = %s\n", robotInfoEx.tszAlignFile];
	[desc appendFormat:@"          tszPurgeFile = %u\n", robotInfoEx.tszPurgeFile];
	[desc appendFormat:@"           dwNumDrives = %u\n", robotInfoEx.dwNumDrives];
	
	for (UInt32 i = 0; i < robotInfoEx.dwNumDrives; ++i) {
		[desc appendFormat:@"                      [%u]\n", i];
		[desc appendFormat:@"               tszSerial = %s\n", robotInfoEx.tszSerial[i]];
		[desc appendFormat:@"                 hDrives = %u\n", robotInfoEx.hDrives[i]];
		[desc appendFormat:@"                dwLocRow = %u\n", robotInfoEx.dwLocRow[i]];
		[desc appendFormat:@"                dwLocCol = %u\n", robotInfoEx.dwLocCol[i]];
	}
	
	[desc appendFormat:@"                 bDate = %s\n", robotInfoEx.bDate];
	[desc appendFormat:@"         bSerialNumber = %s\n", robotInfoEx.bSerialNumber];
	
	return [desc autorelease];
}

+(NSString*)descriptionForStatus:(const PTRobotStatus&)robotStatus {
	NSMutableString* desc = [[NSMutableString alloc] initWithCapacity:512];
	
	[desc appendFormat:@"         dwSystemState = %@\n", [DiscPublisher PTSystemState:robotStatus.dwSystemState]];
	[desc appendFormat:@"         dwSystemError = %@\n", [DiscPublisher PTSystemError:robotStatus.dwSystemError]];
	[desc appendFormat:@"      dwCurrColorSpits = %u/%u\n", robotStatus.dwCurrColorSpits, robotStatus.dwFullColorSpits];
	[desc appendFormat:@"      dwCurrBlackSpits = %u/%u\n", robotStatus.dwCurrBlackSpits, robotStatus.dwFullBlackSpits];
	
	return [desc autorelease];
}

+(NSString*)descriptionForStatus2:(const PTRobotStatus2&)robotStatus2 numBins:(UInt32)numBins numCartridges:(UInt32)numCartridges {
	NSMutableString* desc = [[NSMutableString alloc] initWithCapacity:512];
	
	[desc appendFormat:@"      dwCartridgeTypes = %u\n", robotStatus2.dwCartridgeTypes];
	
	for (UInt32 i = 0; i < numBins; ++i)
		[desc appendFormat:@"   dwNumDiscsInBins[%u] = %@\n", i, [DiscPublisher PTNumDiscs:robotStatus2.dwNumDiscsInBins[i]]];
	
	[desc appendFormat:@"         dwTotalPrints = %u\n", robotStatus2.dwTotalPrints];
	[desc appendFormat:@"          dwTotalPicks = %u\n", robotStatus2.dwTotalPicks];
	[desc appendFormat:@"       lVerticalOffset = %d\n", robotStatus2.lVerticalOffset];
	[desc appendFormat:@"     lHorizontalOffset = %d\n", robotStatus2.lHorizontalOffset];
	[desc appendFormat:@"   dwPrinterTrayStatus = %@\n", [DiscPublisher PTPrinterTrayStatus:robotStatus2.dwPrinterTrayStatus]];
	[desc appendFormat:@"dwDiscPickSwitchStatus = %@\n", [DiscPublisher PTPickSwitchStatus:robotStatus2.dwDiscPickSwitchStatus]];
	
	for (UInt32 i = 0; i < numCartridges; ++i) {
		[desc appendFormat:@"                      [%u]\n", i];
		[desc appendFormat:@"    dwCartridgeInstalled = %@\n", [DiscPublisher PTCartridgeInstalled:robotStatus2.dwCartridgeInstalled[i]]];
		[desc appendFormat:@"   dwCartridgeNeedsAlign = %u\n", robotStatus2.dwCartridgeNeedsAlign[i]];
	}
	
	[desc appendFormat:@"       dwSystemStateHW = %@\n", [DiscPublisher PTSystemState:robotStatus2.dwSystemStateHW]];
	
	return [desc autorelease];
}

@end
