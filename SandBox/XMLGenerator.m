//
//  SandBoxTestFilter.m
//  SandBoxTest
//
//  Copyright (c) 2013 Thomas. All rights reserved.
//

#import "XMLGenerator.h"

#import "AppController.h"
#import "WaitRendering.h"
#import <OsiriX/DCM.h>
#import "MutableArrayCategory.h"
#import <DiscRecordingUI/DRSetupPanel.h>
#import <DiscRecordingUI/DRBurnSetupPanel.h>
#import <DiscRecordingUI/DRBurnProgressPanel.h>
#import "BrowserController.h"
#import "DicomStudy.h"
#import "DicomSeries.h"
#import "DicomImage.h"
#import "DicomStudy+Report.h"
#import "Anonymization.h"
#import "AnonymizationPanelController.h"
#import "AnonymizationViewController.h"
#import "ThreadsManager.h"
#import "NSThread+N2.h"
#import "NSFileManager+N2.h"
#import "N2Debug.h"
#import "NSImage+N2.h"
#import "DicomDir.h"
#import "DicomDatabase.h"
#import <DiskArbitration/DiskArbitration.h>


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
@synthesize originalFile;

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
	[originalFile dealloc];
	[super dealloc];
}

@end





@implementation XMLGenerator

+ (void) createDicomStructureAtPath:(NSString*)path withFiles:(NSMutableArray*)files withCorrespondingImages:(NSMutableArray*)images
{
	NSLog(@"************ Start Create Dicom Structure");
	
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
	
	
	
	NSEnumerator *enumerator;
	//if( anonymizedFiles)
	//enumerator = [anonymizedFiles objectEnumerator];
	//else
		enumerator = [files objectEnumerator];
	NSString *file;
	
	
	while(file = [enumerator nextObject])
		//for (id file in files)
	{
		NSLog(@"file : %@", file);
		
		
		
		
		
		DCMObject *dcmObject = nil;
		

		dcmObject = [DCMObject objectWithContentsOfFile:file decodingPixelData:NO];

		
		
		
		
		
		if (dcmObject)	// <- it's a DICOM file
		{
			NSLog(@"It's a dicom file");
			
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
				if (patient)
				{
					study = [[S_DicomNode alloc] initWithDCMObject:dcmObject];
					[study setParent:patient];
				}
			}
			
			// New series
			if (![seriesInstanceUID isEqualToString:[dcmObject attributeValueWithName:@"SeriesInstanceUID"]])
			{
				seriesInstanceUID = (NSString*)[dcmObject attributeValueWithName:@"SeriesInstanceUID"];
				if (study)
				{
					series = [[S_DicomNode alloc] initWithDCMObject:dcmObject];
					[series setParent:study];
				}
			}
			
			// New instance
			if (![SOPInstanceUID isEqualToString:[dcmObject attributeValueWithName:@"SOPInstanceUID"]])
			{
				SOPInstanceUID = (NSString*)[dcmObject attributeValueWithName:@"SOPInstanceUID"];
				if (series)
				{
					instance = [[S_DicomNode alloc] initWithDCMObject:dcmObject];
					[instance setParent:series];
					NSLog(@"TOTO");
					[instance setOriginalFile:file];
				}
			}
		}
	}
	
	NSLog(@"************ Check 1");
	
//	DCMObject *object = [[patientsList lastObject] dcmObject];
//	NSXMLDocument *doc = [object xmlDocument];
//	
//	NSData *xmlData = [doc XMLDataWithOptions:NSXMLNodePrettyPrint];
//	NSString* outputPath = [[NSString alloc] initWithString:[path stringByAppendingPathComponent:@"test.xml"]];
//
//	NSLog(@"************ Check 2");
//	
//	if (![xmlData writeToFile:outputPath atomically:YES])
//	{
//		NSLog(@"Could not write document out AAAAAAA");
//	}
//	[doc release];
//	
//	NSLog(@"************ Check 7");
	
	NSXMLElement *rootXML = (NSXMLElement*)[NSXMLNode elementWithName:@"DicomStructure"];
	int compteur = 0;
	
	for (id patient in patientsList)
	{
		patientID = (NSString*)[[patient dcmObject] attributeValueWithName:@"PatientID"];
		NSString* patientBirthDate = (NSString*)[[patient dcmObject] attributeValueWithName:@"PatientsBirthDate"];
		NSString* patientPath = [NSString stringWithFormat:@"%@/%@%@%@", path, patientID, @"-", patientBirthDate];
		
		[manager createDirectoryAtPath:patientPath withIntermediateDirectories:FALSE attributes:nil error:nil];
		
		NSXMLElement *patientXML = (NSXMLElement *)[NSXMLNode elementWithName:@"DicomStructure"];
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
			
			NSXMLElement *studyXML = (NSXMLElement *)[NSXMLNode elementWithName:@"DicomStructure"];
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
				
				NSXMLElement *seriesXML = (NSXMLElement *)[NSXMLNode elementWithName:@"DicomStructure"];
				NSXMLElement *seriesNode = (NSXMLElement *)[NSXMLNode elementWithName:@"Series"];
				[seriesNode setAttributes:[self seriesAttributes:[series dcmObject]]];
				[seriesXML addChild:seriesNode];
				
				for (id instance in [series children])
				{
					DCMObject *instanceDicomObject = [instance dcmObject];
					NSString *instanceFileName = [instanceDicomObject attributeValueWithName:@"SOPInstanceUID"];
					NSString *instancePath = [NSString stringWithFormat:@"%@/%@", seriesPath, instanceFileName];
					
					//NSLog(@"************ Check Instance 1");
					//NSLog(@"Instance file name : %@", instanceFileName);
					//NSLog(@"Instance path : %@", instancePath);
					
					// Write dicom file
					//bool temp = [instanceDicomObject writeToFile:instancePath withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality:DCMLosslessQuality atomically:YES];

					
					
					if( [[instanceDicomObject transferSyntax] isEqualToTransferSyntax:[DCMTransferSyntax ExplicitVRBigEndianTransferSyntax]])
						[instanceDicomObject writeToFile:instancePath withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality: DCMLosslessQuality atomically:YES];
					else
						[manager copyPath:[instance originalFile] toPath:instancePath handler:nil];
					//[manager copyItemAtURL:[instance originalFile] toURL:instancePath error:nil];
					
					
					
					//NSLog(@"************ Check Instance 2");
					
					// Add instances to xml file
					NSXMLElement *instanceNode = (NSXMLElement*)[NSXMLNode elementWithName:@"Instance"];
					[instanceNode setAttributes:[NSArray arrayWithObjects:
																			[NSXMLNode attributeWithName:@"SOPInstanceUID" stringValue:instanceFileName],
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
				DicomImage *dicomImage = [images objectAtIndex:(compteur-1)];
				NSData *imageSeries = [[dicomImage series] thumbnail];
				NSImage *im = [[NSImage alloc] initWithData:imageSeries];
				[im saveAsJpegWithName:[seriesPath stringByAppendingPathComponent:@"thumbnail.jpg"]];
				
				//NSLog(@"dicomImage class name : %@", [dicomImage className]);
				
				
				
				
				
				
				// Test bigger thumbnails
				
				//NSImage *testimage = [dicomImage image];
				//NSData *test = [[dicomImage series] images];
				
//				NSSize size;
//				size = NSMakeSize(70, 70);
//
//				NSImage* test2 = [(NSImage*)dicomImage imageByScalingProportionallyToSize:size];
//				[test2 saveAsJpegWithName:[seriesPath stringByAppendingPathComponent:@"thumbnail_2.jpg"]];

			}
		}
	}
	
	NSLog(@"************ End Create Dicom Structure");	
	
	[self generateXMLFile:@"dicom-structure.xml" atPath:path withContent:rootXML];
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
																[NSXMLNode attributeWithName:@"PatientSex" stringValue:[object attributeValueWithName:@"patientSex"]],
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





