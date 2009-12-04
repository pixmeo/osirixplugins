//
//  logWindowController.m
//  logExtractor
//
//  Created by Antoine Rosset on 19.07.07.
//

#import "logWindowController.h"

NSInteger sortByAddress(NSDictionary *roi1, NSDictionary *roi2, void *context)
{
	return [[roi1 objectForKey:@"ip"] compare: [roi2 objectForKey:@"ip"]];
}

@implementation logWindowController

- (void)awakeFromNib
 {
	if( [[NSUserDefaults standardUserDefaults] stringForKey:@"lastURL"])
		[urlString setStringValue: [[NSUserDefaults standardUserDefaults] stringForKey:@"lastURL"]];
 }

- (NSCalendarDate*) convertDate: (NSString*) date
{
	int day;
	int month;
	int year;
	
	day = [[date substringWithRange: NSMakeRange(0,2)] intValue];
	
	NSString *monthString = [date substringWithRange: NSMakeRange(3,3)];
	
	if( [monthString isEqualToString: @"Jan"]) month = 1;
	else if( [monthString isEqualToString: @"Feb"]) month = 2;
	else if( [monthString isEqualToString: @"Mar"]) month = 3;
	else if( [monthString isEqualToString: @"Apr"]) month = 4;
	else if( [monthString isEqualToString: @"May"]) month = 5;
	else if( [monthString isEqualToString: @"Jun"]) month = 6;
	else if( [monthString isEqualToString: @"Jul"]) month = 7;
	else if( [monthString isEqualToString: @"Aug"]) month = 8;
	else if( [monthString isEqualToString: @"Sep"]) month = 9;
	else if( [monthString isEqualToString: @"Oct"]) month = 10;
	else if( [monthString isEqualToString: @"Nov"]) month = 11;
	else if( [monthString isEqualToString: @"Dec"]) month = 12;
	
	year = [[date substringWithRange: NSMakeRange(7,4)] intValue];
	
	return [NSCalendarDate dateWithYear: year month:month day:day hour:0 minute:0 second:0 timeZone:0L];
}

- (void) analyzeThread:(NSDictionary*) threadDictionary
{
	NSAutoreleasePool	*globalPool = [[NSAutoreleasePool alloc] init];
	
	int i;
	
	NSArray	*lines = [threadDictionary objectForKey: @"lines"];
	NSMutableArray	*dictionaryArray = [threadDictionary objectForKey: @"dictionaryArray"];
	int processor = [[threadDictionary objectForKey: @"processor"] intValue];
	
	int total = [lines count] -1;
	
	int processors = MPProcessors();
	int from = (processor * total) / processors;
	int to = ((processor+1) * total) / processors;
	
	[lock lock];
	NSLog( @"thread id: %d, from:%d to:%d", processor, from ,to);
	[lock unlock];
	
	for( i = from ; i < to; i++)
	{
		NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
		
		NSScanner	*scan = [NSScanner scannerWithString: [lines objectAtIndex: i]];
		
		NSString	*empty = 0L, *ip = 0L, *date = 0L, *url = 0L;
		
		@try
		{
			[scan scanUpToString:@" " intoString: &ip]; 
			[scan scanUpToString:@"[" intoString: &empty];
			[scan setScanLocation: [scan scanLocation] +1];
			[scan scanUpToString:@"] " intoString: &date]; 
			[scan scanUpToString:@"/" intoString: &empty];
			[scan setScanLocation: [scan scanLocation] +1];
			[scan scanUpToString:@" HTTP" intoString: &url];
		}
		
		@catch (NSException *e)
		{
			NSLog( [lines objectAtIndex: i]);
			NSLog(@"%@", e);
		}
		NSCalendarDate	*nsdate = [self convertDate: date];
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: ip, @"ip", nsdate, @"date", url, @"url", 0L];
		[dictionaryArray replaceObjectAtIndex:i withObject: dict];
		
		if( processor == processors-1 && i % 2000 == 0)
		{
			[state setStringValue: [NSString stringWithFormat: @"analyzing: %2.2f %%", (float) (100. * (i-from) * processors) / (float) total]];
			[state display];
		}
		
		
		[pool release];
	}
	
	[lock lock];
	threadsFinished++;
	[lock unlock];
	
	[globalPool release];
}

- (void) analyze:(NSString*) f
{	
	NSArray		*lines = [f componentsSeparatedByString:@"\r"];
	NSLog( @"lines: %d", [lines count]);
	
	NSMutableArray		*dictionaryArray = [NSMutableArray arrayWithCapacity: [lines count]];
	int i,x;
	
	NSLog( @"a");
	
	for( i = 0 ; i < [lines count]-1; i++)
	{
		[dictionaryArray addObject: [NSDictionary dictionary]];
	}
	
	int processors = MPProcessors();
	
	lock = [[NSLock alloc] init];
	threadsFinished = 0;

	
	for( i = 0; i < processors-1; i++)
	{
		[NSThread detachNewThreadSelector:@selector(analyzeThread:) toTarget:self withObject: [NSDictionary dictionaryWithObjectsAndKeys: lines, @"lines", dictionaryArray, @"dictionaryArray", [NSNumber numberWithInt: i], @"processor", 0L]];
	}

	[self analyzeThread: [NSDictionary dictionaryWithObjectsAndKeys: lines, @"lines", dictionaryArray, @"dictionaryArray", [NSNumber numberWithInt: i], @"processor", 0L]];
	
	while( threadsFinished != processors)
	{
	}
	
	[state setStringValue: @"analyzing done, start extraction"];
	[state display];
	
	// Extract each month : total connection / unique ip
	NSMutableString	*result = [NSMutableString string];
	
	for( i = 0 ; i < [dictionaryArray count]; i++)
	{
		NSCalendarDate	*startdate = [[dictionaryArray objectAtIndex: i] objectForKey:@"date"];
		int				startIndex = i;
		NSCalendarDate	*curDate = 0L;
		
		do
		{
			i++;
			curDate = [[dictionaryArray objectAtIndex: i] objectForKey:@"date"];

		}while( [curDate monthOfYear] == [startdate monthOfYear] && i < [dictionaryArray count]-1);
		
		NSMutableArray	*uniqueIP = [NSMutableArray arrayWithCapacity: [dictionaryArray count]];
		
		float tiger = 0;
		float leopard = 0;
		
		id* objects = calloc( i-startIndex, sizeof(id));
		[dictionaryArray getObjects: objects range: NSMakeRange( startIndex, i-startIndex)];
		NSArray *a = [NSArray arrayWithObjects: objects count: i-startIndex]; 
		free( objects);
		
		a = [a sortedArrayUsingFunction: sortByAddress context: 0];
		
		NSString *lastIp = 0L;
		
		for( NSDictionary *c in a)
		{
			NSString *ip = [c objectForKey:@"ip"];
			
			if( [ip isEqualToString: lastIp] == NO)
			{
				lastIp = ip;
				[uniqueIP addObject: ip];
				
				NSString *url = [c objectForKey:@"url"];
				
				if( [url isEqualToString:@"versionLeopard.xml"]) leopard++;
				else if( [url isEqualToString:@"versionTiger.xml"]) tiger++;
			}
		}
		
		[state setStringValue: [NSString stringWithFormat: @"extracting: %2.2f %%", (float) (100. * i) / (float) [lines count]]];
		[state display];
		
		int uniqueIPs = [uniqueIP count];
		int ii = i;
		
		ii = ii - startIndex ;
		
		if( [startdate monthOfYear] == [[NSCalendarDate date] monthOfYear] && [startdate yearOfCommonEra] == [[NSCalendarDate date] yearOfCommonEra])
		{
			[result appendString: [NSString stringWithFormat: @"*** uncorrected month: %d : hits: %d unique ip: %d (10.4: %.2f %% 10.5: %.2f %%)\r", [startdate monthOfYear], ii, uniqueIPs, tiger * 100. / (tiger+leopard), leopard * 100. / (tiger+leopard)]];
			
			ii = (ii * 31) / [[NSCalendarDate date] dayOfMonth];
			ii += ((float) ii * (24. - [[NSCalendarDate date] hourOfDay])/24.)/ 31.;
			
			uniqueIPs = (uniqueIPs * 31) / [[NSCalendarDate date] dayOfMonth];
		}
		
		[result appendString: [NSString stringWithFormat: @"month: %d : hits: %d unique ip: %d (10.4: %.2f %% 10.5: %.2f %%)\r", [startdate monthOfYear], ii, uniqueIPs, tiger * 100. / (tiger+leopard), leopard * 100. / (tiger+leopard)]];
		[resultField setString: result];
		[resultField display];
	}
	
	[resultField setString: result];
	[state setStringValue: @"done !"];
}

- (IBAction) openLog:(id) sender;
{
	NSOpenPanel	*open = [NSOpenPanel openPanel];
	
	if( [open runModal] == NSFileHandlingPanelOKButton)
	{
		[self analyze: [NSString stringWithContentsOfFile: [open filename]]];
	}
}

- (IBAction) openLogURL:(id) sender;
{
	[state setStringValue: @"downloading..."];		[state display];
	
	NSString *str = [NSString stringWithContentsOfURL: [NSURL URLWithString: [urlString stringValue]]];
	if( str)
	{
		[[NSFileManager defaultManager] removeFileAtPath: @"last_URL" handler: 0L];
		[str writeToFile: @"last_URL" atomically: YES];
		[self analyze: str];
	
		[[NSUserDefaults standardUserDefaults] setObject: [urlString stringValue] forKey: @"lastURL"];
	}
	else NSBeep();
}

@end
