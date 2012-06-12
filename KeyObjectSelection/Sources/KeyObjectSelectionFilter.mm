//
//  KeyObjectSelectionFilter.m
//  KeyObjectSelection
//
//  Copyright (c) 2012 OsiriX. All rights reserved.
//

#import "KeyObjectSelectionFilter.h"
#import "NSUserDefaults+KOS.h"

#import <OsiriXAPI/dctk.h>
#import <OsiriXAPI/dsrdoc.h>
#import <OsiriXAPI/dsrtypes.h>
//#import <OsiriXAPI/dsrimgtn.h>

#import <OsiriXAPI/PreferencesWindowController.h>
#import <OsiriXAPI/ViewerController.h>
#import <OsiriXAPI/DCMTKQueryNode.h>
#import <OsiriXAPI/NSThread+N2.h>
#import <OsiriXAPI/DicomDatabase.h>
#import <OsiriXAPI/DicomImage.h>
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/ThreadsManager.h>
#import <OsiriXAPI/Notifications.h>
#import <OsiriXAPI/NSFileManager+N2.h>
#import <OsiriXAPI/N2Debug.h>
#import <OsiriXAPI/N2MutableUInteger.h>
#import <OsiriXAPI/DCMTKStoreSCU.h>
#import <OsiriXAPI/MPRController.h>

#undef XRay3DAngiographicImageStorage
#undef XRay3DCraniofacialImageStorage

#import <OsiriX/DCMObject.h>
#import <OsiriX/DCMAbstractSyntaxUID.h>

#import <objc/runtime.h>

@interface DicomImage (KOS)
@end

@implementation DicomImage (KOS)

-(NSString*)pathSOPInstanceUIDAndFrameID {
    if (self.frameID)
        return [NSString stringWithFormat:@"%@: %@ - %@", self.completePath, self.sopInstanceUID, self.frameID];
    else return [NSString stringWithFormat:@"%@: %@", self.completePath, self.sopInstanceUID];
}

@end

@implementation KeyObjectSelectionFilter

static KeyObjectSelectionFilter* KeyObjectSelectionFilterInstance = nil;

static NSString* const KOSIsApplyingKOsThreadKey = @"KOSIsApplyingKOs"; // plugin is applying KOs
static NSString* const KOSIsSettingKeyFlagThreadKey = @"KOSIsSettingKeyFlag"; // OsiriX is setting key image flag

- (void)initPlugin {
    KeyObjectSelectionFilterInstance = self;

	[PreferencesWindowController addPluginPaneWithResourceNamed:@"KeyObjectSelectionPrefs" inBundle:[NSBundle bundleForClass:[self class]] withTitle:@"Key Object Selection" image:[NSImage imageNamed:@"NSUser"]];
    
    // swizzle OsiriX methods
    
    Method method;
    IMP imp;
    NSString* const ExceptionMessage = @"OsiriX has evolved and this plugin hasn't :(";
    
    // ViewerController
    
    Class ViewerControllerClass = [ViewerController class];
    
    method = class_getInstanceMethod(ViewerControllerClass, @selector(changeImageData::::));
    if (!method) [NSException raise:NSGenericException format:ExceptionMessage];
    imp = method_getImplementation(method);
    class_addMethod(ViewerControllerClass, @selector(_ViewerController_changeImageData::::), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_ViewerController_changeImageData::::)));
    
    method = class_getInstanceMethod(ViewerControllerClass, @selector(finalizeSeriesViewing));
    if (!method) [NSException raise:NSGenericException format:ExceptionMessage];
    imp = method_getImplementation(method);
    class_addMethod(ViewerControllerClass, @selector(_ViewerController_finalizeSeriesViewing), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_ViewerController_finalizeSeriesViewing)));
    
    method = class_getInstanceMethod(ViewerControllerClass, @selector(setKeyImage:));
    if (!method) [NSException raise:NSGenericException format:ExceptionMessage];
    imp = method_getImplementation(method);
    class_addMethod(ViewerControllerClass, @selector(_ViewerController_setKeyImage:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_ViewerController_setKeyImage:)));
    
    // DicomImage
    
    Class DicomImageClass = [DicomImage class];
    
    method = class_getInstanceMethod(DicomImageClass, @selector(setIsKeyImage:));
    if (!method) [NSException raise:NSGenericException format:ExceptionMessage];
    imp = method_getImplementation(method);
    class_addMethod(DicomImageClass, @selector(_DicomImage_setIsKeyImage:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_DicomImage_setIsKeyImage:)));

    /* 3D MPR
    
    Class MPRControllerClass = [MPRController class];
    method = class_getInstanceMethod([self class], @selector(_MPRController_setKeyImage:));
    class_addMethod(MPRControllerClass, @selector(setKeyImage:), method_getImplementation(method), method_getTypeEncoding(method));
    
    */
    
    
    // watch for added files notifications
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(observeAddNotification:) name:_O2AddToDBAnywayCompleteNotification object:nil];
}

-(void)dealloc {
    [super dealloc];
}

- (long)filterImage:(NSString*)menuName {
    return 0;
}

- (void)viewerController:(ViewerController*)vc applyKOs:(NSArray*)kos {
    
}

+ (NSArray*)imagesInStudy:(DicomStudy*)study {
    NSMutableArray* images = [NSMutableArray array];
    for (DicomSeries* series in study.series)
        for (DicomImage* image in series.images)
            [images addObject:image];
    return images;
}

+ (NSArray*)KOsInStudy:(DicomStudy*)study {
    NSArray* images = [[self class] imagesInStudy:study];
    return [images filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"modality = 'KO'"]];
}

+ (NSArray*)keyImagesInStudy:(DicomStudy*)study {
    NSArray* images = [[self class] imagesInStudy:study];
    return [images filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isKeyImage = YES"]];
}

+ (void)KOs:(NSArray*)kos analyzeAndReturnKeyImages:(NSMutableArray*)keyImages invalidatedKeyImages:(NSMutableArray*)invalidatedKeyImages invalidatedKOs:(NSMutableArray*)inInvalidatedKOs keyImagesPerKO:(NSMutableArray*)inKeyImagesPerKO{
    kos = [kos sortedArrayUsingComparator: ^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 date] compare:[obj2 date]];
    }];
    
    DLog(@"%d KOS: %@", (int)kos.count, [kos valueForKey:@"pathSOPInstanceUIDAndFrameID"]);

    NSMutableArray* invalidatedKOs = inInvalidatedKOs? inInvalidatedKOs : [NSMutableArray array];
    NSMutableArray* keyImagesPerKO = inKeyImagesPerKO? inKeyImagesPerKO : [NSMutableArray array];
    
    // TODO: use DSRDocument instead of basic DcmDataset
    
    for (NSInteger i = 0; i < kos.count; ++i) {
        DicomImage* ko = [kos objectAtIndex:i];
        NSString* path = [ko completePath];
        
        DcmFileFormat dfile;
        DcmDataset* dset = dfile.getDataset(); // = &dfile;
        if (dfile.loadFile([path fileSystemRepresentation]).bad()) { NSLog(@"Warning: can't load KO file at %@", path); continue; }
        
        /*// we read this file with DSRDocument
        
        DSRDocument document;
        if (document.read(*dset).bad()) { NSLog(@"Warning: can't read KO file at %@", path); continue; }
        DSRDocumentTree& dtree = document.getTree();
        
        DSRCodedEntryValue* conceptName = dtree.getCurrentContentItem().getConceptNamePtr();
        if (!conceptName) { NSLog(@"Warning: KO file at %@ doesn't contain ConceptName", path); continue; }
        
        if (dtree.gotoNamedNode(*conceptName))
            do {
                DSRImageReferenceValue* image = dtree.getCurrentContentItem().getImageReferencePtr();
                NSLog(@"%@ --- %s", path, image->getSOPInstanceUID().c_str());
            } while (dtree.gotoNextNamedNode(*conceptName));
        
        break;*/
        
        DcmSequenceOfItems* sConceptNameCodeSequence = nil;
        if (dset->findAndGetElement(DcmTagKey(DCM_ConceptNameCodeSequence), (DcmElement*&)sConceptNameCodeSequence).bad()) { NSLog(@"Warning: KO file at %@ doesn't contain ConceptNameCodeSequence", path); continue; }
        if (sConceptNameCodeSequence->ident() != EVR_SQ) { NSLog(@"Warning: KO file at %@ contains ConceptNameCodeSequence with VR %s, should be SQ", path, DcmVR(sConceptNameCodeSequence->ident()).getVRName()); continue; }
        if (sConceptNameCodeSequence->card() != 1) { NSLog(@"Warning: KO file at %@ contains ConceptNameCodeSequence with cardinality %d, should be 1", path, (int)sConceptNameCodeSequence->card()); continue; }
        
        DcmItem* iConceptNameCodeSequenceItem = nil;
        iConceptNameCodeSequenceItem = sConceptNameCodeSequence->getItem(0);
        
        DcmSequenceOfItems* sContentSequence = nil;
        if (dset->findAndGetElement(DcmTagKey(DCM_ContentSequence), (DcmElement*&)sContentSequence).bad()) { NSLog(@"Warning: KO file at %@ doesn't contain ContentSequence", path); continue; }
        
        OFString codeValue, codingSchemeDesignator;
        if (iConceptNameCodeSequenceItem->findAndGetOFString(DcmTagKey(DCM_CodeValue), codeValue).bad()) { NSLog(@"Warning: KO file at %@ doesn't contain CodeValue", path); continue; }
        if (iConceptNameCodeSequenceItem->findAndGetOFString(DcmTagKey(DCM_CodingSchemeDesignator), codingSchemeDesignator).bad()) { NSLog(@"Warning: KO file at %@ doesn't contain CodingSchemeDesignator", path); continue; }
        
        if (codingSchemeDesignator == "DCM" && codeValue == "113001") // "Rejected for Quality Reasons", see if any KO is rejected
            for (unsigned int i = 0; i < sContentSequence->card(); ++i) {
                DcmItem* item = sContentSequence->getItem(i);
                OFString referencedSOPInstanceUID;
                if (item->findAndGetOFString(DCM_ReferencedSOPInstanceUID, referencedSOPInstanceUID, 0, OFTrue).good()) {
                    NSPredicate* pred = [NSPredicate predicateWithFormat:@"sopInstanceUID = %@", [NSString stringWithCString:referencedSOPInstanceUID.c_str() encoding:NSUTF8StringEncoding]];
                    NSArray* referencedImages = [kos filteredArrayUsingPredicate:pred];
                    [invalidatedKOs addObjectsFromArray:referencedImages];
                    NSLog(@"%@\n%@ invalidates %@", path, ko.sopInstanceUID, [referencedImages valueForKey:@"pathSOPInstanceUIDAndFrameID"]);
                }
            }
        
        if (codingSchemeDesignator != "DCM" || codeValue != "113000") // not "Of Interest"
            continue;
        
        NSArray* studyImages = [[self class] imagesInStudy:ko.series.study];
        
        NSMutableArray* keyImages = [NSMutableArray array];
        for (unsigned int i = 0; i < sContentSequence->card(); ++i) {
            DcmItem* item = sContentSequence->getItem(i);
            OFString referencedSOPInstanceUID;
            if (item->findAndGetOFString(DcmTagKey(DCM_ReferencedSOPInstanceUID), referencedSOPInstanceUID, 0, OFTrue).good()) {
                NSString* sopInstanceUID = [NSString stringWithCString:referencedSOPInstanceUID.c_str() encoding:NSUTF8StringEncoding];
                
                const char* str;
                if (item->findAndGetString(DCM_ReferencedFrameNumber, str, OFTrue).good()) {
                    for (NSString* frameID in [[NSString stringWithCString:str encoding:NSUTF8StringEncoding] componentsSeparatedByString:@"\\"]) {
                        NSPredicate* pred = [NSPredicate predicateWithFormat:@"sopInstanceUID = %@ AND frameID = %@", sopInstanceUID, [NSNumber numberWithInteger:[frameID integerValue]]];
                        [keyImages addObjectsFromArray:[studyImages filteredArrayUsingPredicate:pred]];
                    }
                } else {
                    NSString* sopInstanceUID = [NSString stringWithCString:referencedSOPInstanceUID.c_str() encoding:NSUTF8StringEncoding];
                    NSPredicate* pred = [NSPredicate predicateWithFormat:@"sopInstanceUID = %@", sopInstanceUID];
                    [keyImages addObjectsFromArray:[studyImages filteredArrayUsingPredicate:pred]];
                }
            }
        }
        
        [keyImagesPerKO addObject:[NSArray arrayWithObjects: ko, keyImages, nil]];
        DLog(@"%@\n%@ sets keyImages %@", path, ko.sopInstanceUID, [keyImages valueForKey:@"pathSOPInstanceUIDAndFrameID"]);
    }
    
    for (NSArray* kipko in keyImagesPerKO) {
        DicomImage* ko = [kipko objectAtIndex:0];
        NSArray* images = [kipko objectAtIndex:1];
        
        DLog(@"Applying %@ dated %@", ko.sopInstanceUID, ko.date);
        
        if ([invalidatedKOs containsObject:ko]) {
            [keyImages removeObjectsInArray:images];
            for (DicomImage* image in images)
                if (![invalidatedKeyImages containsObject:image])
                    [invalidatedKeyImages addObject:image];
        } else {
            for (DicomImage* image in images)
                if (![keyImages containsObject:image])
                    [keyImages addObject:image];
            [invalidatedKeyImages removeObjectsInArray:images];
        }
    }
    
    DLog(@"Invalidated keyImages: %@", [invalidatedKeyImages valueForKey:@"pathSOPInstanceUIDAndFrameID"]);
    
    DLog(@"Valid keyImages: %@", [keyImages valueForKey:@"pathSOPInstanceUIDAndFrameID"]);
}

+ (void)KOs:(NSArray*)kos analyzeAndReturnKeyImages:(NSMutableArray*)keyImages invalidatedKeyImages:(NSMutableArray*)invalidatedKeyImages {
    return [[self class] KOs:kos analyzeAndReturnKeyImages:keyImages invalidatedKeyImages:invalidatedKeyImages invalidatedKOs:nil keyImagesPerKO:nil];
}

- (void)study:(DicomStudy*)study applyKOs:(NSArray*)kos {
    NSMutableArray* keyImages = [NSMutableArray array];
    NSMutableArray* invalidatedKeyImages = [NSMutableArray array];
    [[self class] KOs:kos analyzeAndReturnKeyImages:keyImages invalidatedKeyImages:invalidatedKeyImages];
    
    NSThread* thread = [NSThread currentThread];
    
    N2MutableUInteger* ui = [thread.threadDictionary objectForKey:KOSIsApplyingKOsThreadKey];
    if (!ui) [thread.threadDictionary setObject:(ui = [N2MutableUInteger mutableUIntegerWithUInteger:0]) forKey:KOSIsApplyingKOsThreadKey];
    [ui increment];
    
    for (DicomImage* image in keyImages)
        if (image.isKeyImage.boolValue != YES)
            [image setIsKeyImage:[NSNumber numberWithBool:YES]];
    for (DicomImage* image in invalidatedKeyImages)
        if (image.isKeyImage.boolValue != NO)
            [image setIsKeyImage:[NSNumber numberWithBool:NO]];

    [ui decrement];
    if (!ui.unsignedIntegerValue) [thread.threadDictionary removeObjectForKey:KOSIsApplyingKOsThreadKey];

    // TODO: update GUI
}

- (void)observeAddNotification:(NSNotification*)notification {
    // to avoid applying the same key images over and over, only catch notifications on main databases
    
    DicomDatabase* database = [notification object];
    if (![database isMainDatabase])
        return;
    
    NSThread* thread = [NSThread currentThread];
    if ([thread.threadDictionary objectForKey:KOSIsApplyingKOsThreadKey])
        return; // the plugin is assigning this flag, don't react...
    if ([thread.threadDictionary objectForKey:KOSIsSettingKeyFlagThreadKey])
        return; // this is the consequence of a setIsKeyImage call (the SC being added to the DB), don't react
    
    // find added KeyObject "images"
    
    NSMutableArray* studies = [NSMutableArray array];
    
    NSArray* images = [notification.userInfo objectForKey:OsirixAddToDBNotificationImagesArray];
    for (DicomImage* image in images)
        if (![studies containsObject:image.series.study])
            [studies addObject:image.series.study];

    // apply KOs to related series
    
    for (DicomStudy* study in studies) {
        NSArray* kos = [[self class] KOsInStudy:study];
        if (kos.count)
            [self study:study applyKOs:kos];
    }
}

- (void)viewerController:(ViewerController*)vc changeImageData:(NSMutableArray*)f :(NSMutableArray*)d :(NSData*)v :(BOOL)newViewerWindow {
    // this function is executed AFTER -[ViewerController changeImageData::::]
    if (d.count)
        [NSThread performBlockInBackground: ^{
            // findscu/movescu pacsdevarch 4444 -aet CIH-1208 -S -k 0008,0052=SERIES -k 0020,000d=2.16.840.1.113669.632.20.1211.10001556317 -k 0008,0060=KO
            NSString* tAET = [NSUserDefaults.standardUserDefaults stringForKey:KOSAETKey];
            NSString* tHost = [NSUserDefaults.standardUserDefaults stringForKey:KOSNodeHostKey];
            NSInteger tPort = [NSUserDefaults.standardUserDefaults integerForKey:KOSNodePortKey];
            
            DicomImage* image  = [d objectAtIndex:0];
            DicomSeries* series = [image series];
            DicomStudy* study = [series study];
            
            NSThread* thread = [NSThread currentThread];
            thread.name = [NSString stringWithFormat:NSLocalizedString(@"KeyObjects for %@", nil), study.name];
            [ThreadsManager.defaultManager addThreadAndStart:thread];

            thread.status = [NSString stringWithFormat:NSLocalizedString(@"Loading...", nil)];
            
            NSArray* kos = [[self class] KOsInStudy:study];
            if (kos.count)
                [self study:study applyKOs:kos];
            
            if (![NSUserDefaults.standardUserDefaults boolForKey:KOSSynchronizeKey]) // plugin isn't active
                return;
            
            thread.status = [NSString stringWithFormat:NSLocalizedString(@"Retrieving from %@...", nil), tAET];
            
            DCMTKQueryNode* query = [DCMTKQueryNode queryNodeWithDataset:nil
                                                              callingAET:@"CIH-1208"
                                                               calledAET:tAET
                                                                hostname:tHost
                                                                    port:tPort
                                                          transferSyntax:0
                                                             compression:0
                                                         extraParameters:nil];
            [query setShowErrorMessage:NO];

            // Query
            /*
            [query queryWithValues:[NSArray arrayWithObjects:
                                    // [NSDictionary dictionaryWithObject:@"350794" forKey:@"PatientID"],
                                    [NSDictionary dictionaryWithObjectsAndKeys: @"StudyInstanceUID", @"name", study.studyInstanceUID, @"value", nil],
                                    [NSDictionary dictionaryWithObjectsAndKeys: @"Modality", @"name", @"KO", @"value", nil],
                                    nil]];
            
            NSArray* nodes = [query children]; // contains DCMTKStudyQueryNode instances
            
            for (DCMTKImageQueryNode* node in nodes)
                NSLog(@"Node  %@, %@", [node name], [node uid]);
            */
            
            // Retrieve
            
            DcmDataset dataset;
            dataset.putAndInsertString(DCM_QueryRetrieveLevel, "SERIES", OFTrue);
            dataset.putAndInsertString(DCM_StudyInstanceUID, [study.studyInstanceUID UTF8String], OFTrue);
            dataset.putAndInsertString(DCM_Modality, "KO", OFTrue);

            [query setupNetworkWithSyntax:UID_MOVEStudyRootQueryRetrieveInformationModel dataset:&dataset destination:nil];
        }];
}

- (void)saveKOsForStudy:(DicomStudy*)study {
    NSArray* kos = [[self class] KOsInStudy:study];
    
    NSMutableArray* kosKeyImages = [NSMutableArray array];
    NSMutableArray* kosInvalidatedKeyImages = [NSMutableArray array];
    NSMutableArray* invalidatedKOs = [NSMutableArray array];
    NSMutableArray* keyImagesPerKO = [NSMutableArray array];
    [[self class] KOs:kos analyzeAndReturnKeyImages:kosKeyImages invalidatedKeyImages:kosInvalidatedKeyImages invalidatedKOs:invalidatedKOs keyImagesPerKO:keyImagesPerKO];
    
    NSArray* keyImages = [[self class] keyImagesInStudy:study];
    
    DLog(@"Actual keyImages: %@", [keyImages valueForKey:@"pathSOPInstanceUIDAndFrameID"]);
    
    NSMutableArray* KOsToInvalidate = [NSMutableArray array];
    for (DicomImage* keyImage in kosKeyImages)
        if (![keyImages containsObject:keyImage]) // the KOs list a KeyImage that isn't marked as one anymore, so we need to invalidate the KOs that mark this KeyImage
            for (NSArray* a in keyImagesPerKO) {
                DicomImage* ko = [a objectAtIndex:0];
                if ([invalidatedKOs containsObject:ko] || [KOsToInvalidate containsObject:ko])
                    continue; // this KO already invalidated or selected for invalidation
                NSArray* keyImages = [a objectAtIndex:1];
                if ([keyImages containsObject:keyImage])
                    [KOsToInvalidate addObject:ko];
            }
    
    NSMutableArray* newDcmFiles = [NSMutableArray array];
    
    if (KOsToInvalidate.count)
        [newDcmFiles addObject:[self createKeyObjectSelectionDocumentWithStudy:study codeValue:"113001" meaning:"Rejected for Quality Reasons" contentImages:KOsToInvalidate]];
    if (keyImages.count) {
        NSMutableArray* temp = [[keyImages mutableCopy] autorelease];
        [temp removeObjectsInArray:kosKeyImages];
        if (temp.count)
            [newDcmFiles addObject:[self createKeyObjectSelectionDocumentWithStudy:study codeValue:"113000" meaning:"Of Interest" contentImages:keyImages]];
    }
    
    if (![NSUserDefaults.standardUserDefaults boolForKey:KOSSynchronizeKey]) // plugin isn't active
        return;
    
    if (newDcmFiles.count) // send the new DICOM files to the specified DICOM node
        [NSThread performBlockInBackground: ^{
            NSString* myAET = [NSUserDefaults.standardUserDefaults stringForKey:@"AETITLE"];
            NSString* tAET = [NSUserDefaults.standardUserDefaults stringForKey:KOSAETKey];
            NSString* tHost = [NSUserDefaults.standardUserDefaults stringForKey:KOSNodeHostKey];
            NSInteger tPort = [NSUserDefaults.standardUserDefaults integerForKey:KOSNodePortKey];
            
            NSThread* thread = [NSThread currentThread];
            thread.name = [NSString stringWithFormat:NSLocalizedString(@"KeyObjects for %@", nil), study.name];
            thread.status = [NSString stringWithFormat:NSLocalizedString(@"Sending to %@...", nil), tAET];
            [ThreadsManager.defaultManager addThreadAndStart:thread];
            
            DCMTKStoreSCU* storescu = [[[DCMTKStoreSCU alloc] initWithCallingAET:myAET
                                                                       calledAET:tAET
                                                                        hostname:tHost
                                                                            port:tPort
                                                                     filesToSend:newDcmFiles
                                                                  transferSyntax:0
                                                                     compression:1.0
                                                                 extraParameters:nil] autorelease];
            [storescu run:self];
        }];
}

- (void)finalizeSeriesViewingForViewerController:(ViewerController*)vc {
    // this function is executed BEFORE -[ViewerController finalizeSeriesViewing]
    
    DicomStudy* study = [vc currentStudy];
    
    if (study)
        [self saveKOsForStudy:study];
}

-(NSString*)DA:(NSDate*)date {
    return [date descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil];
}

-(NSString*)TM:(NSDate*)date {
    return [date descriptionWithCalendarFormat:@"%H%M" timeZone:nil locale:nil];
}

-(NSString*)createKeyObjectSelectionDocumentWithStudy:(DicomStudy*)study codeValue:(const char*)codeValue meaning:(const char*)codeMeaning contentImages:(NSArray*)contentImages {
    DicomDatabase* database = [DicomDatabase databaseForContext:study.managedObjectContext];
    
    NSMutableDictionary* contentImagesPerFile = [NSMutableDictionary dictionary];
    for (DicomImage* image in contentImages) {
        NSString* completePath = [image completePath];
        NSMutableArray* images = [contentImagesPerFile objectForKey:completePath];
        if (!images) [contentImagesPerFile setObject:(images = [NSMutableArray array]) forKey:completePath];
        [images addObject:image];
    }
    
    DicomSeries* series = nil; // series containing KO images
    for (DicomImage* ko in [[self class] KOsInStudy:study]) {
        series = ko.series;
        break;
    }
    
    // create KO file
    
    DSRDocument document(DSRTypes::DT_KeyObjectDoc);
    DSRDocumentTree& dtree = document.getTree();

    document.createNewSeriesInStudy(study.studyInstanceUID.UTF8String);
    if (series) {
        document.setSeriesNumber(series.id.stringValue.UTF8String);
        document.setSeriesDescription(series.seriesDescription.UTF8String);
    }
    
    document.setInstanceNumber("1");
    document.setSpecificCharacterSetType(DSRTypes::CS_UTF8);
	if (study.name) document.setPatientsName(study.name.UTF8String);
	if (study.studyName) document.setStudyDescription(study.studyName.UTF8String);
	if (study.dateOfBirth) document.setPatientsBirthDate([[self DA:study.dateOfBirth] UTF8String]);
	if (study.patientSex) document.setPatientsSex(study.patientSex.UTF8String);
	if (study.patientID) document.setPatientID(study.patientID.UTF8String);
	if (study.referringPhysician) document.setReferringPhysiciansName(study.referringPhysician.UTF8String);
	if (study.id) document.setStudyID(study.id.UTF8String);
	if (study.accessionNumber) document.setAccessionNumber(study.accessionNumber.UTF8String);
	document.setSeriesDescription("OsiriX KeyObjectSelection Plugin KO");
    document.setManufacturer("OsiriX KeyObjectSelection Plugin");
    
    NSDate* now = [NSDate date];
    document.setContentDate([[self DA:now] UTF8String]);
    document.setContentTime([[self TM:now] UTF8String]);
    
    // KEY OBJECT DOCUMENT MODULE
    
    dtree.addContentItem(DSRTypes::RT_isRoot, DSRTypes::VT_Container);
    DSRContentItem& dci = dtree.getCurrentContentItem();
    
    DSRCodedEntryValue* conceptName = dci.getConceptNamePtr();
    if (conceptName != NULL)
        conceptName->setCode(codeValue, "DCM", codeMeaning);

    DSRTypes::E_AddMode addMode = DSRTypes::AM_belowCurrent;
    for (NSString* path in contentImagesPerFile) {
        NSArray* contentImages = [contentImagesPerFile objectForKey:path];
        DicomImage* image0 = [contentImages objectAtIndex:0];
        
        DcmFileFormat iff;
        iff.loadFile([[image0 completePath] fileSystemRepresentation]);
        DcmDataset* idataset = iff.getDataset();
        
        const char* sopClassUID;
        idataset->findAndGetString(DcmTagKey(DCM_SOPClassUID), sopClassUID);
        const char* sopInstanceUID;
        idataset->findAndGetString(DcmTagKey(DCM_SOPInstanceUID), sopInstanceUID);
        
        dtree.addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Image, addMode);
        DSRContentItem& ici = dtree.getCurrentContentItem();
        DSRImageReferenceValue* ref = ici.getImageReferencePtr();
        
        ref->setValue(DSRImageReferenceValue(sopClassUID, sopInstanceUID));
        
        if (contentImages.count > 1 || [DCMAbstractSyntaxUID isMultiframe:[NSString stringWithCString:sopClassUID encoding:NSUTF8StringEncoding]])
            for (DicomImage* image in contentImages)
                ref->getFrameList().addItem(image.frameID.integerValue);
        
        addMode = DSRTypes::AM_afterCurrent;
    }
    
    // save
    
    [NSFileManager.defaultManager confirmDirectoryAtPath:database.tempDirPath];
    NSString* outputFilePath = [NSFileManager.defaultManager tmpFilePathInDir:database.tempDirPath];

    DcmFileFormat dff;
    DcmDataset* dataset = dff.getDataset();
    document.write(*dataset);
    
    if (series) {
        dataset->putAndInsertString(DCM_SeriesInstanceUID, series.seriesDICOMUID.UTF8String);
    }
    
    OFCondition cond = dff.saveFile(outputFilePath.fileSystemRepresentation, EXS_LittleEndianExplicit);
    if (cond.bad())
        [NSException raise:NSGenericException format:@"Can't write KO file:\n%s", cond.text()];
    
    NSString* dbpath = [database uniquePathForNewDataFileWithExtension:@"dcm"];
    [NSFileManager.defaultManager moveItemAtPath:outputFilePath toPath:dbpath error:NULL];
    [database addFilesAtPaths:[NSArray arrayWithObject:dbpath]
            postNotifications:NO
                    dicomOnly:YES 
          rereadExistingItems:YES
            generatedByOsiriX:YES];
    
    return dbpath;
}

- (void)dicomImage:(DicomImage*)image setIsKeyImage:(NSNumber*)flag {
    // this function is executed AFTER -[DicomImage setIsKeyImage:] and only if the image's isKeyImage value has changed
    
    NSThread* thread = [NSThread currentThread];
    
    if ([thread.threadDictionary objectForKey:KOSIsApplyingKOsThreadKey])
        return; // it's the plugin that's assigning this flag, don't react...
    
    // DO SOMETHING? no, no
}

-(void)playGrabSound {
    NSString* path = @"/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Grab.aif";
    NSSound* sound = [[NSSound alloc] initWithContentsOfFile:path byReference:NO];
    sound.delegate = self;
    [sound play];
}

- (void)sound:(NSSound*)sound didFinishPlaying:(BOOL)finishedPlaying {
    [sound release];
}

#pragma mark Swizzled methods

- (void)_ViewerController_changeImageData:(NSMutableArray*)f :(NSMutableArray*)d :(NSData*)v :(BOOL)newViewerWindow {
    [self _ViewerController_changeImageData:f:d:v:newViewerWindow];
//    NSLog(@"...changeImageData, react to reload KeyObjectSelectionDocument series");
    [KeyObjectSelectionFilterInstance viewerController:(ViewerController*)self changeImageData:f:d:v:newViewerWindow];
}

- (void)_ViewerController_finalizeSeriesViewing {
    [KeyObjectSelectionFilterInstance finalizeSeriesViewingForViewerController:(ViewerController*)self];
//    NSLog(@"...finalizeSeriesViewing, react to save KeyObjectSelectionDocument series");
    [self _ViewerController_finalizeSeriesViewing];
}

static NSString* const KOSReconstructionsSeriesName = NSLocalizedString(@"OsiriX Screen Captures", nil);

-(void)_ViewerController_setKeyImage:(id)sender {
    //if ([(ViewerController*)self blendingController])
    if (![[[(ViewerController*)self currentImage] isKeyImage] boolValue])
    {
        [KeyObjectSelectionFilterInstance playGrabSound];
        
        DicomStudy* study = [(ViewerController*)self currentStudy];
        
        // export the reconstruction as a new DICOM file
        NSDictionary* result = [(ViewerController*)self exportDICOMFileInt:1 withName:KOSReconstructionsSeriesName allViewers:NO];
        NSString* path = [result objectForKey:@"file"];
        
        // if a "OsiriX KOS Plugin Reconstructions" series already existed, put it in that series
        DicomSeries* series = nil;
        for (DicomSeries* iseries in study.series)
            if ([iseries.name isEqualToString:KOSReconstructionsSeriesName])
                series = iseries;
        if (series) {
            DcmFileFormat dfile;
            DcmDataset* dset = dfile.getDataset(); // = &dfile;
            if (dfile.loadFile(path.fileSystemRepresentation).good()) {
                dfile.loadAllDataIntoMemory();
                
                // clone seriesinstanceUID and seriesNumber
                dset->putAndInsertString(DCM_SeriesInstanceUID, series.seriesDICOMUID.UTF8String);
                dset->putAndInsertString(DCM_SeriesNumber, series.id.stringValue.UTF8String);
                
                // find highest instanceNumber in the series
                NSInteger instanceNumber = 0;
                for (DicomImage* image in series.images)
                    if (image.instanceNumber.integerValue > instanceNumber)
                        instanceNumber = image.instanceNumber.integerValue;
                ++instanceNumber;
                
                NSNumber* instanceNumberString = [NSNumber numberWithInteger:instanceNumber];
                dset->putAndInsertString(DCM_InstanceNumber, instanceNumberString.stringValue.UTF8String);
                dset->putAndInsertString(DCM_AcquisitionNumber, instanceNumberString.stringValue.UTF8String);
                
                dfile.saveFile(path.fileSystemRepresentation);
            }
        }
        
        // import the file into our DB
        DicomDatabase* database = [DicomDatabase databaseForContext:study.managedObjectContext];
        NSArray* images = [database addFilesAtPaths:[NSArray arrayWithObject:path]
                                  postNotifications:YES
                                          dicomOnly:YES 
                                rereadExistingItems:YES
                                  generatedByOsiriX:YES];
        
        // upload the new file to the DICOM node
        if ([NSUserDefaults.standardUserDefaults boolForKey:KOSSynchronizeKey]) // plugin is active
            [NSThread performBlockInBackground: ^{
                NSString* myAET = [NSUserDefaults.standardUserDefaults stringForKey:@"AETITLE"];
                NSString* tAET = [NSUserDefaults.standardUserDefaults stringForKey:KOSAETKey];
                NSString* tHost = [NSUserDefaults.standardUserDefaults stringForKey:KOSNodeHostKey];
                NSInteger tPort = [NSUserDefaults.standardUserDefaults integerForKey:KOSNodePortKey];
                
                NSThread* thread = [NSThread currentThread];
                thread.name = [NSString stringWithFormat:NSLocalizedString(@"KeyObjects for %@", nil), study.name];
                thread.status = [NSString stringWithFormat:NSLocalizedString(@"Saving reconstruction to %@...", nil), tAET];
                [ThreadsManager.defaultManager addThreadAndStart:thread];
                
                DCMTKStoreSCU* storescu = [[[DCMTKStoreSCU alloc] initWithCallingAET:myAET
                                                                           calledAET:tAET
                                                                            hostname:tHost
                                                                                port:tPort
                                                                         filesToSend:[NSArray arrayWithObject:path]
                                                                      transferSyntax:0
                                                                         compression:1.0
                                                                     extraParameters:nil] autorelease];
                [storescu run:self];
            }];
        
        // set the new images as key images
        for (DicomImage* image in images)
            [image setIsKeyImage:[NSNumber numberWithBool:YES]];
        
    } else
        [self _ViewerController_setKeyImage:sender];
}

- (void)_DicomImage_setIsKeyImage:(NSNumber*)flag {
    BOOL wasKeyImage = [[(id)self isKeyImage] boolValue];
    
    NSThread* thread = [NSThread currentThread];
    N2MutableUInteger* ui = [thread.threadDictionary objectForKey:KOSIsSettingKeyFlagThreadKey];
    if (!ui) [thread.threadDictionary setObject:(ui = [N2MutableUInteger mutableUIntegerWithUInteger:0]) forKey:KOSIsSettingKeyFlagThreadKey];
    [ui increment];
    
    [[(DicomImage*)self managedObjectContext] lock]; // this avoids a deadlock
    @try {
        [self _DicomImage_setIsKeyImage:flag];
    } @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    } @finally {
        [[(DicomImage*)self managedObjectContext] unlock];
    }
    
    [ui decrement];
    if (!ui.unsignedIntegerValue) [thread.threadDictionary removeObjectForKey:KOSIsSettingKeyFlagThreadKey];
    
    if (wasKeyImage != flag.boolValue)
        [KeyObjectSelectionFilterInstance dicomImage:(DicomImage*)self setIsKeyImage:flag];
}

/*-(void)_MPRController_setKeyImage:(id)sender {
    NSLog(@"EUREKA MPRController");
}*/

@end
