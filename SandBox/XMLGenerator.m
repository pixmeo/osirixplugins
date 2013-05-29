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




@implementation XMLGenerator


+ (void) createDicomStructureWithFiles:(NSMutableArray*)files atPath:(NSString*)dicomFolderPath withObjects:(NSMutableArray*)dbObjectsID
{
	[self generateXMLFile:@"dicom_structure.xml" atPath:dicomFolderPath withContent:nil];
	
	NSFileManager *manager = [NSFileManager defaultManager]; // For create folders
	
	NSEnumerator *enumerator;
	enumerator = [files objectEnumerator];
	id file;
	
	NSString *patientID = @"";
	NSString *patientPath = @"";
	
	NSString *studyInstanceUID = @"";
	NSString *studyPath = @"";
	
	NSString *seriesInstanceUID = @"";
	NSString *seriesPath = @"";
	
	int compteur = 0;
	while (file = [enumerator nextObject])
	{
	
		DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:file decodingPixelData:NO];
		if( dcmObject)	// <- it's a DICOM file
		{
			
			if (![patientID isEqualToString:[dcmObject attributeValueWithName:@"PatientID"]]) // New patient
			{
				patientID = (NSString*)[dcmObject attributeValueWithName:@"PatientID"];
				patientPath = [dicomFolderPath stringByAppendingPathComponent:patientID];
				
				NSXMLElement *patientXML = (NSXMLElement *)[NSXMLNode elementWithName:@"dicom"];
				[patientXML addChild:[NSXMLNode elementWithName:@"Patient" children:nil attributes:[self patientAttributes:dcmObject]]];
				
				[manager createDirectoryAtPath:patientPath attributes:nil];
				[self generateXMLFile:@"index.xml" atPath:patientPath withContent:patientXML];
			}
			
			if (![studyInstanceUID isEqualToString:[dcmObject attributeValueWithName:@"StudyInstanceUID"]]) // New study
			{
				studyInstanceUID = (NSString*)[dcmObject attributeValueWithName:@"StudyInstanceUID"];
				studyPath = [patientPath stringByAppendingPathComponent:studyInstanceUID];
				
				NSXMLElement *studyXML = (NSXMLElement *)[NSXMLNode elementWithName:@"dicom"];
				[studyXML addChild:[NSXMLNode elementWithName:@"Study" children:nil attributes:[self studyAttributes:dcmObject]]];
				
				[manager createDirectoryAtPath:studyPath attributes:nil];
				[self generateXMLFile:@"index.xml" atPath:studyPath withContent:studyXML];
			}
			
			if (![seriesInstanceUID isEqualToString:[dcmObject attributeValueWithName:@"SeriesInstanceUID"]]) // New series
			{
				seriesInstanceUID = (NSString*)[dcmObject attributeValueWithName:@"SeriesInstanceUID"];
				seriesPath = [studyPath stringByAppendingPathComponent:seriesInstanceUID];
				
				NSXMLElement *seriesXML = (NSXMLElement *)[NSXMLNode elementWithName:@"dicom"];
				[seriesXML addChild:[NSXMLNode elementWithName:@"Series" children:nil attributes:[self seriesAttributes:dcmObject]]];
				
				[manager createDirectoryAtPath:seriesPath attributes:nil];
				[self generateXMLFile:@"index.xml" atPath:seriesPath withContent:seriesXML];
				
				DicomImage *im = [dbObjectsID lastObject];
				NSImage *test = [im thumbnail];
				[test saveAsJpegWithName:[seriesPath stringByAppendingPathComponent:@"thumbnail.jpg"]];
			}
			
			[dcmObject writeToFile:[NSString stringWithFormat:@"%@/%05d", seriesPath, compteur++] withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality: DCMLosslessQuality atomically:YES];
		}
	}
}


+ (void) generateXMLFile:(NSString*)fileName atPath:(NSString*)path withContent:(NSXMLElement*)content
{
	//NSLog(@"generateXMLFile: %@ at path: %@", fileName, path);
	
	NSXMLDocument *xmlDoc;
	if (content != nil)
		xmlDoc = [[NSXMLDocument alloc] initWithRootElement:content];
	else
		xmlDoc = [[NSXMLDocument alloc] initWithRootElement:[NSXMLElement elementWithName:@"root"]];
	
	[xmlDoc setVersion:@"1.0"];
	[xmlDoc setCharacterEncoding:@"UTF-8"];
	
	NSString* outputPath = [[NSString alloc] initWithString:[path stringByAppendingPathComponent:fileName]];
	//NSLog(@"outputPath : %@", outputPath);
	
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
															 [NSXMLNode attributeWithName:@"DirectDownloadThumbnail" stringValue:[object attributeValueWithName:@""]],
															 nil];
	return seriesAttributes;
}


@end
