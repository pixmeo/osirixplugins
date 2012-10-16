//
//  Worklist.m
//  Worklists
//
//  Created by Alessandro Volz on 09/14/2012.
//  Copyright 2012 OsiriX Team. All rights reserved.
//

#import "Worklist.h"
#import "Worklist+POD.h"
#import "WorklistsPlugin.h"
#import <OsiriXAPI/DicomDatabase.h>
#import <OsiriXAPI/DicomAlbum.h>
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/browserController.h>
#import <OsiriXAPI/dimse.h>
#import <OsiriXAPI/dcfilefo.h>
#import <OsiriXAPI/dcelem.h>
#import <OsiriXAPI/dctag.h>
#import <OsiriXAPI/dcdeftag.h>
#import <OsiriXAPI/NSDate+N2.h>
#import <OsiriXAPI/DicomFile.h>
#import <OsiriXAPI/N2Debug.h>
#import <OsiriXAPI/NSThread+N2.h>
#import <OsiriXAPI/ThreadsManager.h>
#import <OsiriXAPI/DICOMToNSString.h>


NSString* const WorklistIDKey = @"id";
NSString* const WorklistNameKey = @"name";
NSString* const WorklistHostKey = @"host";
NSString* const WorklistPortKey = @"port";
NSString* const WorklistCalledAETKey = @"calledAet";
NSString* const WorklistCallingAETKey = @"callingAet";
NSString* const WorklistRefreshSecondsKey = @"refreshSeconds";
NSString* const WorklistAutoRetrieveKey = @"autoRetrieve";
NSString* const WorklistFilterFlagKey = @"filterFlag";
NSString* const WorklistFilterRuleKey = @"filterRule";
NSString* const WorklistNoLongerThenKey = @"noLongerThen";
NSString* const WorklistNoLongerThenIntervalKey = @"noLongerThenInterval";


@interface WorklistNonretainingTimerInvoker : NSObject {
    id _target;
    SEL _sel;
}

+ (id)invokerWithTarget:(id)target selector:(SEL)sel;

@end


@interface WorklistRuleUnarchiveFromData : NSValueTransformer

@end


@implementation WorklistNonretainingTimerInvoker

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
@property (nonatomic,retain) NSTimer* autoretrieveTimer;

@end


@implementation Worklist

@synthesize properties = _properties;
@synthesize refreshTimer = _refreshTimer;
@synthesize autoretrieveTimer = _autoretrieveTimer;

+ (id)worklistWithProperties:(NSDictionary*)properties {
    return [[[[self class] alloc] initWithProperties:properties] autorelease];
}

-(id)initWithProperties:(NSDictionary*)properties {
    if ((self = [super init])) {
        _refreshLock = [[NSRecursiveLock alloc] init];
        _autoretrieveLock = [[NSRecursiveLock alloc] init];
        _currentAutoretrieves = [[NSMutableDictionary alloc] init];
        _lastRefreshStudyInstanceUIDs = [[NSMutableArray alloc] init];
        self.properties = properties;
    }
    
    return self;
}

- (void)dealloc {
    self.properties = nil;
    self.autoretrieveTimer = nil;
    self.refreshTimer = nil;
    [_lastRefreshStudyInstanceUIDs release];
    [_currentAutoretrieves release];
    [_autoretrieveLock release];
    [_refreshLock release];
    [super dealloc];
}

- (void)setRefreshTimer:(NSTimer*)refreshTimer {
    if (refreshTimer != _refreshTimer) {
        [_refreshTimer invalidate];
        [_refreshTimer release];
        _refreshTimer = [refreshTimer retain];
    }
}

- (void)setAutoretrieveTimer:(NSTimer *)autoretrieveTimer {
    if (autoretrieveTimer != _autoretrieveTimer) {
        [_autoretrieveTimer invalidate];
        [_autoretrieveTimer release];
        _autoretrieveTimer = [autoretrieveTimer retain];
    }
}

- (NSString*)albumIdDefaultsKey {
    return [NSString stringWithFormat:@"Worklist Album ID %@", [_properties objectForKey:WorklistIDKey]];
}

- (NSString*)albumId {
    return [NSUserDefaults.standardUserDefaults objectForKey:self.albumIdDefaultsKey];
}

- (void)setAlbumId:(NSString*)value {
    [NSUserDefaults.standardUserDefaults setObject:value forKey:self.albumIdDefaultsKey];
}

- (DicomAlbum*)albumInDatabase:(DicomDatabase*)db create:(BOOL)create { // make sure it has an album, and return it
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

- (DicomAlbum*)albumInDatabase:(DicomDatabase*)db {
    return [self albumInDatabase:db create:YES];
}

- (void)setProperties:(NSDictionary*)properties {
    if (properties != _properties) {
        BOOL change = !_properties || ![properties isEqual:_properties];
        
        [_properties release];
        _properties = [properties copy];
        
        if (!properties || !change)
            return;
        
        DicomDatabase* db = [DicomDatabase defaultDatabase];
        
        [self albumInDatabase:db];
        
        NSTimeInterval ti = 300; // the default
        NSNumber* tin = [properties objectForKey:WorklistRefreshSecondsKey];
        if (tin) ti = [tin integerValue];
        
        if (ti != -1) {
            if (!self.refreshTimer || _refreshTimer.timeInterval != ti)
                self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:ti target:[WorklistNonretainingTimerInvoker invokerWithTarget:self selector:@selector(initiateRefresh)] selector:@selector(fire:) userInfo:nil repeats:YES];
            [_refreshTimer fire];
        } else {
            self.refreshTimer = nil;
            self.autoretrieveTimer = nil;
        }
    }
}

+ (void)deleteAlbumWithId:(NSString*)albumId {
    DicomDatabase* db = [DicomDatabase defaultDatabase];
    // delete the album
    DicomAlbum* album = [db objectWithID:albumId];
    
    if (!album)
        return;
    
    [db.managedObjectContext deleteObject:album];
    // refresh
    [WorklistsPlugin refreshAlbumsForDatabase:db];
}

- (void)delete {
    [WorklistsPlugin.instance deselectAlbumOfWorklist:self];
    // delete album
    [[self class] deleteAlbumWithId:[self albumId]];
    // delete data
    [NSUserDefaults.standardUserDefaults removeObjectForKey:self.albumIdDefaultsKey];
}

static void _findUserCallback(void* callbackData, T_DIMSE_C_FindRQ* request, int responseCount, T_DIMSE_C_FindRSP* rsp, DcmDataset* response) {
    NSMutableArray* entries = (id)callbackData;
    
    // NSLog(@"_findUserCallback %d", responseCount);
    // response->print(COUT);
    
    NSMutableDictionary* entry = [NSMutableDictionary dictionary];
    [entries addObject:entry];
    
    OFString string;
    DcmItem* item;
    
    NSStringEncoding encoding = NSISOLatin1StringEncoding;
    if (response->findAndGetOFString(DCM_SpecificCharacterSet, string).good())
        encoding = [NSString encodingForDICOMCharacterSet:[NSString stringWithUTF8String:string.c_str()]];
    
    if (response->findAndGetOFString(DCM_AccessionNumber, string).good())
        [entry setObject:[NSString stringWithCString:string.c_str() encoding:encoding] forKey:@"AccessionNumber"];
    if (response->findAndGetOFString(DCM_ReferringPhysiciansName, string).good())
        [entry setObject:[NSString stringWithCString:string.c_str() encoding:encoding] forKey:@"ReferringPhysiciansName"];
    if (response->findAndGetOFString(DCM_PatientsName, string).good())
        [entry setObject:[NSString stringWithCString:string.c_str() encoding:encoding] forKey:@"PatientsName"];
    if (response->findAndGetOFString(DCM_PatientID, string).good())
        [entry setObject:[NSString stringWithCString:string.c_str() encoding:encoding] forKey:@"PatientID"];
    if (response->findAndGetOFString(DCM_PatientsBirthDate, string).good())
        [entry setObject:[NSString stringWithCString:string.c_str() encoding:encoding] forKey:@"PatientsBirthDate"];
    if (response->findAndGetOFString(DCM_PatientsSex, string).good())
        [entry setObject:[NSString stringWithCString:string.c_str() encoding:encoding] forKey:@"PatientsSex"];
    if (response->findAndGetOFString(DCM_StudyInstanceUID, string).good())
        [entry setObject:[NSString stringWithCString:string.c_str() encoding:encoding] forKey:@"StudyInstanceUID"];
    if (response->findAndGetOFString(DCM_RequestedProcedureDescription, string).good())
        [entry setObject:[NSString stringWithCString:string.c_str() encoding:encoding] forKey:@"RequestedProcedureDescription"];
    
    if (response->findAndGetSequenceItem(DCM_ScheduledProcedureStepSequence, item).good()) {
        if (item->findAndGetOFString(DCM_Modality, string).good())
            [entry setObject:[NSString stringWithCString:string.c_str() encoding:encoding] forKey:@"Modality"];
        if (item->findAndGetOFString(DCM_ScheduledPerformingPhysiciansName, string).good())
            [entry setObject:[NSString stringWithCString:string.c_str() encoding:encoding] forKey:@"ScheduledPerformingPhysiciansName"];
        if (item->findAndGetOFString(DCM_ScheduledProcedureStepStartDate, string).good())
            [entry setObject:[NSString stringWithCString:string.c_str() encoding:encoding] forKey:@"ScheduledProcedureStepStartDate"];
        if (item->findAndGetOFString(DCM_ScheduledProcedureStepStartTime, string).good())
            [entry setObject:[NSString stringWithCString:string.c_str() encoding:encoding] forKey:@"ScheduledProcedureStepStartTime"];
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
    study.dateOfBirth = [NSDate dateWithYYYYMMDD:[entry objectForKey:@"PatientsBirthDate"] HHMMss:nil];
    study.patientSex = [entry objectForKey:@"PatientsSex"];
    
    study.studyInstanceUID = [entry objectForKey:@"StudyInstanceUID"];
    study.studyName = [entry objectForKey:@"RequestedProcedureDescription"];
    study.date = [NSDate dateWithYYYYMMDD:[entry objectForKey:@"ScheduledProcedureStepStartDate"] HHMMss:[entry objectForKey:@"ScheduledProcedureStepStartTime"]]; 
    study.modality = [entry objectForKey:@"Modality"];
    study.accessionNumber = [entry objectForKey:@"AccessionNumber"];
    study.referringPhysician = [entry objectForKey:@"ReferringPhysiciansName"];
    study.performingPhysician = [entry objectForKey:@"ScheduledPerformingPhysiciansName"];

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
    if (![_refreshLock tryLock])
        return;
    @try {
        @synchronized (self) {
            NSThread* thread = [NSThread isMainThread]? nil : [NSThread currentThread];
            thread.name = [NSString stringWithFormat:NSLocalizedString(@"Refreshing Worklist: %@", nil), [_properties objectForKey:WorklistNameKey]];
            thread.status = [NSString stringWithFormat:NSLocalizedString(@"Querying %@...", nil), [_properties objectForKey:WorklistCalledAETKey]];
            thread.supportsCancel = YES;
            if (thread) [ThreadsManager.defaultManager addThreadAndStart:thread];
            
            DicomDatabase* db = [[DicomDatabase defaultDatabase] independentDatabase];
            
            DicomAlbum* album = [self albumInDatabase:db];
            @synchronized ([WorklistsPlugin instance]) {
                NSArray* savedAlbumIDs = [NSUserDefaults.standardUserDefaults objectForKey:WorklistAlbumIDsDefaultsKey];
                NSString* albumId = [self albumId];
                if (![savedAlbumIDs containsObject:albumId]) {
                    NSMutableArray* mAlbumIDs = [savedAlbumIDs isKindOfClass:[NSArray class]]? [[savedAlbumIDs mutableCopy] autorelease] : [NSMutableArray array];
                    [mAlbumIDs addObject:albumId];
                    [NSUserDefaults.standardUserDefaults setObject:mAlbumIDs forKey:WorklistAlbumIDsDefaultsKey];
                }
            }
            
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
                sprintf(peerHost, "%s:%d", peerAddress.UTF8String, (int)peerPort);
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
                
                DcmDataset* dataset = dcmff.getDataset();
                dataset->insert(newDicomElement(DcmTag(DCM_AccessionNumber)));
                dataset->insert(newDicomElement(DcmTag(DCM_ReferringPhysiciansName)));
                dataset->insert(newDicomElement(DcmTag(DCM_PatientsName)));
                dataset->insert(newDicomElement(DcmTag(DCM_PatientID)));
                dataset->insert(newDicomElement(DcmTag(DCM_PatientsBirthDate)));
                dataset->insert(newDicomElement(DcmTag(DCM_PatientsSex)));
                dataset->insert(newDicomElement(DcmTag(DCM_StudyInstanceUID)));
                dataset->insert(newDicomElement(DcmTag(DCM_RequestedProcedureDescription)));
                
                DcmItem* spssi;
                dataset->findOrCreateSequenceItem(DCM_ScheduledProcedureStepSequence, spssi);
                spssi->insert(newDicomElement(DcmTag(DCM_Modality)));
                spssi->insert(newDicomElement(DcmTag(DCM_ScheduledPerformingPhysiciansName)));
                spssi->insert(newDicomElement(DcmTag(DCM_ScheduledProcedureStepStartDate)));
                spssi->insert(newDicomElement(DcmTag(DCM_ScheduledProcedureStepStartTime)));
                
                T_DIMSE_C_FindRSP rsp;
                cond = DIMSE_findUser(assoc, presId, &req, dcmff.getDataset(), _findUserCallback, entries, DIMSE_BLOCKING, 0, &rsp, &statusDetail);
                if (cond.bad())
                    [NSException raise:NSGenericException format:@"%s", cond.text()];

                // NSLog(@"Results: %@", entries);
                // NSLog(@"Worklist: %d studies in %@", (int)entries.count, [_properties objectForKey:WorklistNameKey]);
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
            
            if (thread.isCancelled)
                return;
            
            // filter results
            
            if ([[_properties objectForKey:WorklistFilterFlagKey] boolValue]) {
                NSPredicate* predicate = [[NSValueTransformer valueTransformerForName:@"WorklistRuleUnarchiveFromData"] transformedValue:[_properties objectForKey:WorklistFilterRuleKey]];
                [entries filterUsingPredicate:predicate];
            }
            
            thread.status = NSLocalizedString(@"Synchronizing...", nil);

            // for every entry, have a valid DicomStudy instance
            
            NSMutableArray* wstudies = [NSMutableArray array];
            
            NSPredicate* predicateTemplate = [NSPredicate predicateWithFormat:@"patientID = $PatientID AND accessionNumber = $AccessionNumber AND studyInstanceUID = $StudyInstanceUID"];
            
            for (NSDictionary* entry in entries) {
                NSArray* studies = [db objectsForEntity:db.studyEntity predicate:[predicateTemplate predicateWithSubstitutionVariables:entry]];
                
                if (!studies.count)
                    studies = [NSArray arrayWithObject:[self database:db createEmptyStudy:entry]];
                
                [wstudies addObjectsFromArray:studies];
            }

            [wstudies setValue:[NSDate date] forKey:@"dateAdded"];

            @synchronized (_lastRefreshStudyInstanceUIDs) {
                [_lastRefreshStudyInstanceUIDs removeAllObjects];
                [_lastRefreshStudyInstanceUIDs addObjectsFromArray:[wstudies valueForKey:@"studyInstanceUID"]];
            }
            
            // synchronize the album studies with the studies array
            
            NSMutableSet* astudies = [album mutableSetValueForKey:@"studies"];
            
            for (DicomStudy* study in wstudies) {
                [WorklistsPlugin.instance setLastSeenDate:[NSDate date] forStudy:study worklist:self];
                if (![astudies containsObject:study])
                    [astudies addObject:study];
            }
            
            for (DicomStudy* study in [[astudies copy] autorelease])
                if (![wstudies containsObject:study]) { // study is no longer in the worklist
                    BOOL remove = NO;
                    NSNumber* removen = [_properties objectForKey:WorklistNoLongerThenKey];
                    if (removen) remove = [removen boolValue];
                    
                    if (!remove) {
                        NSTimeInterval ti = 7200; // the default
                        NSNumber* tin = [_properties objectForKey:WorklistNoLongerThenIntervalKey];
                        if (tin) ti = [tin integerValue];
                        NSDate* studyLastSeenDate = [WorklistsPlugin.instance lastSeenDateForStudy:study worklist:self];
                        if (!studyLastSeenDate || -[studyLastSeenDate timeIntervalSinceNow] > ti)
                            remove = YES;
                    }
                    
                    if (remove) {
                        [astudies removeObject:study];
                        [WorklistsPlugin.instance setLastSeenDate:nil forStudy:study worklist:self];
                        // if the study is empty, delete it
                        NSSet* series = [study series];
                        if (!series.count || (series.count == 1 && [[series.anyObject id] intValue] == 5005 && [[series.anyObject name] isEqualToString:@"OsiriX No Autodeletion"])) {
                            for (DicomSeries* s in [series.copy autorelease])
                                [db.managedObjectContext deleteObject:s];
                            [db.managedObjectContext deleteObject:study];
                        }
                    }
                }
            
            [WorklistsPlugin.instance saveSLSDs];
            [db save]; // this is a secondary db, make sure the changes are applied to the main db before refreshing...
            [self performSelectorOnMainThread:@selector(_mainThreadGUIRefresh) withObject:nil waitUntilDone:NO];
            
            // auto-retrieve
            
            NSTimeInterval ti = 30; // the default
            NSNumber* tin = [_properties objectForKey:WorklistAutoRetrieveKey];
            if (tin) ti = [tin integerValue];
            
            if (ti > 0) {
                if (!self.autoretrieveTimer || _autoretrieveTimer.timeInterval != ti) {
                    self.autoretrieveTimer = [NSTimer timerWithTimeInterval:ti target:[WorklistNonretainingTimerInvoker invokerWithTarget:self selector:@selector(initiateAutoretrieve)] selector:@selector(fire:) userInfo:nil repeats:YES];
                    [NSRunLoop.mainRunLoop addTimer:_autoretrieveTimer forMode:NSDefaultRunLoopMode];
                }
            } else
                self.autoretrieveTimer = nil;
            if (ti != -1)
                [self autoretrieveWithDatabase:db];
        }
    } @catch (...) {
        @throw;
    } @finally {
        [_refreshLock unlock];
    }
}

- (void)_threadRefresh {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try {
        [self refresh];
        [[WorklistsPlugin instance] clearErrorOnWorklist:self];
    } @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
        [[WorklistsPlugin instance] setError:e onWorklist:self];
    } @finally {
        [pool release];
    }
}

- (void)initiateRefresh {
    [self performSelectorInBackground:@selector(_threadRefresh) withObject:nil];
}

- (void)_mainThreadGUIRefresh {
    DicomDatabase* db = [DicomDatabase defaultDatabase];
    
    [WorklistsPlugin refreshAlbumsForDatabase:db];
    
    [BrowserController.currentBrowser outlineViewRefresh];
    
    // if album is selected, refresh the study list
    DicomAlbum* album = [db objectWithID:self.albumId];
    if (album && [[[BrowserController currentBrowser] albumTable] isRowSelected:[db.albums indexOfObject:album]+1]) // album is selected
        [BrowserController.currentBrowser tableViewSelectionDidChange:[NSNotification notificationWithName:NSTableViewSelectionDidChangeNotification object:[BrowserController.currentBrowser albumTable]]];
}

- (NSArray*)lastRefreshStudyInstanceUIDs {
    @synchronized (_lastRefreshStudyInstanceUIDs) {
        return [_lastRefreshStudyInstanceUIDs.copy autorelease];
    }
}

@end


@implementation WorklistRuleUnarchiveFromData

+ (Class)transformedValueClass {
    return [NSPredicate class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (NSPredicate*)transformedValue:(id)input {
    if ([input isKindOfClass:[NSPredicate class]])
        return input;
    
    NSPredicate* predicate = nil;
    
    if ([input isKindOfClass:[NSData class]])
        predicate = [NSKeyedUnarchiver unarchiveObjectWithData:input];
    if ([input isKindOfClass:[NSString class]]) {
        @try {
            predicate = [NSPredicate predicateWithFormat:input];
            if ([predicate isKindOfClass:[NSPredicate class]] && ![predicate isKindOfClass:[NSCompoundPredicate class]])
                predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObject:predicate]];
        } @catch (...) {
        }
    }
    
    if ([predicate isKindOfClass:[NSPredicate class]])
        return predicate;
    
    return nil;
}

- (NSData*)reverseTransformedValue:(NSPredicate*)predicate {
    return [NSKeyedArchiver archivedDataWithRootObject:predicate];
}

@end


















