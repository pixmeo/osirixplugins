//
//  SandBoxTestFilter.m
//  SandBoxTest
//
//  Copyright (c) 2013 Thomas. All rights reserved.
//

#import "XMLGenerator.h"


@interface NSImage(saveAsJpegWithName)
- (void) saveAsJpegWithName:(NSString*) fileName;
@end

@implementation NSImage(saveAsJpegWithName)

- (void) saveAsJpegWithName:(NSString*) fileName
{
	// Cache the reduced image
	NSData *imageData = [self TIFFRepresentation];
	NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
	NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
	imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
	[imageData writeToFile:fileName atomically:NO];
}

@end




@implementation S_DicomNode

@synthesize parent;
@synthesize children;
@synthesize dcmObject;

- (id) initWithDCMObject:(DCMObject*)object
{
	if (self = [super init])
	{
		[self setDcmObject:object];
		[self setParent:nil];
		[self setChildren:[NSMutableArray array]];
	}
	return self;
}

- (void) setParent:(S_DicomNode*)newParent
{
	parent = newParent;
	[newParent addChild:self];
}

- (void) addChild:(S_DicomNode*)newChild
{
	[children addObject:newChild];
	if ([newChild parent] != self)
		[newChild setParent:self];
}

- (void) dealloc
{
	[dcmObject release];
	[parent release];
	[children release];
	[super dealloc];
}

@end





@implementation XMLGenerator

+ (void) createDicomStructureAtPath:(NSString*)path withFiles:(NSMutableArray*)files withCorrespondingImages:(NSMutableArray*)images
{
	NSFileManager *manager = [NSFileManager defaultManager]; // For create folders
	
	NSString *patientPath = path;
	NSString *studyPath = path;
	NSString *seriesPath = path;
	
	NSString *patientID = @"";
	NSString *studyInstanceUID = @"";
	NSString *seriesInstanceUID = @"";
	NSString *SOPInstanceUID = @"";
	
	S_DicomNode *patient;
	S_DicomNode *study;
	S_DicomNode *series;
	S_DicomNode *instance;
	
	NSMutableArray *patientsList = [NSMutableArray array];
	
	for (id file in files)
	{
		DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:file decodingPixelData:NO];
		if (dcmObject)	// <- it's a DICOM file
		{
			// New patient
			if (![patientID isEqualToString:[dcmObject attributeValueWithName:@"PatientID"]])
			{
				patientID = (NSString*)[dcmObject attributeValueWithName:@"PatientID"];
				patient = [[S_DicomNode alloc] initWithDCMObject:dcmObject];
				[patientsList addObject:patient];
			}
			
			// New study
			if (![studyInstanceUID isEqualToString:[dcmObject attributeValueWithName:@"StudyInstanceUID"]])
			{
				studyInstanceUID = (NSString*)[dcmObject attributeValueWithName:@"StudyInstanceUID"];
				study = [[S_DicomNode alloc] initWithDCMObject:dcmObject];
				[study setParent:patient];
			}
			
			// New series
			if (![seriesInstanceUID isEqualToString:[dcmObject attributeValueWithName:@"SeriesInstanceUID"]])
			{
				seriesInstanceUID = (NSString*)[dcmObject attributeValueWithName:@"SeriesInstanceUID"];
				series = [[S_DicomNode alloc] initWithDCMObject:dcmObject];
				[series setParent:study];
			}
			
			// New instance
			if (![SOPInstanceUID isEqualToString:[dcmObject attributeValueWithName:@"SOPInstanceUID"]])
			{
				SOPInstanceUID = (NSString*)[dcmObject attributeValueWithName:@"SOPInstanceUID"];
				instance = [[S_DicomNode alloc] initWithDCMObject:dcmObject];
				[instance setParent:series];
			}
		}
	}
	
	NSXMLElement *rootXML = (NSXMLElement*)[NSXMLNode elementWithName:@"dicom"];
	int compteur = 0;
	
	for (id patient in patientsList)
	{
		patientID = (NSString*)[[patient dcmObject] attributeValueWithName:@"PatientID"];
		patientPath = [path stringByAppendingPathComponent:patientID];
		[manager createDirectoryAtPath:patientPath withIntermediateDirectories:FALSE attributes:nil error:nil];
		
		NSXMLElement *patientXML = (NSXMLElement *)[NSXMLNode elementWithName:@"dicom"];
		NSXMLElement *patientNode = (NSXMLElement *)[NSXMLNode elementWithName:@"Patient"];
		[patientNode setAttributes:[self patientAttributes:[patient dcmObject]]];
		[patientXML addChild:patientNode];
		[self generateXMLFile:@"index.xml" atPath:patientPath withContent:patientXML];
		[patientNode detach];
		[rootXML addChild:patientNode];
		
		for (id study in [patient children])
		{
			studyInstanceUID = (NSString*)[[study dcmObject] attributeValueWithName:@"StudyInstanceUID"];
			studyPath = [patientPath stringByAppendingPathComponent:studyInstanceUID];
			[manager createDirectoryAtPath:studyPath withIntermediateDirectories:FALSE attributes:nil error:nil];
			
			NSXMLElement *studyXML = (NSXMLElement *)[NSXMLNode elementWithName:@"dicom"];
			NSXMLElement *studyNode = (NSXMLElement *)[NSXMLNode elementWithName:@"Study"];
			[studyNode setAttributes:[self studyAttributes:[study dcmObject]]];
			[studyXML addChild:studyNode];
			[self generateXMLFile:@"index.xml" atPath:studyPath withContent:studyXML];
			[studyNode detach];
			[patientNode addChild:studyNode];
			
			for (id series in [study children])
			{
				seriesInstanceUID = (NSString*)[[series dcmObject] attributeValueWithName:@"SeriesInstanceUID"];
				seriesPath = [studyPath stringByAppendingPathComponent:seriesInstanceUID];
				[manager createDirectoryAtPath:seriesPath withIntermediateDirectories:FALSE attributes:nil error:nil];
				
				NSXMLElement *seriesXML = (NSXMLElement *)[NSXMLNode elementWithName:@"dicom"];
				NSXMLElement *seriesNode = (NSXMLElement *)[NSXMLNode elementWithName:@"Series"];
				[seriesNode setAttributes:[self seriesAttributes:[series dcmObject]]];
				[seriesXML addChild:seriesNode];
				
				for (id instance in [series children])
				{
					// Write dicom file
					[[instance dcmObject] writeToFile:[NSString stringWithFormat:@"%@/%05d", seriesPath, compteur] withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality:DCMLosslessQuality atomically:YES];
					
					// Add instances to xml file
					NSXMLElement *instanceNode = (NSXMLElement*)[NSXMLNode elementWithName:@"Instance"];
					[instanceNode setAttributes:[NSArray arrayWithObjects:
																			[NSXMLNode attributeWithName:@"SOPInstanceUID" stringValue:[NSString stringWithFormat:@"%05d", compteur]],
																			[NSXMLNode attributeWithName:@"InstanceNumber" stringValue:[NSString stringWithFormat:@"%i", compteur]],
																			[NSXMLNode attributeWithName:@"DirectDownloadFile" stringValue:@""],
																			nil]];
					[seriesNode addChild:instanceNode];
					
					compteur++;
				}
				
				[self generateXMLFile:@"index.xml" atPath:seriesPath withContent:seriesXML];
				[seriesNode detach];
				[studyNode addChild:seriesNode];
				
				// Create thumbnail
				NSData *imageSeries = [[[images objectAtIndex:(compteur-1)] series] thumbnail];
				NSImage *im = [[NSImage alloc] initWithData:imageSeries];
				[im saveAsJpegWithName:[seriesPath stringByAppendingPathComponent:@"thumbnail.jpg"]];
			}
		}
	}
	[self generateXMLFile:@"dicom_structure.xml" atPath:path withContent:rootXML];
}



+ (void) generateXMLFile:(NSString*)fileName atPath:(NSString*)path withContent:(NSXMLElement*)content
{
	NSXMLDocument *xmlDoc;
	if (content != nil)
		xmlDoc = [[NSXMLDocument alloc] initWithRootElement:content];
	else
		xmlDoc = [[NSXMLDocument alloc] initWithRootElement:[NSXMLElement elementWithName:@"root"]];
	
	[xmlDoc setVersion:@"1.0"];
	[xmlDoc setCharacterEncoding:@"UTF-8"];
	
	NSString* outputPath = [[NSString alloc] initWithString:[path stringByAppendingPathComponent:fileName]];
	
	NSData *xmlData = [xmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
	if (![xmlData writeToFile:outputPath atomically:YES])
	{
		NSLog(@"Could not write document out...");
	}
	
	[xmlDoc release];
}


+ (NSArray*) patientAttributes:(DCMObject*)object
{
	NSArray *patientAttributes = [NSArray arrayWithObjects:
																[NSXMLNode attributeWithName:@"PatientID" stringValue:[object attributeValueWithName:@"PatientID"]],
																[NSXMLNode attributeWithName:@"PatientName" stringValue:[object attributeValueWithName:@"PatientsName"]],
																[NSXMLNode attributeWithName:@"PatientBirthDate" stringValue:[object attributeValueWithName:@"PatientsBirthDate"]],
																[NSXMLNode attributeWithName:@"PatientSex" stringValue:[object attributeValueWithName:@"PatientsSex"]],
																nil];
	return patientAttributes;
}

+ (NSArray*) studyAttributes:(DCMObject*)object
{
	NSArray *studyAttributes = [NSArray arrayWithObjects:
															[NSXMLNode attributeWithName:@"StudyInstanceUID" stringValue:[object attributeValueWithName:@"StudyInstanceUID"]],
															[NSXMLNode attributeWithName:@"StudyDescription" stringValue:[object attributeValueWithName:@"StudyDescription"]],
															[NSXMLNode attributeWithName:@"StudyDate" stringValue:[object attributeValueWithName:@"StudyDate"]],
															[NSXMLNode attributeWithName:@"StudyTime" stringValue:[object attributeValueWithName:@"StudyTime"]],
															nil];
	return studyAttributes;
}

+ (NSArray*) seriesAttributes:(DCMObject*)object
{
	NSArray *seriesAttributes = [NSArray arrayWithObjects:
															 [NSXMLNode attributeWithName:@"SeriesInstanceUID" stringValue:[object attributeValueWithName:@"SeriesInstanceUID"]],
															 [NSXMLNode attributeWithName:@"SeriesDescription" stringValue:[object attributeValueWithName:@"SeriesDescription"]],
															 [NSXMLNode attributeWithName:@"SeriesNumber" stringValue:[object attributeValueWithName:@"SeriesNumber"]],
															 [NSXMLNode attributeWithName:@"Modality" stringValue:[object attributeValueWithName:@"Modality"]],
															 [NSXMLNode attributeWithName:@"DirectDownloadThumbnail" stringValue:@"thumbnail.jpg"],
															 nil];
	return seriesAttributes;
}

// Obsolète
+ (NSArray*) instanceAttributes:(DCMObject*)object
{
	NSArray *instanceAttributes = [NSArray arrayWithObjects:
																 [NSXMLNode attributeWithName:@"SOPInstanceUID" stringValue:[object attributeValueWithName:@""]],
																 [NSXMLNode attributeWithName:@"InstanceNumber" stringValue:[object attributeValueWithName:@""]],
																 [NSXMLNode attributeWithName:@"DirectDownloadFile" stringValue:[object attributeValueWithName:@""]],
																 nil];
	return instanceAttributes;
}


@end





