//
//  Worklist.m
//  Worklists
//
//  Created by Alessandro Volz on 09/14/2012.
//  Copyright 2012 OsiriX Team. All rights reserved.
//

#import "Worklist.h"
#import "WorklistsPlugin.h"
#import <OsiriXAPI/DicomDatabase.h>
#import <OsiriXAPI/DicomAlbum.h>
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/browserController.h>
#import <OsiriXAPI/Notifications.h>
#import <OsiriXAPI/dimse.h>
#import <OsiriXAPI/dcfilefo.h>
#import <OsiriXAPI/dcelem.h>
#import <OsiriXAPI/dctag.h>
#import <OsiriXAPI/dcdeftag.h>
#import <OsiriXAPI/NSDate+N2.h>


NSString* const WorklistIDKey = @"id";
NSString* const WorklistNameKey = @"name";
NSString* const WorklistHostKey = @"host";
NSString* const WorklistPortKey = @"port";
NSString* const WorklistCalledAETKey = @"calledAet";
NSString* const WorklistCallingAETKey = @"callingAet";
NSString* const WorklistRefreshSecondsKey = @"refreshSeconds";
NSString* const WorklistAutoRetrieveKey = @"autoRetrieve";


@interface Worklist ()

@property(retain,readwrite) NSDate* lastUpdateDate;

//+ (void)worklistWithID:(NSString*)wid setAlbumID:(NSString*)aid;

@end


@implementation Worklist

@synthesize lastUpdateDate = _lastUpdateDate;
@synthesize properties = _properties;

+ (id)worklistWithProperties:(NSMutableDictionary*)properties {
    return [[[[self class] alloc] initWithProperties:properties] autorelease];
}

-(id)initWithProperties:(NSMutableDictionary*)properties {
    if ((self = [super init])) {
        self.properties = properties;
        [self update];
    }
    
    return self;
}

- (void)dealloc {
    self.lastUpdateDate = nil;
    self.properties = nil;
    [super dealloc];
}

+ (void)invalidateAlbumsCacheForDatabase:(DicomDatabase*)db {
    [NSNotificationCenter.defaultCenter postNotificationName:O2DatabaseInvalidateAlbumsCacheNotification object:db];
}

- (NSString*)albumIdDefaultsKey {
    return [NSString stringWithFormat:@"Worklist Album ID %@", [_properties objectForKey:WorklistIDKey]];
}

- (NSString*)albumId {
    return [NSUserDefaults.standardUserDefaults objectForKey:self.albumIdDefaultsKey];
}

-(void)setAlbumId:(NSString*)value {
    [NSUserDefaults.standardUserDefaults setObject:value forKey:self.albumIdDefaultsKey];
}

- (DicomAlbum*)albumInDatabase:(DicomDatabase*)db { // make sure it has an album, and return it
    NSString* albumId = [self albumId];
    DicomAlbum* album = nil;
    
    NSString* name = [_properties objectForKey:WorklistNameKey];
    if (!name.length)
        name = NSLocalizedString(@"Worklist", nil);
    
    if (albumId) // make sure the album exists
        if ((album = [db objectWithID:albumId]) == nil) // it doesn't
            albumId = nil;
        else {
            // make sure the album name matches the name property
            album.name = name;
        }
    
    if (!albumId) { // create the album
        album = [db newObjectForEntity:[db albumEntity]];
        album.name = name;
        [album.managedObjectContext save:NULL]; // we want a persistent NSManagedObject ID, that is only given on save
        albumId = [[album.objectID URIRepresentation] absoluteString];
        [self setAlbumId:albumId];
    }
    
    return album;
}

- (void)setProperties:(NSMutableDictionary*)properties {
    if (properties != _properties) {
        [_properties release];
        _properties = [properties retain];
    }
    
    if (!properties)
        return;
    
    DicomDatabase* db = [DicomDatabase defaultDatabase];
    
    [self albumInDatabase:db];
    
    [[self class] invalidateAlbumsCacheForDatabase:db];
    [BrowserController.currentBrowser refreshAlbums];

}

- (void)delete {
    DicomDatabase* db = [DicomDatabase defaultDatabase];
    
    [WorklistsPlugin.instance deselectAlbumOfWorklist:self];
    
    // delete the album
    NSString* albumId = [self albumId];
    DicomAlbum* album = [db objectWithID:albumId];
    [db.managedObjectContext deleteObject:album];
    
    // delete data
    [NSUserDefaults.standardUserDefaults removeObjectForKey:self.albumIdDefaultsKey];
    
    [[self class] invalidateAlbumsCacheForDatabase:db];
    [BrowserController.currentBrowser refreshAlbums];
}

static void _findUserCallback(void* callbackData, T_DIMSE_C_FindRQ* request, int responseCount, T_DIMSE_C_FindRSP* rsp, DcmDataset* response) {
    NSMutableArray* entries = (id)callbackData;
    
    // NSLog(@"_findUserCallback %d", responseCount);
    response->print(COUT);
    
    NSMutableDictionary* entry = [NSMutableDictionary dictionary];
    [entries addObject:entry];
    
    OFString string;
    DcmItem* item;
    
    CFStringEncoding encoding = kCFStringEncodingASCII;
    if (response->findAndGetOFString(DCM_SpecificCharacterSet, string).good()) {
        if (strcmp(string.c_str(), "ISO_IR 6") == 0)
            encoding = kCFStringEncodingASCII;
        if (strcmp(string.c_str(), "ISO_IR 100") == 0)
            encoding = kCFStringEncodingISOLatin1;
        if (strcmp(string.c_str(), "ISO_IR 101") == 0)
            encoding = kCFStringEncodingISOLatin2;
        if (strcmp(string.c_str(), "ISO_IR 109") == 0)
            encoding = kCFStringEncodingISOLatin3;
        if (strcmp(string.c_str(), "ISO_IR 110") == 0)
            encoding = kCFStringEncodingISOLatin4;
        if (strcmp(string.c_str(), "ISO_IR 144") == 0)
            encoding = kCFStringEncodingISOLatinCyrillic;
        if (strcmp(string.c_str(), "ISO_IR 127") == 0)
            encoding = kCFStringEncodingISOLatinArabic;
        if (strcmp(string.c_str(), "ISO_IR 126") == 0)
            encoding = kCFStringEncodingISOLatinGreek;
        if (strcmp(string.c_str(), "ISO_IR 138") == 0)
            encoding = kCFStringEncodingISOLatinHebrew;
        if (strcmp(string.c_str(), "ISO_IR 148") == 0)
            encoding = kCFStringEncodingISOLatin5;
        if (strcmp(string.c_str(), "ISO_IR 13") == 0)
            encoding = kCFStringEncodingDOSJapanese; // TODO: ???
        if (strcmp(string.c_str(), "ISO_IR 166") == 0)
            encoding = kCFStringEncodingISOLatinThai;
        if (strcmp(string.c_str(), "ISO_IR 192") == 0)
            encoding = kCFStringEncodingUTF8;
    }
    
    if (response->findAndGetOFString(DCM_AccessionNumber, string).good())
        [entry setObject:[(id)CFStringCreateWithCString(nil, string.c_str(), encoding) autorelease] forKey:@"AccessionNumber"];
    if (response->findAndGetOFString(DCM_ReferringPhysiciansName, string).good())
        [entry setObject:[(id)CFStringCreateWithCString(nil, string.c_str(), encoding) autorelease] forKey:@"ReferringPhysiciansName"];
    if (response->findAndGetOFString(DCM_PatientsName, string).good())
        [entry setObject:[(id)CFStringCreateWithCString(nil, string.c_str(), encoding) autorelease] forKey:@"PatientsName"];
    if (response->findAndGetOFString(DCM_PatientID, string).good())
        [entry setObject:[(id)CFStringCreateWithCString(nil, string.c_str(), encoding) autorelease] forKey:@"PatientID"];
    if (response->findAndGetOFString(DCM_PatientsBirthDate, string).good())
        [entry setObject:[(id)CFStringCreateWithCString(nil, string.c_str(), encoding) autorelease] forKey:@"PatientsBirthDate"];
    if (response->findAndGetOFString(DCM_PatientsSex, string).good())
        [entry setObject:[(id)CFStringCreateWithCString(nil, string.c_str(), encoding) autorelease] forKey:@"PatientsSex"];
    if (response->findAndGetOFString(DCM_StudyInstanceUID, string).good())
        [entry setObject:[(id)CFStringCreateWithCString(nil, string.c_str(), encoding) autorelease] forKey:@"StudyInstanceUID"];
    if (response->findAndGetOFString(DCM_RequestedProcedureDescription, string).good())
        [entry setObject:[(id)CFStringCreateWithCString(nil, string.c_str(), encoding) autorelease] forKey:@"RequestedProcedureDescription"];
    
    if (response->findAndGetSequenceItem(DCM_ScheduledProcedureStepSequence, item).good()) {
        if (item->findAndGetOFString(DCM_Modality, string).good())
            [entry setObject:[(id)CFStringCreateWithCString(nil, string.c_str(), encoding) autorelease] forKey:@"Modality"];
        if (item->findAndGetOFString(DCM_ScheduledPerformingPhysiciansName, string).good())
            [entry setObject:[(id)CFStringCreateWithCString(nil, string.c_str(), encoding) autorelease] forKey:@"ScheduledPerformingPhysiciansName"];
        if (item->findAndGetOFString(DCM_ScheduledProcedureStepStartDate, string).good())
            [entry setObject:[(id)CFStringCreateWithCString(nil, string.c_str(), encoding) autorelease] forKey:@"ScheduledProcedureStepStartDate"];
        if (item->findAndGetOFString(DCM_ScheduledProcedureStepStartTime, string).good())
            [entry setObject:[(id)CFStringCreateWithCString(nil, string.c_str(), encoding) autorelease] forKey:@"ScheduledProcedureStepStartTime"];
    }
}

- (DicomStudy*)database:(DicomDatabase*)db createEmptyStudy:(NSDictionary*)entry {
    DicomStudy* study = [db newObjectForEntity:db.studyEntity];
    
    study.studyInstanceUID = [entry objectForKey:@"StudyInstanceUID"];
    
    NSString* name = [entry objectForKey:@"PatientsName"];
    name = [name stringByReplacingOccurrencesOfString:@", " withString:@" "];
    name = [name stringByReplacingOccurrencesOfString:@"," withString:@" "];
    name = [name stringByReplacingOccurrencesOfString:@"^ " withString:@" "];
    name = [name stringByReplacingOccurrencesOfString:@"^" withString:@" "];
    study.name = name;
    
    study.patientID = [entry objectForKey:@"PatientID"];
    //study.patientUID = [entry objectForKey:@"patientUID"];
    study.dateOfBirth = [NSDate dateWithYYYYMMDD:[entry objectForKey:@"PatientsBirthDate"] HHMMss:nil];
    study.studyName = [entry objectForKey:@"RequestedProcedureDescription"];
    study.date = [NSDate dateWithYYYYMMDD:[entry objectForKey:@"ScheduledProcedureStepStartDate"] HHMMss:[entry objectForKey:@"ScheduledProcedureStepStartTime"]]; 
    study.modality = [entry objectForKey:@"Modality"];
    study.accessionNumber = [entry objectForKey:@"AccessionNumber"];
    
    DicomSeries* series = [db newObjectForEntity:db.seriesEntity];
    
    series.name = @"OsiriX No Autodeletion";
    series.id = [NSNumber numberWithInt:5005];
    
    [[study mutableSetValueForKey:@"series"] addObject:series];
    
    return study;
}

- (void)update {
    OFCondition cond;
    
    NSString* calledAet = [_properties objectForKey:WorklistCalledAETKey]; // XPLORE
    NSString* callingAet = [_properties objectForKey:WorklistCallingAETKey]; // QSSCT2
    NSString* peerAddress = [_properties objectForKey:WorklistHostKey];
    NSInteger peerPort = [[_properties objectForKey:WorklistPortKey] intValue];
    if (!peerPort) peerPort = 104;
    
    if (!calledAet || !callingAet || !peerAddress)
        return; // TODO: report errors, somehow....
    
    T_ASC_Network* net;
    int acse_timeout = 30;

    cond = ASC_initializeNetwork(NET_REQUESTOR, 0, acse_timeout, &net);
    if (cond.bad()) {
        DimseCondition::dump(cond); // TODO: report errors, somehow....
    }
    
    T_ASC_Parameters* params;
    ASC_createAssociationParameters(&params, ASC_DEFAULTMAXPDU);

    ASC_setAPTitles(params, callingAet.UTF8String, calledAet.UTF8String, NULL);
    
    cond = ASC_setTransportLayerType(params, false);
    if (cond.bad()) {
        DimseCondition::dump(cond); // TODO: report errors, somehow....
    }
    
    DIC_NODENAME localHost;
    DIC_NODENAME peerHost;
    gethostname(localHost, sizeof(localHost)-1);
    sprintf(peerHost, "%s:%d", peerAddress.UTF8String, peerPort);
    ASC_setPresentationAddresses(params, localHost, peerHost);

    const char* transferSyntaxes[] = { UID_LittleEndianExplicitTransferSyntax, UID_BigEndianExplicitTransferSyntax, UID_LittleEndianImplicitTransferSyntax };
    cond = ASC_addPresentationContext(params, 1, UID_FINDModalityWorklistInformationModel, transferSyntaxes, 3);
    if (cond.bad()) {
        DimseCondition::dump(cond); // TODO: report errors, somehow....
    }
    
    T_ASC_Association* assoc;
    cond = ASC_requestAssociation(net, params, &assoc);
    if (cond.bad()) {
        DimseCondition::dump(cond); // TODO: report errors, somehow....
    }
    
    DIC_US msgId = assoc->nextMsgID++;
    
    T_ASC_PresentationContextID presId = ASC_findAcceptedPresentationContextID(assoc, UID_FINDModalityWorklistInformationModel);
    if (presId == 0) {
        //("No presentation context");
    }

    T_DIMSE_C_FindRQ req;
    bzero((char*)&req, sizeof(req));
    req.MessageID = msgId;
    strcpy(req.AffectedSOPClassUID, UID_FINDModalityWorklistInformationModel);
    req.DataSetType = DIMSE_DATASET_PRESENT;
    req.Priority = DIMSE_PRIORITY_LOW;
    
    DcmFileFormat dcmff;
    dcmff.getDataset()->insert(newDicomElement(DcmTag(0x0040,0x0100)));
    
    NSMutableArray* entries = [NSMutableArray array];
    
    T_DIMSE_C_FindRSP rsp;
    DcmDataset* statusDetail = nil;
    cond = DIMSE_findUser(assoc, presId, &req, dcmff.getDataset(), _findUserCallback, entries, DIMSE_BLOCKING, 0, &rsp, &statusDetail);
    if (cond.bad()) {
        DimseCondition::dump(cond); // TODO: report errors, somehow....
    }
    
    if (statusDetail)
        delete statusDetail;
    
    ASC_releaseAssociation(assoc); // release association
    ASC_destroyAssociation(&assoc); // delete assoc structure
    ASC_dropNetwork(&net); // delete net structure
    
    NSLog(@"Results: %@", entries);
    
    // for every entry, have a valid DicomStudy instance
    
    NSMutableArray* wstudies = [NSMutableArray array];
    DicomDatabase* db = [[DicomDatabase defaultDatabase] independentDatabase];
    
    NSPredicate* predicateTemplate = [NSPredicate predicateWithFormat:@"patientID = $PatientID AND accessionNumber = $AccessionNumber AND studyInstanceUID = $StudyInstanceUID"];
    
    for (NSDictionary* entry in entries) {
        NSArray* studies = [db objectsForEntity:db.studyEntity predicate:[predicateTemplate predicateWithSubstitutionVariables:entry]];
        
        if (!studies.count)
            studies = [NSArray arrayWithObject:[self database:db createEmptyStudy:entry]];
        
        [wstudies addObjectsFromArray:studies];
    }
    
    // synchronize the album studies with the studies array
    
    DicomAlbum* album = [self albumInDatabase:db];
    NSMutableSet* astudies = [album mutableSetValueForKey:@"studies"];
    
    for (DicomStudy* study in wstudies)
        if (![astudies containsObject:study])
            [astudies addObject:study];
    for (DicomStudy* study in [[astudies copy] autorelease])
        if (![wstudies containsObject:study]) {
            [astudies removeObject:study];
            // if the study is empty, delete it
            NSSet* series = [study series];
            if (!series.count || (series.count == 1 && [[series.anyObject id] intValue] == 5005 && [[series.anyObject name] isEqualToString:@"OsiriX No Autodeletion"])) {
                for (DicomSeries* s in [series.copy autorelease])
                    [db.managedObjectContext deleteObject:s];
                [db.managedObjectContext deleteObject:study];
            }
        }
    
    [self performSelector:@selector(_afterDelayRefresh) withObject:nil afterDelay:0.001];
}

- (void)_afterDelayRefresh {
    if (![NSThread isMainThread])
        [self performSelectorOnMainThread:@selector(_afterDelayRefresh) withObject:nil waitUntilDone:NO];
    else {
        [[self class] invalidateAlbumsCacheForDatabase:[DicomDatabase defaultDatabase]];
        [BrowserController.currentBrowser refreshAlbums];
        [BrowserController.currentBrowser outlineViewRefresh];
    }
}





























@end
