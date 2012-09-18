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
#import <OsiriXAPI/DicomFile.h>
#import <OsiriXAPI/N2Debug.h>


NSString* const WorklistIDKey = @"id";
NSString* const WorklistNameKey = @"name";
NSString* const WorklistHostKey = @"host";
NSString* const WorklistPortKey = @"port";
NSString* const WorklistCalledAETKey = @"calledAet";
NSString* const WorklistCallingAETKey = @"callingAet";
NSString* const WorklistRefreshSecondsKey = @"refreshSeconds";
NSString* const WorklistAutoRetrieveKey = @"autoRetrieve";


@interface WorklistTimerInvoker : NSObject {
    id _target;
    SEL _sel;
}

+ (id)invokerWithTarget:(id)target selector:(SEL)sel;

@end


@implementation WorklistTimerInvoker

- (id)initWithTarget:(id)target selector:(SEL)sel {
    if ((self = [super init])) {
        _target = target; // no retain!
        _sel = sel;
    }
    
    return self;
}

+ (id)invokerWithTarget:(id)target selector:(SEL)sel {
    return [[[[self class] alloc] initWithTarget:target selector:sel] autorelease];
}

- (void)fire:(NSTimer*)timer {
    [_target performSelector:_sel withObject:timer];
}

@end


@interface Worklist ()

@property (nonatomic,retain) NSTimer* refreshTimer;

@end


@implementation Worklist

@synthesize properties = _properties;
@synthesize refreshTimer = _refreshTimer;

+ (id)worklistWithProperties:(NSDictionary*)properties {
    return [[[[self class] alloc] initWithProperties:properties] autorelease];
}

-(id)initWithProperties:(NSDictionary*)properties {
    if ((self = [super init])) {
        self.properties = properties;
    }
    
    return self;
}

- (void)dealloc {
    self.refreshTimer = nil;
    self.properties = nil;
    [super dealloc];
}

- (void)setRefreshTimer:(NSTimer*)refreshTimer {
    if (refreshTimer != _refreshTimer) {
        [_refreshTimer invalidate];
        [_refreshTimer release];
        _refreshTimer = [refreshTimer retain];
    }
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

- (void)setProperties:(NSDictionary*)properties {
    if (properties != _properties && ![properties isEqual:_properties]) {
        [_properties release];
        _properties = [properties retain];
    }
    
    if (!properties)
        return;
    
    DicomDatabase* db = [DicomDatabase defaultDatabase];
    
    [self albumInDatabase:db];
    
    NSTimeInterval ti = [[properties objectForKey:WorklistRefreshSecondsKey] integerValue];
    if (!ti) ti = 300; // the default
    
    if (!self.refreshTimer || _refreshTimer.timeInterval != ti)
        self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:ti target:[WorklistTimerInvoker invokerWithTarget:self selector:@selector(initiateRefresh)] selector:@selector(fire:) userInfo:nil repeats:YES];
    
    [_refreshTimer fire];
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

// TODO: CDStringEncoding only supports part of the needed encodings, we should switch to iconv...
#define WorklistsEncodingType CFStringEncoding
#define WorklistsDefaultEncoding kCFStringEncodingISOLatin1

static WorklistsEncodingType WorklistEncodingWithDicomName(const OFString& string) {
    if (string == "ISO_IR 6")
        return kCFStringEncodingASCII;
    if (string == "ISO_IR 100")
        return kCFStringEncodingISOLatin1;
    if (string == "ISO_IR 101")
        return kCFStringEncodingISOLatin2;
    if (string == "ISO_IR 109")
        return kCFStringEncodingISOLatin3;
    if (string == "ISO_IR 110")
        return kCFStringEncodingISOLatin4;
    if (string == "ISO_IR 144")
        return kCFStringEncodingISOLatinCyrillic;
    if (string == "ISO_IR 127")
        return kCFStringEncodingISOLatinArabic;
    if (string == "ISO_IR 126")
        return kCFStringEncodingISOLatinGreek;
    if (string == "ISO_IR 138")
        return kCFStringEncodingISOLatinHebrew;
    if (string == "ISO_IR 148")
        return kCFStringEncodingISOLatin5;
    if (string == "ISO_IR 13")
        return kCFStringEncodingDOSJapanese; // TODO: ???
    if (string == "ISO_IR 166")
        return kCFStringEncodingISOLatinThai;
    if (string == "ISO_IR 192")
        return kCFStringEncodingUTF8;
    
    return kCFStringEncodingISOLatin1; // hmmm
}

static NSString* WorklistsString(const OFString& string, WorklistsEncodingType encoding) {
    return [(id)CFStringCreateWithCString(nil, string.c_str(), encoding) autorelease];
}

static void _findUserCallback(void* callbackData, T_DIMSE_C_FindRQ* request, int responseCount, T_DIMSE_C_FindRSP* rsp, DcmDataset* response) {
    NSMutableArray* entries = (id)callbackData;
    
    // NSLog(@"_findUserCallback %d", responseCount);
    // response->print(COUT);
    
    NSMutableDictionary* entry = [NSMutableDictionary dictionary];
    [entries addObject:entry];
    
    OFString string;
    DcmItem* item;
    
    WorklistsEncodingType encoding = WorklistsDefaultEncoding;
    if (response->findAndGetOFString(DCM_SpecificCharacterSet, string).good())
        encoding = WorklistEncodingWithDicomName(string);
    
    if (response->findAndGetOFString(DCM_AccessionNumber, string).good())
        [entry setObject:WorklistsString(string, encoding) forKey:@"AccessionNumber"];
    if (response->findAndGetOFString(DCM_ReferringPhysiciansName, string).good())
        [entry setObject:WorklistsString(string, encoding) forKey:@"ReferringPhysiciansName"];
    if (response->findAndGetOFString(DCM_PatientsName, string).good())
        [entry setObject:WorklistsString(string, encoding) forKey:@"PatientsName"];
    if (response->findAndGetOFString(DCM_PatientID, string).good())
        [entry setObject:WorklistsString(string, encoding) forKey:@"PatientID"];
    if (response->findAndGetOFString(DCM_PatientsBirthDate, string).good())
        [entry setObject:WorklistsString(string, encoding) forKey:@"PatientsBirthDate"];
    if (response->findAndGetOFString(DCM_PatientsSex, string).good())
        [entry setObject:WorklistsString(string, encoding) forKey:@"PatientsSex"];
    if (response->findAndGetOFString(DCM_StudyInstanceUID, string).good())
        [entry setObject:WorklistsString(string, encoding) forKey:@"StudyInstanceUID"];
    if (response->findAndGetOFString(DCM_RequestedProcedureDescription, string).good())
        [entry setObject:WorklistsString(string, encoding) forKey:@"RequestedProcedureDescription"];
    
    if (response->findAndGetSequenceItem(DCM_ScheduledProcedureStepSequence, item).good()) {
        if (item->findAndGetOFString(DCM_Modality, string).good())
            [entry setObject:WorklistsString(string, encoding) forKey:@"Modality"];
        if (item->findAndGetOFString(DCM_ScheduledPerformingPhysiciansName, string).good())
            [entry setObject:WorklistsString(string, encoding) forKey:@"ScheduledPerformingPhysiciansName"];
        if (item->findAndGetOFString(DCM_ScheduledProcedureStepStartDate, string).good())
            [entry setObject:WorklistsString(string, encoding) forKey:@"ScheduledProcedureStepStartDate"];
        if (item->findAndGetOFString(DCM_ScheduledProcedureStepStartTime, string).good())
            [entry setObject:WorklistsString(string, encoding) forKey:@"ScheduledProcedureStepStartTime"];
    }
}

- (DicomStudy*)database:(DicomDatabase*)db createEmptyStudy:(NSDictionary*)entry {
    DicomStudy* study = [db newObjectForEntity:db.studyEntity];
    
    NSString* name = [entry objectForKey:@"PatientsName"];
    NSString* oname = name;
    name = [name stringByReplacingOccurrencesOfString:@", " withString:@" "];
    name = [name stringByReplacingOccurrencesOfString:@"," withString:@" "];
    name = [name stringByReplacingOccurrencesOfString:@"^ " withString:@" "];
    name = [name stringByReplacingOccurrencesOfString:@"^" withString:@" "];
    
    study.name = name;
    
    study.patientID = [entry objectForKey:@"PatientID"];
    
    study.studyInstanceUID = [entry objectForKey:@"StudyInstanceUID"];
    study.dateOfBirth = [NSDate dateWithYYYYMMDD:[entry objectForKey:@"PatientsBirthDate"] HHMMss:nil];
    study.studyName = [entry objectForKey:@"RequestedProcedureDescription"];
    study.date = [NSDate dateWithYYYYMMDD:[entry objectForKey:@"ScheduledProcedureStepStartDate"] HHMMss:[entry objectForKey:@"ScheduledProcedureStepStartTime"]]; 
    study.modality = [entry objectForKey:@"Modality"];
    study.accessionNumber = [entry objectForKey:@"AccessionNumber"];
    
    study.patientUID = [DicomFile patientUID:[NSDictionary dictionaryWithObjectsAndKeys:
                                              oname, @"patientName",
                                              study.patientID, @"patientID",
                                              study.dateOfBirth, @"patientBirthDate",
                                              nil]];
    
    DicomSeries* series = [db newObjectForEntity:db.seriesEntity];
    
    series.name = @"OsiriX No Autodeletion";
    series.id = [NSNumber numberWithInt:5005];
    
    [[study mutableSetValueForKey:@"series"] addObject:series];
    
    return study;
}

- (void)refresh {
    @synchronized (self) {
        T_ASC_Network* net = nil;
        T_ASC_Association* assoc = nil;
        NSMutableArray* entries = [NSMutableArray array];
        DcmDataset* statusDetail = nil;
        
        @try {
            OFCondition cond;
            
            NSString* calledAet = [_properties objectForKey:WorklistCalledAETKey]; // XPLORE
            NSString* callingAet = [_properties objectForKey:WorklistCallingAETKey]; // QSSCT2
            NSString* peerAddress = [_properties objectForKey:WorklistHostKey];
            NSInteger peerPort = [[_properties objectForKey:WorklistPortKey] intValue];
            if (!peerPort) peerPort = 104;
            
            if (!calledAet || !callingAet || !peerAddress)
                [NSException raise:NSGenericException format:@"Incomplete worklist setup"];
            
            int acse_timeout = 30;

            cond = ASC_initializeNetwork(NET_REQUESTOR, 0, acse_timeout, &net);
            if (cond.bad())
                [NSException raise:NSGenericException format:@"%s", cond.text()];
            
            T_ASC_Parameters* params;
            ASC_createAssociationParameters(&params, ASC_DEFAULTMAXPDU);

            ASC_setAPTitles(params, callingAet.UTF8String, calledAet.UTF8String, NULL);
            
            cond = ASC_setTransportLayerType(params, false);
            if (cond.bad())
                [NSException raise:NSGenericException format:@"%s", cond.text()];
            
            DIC_NODENAME localHost;
            DIC_NODENAME peerHost;
            gethostname(localHost, sizeof(localHost)-1);
            sprintf(peerHost, "%s:%d", peerAddress.UTF8String, peerPort);
            ASC_setPresentationAddresses(params, localHost, peerHost);

            const char* transferSyntaxes[] = { UID_LittleEndianExplicitTransferSyntax, UID_BigEndianExplicitTransferSyntax, UID_LittleEndianImplicitTransferSyntax };
            cond = ASC_addPresentationContext(params, 1, UID_FINDModalityWorklistInformationModel, transferSyntaxes, 3);
            if (cond.bad())
                [NSException raise:NSGenericException format:@"%s", cond.text()];
            
            cond = ASC_requestAssociation(net, params, &assoc);
            if (cond.bad())
                [NSException raise:NSGenericException format:@"%s", cond.text()];
            
            DIC_US msgId = assoc->nextMsgID++;
            
            T_ASC_PresentationContextID presId = ASC_findAcceptedPresentationContextID(assoc, UID_FINDModalityWorklistInformationModel);
            if (presId == 0)
                [NSException raise:NSGenericException format:@"No presentation contexts"];

            T_DIMSE_C_FindRQ req;
            bzero((char*)&req, sizeof(req));
            req.MessageID = msgId;
            strcpy(req.AffectedSOPClassUID, UID_FINDModalityWorklistInformationModel);
            req.DataSetType = DIMSE_DATASET_PRESENT;
            req.Priority = DIMSE_PRIORITY_LOW;
            
            DcmFileFormat dcmff;
            dcmff.getDataset()->insert(newDicomElement(DcmTag(0x0040,0x0100)));
            
            T_DIMSE_C_FindRSP rsp;
            cond = DIMSE_findUser(assoc, presId, &req, dcmff.getDataset(), _findUserCallback, entries, DIMSE_BLOCKING, 0, &rsp, &statusDetail);
            if (cond.bad())
                [NSException raise:NSGenericException format:@"%s", cond.text()];

            // NSLog(@"Results: %@", entries);
            NSLog(@"Worklist: %d studies in %@", (int)entries.count, [_properties objectForKey:WorklistNameKey]);
        } @catch (...) {
            @throw;
        } @finally {
            if (statusDetail)
                delete statusDetail;
            
            if (assoc) {
                ASC_releaseAssociation(assoc);
                ASC_destroyAssociation(&assoc);
            }
            
            if (net)
                ASC_dropNetwork(&net);
        }
        
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
        
        [db save]; // this is a secondary db, make sure the changes are applied to the main db before refreshing...
        [self performSelectorOnMainThread:@selector(_mainThreadGUIRefresh) withObject:nil waitUntilDone:NO];
    }
}

-(void)_threadRefresh {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try {
        [self refresh];
    } @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    } @finally {
        [pool release];
    }
}

- (void)initiateRefresh {
    [self performSelectorInBackground:@selector(_threadRefresh) withObject:nil];
}

- (void)_mainThreadGUIRefresh {
    DicomDatabase* db = [DicomDatabase defaultDatabase];
    
    [[self class] invalidateAlbumsCacheForDatabase:db];
    [BrowserController.currentBrowser refreshAlbums];
    [BrowserController.currentBrowser outlineViewRefresh];
    
    // if album is selected, refresh the study list
    DicomAlbum* album = [db objectWithID:self.albumId];
    if (album && [[[BrowserController currentBrowser] albumTable] isRowSelected:[db.albums indexOfObject:album]+1]) // album is selected
        [BrowserController.currentBrowser tableViewSelectionDidChange:[NSNotification notificationWithName:NSTableViewSelectionDidChangeNotification object:[BrowserController.currentBrowser albumTable]]];
}





























@end
