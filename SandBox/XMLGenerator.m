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

@synthesize identifier;
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
	[identifier release];
	[dcmObject release];
	[parent release];
	[children release];
	[originalFile release];
	[super dealloc];
}

@end



@implementation XMLGenerator

+ (void) createDicomStructureAtPath:(NSString*)path withFiles:(NSMutableArray*)files withCorrespondingImages:(NSMutableArray*)images
{
	NSLog(@"************ Start Create Dicom Structure");
	
	NSFileManager *manager = [NSFileManager defaultManager]; // For create folders
	
	
	NSMutableArray *patientIDList = [NSMutableArray array];
	NSMutableArray *studyIDList = [NSMutableArray array];
	NSMutableArray *seriesIDList = [NSMutableArray array];
	NSMutableArray *instanceIDList = [NSMutableArray array];
	
	NSMutableArray *patientPathList = [NSMutableArray array];
	NSMutableArray *studyPathList = [NSMutableArray array];
	NSMutableArray *seriesPathList = [NSMutableArray array];

	NSMutableArray *patientNodeList = [NSMutableArray array];
	NSMutableArray *studyNodeList = [NSMutableArray array];
	NSMutableArray *seriesNodeList = [NSMutableArray array];
	
	NSMutableArray *patientXMLList = [NSMutableArray array];
	NSMutableArray *studyXMLList = [NSMutableArray array];
	NSMutableArray *seriesXMLList = [NSMutableArray array];

	
	
	NSEnumerator *enumerator;
	//if( anonymizedFiles)
	//enumerator = [anonymizedFiles objectEnumerator];
	//else
	enumerator = [files objectEnumerator];
	NSString *file;
	
	
	int compteur = 0;
	
	NSXMLElement *rootXML = (NSXMLElement*)[NSXMLNode elementWithName:@"DicomStructure"];
	
	while (file = [enumerator nextObject])
	{
		compteur++;
		//NSLog(@"CompteurAAA : %d", compteur);
		
		@autoreleasepool
		{
			DCMObject *dcmObjectTest = [DCMObject objectWithContentsOfFile:file decodingPixelData:NO];
			
			if (dcmObjectTest)	// <- it's a DICOM file
			{
				
				// New patient
				if (![[patientIDList lastObject] isEqualToString:[dcmObjectTest attributeValueWithName:@"PatientID"]])
				{
					NSString* patientID = (NSString*)[dcmObjectTest attributeValueWithName:@"PatientID"];
					[patientIDList addObject:patientID];
					
					NSString* patientBirthDate = (NSString*)[dcmObjectTest attributeValueWithName:@"PatientsBirthDate"];
					
					NSString* patientPath = [NSString stringWithFormat:@"%@/%@%@%@", path, patientID, @"-", patientBirthDate];
					[patientPathList addObject:patientPath];
					
					[manager createDirectoryAtPath:patientPath withIntermediateDirectories:FALSE attributes:nil error:nil];
					
					NSXMLElement* patientXML = (NSXMLElement *)[NSXMLNode elementWithName:@"DicomStructure"];
					[patientXMLList addObject:patientXML];
					
					NSXMLElement* patientNode = (NSXMLElement *)[NSXMLNode elementWithName:@"Patient"];
					[patientNodeList addObject:patientNode];
					
					[patientNode setAttributes:[self patientAttributes:dcmObjectTest]];
					[patientXML addChild:patientNode];
					
					[self generateXMLFile:@"index.xml" atPath:patientPath withContent:patientXML];
					[patientNode detach];
					[rootXML addChild:patientNode];
				}
				
				// New study
				if (![[studyIDList lastObject] isEqualToString:[dcmObjectTest attributeValueWithName:@"StudyInstanceUID"]])
				{
					NSString* studyInstanceUID = (NSString*)[dcmObjectTest attributeValueWithName:@"StudyInstanceUID"];
					[studyIDList addObject:studyInstanceUID];
					
					NSString* studyPath = [[patientPathList lastObject] stringByAppendingPathComponent:studyInstanceUID];
					[studyPathList addObject:studyPath];
					
					[manager createDirectoryAtPath:studyPath withIntermediateDirectories:FALSE attributes:nil error:nil];
					
					NSXMLElement* studyXML = (NSXMLElement *)[NSXMLNode elementWithName:@"DicomStructure"];
					[studyXMLList addObject:studyXML];
					
					NSXMLElement* studyNode = (NSXMLElement *)[NSXMLNode elementWithName:@"Study"];
					[studyNodeList addObject:studyNode];
					
					[studyNode setAttributes:[self studyAttributes:dcmObjectTest]];
					[studyXML addChild:studyNode];
					
					[self generateXMLFile:@"index.xml" atPath:studyPath withContent:studyXML];
					[studyNode detach];
					[[patientNodeList lastObject] addChild:studyNode];
				}
				
				// New series
				if (![[seriesIDList lastObject] isEqualToString:[dcmObjectTest attributeValueWithName:@"SeriesInstanceUID"]])
				{
					NSString* seriesInstanceUID = (NSString*)[dcmObjectTest attributeValueWithName:@"SeriesInstanceUID"];
					[seriesIDList addObject:seriesInstanceUID];
					
					NSString* seriesPath = [[studyPathList lastObject] stringByAppendingPathComponent:seriesInstanceUID];
					[seriesPathList addObject:seriesPath];
					
					[manager createDirectoryAtPath:seriesPath withIntermediateDirectories:FALSE attributes:nil error:nil];
					
					NSXMLElement* seriesXML = (NSXMLElement *)[NSXMLNode elementWithName:@"DicomStructure"];
					[seriesXMLList addObject:seriesXML];
					
					NSXMLElement* seriesNode = (NSXMLElement *)[NSXMLNode elementWithName:@"Series"];
					[seriesNodeList addObject:seriesNode];
					
					[seriesNode setAttributes:[self seriesAttributes:dcmObjectTest]];
					[seriesXML addChild:seriesNode];
				}
				
				// New instance
				if (![[instanceIDList lastObject] isEqualToString:[dcmObjectTest attributeValueWithName:@"SOPInstanceUID"]])
				{
					NSString* SOPInstanceUID = (NSString*)[dcmObjectTest attributeValueWithName:@"SOPInstanceUID"];
					[instanceIDList addObject:SOPInstanceUID];
					
					NSString *instanceFileName = [dcmObjectTest attributeValueWithName:@"SOPInstanceUID"];
					NSString *instancePath = [NSString stringWithFormat:@"%@/%@", [seriesPathList lastObject], instanceFileName];
					
					// Write dicom file
					if( [[dcmObjectTest transferSyntax] isEqualToTransferSyntax:[DCMTransferSyntax ExplicitVRBigEndianTransferSyntax]])
						[dcmObjectTest writeToFile:instancePath withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality: DCMLosslessQuality atomically:YES];
					else
						[manager copyPath:file toPath:instancePath handler:nil];
					
					// Add instances to xml file
					NSXMLElement *instanceNode = (NSXMLElement*)[NSXMLNode elementWithName:@"Instance"];
					[instanceNode setAttributes:[NSArray arrayWithObjects:
																			 [NSXMLNode attributeWithName:@"SOPInstanceUID" stringValue:instanceFileName],
																			 [NSXMLNode attributeWithName:@"InstanceNumber" stringValue:[NSString stringWithFormat:@"%i", compteur]],
																			 [NSXMLNode attributeWithName:@"DirectDownloadFile" stringValue:@""],
																			 nil]];
					[[seriesNodeList lastObject] addChild:instanceNode];
					
				}
				
				// Create the series xml file (did after because of listing the instances)
				if (file != [files lastObject])
				{
					if (![[seriesIDList lastObject] isEqualToString:[[DCMObject objectWithContentsOfFile:[files objectAtIndex:compteur] decodingPixelData:NO] attributeValueWithName:@"SeriesInstanceUID"]])
					{
						[self generateXMLFile:@"index.xml" atPath:[seriesPathList lastObject] withContent:[seriesXMLList lastObject]];
						[[seriesNodeList lastObject] detach];
						[[studyNodeList lastObject] addChild:[seriesNodeList lastObject]];
					}
				}
				else
				{
					[self generateXMLFile:@"index.xml" atPath:[seriesPathList lastObject] withContent:[seriesXMLList lastObject]];
					[[seriesNodeList lastObject] detach];
					[[studyNodeList lastObject] addChild:[seriesNodeList lastObject]];
				}
				
			}
		}
	}

	[self generateXMLFile:@"dicom-structure.xml" atPath:path withContent:rootXML];
	NSLog(@"************ End Create Dicom Structure");
}



//+ (void) createDicomStructureAtPath:(NSString*)path withFiles:(NSMutableArray*)files withCorrespondingImages:(NSMutableArray*)images
//{
//	NSLog(@"************ Start Create Dicom Structure");
//	
//	NSFileManager *manager = [NSFileManager defaultManager]; // For create folders
//	
//	NSEnumerator *enumerator;
//	//if( anonymizedFiles)
//	//enumerator = [anonymizedFiles objectEnumerator];
//	//else
//	enumerator = [files objectEnumerator];
//	NSString *file;
//	
//	
//	
//	NSXMLElement *rootXML = (NSXMLElement*)[NSXMLNode elementWithName:@"DicomStructure"];
//	int compteur = 0;
//	
//	
//	NSString *patientID = @"";
//	NSString *studyInstanceUID = @"";
//	NSString *seriesInstanceUID = @"";
//	NSString *SOPInstanceUID = @"";
//	
//	NSString *patientPath = path;
//	NSString *studyPath = path;
//	NSString *seriesPath = path;
//	NSString *instancePath = path;
//	
//	NSXMLElement *patientNode;
//	NSXMLElement *studyNode;
//	NSXMLElement *seriesNode;
//	NSXMLElement *instanceNode;
//	
//	NSXMLElement *patientXML;
//	NSXMLElement *studyXML;
//	NSXMLElement *seriesXML;
//	
//	//S_DicomNode* currentPatient = nil;
//	
//	while (file = [enumerator nextObject])
//	{
//		//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//		//@autoreleasepool {
//		
//		compteur++;
//		NSLog(@"CompteurAAA : %d", compteur);
//		
//		DCMObject *dcmObjectTest = [[DCMObject objectWithContentsOfFile:file decodingPixelData:NO] autorelease];
//		
//		
//		if (dcmObjectTest)	// <- it's a DICOM file
//		{
//			
//			
//				
//			// New patient
//			if (![patientID isEqualToString:[dcmObjectTest attributeValueWithName:@"PatientID"]])
//			{
//				patientID = [dcmObjectTest attributeValueWithName:@"PatientID"];
//				NSString* patientBirthDate = (NSString*)[dcmObjectTest attributeValueWithName:@"PatientsBirthDate"];
//				patientPath = [NSString stringWithFormat:@"%@/%@%@%@", path, patientID, @"-", patientBirthDate];
//				[manager createDirectoryAtPath:patientPath withIntermediateDirectories:FALSE attributes:nil error:nil];
//				
//				patientXML = (NSXMLElement *)[NSXMLNode elementWithName:@"DicomStructure"];
//				patientNode = (NSXMLElement *)[NSXMLNode elementWithName:@"Patient"];
//				[patientNode setAttributes:[self patientAttributes:dcmObjectTest]];
//				[patientXML addChild:patientNode];
//				[self generateXMLFile:@"index.xml" atPath:patientPath withContent:patientXML];
//				[patientNode detach];
//				[rootXML addChild:patientNode];
//			}
//			
//			
////			// New study
////			if (![studyInstanceUID isEqualToString:[dcmObjectTest attributeValueWithName:@"StudyInstanceUID"]])
////			{
////				
////				studyInstanceUID = (NSString*)[dcmObjectTest attributeValueWithName:@"StudyInstanceUID"];
////				studyPath = [patientPath stringByAppendingPathComponent:studyInstanceUID];
////				[manager createDirectoryAtPath:studyPath withIntermediateDirectories:FALSE attributes:nil error:nil];
////				
////				studyXML = (NSXMLElement *)[NSXMLNode elementWithName:@"DicomStructure"];
////				studyNode = (NSXMLElement *)[NSXMLNode elementWithName:@"Study"];
////				[studyNode setAttributes:[self studyAttributes:dcmObjectTest]];
////				[studyXML addChild:studyNode];
////				[self generateXMLFile:@"index.xml" atPath:studyPath withContent:studyXML];
////				[studyNode detach];
////				[patientNode addChild:studyNode];
////				
////			}
//			
//			
////			// New series
////			if (![g_seriesInstanceUID isEqualToString:[dcmObjectTest attributeValueWithName:@"SeriesInstanceUID"]])
////			{
////				
////				g_seriesInstanceUID = (NSString*)[dcmObjectTest attributeValueWithName:@"SeriesInstanceUID"];
////				
////				seriesPath = [studyPath stringByAppendingPathComponent:g_seriesInstanceUID];
////				[manager createDirectoryAtPath:seriesPath withIntermediateDirectories:FALSE attributes:nil error:nil];
////				
////				seriesXML = (NSXMLElement *)[NSXMLNode elementWithName:@"DicomStructure"];
////				seriesNode = (NSXMLElement *)[NSXMLNode elementWithName:@"Series"];
////				[seriesNode setAttributes:[self seriesAttributes:dcmObjectTest]];
////				[seriesXML addChild:seriesNode];
////				
////			}
//			
//			
//			//			// New instance
//			//			if (![SOPInstanceUID isEqualToString:[dcmObjectTest attributeValueWithName:@"SOPInstanceUID"]])
//			//			{
//			//
//			//				//DCMObject *instanceDicomObject = dcmObjectTest;
//			//				NSString* instanceFileName = [dcmObjectTest attributeValueWithName:@"SOPInstanceUID"];
//			//				instancePath = [NSString stringWithFormat:@"%@/%@", seriesPath, instanceFileName];
//			//
//			////				NSLog(@"************ Check Instance 1");
//			////				NSLog(@"Instance file name : %@", instanceFileName);
//			////				NSLog(@"Instance path : %@", instancePath);
//			////
//			//
//			//				if( [[dcmObjectTest transferSyntax] isEqualToTransferSyntax:[DCMTransferSyntax ExplicitVRBigEndianTransferSyntax]])
//			//					[dcmObjectTest writeToFile:instancePath withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality: DCMLosslessQuality atomically:YES];
//			//				else
//			//					[manager copyPath:file toPath:instancePath handler:nil];
//			//
//			//				// Add instances to xml file
//			//				instanceNode = (NSXMLElement*)[NSXMLNode elementWithName:@"Instance"];
//			//				[instanceNode setAttributes:[NSArray arrayWithObjects:
//			//																		 [NSXMLNode attributeWithName:@"SOPInstanceUID" stringValue:instanceFileName],
//			//																		 [NSXMLNode attributeWithName:@"InstanceNumber" stringValue:[NSString stringWithFormat:@"%i", compteur]],
//			//																		 [NSXMLNode attributeWithName:@"DirectDownloadFile" stringValue:@""],
//			//																		 nil]];
//			//				[seriesNode addChild:instanceNode];
//			//
//			//
//			//
//			//
//			//			}
//			//
//			//
//			//			if (file != [files lastObject])
//			//			{
//			//
//			//				if (![seriesInstanceUID isEqualToString:[[DCMObject objectWithContentsOfFile:[files objectAtIndex:compteur] decodingPixelData:NO] attributeValueWithName:@"SeriesInstanceUID"]])
//			//				{
//			//					[self generateXMLFile:@"index.xml" atPath:seriesPath withContent:seriesXML];
//			//					[seriesNode detach];
//			//					[studyNode addChild:seriesNode];
//			//				}
//			//			}
//			//			else
//			//			{
//			//				[self generateXMLFile:@"index.xml" atPath:seriesPath withContent:seriesXML];
//			//				[seriesNode detach];
//			//				[studyNode addChild:seriesNode];
//			//			}
//			//
//			//
//			//			// Create thumbnail
//			//			DicomImage* dicomImage = [images objectAtIndex:(compteur-1)];
//			//			NSData* imageSeries = [[dicomImage series] thumbnail];
//			//			NSImage* im = [[NSImage alloc] initWithData:imageSeries];
//			//			[im saveAsJpegWithName:[seriesPath stringByAppendingPathComponent:@"thumbnail.jpg"]];
//			//			[im release];
//			
//			
//		}
//		
//		//}
//		//[pool release];
//	}
//	
//	
//	
//	
//	
//	
//	NSLog(@"************ End Create Dicom Structure");	
//	
//	[self generateXMLFile:@"dicom-structure.xml" atPath:path withContent:rootXML];
//}




//// BAD Access sur seriesInstanceUID
//+ (void) createDicomStructureAtPath:(NSString*)path withFiles:(NSMutableArray*)files withCorrespondingImages:(NSMutableArray*)images
//{
//	NSLog(@"************ Start Create Dicom Structure");
//	
//	NSFileManager *manager = [NSFileManager defaultManager]; // For create folders
//	
//	NSEnumerator *enumerator;
//	//if( anonymizedFiles)
//	//enumerator = [anonymizedFiles objectEnumerator];
//	//else
//		enumerator = [files objectEnumerator];
//	NSString *file;
//	
//	
//	
//	NSXMLElement *rootXML = (NSXMLElement*)[NSXMLNode elementWithName:@"DicomStructure"];
//	int compteur = 0;
//	
//
//	NSString *patientID = @"";
//	NSString *studyInstanceUID = @"";
//	NSString *seriesInstanceUID = @"";
//	NSString *SOPInstanceUID = @"";
//
//	NSString *patientPath = path;
//	NSString *studyPath = path;
//	NSString *seriesPath = path;
//	NSString *instancePath = path;
//	
//	NSXMLElement *patientNode;
//	NSXMLElement *studyNode;
//	NSXMLElement *seriesNode;
//	NSXMLElement *instanceNode;
//	
//	NSXMLElement *patientXML;
//	NSXMLElement *studyXML;
//	NSXMLElement *seriesXML;
//	
//	S_DicomNode* currentPatient = nil;
//	
//	while (file = [enumerator nextObject])
//	{
//		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//		//@autoreleasepool {
//			
//		DCMObject *dcmObjectTest;
//		
//		compteur++;
//		NSLog(@"CompteurAAA : %d", compteur);
//		
//		
//		dcmObjectTest = [DCMObject objectWithContentsOfFile:file decodingPixelData:NO];
//		
//		
//			
//		if (dcmObjectTest)	// <- it's a DICOM file
//		{
//						
//			NSString* pathLoad = [path stringByAppendingPathComponent:@"dicom-structure.xml"];
//			NSXMLDocument* doc = [[NSXMLDocument alloc] initWithContentsOfURL: [NSURL fileURLWithPath:pathLoad] options:0 error:NULL];
//			rootXML = [doc rootElement];
//
//			if ([[rootXML elementsForName:@"Patient"] count] == 0)
//				patientID = @"";
//			else
//				patientID = (NSString*)[[[rootXML elementsForName:@"Patient"] lastObject] attributeWithName:@"PatientID"];
//			
//			if (![patientID isEqualToString:[dcmObjectTest attributeValueWithName:@"PatientID"]])
//			{
//				patientNode = (NSXMLElement *)[NSXMLNode elementWithName:@"Patient"];
//				[patientNode setAttributes:[self patientAttributes:dcmObjectTest]];
//				[rootXML addChild:patientNode];
//			}
//				
//
//			
//			
////			// New patient
////			if (![patientID isEqualToString:[dcmObjectTest attributeValueWithName:@"PatientID"]])
////			{
////				patientID = (NSString*)[dcmObjectTest attributeValueWithName:@"PatientID"];
////				NSString* patientBirthDate = (NSString*)[dcmObjectTest attributeValueWithName:@"PatientsBirthDate"];
////				patientPath = [NSString stringWithFormat:@"%@/%@%@%@", path, patientID, @"-", patientBirthDate];
////				[manager createDirectoryAtPath:patientPath withIntermediateDirectories:FALSE attributes:nil error:nil];
////				
////				patientXML = (NSXMLElement *)[NSXMLNode elementWithName:@"DicomStructure"];
////				patientNode = (NSXMLElement *)[NSXMLNode elementWithName:@"Patient"];
////				[patientNode setAttributes:[self patientAttributes:dcmObjectTest]];
////				[patientXML addChild:patientNode];
////				[self generateXMLFile:@"index.xml" atPath:patientPath withContent:patientXML];
////				[patientNode detach];
////				[rootXML addChild:patientNode];
////			}
//			
////			NSString* studyTest = studyInstanceUID;
////			NSString* studyTest2 = [dcmObjectTest attributeValueWithName:@"StudyInstanceUID"];
////			
////			// New study
////			if (![studyInstanceUID isEqualToString:[dcmObjectTest attributeValueWithName:@"StudyInstanceUID"]])
////			{
////					
////				studyInstanceUID = (NSString*)[dcmObjectTest attributeValueWithName:@"StudyInstanceUID"];
////				studyPath = [patientPath stringByAppendingPathComponent:studyInstanceUID];
////				[manager createDirectoryAtPath:studyPath withIntermediateDirectories:FALSE attributes:nil error:nil];
////					
////				studyXML = (NSXMLElement *)[NSXMLNode elementWithName:@"DicomStructure"];
////				studyNode = (NSXMLElement *)[NSXMLNode elementWithName:@"Study"];
////				[studyNode setAttributes:[self studyAttributes:dcmObjectTest]];
////				[studyXML addChild:studyNode];
////				[self generateXMLFile:@"index.xml" atPath:studyPath withContent:studyXML];
////				[studyNode detach];
////				[patientNode addChild:studyNode];
////					
////			}
//				
////			NSString* seriesTest = seriesInstanceUID;
////			NSString* seriesTest2 = [dcmObjectTest attributeValueWithName:@"SeriesInstanceUID"];
////			
////
////			// New series
////			if (![seriesInstanceUID isEqualToString:[dcmObjectTest attributeValueWithName:@"SeriesInstanceUID"]])
////			{
////
////				//[seriesInstanceUID release];
////				seriesInstanceUID = (NSString*)[dcmObjectTest attributeValueWithName:@"SeriesInstanceUID"];
////				//[seriesInstanceUID initWithString:[dcmObjectTest attributeValueWithName:@"SeriesInstanceUID"]];
////				[seriesInstanceUID retain];
////				seriesPath = [studyPath stringByAppendingPathComponent:seriesInstanceUID];
////				[manager createDirectoryAtPath:seriesPath withIntermediateDirectories:FALSE attributes:nil error:nil];
////					
////				seriesXML = (NSXMLElement *)[NSXMLNode elementWithName:@"DicomStructure"];
////				seriesNode = (NSXMLElement *)[NSXMLNode elementWithName:@"Series"];
////				[seriesNode setAttributes:[self seriesAttributes:dcmObjectTest]];
////				[seriesXML addChild:seriesNode];
////					
////			}
//				
//
////			// New instance
////			if (![SOPInstanceUID isEqualToString:[dcmObjectTest attributeValueWithName:@"SOPInstanceUID"]])
////			{
////
////				//DCMObject *instanceDicomObject = dcmObjectTest;
////				NSString* instanceFileName = [dcmObjectTest attributeValueWithName:@"SOPInstanceUID"];
////				instancePath = [NSString stringWithFormat:@"%@/%@", seriesPath, instanceFileName];
////					
//////				NSLog(@"************ Check Instance 1");
//////				NSLog(@"Instance file name : %@", instanceFileName);
//////				NSLog(@"Instance path : %@", instancePath);
//////					
////					
////				if( [[dcmObjectTest transferSyntax] isEqualToTransferSyntax:[DCMTransferSyntax ExplicitVRBigEndianTransferSyntax]])
////					[dcmObjectTest writeToFile:instancePath withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality: DCMLosslessQuality atomically:YES];
////				else
////					[manager copyPath:file toPath:instancePath handler:nil];
////					
////				// Add instances to xml file
////				instanceNode = (NSXMLElement*)[NSXMLNode elementWithName:@"Instance"];
////				[instanceNode setAttributes:[NSArray arrayWithObjects:
////																		 [NSXMLNode attributeWithName:@"SOPInstanceUID" stringValue:instanceFileName],
////																		 [NSXMLNode attributeWithName:@"InstanceNumber" stringValue:[NSString stringWithFormat:@"%i", compteur]],
////																		 [NSXMLNode attributeWithName:@"DirectDownloadFile" stringValue:@""],
////																		 nil]];
////				[seriesNode addChild:instanceNode];
////					
////
////
////						
////			}
////				
////				
////			if (file != [files lastObject])
////			{
////					
////				if (![seriesInstanceUID isEqualToString:[[DCMObject objectWithContentsOfFile:[files objectAtIndex:compteur] decodingPixelData:NO] attributeValueWithName:@"SeriesInstanceUID"]])
////				{
////					[self generateXMLFile:@"index.xml" atPath:seriesPath withContent:seriesXML];
////					[seriesNode detach];
////					[studyNode addChild:seriesNode];
////				}
////			}
////			else
////			{
////				[self generateXMLFile:@"index.xml" atPath:seriesPath withContent:seriesXML];
////				[seriesNode detach];
////				[studyNode addChild:seriesNode];
////			}
////				
////				
////			// Create thumbnail
////			DicomImage* dicomImage = [images objectAtIndex:(compteur-1)];
////			NSData* imageSeries = [[dicomImage series] thumbnail];
////			NSImage* im = [[NSImage alloc] initWithData:imageSeries];
////			[im saveAsJpegWithName:[seriesPath stringByAppendingPathComponent:@"thumbnail.jpg"]];
////			[im release];
//			
//			
//		}
//			
//		//}
//		[self generateXMLFile:@"dicom-structure.xml" atPath:path withContent:rootXML];
//		[pool release];
//	}
//	
//	
//	
//	
//	
//	
//	NSLog(@"************ End Create Dicom Structure");	
//	
//	[self generateXMLFile:@"dicom-structure.xml" atPath:path withContent:rootXML];
//}





//// Original
//+ (void) createDicomStructureAtPath:(NSString*)path withFiles:(NSMutableArray*)files withCorrespondingImages:(NSMutableArray*)images
//{
//	NSLog(@"************ Start Create Dicom Structure");
//	
//	NSFileManager *manager = [NSFileManager defaultManager]; // For create folders
//	
//	NSString *patientPath = path;
//	NSString *studyPath = path;
//	NSString *seriesPath = path;
//	
//	NSString *patientID = @"";
//	NSString *studyInstanceUID = @"";
//	NSString *seriesInstanceUID = @"";
//	NSString *SOPInstanceUID = @"";
//	
//	
//	
//	NSMutableArray *patientsList = [NSMutableArray array];
//	
//	
//	
//	NSEnumerator *enumerator;
//	//if( anonymizedFiles)
//	//enumerator = [anonymizedFiles objectEnumerator];
//	//else
//	enumerator = [files objectEnumerator];
//	NSString *file;
//	
//	
//	int compteurTest = 0;
//	int limite = 1106;
//	
//	while (file = [enumerator nextObject])
//	{
//		//for (id file in files)
//		@autoreleasepool{
//			
//			compteurTest++;
//			//NSLog(@"file : %@", file);
//			
//			
//			
//			
//			
//			DCMObject *dcmObjectTest = nil;
//			
//			
//			NSLog(@"CompteurTest : %i", compteurTest);
//			if (compteurTest > limite)
//			{
//				
//			}
//			
//			
//			NSLog(@"File : %@", file);
//			if (file)
//				dcmObjectTest = [DCMObject objectWithContentsOfFile:file decodingPixelData:NO]; // Error
//			
//			
//			
//			S_DicomNode *patient;
//			S_DicomNode *study;
//			S_DicomNode *series;
//			S_DicomNode *instance;
//			
//			
//			if (dcmObjectTest)	// <- it's a DICOM file
//			{
//				//NSLog(@"It's a dicom file");
//				
//				// New patient
//				if (![patientID isEqualToString:[dcmObjectTest attributeValueWithName:@"PatientID"]])
//				{
//					
//					patientID = (NSString*)[dcmObjectTest attributeValueWithName:@"PatientID"];
//					patient = [[[S_DicomNode alloc] initWithDCMObject:dcmObjectTest] autorelease];
//					[patientsList addObject:patient];
//					
//				}
//				
//				// New study
//				if (![studyInstanceUID isEqualToString:[dcmObjectTest attributeValueWithName:@"StudyInstanceUID"]])
//				{
//					studyInstanceUID = (NSString*)[dcmObjectTest attributeValueWithName:@"StudyInstanceUID"];
//					if (patient)
//					{
//						study = [[[S_DicomNode alloc] initWithDCMObject:dcmObjectTest] autorelease];
//						[study setParent:patient];
//					}
//				}
//				
//				// New series
//				if (![seriesInstanceUID isEqualToString:[dcmObjectTest attributeValueWithName:@"SeriesInstanceUID"]])
//				{
//					seriesInstanceUID = (NSString*)[dcmObjectTest attributeValueWithName:@"SeriesInstanceUID"];
//					if (study)
//					{
//						series = [[[S_DicomNode alloc] initWithDCMObject:dcmObjectTest] autorelease];
//						[series setParent:study];
//					}
//				}
//				
//				// New instance
//				if (![SOPInstanceUID isEqualToString:[dcmObjectTest attributeValueWithName:@"SOPInstanceUID"]])
//				{
//					SOPInstanceUID = (NSString*)[dcmObjectTest attributeValueWithName:@"SOPInstanceUID"];
//					if (series)
//					{
//						instance = [[S_DicomNode alloc] initWithDCMObject:dcmObjectTest];
//						[instance setParent:series];
//						//NSLog(@"TOTO");
//						[instance setOriginalFile:file];
//					}
//				}
//			}
//			
//			//		[patient release];
//			//		[study release];
//			//		[series release];
//			//[dcmObjectTest release];
//			//[dcmObjectTest dealloc];
//			
//		}
//	}
//	
//	NSLog(@"************ Check 1");
//	
//	//	DCMObject *object = [[patientsList lastObject] dcmObject];
//	//	NSXMLDocument *doc = [object xmlDocument];
//	//
//	//	NSData *xmlData = [doc XMLDataWithOptions:NSXMLNodePrettyPrint];
//	//	NSString* outputPath = [[NSString alloc] initWithString:[path stringByAppendingPathComponent:@"test.xml"]];
//	//
//	//	NSLog(@"************ Check 2");
//	//
//	//	if (![xmlData writeToFile:outputPath atomically:YES])
//	//	{
//	//		NSLog(@"Could not write document out AAAAAAA");
//	//	}
//	//	[doc release];
//	//
//	//	NSLog(@"************ Check 7");
//	
//	NSXMLElement *rootXML = (NSXMLElement*)[NSXMLNode elementWithName:@"DicomStructure"];
//	int compteur = 0;
//	
//	for (id patient in patientsList)
//	{
//		patientID = (NSString*)[[patient dcmObject] attributeValueWithName:@"PatientID"];
//		NSString* patientBirthDate = (NSString*)[[patient dcmObject] attributeValueWithName:@"PatientsBirthDate"];
//		NSString* patientPath = [NSString stringWithFormat:@"%@/%@%@%@", path, patientID, @"-", patientBirthDate];
//		
//		[manager createDirectoryAtPath:patientPath withIntermediateDirectories:FALSE attributes:nil error:nil];
//		
//		NSXMLElement *patientXML = (NSXMLElement *)[NSXMLNode elementWithName:@"DicomStructure"];
//		NSXMLElement *patientNode = (NSXMLElement *)[NSXMLNode elementWithName:@"Patient"];
//		[patientNode setAttributes:[self patientAttributes:[patient dcmObject]]];
//		[patientXML addChild:patientNode];
//		[self generateXMLFile:@"index.xml" atPath:patientPath withContent:patientXML];
//		[patientNode detach];
//		[rootXML addChild:patientNode];
//		
//		for (id study in [patient children])
//		{
//			studyInstanceUID = (NSString*)[[study dcmObject] attributeValueWithName:@"StudyInstanceUID"];
//			studyPath = [patientPath stringByAppendingPathComponent:studyInstanceUID];
//			[manager createDirectoryAtPath:studyPath withIntermediateDirectories:FALSE attributes:nil error:nil];
//			
//			NSXMLElement *studyXML = (NSXMLElement *)[NSXMLNode elementWithName:@"DicomStructure"];
//			NSXMLElement *studyNode = (NSXMLElement *)[NSXMLNode elementWithName:@"Study"];
//			[studyNode setAttributes:[self studyAttributes:[study dcmObject]]];
//			[studyXML addChild:studyNode];
//			[self generateXMLFile:@"index.xml" atPath:studyPath withContent:studyXML];
//			[studyNode detach];
//			[patientNode addChild:studyNode];
//			
//			for (id series in [study children])
//			{
//				seriesInstanceUID = (NSString*)[[series dcmObject] attributeValueWithName:@"SeriesInstanceUID"];
//				seriesPath = [studyPath stringByAppendingPathComponent:seriesInstanceUID];
//				[manager createDirectoryAtPath:seriesPath withIntermediateDirectories:FALSE attributes:nil error:nil];
//				
//				NSXMLElement *seriesXML = (NSXMLElement *)[NSXMLNode elementWithName:@"DicomStructure"];
//				NSXMLElement *seriesNode = (NSXMLElement *)[NSXMLNode elementWithName:@"Series"];
//				[seriesNode setAttributes:[self seriesAttributes:[series dcmObject]]];
//				[seriesXML addChild:seriesNode];
//				
//				for (id instance in [series children])
//				{
//					DCMObject *instanceDicomObject = [instance dcmObject];
//					NSString *instanceFileName = [instanceDicomObject attributeValueWithName:@"SOPInstanceUID"];
//					NSString *instancePath = [NSString stringWithFormat:@"%@/%@", seriesPath, instanceFileName];
//					
//					//NSLog(@"************ Check Instance 1");
//					//NSLog(@"Instance file name : %@", instanceFileName);
//					//NSLog(@"Instance path : %@", instancePath);
//					
//					// Write dicom file
//					//bool temp = [instanceDicomObject writeToFile:instancePath withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality:DCMLosslessQuality atomically:YES];
//					
//					
//					
//					if( [[instanceDicomObject transferSyntax] isEqualToTransferSyntax:[DCMTransferSyntax ExplicitVRBigEndianTransferSyntax]])
//						[instanceDicomObject writeToFile:instancePath withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality: DCMLosslessQuality atomically:YES];
//					else
//						[manager copyPath:[instance originalFile] toPath:instancePath handler:nil];
//					//[manager copyItemAtURL:[instance originalFile] toURL:instancePath error:nil];
//					
//					
//					
//					//NSLog(@"************ Check Instance 2");
//					
//					// Add instances to xml file
//					NSXMLElement *instanceNode = (NSXMLElement*)[NSXMLNode elementWithName:@"Instance"];
//					[instanceNode setAttributes:[NSArray arrayWithObjects:
//																			 [NSXMLNode attributeWithName:@"SOPInstanceUID" stringValue:instanceFileName],
//																			 [NSXMLNode attributeWithName:@"InstanceNumber" stringValue:[NSString stringWithFormat:@"%i", compteur]],
//																			 [NSXMLNode attributeWithName:@"DirectDownloadFile" stringValue:@""],
//																			 nil]];
//					[seriesNode addChild:instanceNode];
//					
//					compteur++;
//				}
//				
//				[self generateXMLFile:@"index.xml" atPath:seriesPath withContent:seriesXML];
//				[seriesNode detach];
//				[studyNode addChild:seriesNode];
//				
//				// Create thumbnail
//				DicomImage *dicomImage = [images objectAtIndex:(compteur-1)];
//				NSData *imageSeries = [[dicomImage series] thumbnail];
//				NSImage *im = [[NSImage alloc] initWithData:imageSeries];
//				[im saveAsJpegWithName:[seriesPath stringByAppendingPathComponent:@"thumbnail.jpg"]];
//				
//				//NSLog(@"dicomImage class name : %@", [dicomImage className]);
//
//				
//				
//				
//				
//				
//				// Test bigger thumbnails
//				
//				//NSImage *testimage = [dicomImage image];
//				//NSData *test = [[dicomImage series] images];
//				
//				//				NSSize size;
//				//				size = NSMakeSize(70, 70);
//				//
//				//				NSImage* test2 = [(NSImage*)dicomImage imageByScalingProportionallyToSize:size];
//				//				[test2 saveAsJpegWithName:[seriesPath stringByAppendingPathComponent:@"thumbnail_2.jpg"]];
//				
//			}
//		}
//	}
//	
//	NSLog(@"************ End Create Dicom Structure");
//	
//	[self generateXMLFile:@"dicom-structure.xml" atPath:path withContent:rootXML];
//}


+ (void) generateXMLFile:(NSString*)fileName atPath:(NSString*)path withContent:(NSXMLElement*)content
{
	NSXMLDocument *xmlDoc;
	if (content != nil)
		xmlDoc = [[NSXMLDocument alloc] initWithRootElement:content];
	else
		xmlDoc = [[NSXMLDocument alloc] initWithRootElement:[NSXMLElement elementWithName:@"root"]];
	
	[xmlDoc setVersion:@"1.0"];
	[xmlDoc setCharacterEncoding:@"UTF-8"];
	
	NSString* outputPath = [[[NSString alloc] initWithString:[path stringByAppendingPathComponent:fileName]] autorelease];
	
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





