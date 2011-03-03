//
//  DiscPublisherPrivate.m
//  Primiera
//
//  Created by Alessandro Volz on 2/10/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#include "DiscPublisher+Constants.h"
#include <OsiriXAPI/NSString+N2.h>


@implementation DiscPublisher (Constants)

const NSString* const DiscPublisherException = @"Disk Publisher Exception";

const NSString* const DiscPublisherErrorInternalErrorOccurred = @"An internal error occurred";
const NSString* const DiscPublisherErrorCommandOutOfSequence = @"Command called out of sequence";
const NSString* const DiscPublisherErrorDLLNotFound = @"One of the support DLLs cannot be found";
const NSString* const DiscPublisherErrorNoRobotsFound = @"No robots found";
const NSString* const DiscPublisherErrorNotEnoughMemory = @"Not enough memory allocated";
const NSString* const DiscPublisherErrorInvalidRobotHandle = @"Invalid robot handle";
const NSString* const DiscPublisherErrorInvalidRobotAction = @"Invalid robot action";
const NSString* const DiscPublisherErrorNoResponseFromRobot = @"No response from robot";
const NSString* const DiscPublisherErrorNoPrinter = @"The robot doesn't have a printer";
const NSString* const DiscPublisherErrorInvalidLocation = @"Invalid robot location";
const NSString* const DiscPublisherErrorNotReadyToAcceptNewJob = @"Robot is not ready to accept new jobs";

#pragma mark -
#pragma mark Constants
	
+(NSString*)PTRobotType:(UInt32)type {
	switch (type) {
		case ROBOT_DISCPUBLISHER: return @"ROBOT_DISCPUBLISHER";
		case ROBOT_DISCPUBLISHERII: return @"ROBOT_DISCPUBLISHERII";
		case ROBOT_DISCPUBLISHERPRO: return @"ROBOT_DISCPUBLISHERPRO";
		case ROBOT_COMPOSERMAX: return @"ROBOT_COMPOSERMAX";
		case ROBOT_RACKMOUNT_DPII: return @"ROBOT_RACKMOUNT_DPII";
		case ROBOT_DISCPUBLISHER_XRP: return @"ROBOT_DISCPUBLISHER_XRP";
		case ROBOT_DISCPUBLISHER_SE: return @"ROBOT_DISCPUBLISHER_SE";
		default: return [NSString stringWithFormat:@"%u", type];
	}
}

+(NSString*)PTRobotOptions:(UInt32)options {
	NSMutableString* desc = [[NSMutableString alloc] initWithCapacity:512];
	
	if (options&PTOPT_KIOSKMODE)
		[desc appendFormat:@"%@PTOPT_KIOSKMODE", [desc length]?@", ":@""];
	
	if (!options) [desc appendString:@"NONE"];
	
	return [desc autorelease];
}

+(NSString*)PTRobotActions:(UInt32)actions {
	NSMutableString* desc = [[NSMutableString alloc] initWithCapacity:512];
	
	if (actions&PTACT_ALIGNPRINTER)
		[desc appendFormat:@"%@PTACT_ALIGNPRINTER", [desc length]?@", ":@""];
	if (actions&PTACT_IGNOREINKLOW)
		[desc appendFormat:@"%@PTACT_IGNOREINKLOW", [desc length]?@", ":@""];
	if (actions&PTACT_DISABLEPWRBUTTON)
		[desc appendFormat:@"%@PTACT_DISABLEPWRBUTTON", [desc length]?@", ":@""];
	if (actions&PTACT_REINIT_DRIVES)
		[desc appendFormat:@"%@PTACT_REINIT_DRIVES", [desc length]?@", ":@""];
	if (actions&PTACT_IDENTIFY)
		[desc appendFormat:@"%@PTACT_IDENTIFY", [desc length]?@", ":@""];
	if (actions&PTACT_CANCELCMD)
		[desc appendFormat:@"%@PTACT_CANCELCMD", [desc length]?@", ":@""];
	if (actions&PTACT_ENABLEPWRBUTTON)
		[desc appendFormat:@"%@PTACT_ENABLEPWRBUTTON", [desc length]?@", ":@""];
	if (actions&PTACT_RESETSYSTEM)
		[desc appendFormat:@"%@PTACT_RESETSYSTEM", [desc length]?@", ":@""];
	if (actions&PTACT_CHECKDISCS)
		[desc appendFormat:@"%@PTACT_CHECKDISCS", [desc length]?@", ":@""];
	if (actions&PTACT_CLEANCARTRIDGES)
		[desc appendFormat:@"%@PTACT_CLEANCARTRIDGES", [desc length]?@", ":@""];
	if (actions&PTACT_CALIBRATE_ONE_DISC)
		[desc appendFormat:@"%@PTACT_CALIBRATE_ONE_DISC", [desc length]?@", ":@""];
	if (actions&PTACT_CHANGE_CARTRIDGE)
		[desc appendFormat:@"%@PTACT_CHANGE_CARTRIDGE", [desc length]?@", ":@""];
	if (actions&PTACT_END_CARTRIDGE_CHANGE)
		[desc appendFormat:@"%@PTACT_END_CARTRIDGE_CHANGE", [desc length]?@", ":@""];
	if (actions&PTACT_SHIP_POSITION)
		[desc appendFormat:@"%@PTACT_SHIP_POSITION", [desc length]?@", ":@""];
	if (actions&PTACT_RESET_LEFT_INK_LEVELS)
		[desc appendFormat:@"%@PTACT_RESET_LEFT_INK_LEVELS", [desc length]?@", ":@""];
	if (actions&PTACT_RESET_RIGHT_INK_LEVELS)
		[desc appendFormat:@"%@PTACT_RESET_RIGHT_INK_LEVELS", [desc length]?@", ":@""];
	if (actions&PTACT_ALLOW_NO_CARTRIDGES)
		[desc appendFormat:@"%@PTACT_ALLOW_NO_CARTRIDGES", [desc length]?@", ":@""];
	
	if (!actions) [desc appendString:@"NONE"];
	
	return [desc autorelease];
}

+(NSString*)PTRobotBusType:(UInt32)busType {
	switch (busType) {
		case BUSTYPE_USB: return @"BUSTYPE_USB";
		case BUSTYPE_1394: return @"BUSTYPE_1394";
		default: return [NSString stringWithFormat:@"%u", busType];
	}
}

+(NSString*)PTCartridgeType:(UInt32)cartridgeType {
	switch (cartridgeType) {
		case CARTRIDGE_NONE: return @"CARTRIDGE_NONE";
		case CARTRIDGE_COLOR: return @"CARTRIDGE_COLOR";
		case CARTRIDGE_BLACK: return @"CARTRIDGE_BLACK";
		default: return [NSString stringWithFormat:@"%u", cartridgeType];
	}
}

+(NSString*)PTCartridgeInstalled:(UInt32)cartridgeInstalled {
	switch (cartridgeInstalled) {
		case NO_CARTRIDGE_INSTALLED: return @"NO_CARTRIDGE_INSTALLED";
		case VALID_CARTRIDGE: return @"VALID_CARTRIDGE";
		case INVALID_CARTRIDGE: return @"INVALID_CARTRIDGE";
		default: return [NSString stringWithFormat:@"%u", cartridgeInstalled];
	}
}

+(NSString*)PTNumDiscs:(UInt32)num {
	switch (num) {
		case UNKNOWN_NUM_DISCS: return @"UNKNOWN_NUM_DISCS";
		default: return [NSString stringWithFormat:@"%u", num];
	}
}

+(NSString*)PTPrinterTrayStatus:(UInt32)status {
	switch (status) {
		case PRINT_TRAY_IN_WITH_DISC: return @"PRINT_TRAY_IN_WITH_DISC";
		case PRINT_TRAY_IN_NO_DISC: return @"PRINT_TRAY_IN_NO_DISC";
		case PRINT_TRAY_OUT: return @"PRINT_TRAY_OUT";
		default: return [NSString stringWithFormat:@"%u", status];
	}
}

+(NSString*)PTPickSwitchStatus:(UInt32)status {
	switch (status) {
		case DISC_PICKER_NO_DISC: return @"DISC_PICKER_NO_DISC";
		case DISC_PICKER_HAS_DISC: return @"DISC_PICKER_HAS_DISC";
		default: return [NSString stringWithFormat:@"%u", status];
	}
}

+(NSString*)PTSystemState:(UInt32)state {
	switch (state) {
		case SYSSTATE_IDLE: return @"SYSSTATE_IDLE";
		case SYSSTATE_BUSY: return @"SYSSTATE_BUSY";
		case SYSSTATE_ERROR: return @"SYSSTATE_ERROR";
		default: return [NSString stringWithFormat:@"%u", state];
	}
}

+(NSString*)JPJobType:(UInt32)type {
	switch (type) {
		case JP_JOB_AUDIO: return @"JP_JOB_AUDIO";
		case JP_JOB_DATA: return @"JP_JOB_DATA";
		case JP_JOB_IMAGE: return @"JP_JOB_IMAGE";
		case JP_JOB_PRINT_ONLY: return @"JP_JOB_PRINT_ONLY";
		case JP_JOB_MULTISESSION: return @"JP_JOB_MULTISESSION";
		case JP_JOB_READ: return @"JP_JOB_READ";
		case JP_JOB_COPY: return @"JP_JOB_COPY";
		case JP_JOB_SAVE_GI: return @"JP_JOB_SAVE_GI";
		case JP_JOB_UNKNOWN: return @"JP_JOB_UNKNOWN";
		default: return [NSString stringWithFormat:@"%u", type];
	}
}

+(NSString*)JPJobState:(UInt32)state {
	switch (state) {
		case JOB_NOT_STARTED: return @"JOB_NOT_STARTED";
		case JOB_RECORDING: return @"JOB_RECORDING";
		case JOB_PRINTING: return @"JOB_PRINTING";
		case JOB_COMPLETED: return @"JOB_COMPLETED";
		case JOB_ABORTED: return @"JOB_ABORTED";
		case JOB_PAUSED: return @"JOB_PAUSED";
		case JOB_RESUMED: return @"JOB_RESUMED";
		case JOB_FAILED: return @"JOB_FAILED";
		case JOB_VERIFYING: return @"JOB_VERIFYING";
		case JOB_READING: return @"JOB_READING";
		case JOB_ABORTING: return @"JOB_ABORTING";
		default: return [NSString stringWithFormat:@"%u", state];
	}
}

+(NSString*)JMDiscType:(UInt32)type {
	switch (type) {
		case DISCTYPE_CD: return @"DISCTYPE_CD";
		case DISCTYPE_DVD: return @"DISCTYPE_DVD";
		case DISCTYPE_DVDDL: return @"DISCTYPE_DVDDL";
		case DISCTYPE_BR: return @"DISCTYPE_BR";
		case DISCTYPE_BR_DL: return @"DISCTYPE_BR_DL";
		default: return @"DISCTYPE_UNKNOWN";
	}
}

#pragma mark -
#pragma mark Descriptions

+(NSString*)descriptionForDiscError:(const DiscError&)discError {
	NSMutableString* desc = [[NSMutableString alloc] initWithCapacity:512];
	
	[desc appendFormat:@"            nDiscIndex = %d\n", discError.nDiscIndex];
	[desc appendFormat:@"           dwDiscError = %u\n", discError.dwDiscError];
	[desc appendFormat:@"               dwSense = %u\n", discError.dwSense];
	[desc appendFormat:@"             dwCommand = %u\n", discError.dwCommand];
	[desc appendFormat:@"                 dwASC = %u\n", discError.dwASC];
	[desc appendFormat:@"                dwASCQ = %u\n", discError.dwASCQ];
	[desc appendFormat:@"              dwSector = %u\n", discError.dwSector];
	
	return [desc autorelease];
}

+(NSString*)descriptionForDiscThreadSummary:(const DiscThreadSummary&)discThreadSummary {
	NSMutableString* desc = [[NSMutableString alloc] initWithCapacity:512];
	
	[desc appendFormat:@"             dwDriveID = %u\n", discThreadSummary.dwDriveID];
	[desc appendFormat:@"               dwState = %u\n", discThreadSummary.dwState];
	[desc appendFormat:@"             dwDiscNum = %u\n", discThreadSummary.dwDiscNum];
	
	return [desc autorelease];
}

+(NSString*)descriptionForJobStatus:(const JobStatus&)jobStatus {
	NSMutableString* desc = [[NSMutableString alloc] initWithCapacity:512];
	
	[desc appendFormat:@"               dwJobID = %u\n", jobStatus.dwJobID];
	[desc appendFormat:@"             dwJobType = %@\n", [DiscPublisher JPJobType:jobStatus.dwJobType]];
	[desc appendFormat:@"            dwJobState = %@\n", [DiscPublisher JPJobState:jobStatus.dwJobState]];
	[desc appendFormat:@"      nPercentComplete = %d\n", jobStatus.nPercentComplete];
	[desc appendFormat:@"         nNumGoodDiscs = %d\n", jobStatus.nNumGoodDiscs];
	[desc appendFormat:@"          nNumBadDiscs = %d\n", jobStatus.nNumBadDiscs];
	[desc appendFormat:@"       nNumCopiesTotal = %d\n", jobStatus.nNumCopiesTotal];
	[desc appendFormat:@"   nNumCopiesCompleted = %d\n", jobStatus.nNumCopiesCompleted];
	[desc appendFormat:@"       tszStatusString = %s\n", jobStatus.tszStatusString];
	[desc appendFormat:@"       nBadDiscsInARow = %d\n", jobStatus.nBadDiscsInARow];
	[desc appendFormat:@"           dwLastError = %u\n", jobStatus.dwLastError];
	
	[desc appendFormat:@"           nDiscErrors = %d\n", jobStatus.nDiscErrors];
	for (NSInteger i = 0; i < jobStatus.nDiscErrors; ++i) {
		[desc appendFormat:@"            discErrors[%d]\n", i];
		[desc appendString:[[self descriptionForDiscError:jobStatus.discErrors[i]] stringByPrefixingLinesWithString:@"  "]];
	}
	
	[desc appendFormat:@"        nLoadDiscCount = %d\n", jobStatus.nLoadDiscCount];
	for (NSInteger i = 0; i < jobStatus.nLoadDiscCount; ++i) {
		[desc appendFormat:@"                      [%d]\n", i];
		[desc appendFormat:@"         nLoadDriveIndex = %d\n", jobStatus.nLoadDriveIndex[i]];
		[desc appendFormat:@"         nLoadDriveState = %d\n", jobStatus.nLoadDriveState[i]];
		[desc appendFormat:@"        cLoadDriveLetter = %c\n", jobStatus.cLoadDriveLetter[i]];
	}
	
	[desc appendFormat:@"      dwNumDiscThreads = %u\n", jobStatus.dwJobID];
	for (UInt32 i = 0; i < jobStatus.dwNumDiscThreads; ++i) {
		[desc appendFormat:@"     discThreadSummary[%d]\n", i];
		[desc appendString:[[self descriptionForDiscThreadSummary:jobStatus.discThreadSummary[i]] stringByPrefixingLinesWithString:@"  "]];
	}
	
	return [desc autorelease];
}

#pragma mark -
#pragma mark Errors

+(NSString*)PTSystemError:(UInt32)err {
	switch (err) {
		case SYSERR_PTR_TRAY: return @"SYSERR_PTR_TRAY";
		case SYSERR_CART_CODE: return @"SYSERR_CART_CODE";
		case SYSERR_INPUT_EMPTY: return @"SYSERR_INPUT_EMPTY";
		case SYSERR_PTR_COMM: return @"SYSERR_PTR_COMM";
		case SYSERR_CLR_EMPTY: return @"SYSERR_CLR_EMPTY";
		case SYSERR_BLK_EMPTY: return @"SYSERR_BLK_EMPTY";
		case SYSERR_BOTH_EMPTY: return @"SYSERR_BOTH_EMPTY";
		case SYSERR_PICK: return @"SYSERR_PICK";
		case SYSERR_ARM_MOVE: return @"SYSERR_ARM_MOVE";
		case SYSERR_CART_MOVE: return @"SYSERR_CART_MOVE";
		case SYSERR_INTERNAL_SW: return @"SYSERR_INTERNAL_SW";
		case SYSERR_NO_ROBODRIVES: return @"SYSERR_NO_ROBODRIVES";
		case SYSERR_OFFLINE: return @"SYSERR_OFFLINE";
		case SYSERR_COVER_OPEN: return @"SYSERR_COVER_OPEN";
		case SYSERR_PRINTER_PICK: return @"SYSERR_PRINTER_PICK";
		case SYSERR_MULTIPLE_PICK: return @"SYSERR_MULTIPLE_PICK";
		case SYSERR_MULTIPLEDISCS_IN_PRINTER: return @"SYSERR_MULTIPLEDISCS_IN_PRINTER";
		case SYSERR_MULTIPLEDISCS_IN_RECORDER: return @"SYSERR_MULTIPLEDISCS_IN_RECORDER";
		case SYSERR_DROPPED_DISC_RECORDER: return @"SYSERR_DROPPED_DISC_RECORDER";
		case SYSERR_DROPPED_DISC_BIN1: return @"SYSERR_DROPPED_DISC_BIN1";
		case SYSERR_DROPPED_DISC_BIN2: return @"SYSERR_DROPPED_DISC_BIN2";
		case SYSERR_DROPPED_DISC_BIN3: return @"SYSERR_DROPPED_DISC_BIN3";
		case SYSERR_DROPPED_DISC_BIN4: return @"SYSERR_DROPPED_DISC_BIN4";
		case SYSERR_DROPPED_DISC_BIN5: return @"SYSERR_DROPPED_DISC_BIN5";
		case SYSERR_DROPPED_DISC_PRINTER: return @"SYSERR_DROPPED_DISC_PRINTER";
		case SYSERR_DROPPED_DISC_REJECT: return @"SYSERR_DROPPED_DISC_REJECT";
		case SYSERR_DROPPED_DISC_UNKNOWN: return @"SYSERR_DROPPED_DISC_UNKNOWN";
		case SYSERR_ALIGNNEEDED: return @"SYSERR_ALIGNNEEDED";
		case SYSERR_COLOR_INVALID: return @"SYSERR_COLOR_INVALID";
		case SYSERR_BLACK_INVALID: return @"SYSERR_BLACK_INVALID";
		case SYSERR_BOTH_INVALID: return @"SYSERR_BOTH_INVALID";
		case SYSERR_NOCARTS: return @"SYSERR_NOCARTS";
		case SYSERR_K_IN_CMY: return @"SYSERR_K_IN_CMY";
		case SYSERR_CMY_IN_K: return @"SYSERR_CMY_IN_K";
		case SYSERR_SWAPPED: return @"SYSERR_SWAPPED";
		case SYSERR_PIGONPRO: return @"SYSERR_PIGONPRO";
		case SYSERR_ALIGNFAILED: return @"SYSERR_ALIGNFAILED";
		case SYSERR_DROPPED_DISC_PRINTER_FATAL: return @"SYSERR_DROPPED_DISC_PRINTER_FATAL";
		case SYSERR_MULTIPLEDISCS_IN_RIGHTBIN: return @"SYSERR_MULTIPLEDISCS_IN_RIGHTBIN";
		case SYSERR_MULTIPLEDISCS_IN_LEFTBIN: return @"SYSERR_MULTIPLEDISCS_IN_LEFTBIN";
		case SYSERR_CLR_EMPTY_FINAL: return @"SYSERR_CLR_EMPTY_FINAL";
		case SYSERR_BLK_EMPTY_FINAL: return @"SYSERR_BLK_EMPTY_FINAL";
		case SYSERR_BOTH_EMPTY_FINAL: return @"SYSERR_BOTH_EMPTY_FINAL";
		case SYSERR_WAITING_FOR_PRINTER: return @"SYSERR_WAITING_FOR_PRINTER";
		case SYSERR_NO_DISC_IN_PRINTER: return @"SYSERR_NO_DISC_IN_PRINTER";
		case SYSERR_BUSY: return @"SYSERR_BUSY";
		default: return [NSString stringWithFormat:@"PTSYSERR %u", err];
	}
}

+(NSString*)PTError:(UInt32)err {
	switch (err) {
		case PTROBOT_INTERNAL: return @"PTROBOT_INTERNAL";
		case PTROBOT_SEQUENCE: return @"PTROBOT_SEQUENCE";
		case PTROBOT_INVALID_ROBOT: return @"PTROBOT_INVALID_ROBOT";
		case PTROBOT_INVALID_DRIVE: return @"PTROBOT_INVALID_DRIVE";
		case PTROBOT_INVALID_BIN: return @"PTROBOT_INVALID_BIN";
		case PTROBOT_NODRIVES: return @"PTROBOT_NODRIVES";
		case PTROBOT_OPENCLOSE_FAILED: return @"PTROBOT_OPENCLOSE_FAILED";
		case PTROBOT_OVERFLOW: return @"PTROBOT_OVERFLOW";
		case PTROBOT_NO_PRINTER: return @"PTROBOT_NO_PRINTER";
		case PTROBOT_PRINTFILE_INVALID: return @"PTROBOT_PRINTFILE_INVALID";
		case PTROBOT_PRINTAPP_NOT_INSTALLED: return @"PTROBOT_PRINTAPP_NOT_INSTALLED";
		case PTROBOT_PRINTFILE_NOT_FOUND: return @"PTROBOT_PRINTFILE_NOT_FOUND";
		case PTROBOT_PRN_INVALID: return @"PTROBOT_PRN_INVALID";
		case PTROBOT_UNSUPPORTED_OPTION: return @"PTROBOT_UNSUPPORTED_OPTION";
		case PTROBOT_DIRNOTFOUND: return @"PTROBOT_DIRNOTFOUND";
		case PTROBOT_INVALID_LOCATION: return @"PTROBOT_INVALID_LOCATION";
		case PTROBOT_MULTDRIVES: return @"PTROBOT_MULTDRIVES";
		case PTROBOT_INVALID_PRINTER_SETTINGS: return @"PTROBOT_INVALID_PRINTER_SETTINGS";
		case PTROBOT_INVALID_DRIVE_POSITION: return @"PTROBOT_INVALID_DRIVE_POSITION";
		case PTROBOT_INVALID_ACTION: return @"PTROBOT_INVALID_ACTION";
		case PTROBOT_FEATURE_NOT_IMPLEMENTED: return @"PTROBOT_FEATURE_NOT_IMPLEMENTED";
		case PTROBOT_PRINTAPP_OPEN: return @"PTROBOT_PRINTAPP_OPEN";
		case PTROBOT_MISSING_DLL: return @"PTROBOT_MISSING_DLL";
		case PTROBOT_DRIVE_NOT_READY: return @"PTROBOT_DRIVE_NOT_READY";
		case PTROBOT_INVALID_MEDIA: return @"PTROBOT_INVALID_MEDIA";
		case PTROBOT_NO_MEDIA: return @"PTROBOT_NO_MEDIA";
		case PTROBOT_INVALID_LANG: return @"PTROBOT_INVALID_LANG";
		case PTROBOT_INVALID_ERROR: return @"PTROBOT_INVALID_ERROR";
		case PTROBOT_BUSY: return @"PTROBOT_BUSY";
		case PTROBOT_INVALID_EXTENSION: return @"PTROBOT_INVALID_EXTENSION";
		default: return [self PTSystemError:err];
	}
}

+(NSString*)JPSystemError:(UInt32)err {
	switch (err) {
		case JPSYSERR_PTR_TRAY: return @"JPSYSERR_PTR_TRAY";
		case JPSYSERR_CART_CODE: return @"JPSYSERR_CART_CODE";
		case JPSYSERR_INPUT_EMPTY: return @"JPSYSERR_INPUT_EMPTY";
		case JPSYSERR_PTR_COMM: return @"JPSYSERR_PTR_COMM";
		case JPSYSERR_CLR_EMPTY: return @"JPSYSERR_CLR_EMPTY";
		case JPSYSERR_BLK_EMPTY: return @"JPSYSERR_BLK_EMPTY";
		case JPSYSERR_BOTH_EMPTY: return @"JPSYSERR_BOTH_EMPTY";
		case JPSYSERR_PICK: return @"JPSYSERR_PICK";
		case JPSYSERR_ARM_MOVE: return @"JPSYSERR_ARM_MOVE";
		case JPSYSERR_CART_MOVE: return @"JPSYSERR_CART_MOVE";
		case JPSYSERR_ADMIN: return @"JPSYSERR_ADMIN";
		case JPSYSERR_INTERNAL_SW: return @"JPSYSERR_INTERNAL_SW";
		case JPSYSERR_NO_ROBODRIVES: return @"JPSYSERR_NO_ROBODRIVES";
		case JPSYSERR_OFFLINE: return @"JPSYSERR_OFFLINE";
		case JPSYSERR_COVER_OPEN: return @"JPSYSERR_COVER_OPEN";
		case JPSYSERR_PRINTER_PICK: return @"JPSYSERR_PRINTER_PICK";
		case JPSYSERR_MULTIPLE_PICK: return @"JPSYSERR_MULTIPLE_PICK";
		case JPSYSERR_DROPPED_DISC_RECORDER: return @"JPSYSERR_DROPPED_DISC_RECORDER";
		case JPSYSERR_DROPPED_DISC_PRINTER: return @"JPSYSERR_DROPPED_DISC_PRINTER";
		case JPSYSERR_DROPPED_DISC_LEFTBIN: return @"JPSYSERR_DROPPED_DISC_LEFTBIN";
		case JPSYSERR_DROPPED_DISC_REJECT: return @"JPSYSERR_DROPPED_DISC_REJECT";
		case JPSYSERR_ALIGNNEEDED: return @"JPSYSERR_ALIGNNEEDED";
		case JPSYSERR_COLOR_INVALID: return @"JPSYSERR_COLOR_INVALID";
		case JPSYSERR_BLACK_INVALID: return @"JPSYSERR_BLACK_INVALID";
		case JPSYSERR_BOTH_INVALID: return @"JPSYSERR_BOTH_INVALID";
		case JPSYSERR_NOCARTS: return @"JPSYSERR_NOCARTS";
		case JPSYSERR_K_IN_CMY: return @"JPSYSERR_K_IN_CMY";
		case JPSYSERR_CMY_IN_K: return @"JPSYSERR_CMY_IN_K";
		case JPSYSERR_SWAPPED: return @"JPSYSERR_SWAPPED";
		case JPSYSERR_PIGONPRO: return @"JPSYSERR_PIGONPRO";
		case JPSYSERR_ALIGNFAILED: return @"JPSYSERR_ALIGNFAILED";
		case JPSYSERR_DROPPED_DISC_PRINTER_FATAL: return @"JPSYSERR_DROPPED_DISC_PRINTER_FATAL";
		case JPSYSERR_MULTIPLEDISCS_IN_RIGHTBIN: return @"JPSYSERR_MULTIPLEDISCS_IN_RIGHTBIN";
		case JPSYSERR_MULTIPLEDISCS_IN_LEFTBIN: return @"JPSYSERR_MULTIPLEDISCS_IN_LEFTBIN";
		case JPSYSERR_CLR_EMPTY_FINAL: return @"JPSYSERR_CLR_EMPTY_FINAL";
		case JPSYSERR_BLK_EMPTY_FINAL: return @"JPSYSERR_BLK_EMPTY_FINAL";
		case JPSYSERR_BOTH_EMPTY_FINAL: return @"JPSYSERR_BOTH_EMPTY_FINAL";
		case JPSYSERR_WAITING_FOR_PRINTER: return @"JPSYSERR_WAITING_FOR_PRINTER";
		case JPSYSERR_DROPPED_DISC_OTHER: return @"JPSYSERR_DROPPED_DISC_OTHER";
		case JPSYSERR_NO_DISC_IN_PRINTER: return @"JPSYSERR_NO_DISC_IN_PRINTER";
		case JPSYSERR_DROPPED_DISC_RIGHTBIN: return @"JPSYSERR_DROPPED_DISC_RIGHTBIN";
		case JPSYSERR_BUSY: return @"JPSYSERR_BUSY";
		default: return [NSString stringWithFormat:@"JPSYSERR %u", err];
	}
}

+(NSString*)JPError:(UInt32)err {
	switch (err) {
		case JOBERR_INTERNAL_RECORDING: return @"JOBERR_INTERNAL_RECORDING";
		case JOBERR_INTERNAL_JOBPROC: return @"JOBERR_INTERNAL_JOBPROC";
		case JOBERR_INTERNAL_ROBOTICS: return @"JOBERR_INTERNAL_ROBOTICS";
		case JOBERR_BURNFILE_INVALID: return @"JOBERR_BURNFILE_INVALID";
		case JOBERR_BURNFILE_TOO_MANY: return @"JOBERR_BURNFILE_TOO_MANY";
		case JOBERR_BURNFILE_NONE: return @"JOBERR_BURNFILE_NONE";
		case JOBERR_PRINTFILE_INVALID: return @"JOBERR_PRINTFILE_INVALID";
		case JOBERR_JOBFILE_INVALID: return @"JOBERR_JOBFILE_INVALID";
		case JOBERR_STATUSFILE: return @"JOBERR_STATUSFILE";
		case JOBERR_MEDIA_INVALID: return @"JOBERR_MEDIA_INVALID";
		case JOBERR_MEDIA_NO_SPACE: return @"JOBERR_MEDIA_NO_SPACE";
		case JOBERR_MEDIA_NOT_BLANK: return @"JOBERR_MEDIA_NOT_BLANK";
		case JOBERR_DRIVE_OPENCLOSE: return @"JOBERR_DRIVE_OPENCLOSE";
		case JOBERR_DRIVE_NOT_READY: return @"JOBERR_DRIVE_NOT_READY";
		case JOBERR_DRIVE_NOT_ROBOTIC: return @"JOBERR_DRIVE_NOT_ROBOTIC";
		case JOBERR_ABORTED: return @"JOBERR_ABORTED";
		case JOBERR_DVD_INVALID: return @"JOBERR_DVD_INVALID";
		case JOBERR_RECORDING: return @"JOBERR_RECORDING";
		case JOBERR_VERIFYING: return @"JOBERR_VERIFYING";
		case JOBERR_REJECTS_TOO_MANY: return @"JOBERR_REJECTS_TOO_MANY";
		case JOBERR_SESSION_INVALID: return @"JOBERR_SESSION_INVALID";
		case JOBERR_CLIENT_INVALID: return @"JOBERR_CLIENT_INVALID";
		case JOBERR_CLIENTMSG_INVALID: return @"JOBERR_CLIENTMSG_INVALID";
		case JOBERR_UNKNOWN_JOBTYPE: return @"JOBERR_UNKNOWN_JOBTYPE";
		case JOBERR_KEYVALUE_INVALID: return @"JOBERR_KEYVALUE_INVALID";
		case JOBERR_TEMP_OVERFLOW: return @"JOBERR_TEMP_OVERFLOW";
		case JOBERR_CDTEXT_INVALID: return @"JOBERR_CDTEXT_INVALID";
		case JOBERR_PRINTAPP_NOTINSTALLED: return @"JOBERR_PRINTAPP_NOTINSTALLED";
		case JOBERR_PRINTFILE_NOTEXIST: return @"JOBERR_PRINTFILE_NOTEXIST";
		case JOBERR_INVALIDCART_FOR_PRINT: return @"JOBERR_INVALIDCART_FOR_PRINT";
		case JOBERR_READLOC_NO_SPACE: return @"JOBERR_READLOC_NO_SPACE";
		case JOBERR_READING: return @"JOBERR_READING";
		case JOBERR_INVALID_PVDFIELD: return @"JOBERR_INVALID_PVDFIELD";
		case JOBERR_INVALID_PVDJOBTYPE: return @"JOBERR_INVALID_PVDJOBTYPE";
		case JOBERR_CREATING_IMAGE: return @"JOBERR_CREATING_IMAGE";
		case JOBERR_NO_STATUS: return @"JOBERR_NO_STATUS";
		case JOBERR_NOT_SUPPORTED: return @"JOBERR_NOT_SUPPORTED";
		case JOBERR_INVALID_JOB_ID: return @"JOBERR_INVALID_JOB_ID";
		case JOBERR_STRING_TOO_LONG: return @"JOBERR_STRING_TOO_LONG";
		case JOBERR_NOT_READY: return @"JOBERR_NOT_READY";
		case THREAD_TERMINATED: return @"THREAD_TERMINATED";
		default: return [DiscPublisher JPSystemError:err];
	}
}

+(NSString*)JMError:(UInt32)err {
	switch (err) {
		case JM_XML_OPEN_ERR: return @"JM_XML_OPEN_ERR";
		case JM_XML_SAVE_ERR: return @"JM_XML_SAVE_ERR";
		case JM_XML_ERROR: return @"JM_XML_ERROR";
		case JM_INTERNAL_ERR: return @"JM_INTERNAL_ERR";
		case JM_TRY_LATER: return @"JM_TRY_LATER";
		case JM_NO_ROBOTS: return @"JM_NO_ROBOTS";
		case JM_DRIVE_NOT_FOUND: return @"JM_DRIVE_NOT_FOUND";
		case JM_FILE_NOT_FOUND: return @"JM_FILE_NOT_FOUND";
		case JM_NO_FILE_SPECIFIED: return @"JM_NO_FILE_SPECIFIED";
		case JM_LOGGING_ERROR: return @"JM_LOGGING_ERROR";
		default: return [DiscPublisher JPSystemError:err];
	}
}

@end
