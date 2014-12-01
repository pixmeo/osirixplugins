//
//  Worklist+POD.m
//  Worklists
//
//  Created by Alessandro Volz on 19.09.12.
//
//

#import "Worklist+POD.h"
#import <OsiriXAPI/DicomDatabase.h>
#import <OsiriXAPI/DicomAlbum.h>
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/DicomImage.h>
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/N2Debug.h>
#import <OsiriXAPI/N2Stuff.h>
#import <OsiriXAPI/BrowserController.h>
#import <OsiriXAPI/NSThread+N2.h>
#import <OsiriXAPI/ThreadsManager.h>
#import <OsiriXAPI/DCMTKStudyQueryNode.h>
#import <OsiriXAPI/DCMTKRootQueryNode.h>
#import <OsiriXAPI/DCMTKImageQueryNode.h>
#import <OsiriXAPI/dcfilefo.h>
#import <OsiriXAPI/dcelem.h>
#import <OsiriXAPI/dctag.h>
#import <OsiriXAPI/dcdeftag.h>
#import <OsiriX/DCMNetServiceDelegate.h>
#import <OsiriXAPI/DICOMToNSString.h>
#import <dispatch/dispatch.h>

@interface WorklistImagesQueryNode : DCMTKStudyQueryNode {
    const DcmDataset* _moveDataset;
}

+ (id)queryNodeWithDataset:(const DcmDataset*)dataset
               moveDataset:(const DcmDataset*)moveDataset
                callingAET:(NSString*)myAET
                 calledAET:(NSString*)theirAET
                  hostname:(NSString*)hostname
                      port:(int)port
            transferSyntax:(int)transferSyntax
               compression:(float)compression
           extraParameters:(NSDictionary *)extraParameters;

@end


@implementation Worklist (POD)

- (void)_delayedMainThreadGUIRefresh {
    if (![NSThread isMainThread])
        [self performSelectorOnMainThread:@selector(_delayedMainThreadGUIRefresh) withObject:nil waitUntilDone:NO];
    else {
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_mainThreadGUIRefresh) object:nil];
        [self performSelector:@selector(_mainThreadGUIRefresh) withObject:nil afterDelay:0.01];
    }
}

- (void)autoretrieveWithDatabase:(DicomDatabase*)db {
    // don't autoretrieve if a refresh is running...
    if (![_refreshLock tryLock])
        return;
    [_refreshLock unlock];
    // ok...
    if (![_autoretrieveLock tryLock])
        return;
    @try {
        
        static NSString *singleRetrieveAtATime= @"singleRetrieveAtATime";
        
        @synchronized (singleRetrieveAtATime) { // @synchronized (self) wasnt working...
            NSThread* arthread = [NSThread isMainThread]? nil : [NSThread currentThread];
            arthread.name = [NSString stringWithFormat:NSLocalizedString(@"Refreshing %@", nil), [_properties objectForKey:WorklistNameKey]];
            arthread.status = [NSString stringWithFormat:NSLocalizedString(@"Synchronizing with POD nodes...", nil)];
            arthread.supportsCancel = YES;
            if (arthread) [ThreadsManager.defaultManager addThreadAndStart:arthread];
            
            if (![NSUserDefaults.standardUserDefaults boolForKey:@"searchForComparativeStudiesOnDICOMNodes"])
                return;
            
            // get POD servers list
            
            NSMutableArray* dicomNodes = [NSMutableArray array];
            NSArray* allDicomNodes = [DCMNetServiceDelegate DICOMServersListSendOnly:NO QROnly:NO];
            for (NSDictionary* si in [NSUserDefaults.standardUserDefaults arrayForKey:@"comparativeSearchDICOMNodes"])
                for (NSDictionary* di in allDicomNodes)
                    if ([[si objectForKey:@"AETitle"] isEqualToString:[di objectForKey:@"AETitle"]] &&
                        [[si objectForKey:@"name"] isEqualToString:[di objectForKey:@"Description"]] &&
                        [[si objectForKey:@"AddressAndPort"] isEqualToString:[NSString stringWithFormat:@"%@:%@", [di valueForKey:@"Address"], [di valueForKey:@"Port"]]])
                    {
                        [dicomNodes addObject:di];
                    }

            // studies in album
            
            DicomAlbum* album = [self albumInDatabase:db];
            NSMutableArray* astudies = [[album.studies.allObjects mutableCopy] autorelease];
            NSString* mySyncObject = [NSString string];
            
            if (!astudies.count)
                return;
            
            // do the querying...
            
            //static dispatch_semaphore_t globalQuerySemaphore = dispatch_semaphore_create(4); // we allow N concurrent queries...
            
            int progress = 0, *progressp = &progress;
            int subthreads = 0, *subthreadsp = &subthreads;
            
            int iStudy = -1;
            while (true) { // for (int i = 0; i < astudies.count; ++i)
                ++iStudy;
                
                BOOL wait = YES;
                while (wait) { // do this while subthreads are running: it is possible that some of them will generate additional studies to load
                    @synchronized(mySyncObject) {
                        wait = (iStudy == astudies.count && subthreads);
                    }
                    if (wait) [NSThread sleepForTimeInterval:0.01];
                }
                
                @synchronized(mySyncObject) {
                    if (iStudy >= astudies.count)
                        break;
                }
                
                if (arthread.isCancelled)
                    break;

                while (*subthreadsp >= 4)
                    [NSThread sleepForTimeInterval:0.01];
                @synchronized(mySyncObject) {
                    ++(*subthreadsp);
                }

//                [NSThread performBlockInBackground:^
                {
                    @try {
                        // NSLog(@"Querying %@ ...", studyInstanceUID);
                        DicomStudy* istudy;
                        NSString* accessionNumber;
                        NSString* studyInstanceUID;
                        NSString* studyPatientName;
                        @synchronized(mySyncObject) {
                            istudy = [astudies objectAtIndex:iStudy];
                            studyInstanceUID = istudy.studyInstanceUID;
                            accessionNumber = istudy.accessionNumber;
                            studyPatientName = istudy.name;
                        }
                        
                        NSThread* athread = [NSThread currentThread];
                        athread.name = [NSString stringWithFormat:NSLocalizedString(@"Autoretrieving %@", nil), studyPatientName];
                        [ThreadsManager.defaultManager addThreadAndStart:athread];

                        for (NSDictionary* dn in dicomNodes) {
                            BOOL useAccessionNumberMode = [[self.properties objectForKey:@"ifNothingThenSearchAccessionNumbers"] boolValue];
                            for (int mode = 0; mode < (useAccessionNumberMode? 2 : 1); ++mode) { // 0 -> StudyInstanceUID, 1 -> AccessionNumber
                                
                                // remote studies
                                
                                athread.status = [NSString stringWithFormat:NSLocalizedString(@"Querying %@...", nil), [dn objectForKey:@"Description"]];
                                
                                DCMTKRootQueryNode* slQueryNode = [DCMTKRootQueryNode queryNodeWithDataset:nil
                                                                                                callingAET:[NSUserDefaults.standardUserDefaults stringForKey:@"AETITLE"]
                                                                                                 calledAET:[dn objectForKey:@"AETitle"]
                                                                                                  hostname:[dn objectForKey:@"Address"]
                                                                                                      port:[[dn objectForKey:@"Port"] intValue]
                                                                                            transferSyntax:0 //[[dn objectForKey:@"TransferSyntax"] intValue]
                                                                                               compression:0
                                                                                           extraParameters:dn];
                                
                                NSMutableArray *filterArray = [NSMutableArray array];
                                
                                switch (mode) {
                                    case 0:
                                        [filterArray addObject: [NSDictionary dictionaryWithObjectsAndKeys: studyInstanceUID, @"value", @"StudyInstanceUID", @"name", nil]];
                                        break;
                                    case 1:
                                        [filterArray addObject: [NSDictionary dictionaryWithObjectsAndKeys: accessionNumber, @"value", @"AccessionNumber", @"name", nil]];
                                        break;
                                }
                                
                                [slQueryNode queryWithValues: filterArray dataset: nil syntaxAbstract: [NSString stringWithFormat: @"%s", UID_FINDStudyRootQueryRetrieveInformationModel]];
                                
                                [slQueryNode setShowErrorMessage:NO];
                                
                                if (!slQueryNode.children.count && mode == 0)
                                    continue; // no such study on PACS, switch to AccessionNumber mode or give up...
                                
                                // now we know local and remote studies number...
                                
                                BOOL stopMode = NO;
                                
                                for (DCMTKStudyQueryNode* remoteStudyNode in slQueryNode.children) {
                                    if (mode == 1) {
                                        @synchronized (mySyncObject) {
                                            DicomStudy* nstudy;
                                            NSString* studyInstanceUID;
                                            NSString* studyName;

                                            BOOL refresh = NO;

                                            NSArray* studies = [db objectsForEntity:db.studyEntity predicate:[NSPredicate predicateWithFormat:@"patientID = %@ AND accessionNumber = %@ AND studyInstanceUID = %@", remoteStudyNode.patientID, remoteStudyNode.accessionNumber, remoteStudyNode.studyInstanceUID]];
                                            if (!studies.count) {
                                                NSMutableDictionary* entry = [NSMutableDictionary dictionary];
                                                if (istudy.name) [entry setObject:istudy.name forKey:@"PatientsName"];
                                                if (istudy.patientID) [entry setObject:istudy.patientID forKey:@"PatientID"];
                                                if (istudy.dateOfBirth) [entry setObject:istudy.dateOfBirth forKey:@"PatientsBirthDate"];
                                                if (istudy.patientSex) [entry setObject:istudy.patientSex forKey:@"PatientsSex"];
                                                if (remoteStudyNode.studyInstanceUID) [entry setObject:remoteStudyNode.studyInstanceUID forKey:@"StudyInstanceUID"];
                                                if (remoteStudyNode.studyName) [entry setObject:remoteStudyNode.studyName forKey:@"RequestedProcedureDescription"];
                                                if (remoteStudyNode.date) [entry setObject:remoteStudyNode.date forKey:@"Date"];
                                                if (remoteStudyNode.modality) [entry setObject:remoteStudyNode.modality forKey:@"Modality"];
                                                if (remoteStudyNode.accessionNumber) [entry setObject:remoteStudyNode.accessionNumber forKey:@"AccessionNumber"];
                                                studies = [NSArray arrayWithObject:[self database:db createEmptyStudy:entry]];
                                                refresh = YES;
                                            }
                                            
                                            nstudy = [studies objectAtIndex:0];
                                            studyInstanceUID = nstudy.studyInstanceUID;
                                            studyName = nstudy.studyName;
                                            
                                            if (![_lastRefreshStudyInstanceUIDs containsObject:studyInstanceUID])
                                                [_lastRefreshStudyInstanceUIDs addObject:studyInstanceUID];

                                            for (id obj in studies)
                                                if (![astudies containsObject:obj]) {
                                                    [astudies addObject:obj];
                                                    [[album mutableSetValueForKey:@"studies"] addObject:obj];
                                                    refresh = YES;
                                                }
                                            if (refresh)
                                                [db save];
                                            [self _delayedMainThreadGUIRefresh];
                                        }
                                    } else {
                                        NSString* studyInstanceUID;
                                        NSString* studyName;

                                        @synchronized (mySyncObject) {
                                            studyInstanceUID = istudy.studyInstanceUID;
                                            studyName = istudy.studyName;
                                        }
                                        
                                        // local image count?
                                        
                                        NSMutableArray* localSOPInstanceUIDs = [NSMutableArray array];
                                        @synchronized(mySyncObject) {
                                            for (DicomImage* image in istudy.images.allObjects)
                                                [localSOPInstanceUIDs addObject:image.sopInstanceUID];
                                        }
                                        
                                        NSMutableArray* studyCurrentAutoretrieves = nil;
                                        @synchronized (_currentAutoretrieves) {
                                            studyCurrentAutoretrieves = [_currentAutoretrieves objectForKey:studyInstanceUID];
                                            if (!studyCurrentAutoretrieves) [_currentAutoretrieves setObject:(studyCurrentAutoretrieves = [NSMutableArray array]) forKey:studyInstanceUID];
                                            // current transfers are considered as already available to avoid transferring them twice
                                            for (NSArray* iInstanceUIDs in studyCurrentAutoretrieves)
                                                for (NSString* iInstanceUID in iInstanceUIDs)
                                                    [localSOPInstanceUIDs addObject:iInstanceUID];
                                        }
                                        
                                        NSArray* distinctLocalSOPInstanceUIDs = [localSOPInstanceUIDs valueForKeyPath:@"@distinctUnionOfObjects.self"];

                                        // now we know local and remote number of images for this study
                                        
                                        if (remoteStudyNode.numberOfImages.intValue <= distinctLocalSOPInstanceUIDs.count)
                                            continue; // nothing to retrieve, we have all... probably
                                        
                                        int imageLevel = [[NSUserDefaults standardUserDefaults] boolForKey:@"TryIMAGELevelDICOMRetrieveIfLocalImages"];
                                        if (!localSOPInstanceUIDs.count) // if locally there are no images, just get the whole study
                                            imageLevel = NO;

                                        for (; imageLevel >= 0; --imageLevel) {
                                            NSMutableArray* instanceUIDs = [NSMutableArray array]; // [iqns valueForKey:@"uid"];
                                            DCMTKQueryNode* queryNode = nil;

//                                            if (imageLevel) {
//                                                if (remoteStudyNode.numberOfImages.intValue - distinctLocalSOPInstanceUIDs.count > distinctLocalSOPInstanceUIDs.count)
//                                                    continue; // retrieve the whole study, it'll take less time than querying etc etc... we have less than half the images on the server anyway
//                                                
//                                                athread.status = [NSString stringWithFormat:NSLocalizedString(@"Querying %@...", nil), N2SingularPluralCount(remoteStudyNode.numberOfImages.intValue, NSLocalizedString(@"image", nil), NSLocalizedString(@"images", nil))];
//                                                
//                                                DcmDataset ilDataset;
//                                                ilDataset.putAndInsertString(DCM_QueryRetrieveLevel, "IMAGE");
//                                                ilDataset.insertEmptyElement(DCM_SOPInstanceUID);
//                                                //dataset.putAndInsertString(DCM_SpecificCharacterSet, stringEncoding.UTF8String);
//                                                // dataset.putAndInsertString(DCM_PatientID, [study.patientID cStringUsingEncoding:encoding]);
//                                                // dataset.putAndInsertString(DCM_AccessionNumber, [study.accessionNumber cStringUsingEncoding:encoding]);
//                                                switch (mode) {
//                                                    case 0:
//                                                        ilDataset.putAndInsertString(DCM_StudyInstanceUID, studyInstanceUID.UTF8String);
//                                                        break;
//                                                    case 1:
//                                                        ilDataset.putAndInsertString(DCM_StudyInstanceUID, remoteStudyNode.studyInstanceUID.UTF8String);
//                                                        ilDataset.putAndInsertString(DCM_AccessionNumber, accessionNumber.UTF8String);
//                                                        break;
//                                                }
//
//                                                DCMTKStudyQueryNode* ilQueryNode = [DCMTKStudyQueryNode queryNodeWithDataset:&ilDataset
//                                                                                                                  callingAET:[NSUserDefaults.standardUserDefaults stringForKey:@"AETITLE"]
//                                                                                                                   calledAET:[dn objectForKey:@"AETitle"]
//                                                                                                                    hostname:[dn objectForKey:@"Address"]
//                                                                                                                        port:[[dn objectForKey:@"Port"] intValue]
//                                                                                                              transferSyntax:[[dn objectForKey:@"TransferSyntax"] intValue]
//                                                                                                                 compression:0
//                                                                                                             extraParameters:dn];
//                                                [ilQueryNode setShowErrorMessage:NO];
//                                                
//                                                [ilQueryNode setupNetworkWithSyntax:UID_FINDStudyRootQueryRetrieveInformationModel dataset:&ilDataset destination:nil];
//                                                
//                                                if (arthread.isCancelled || athread.isCancelled)
//                                                    return;
//                                                
//                                                if (!ilQueryNode.children.count)
//                                                    continue; // goto study level or stop
//                                                
//                                                NSMutableArray* iqns = [NSMutableArray array];
//                                                
//                                                for (DCMTKImageQueryNode* imageQueryNode in ilQueryNode.children)
//                                                    if (imageQueryNode.uid && ![localSOPInstanceUIDs containsObject:imageQueryNode.uid]) {
//                                                        [localSOPInstanceUIDs addObject:imageQueryNode.uid];
//                                                        [iqns addObject:imageQueryNode];
//                                                    }
//                                                
//                                                if (!iqns.count) {
//                                                    stopMode = YES;
//                                                    break; // nothing to retrieve
//                                                }
//
//                                                for (DCMTKImageQueryNode* iqn in iqns)
//                                                    [instanceUIDs addObject:iqn.uid];
//                                                
//                                                athread.status = [NSString stringWithFormat:NSLocalizedString(@"Retrieving %@ for %@...", nil), N2SingularPluralCount(iqns.count, NSLocalizedString(@"image", nil), NSLocalizedString(@"images", nil)), studyName];
//                                                
//                                                DcmDataset mdataset;
//                                                mdataset.putAndInsertString(DCM_QueryRetrieveLevel, "IMAGE");
//                                                mdataset.putAndInsertOFStringArray(DCM_SOPInstanceUID, [[instanceUIDs componentsJoinedByString:@"\\"] UTF8String]);
//                                                mdataset.putAndInsertOFStringArray(DCM_StudyInstanceUID, [[[iqns valueForKey:@"studyInstanceUID"] componentsJoinedByString:@"\\"] UTF8String]);
//                                                
//                                                queryNode = [WorklistImagesQueryNode queryNodeWithDataset:&ilDataset
//                                                                                              moveDataset:(DcmDataset*)mdataset.clone()
//                                                                                               callingAET:[NSUserDefaults.standardUserDefaults stringForKey:@"AETITLE"]
//                                                                                                calledAET:[dn objectForKey:@"AETitle"]
//                                                                                                 hostname:[dn objectForKey:@"Address"]
//                                                                                                     port:[[dn objectForKey:@"Port"] intValue]
//                                                                                           transferSyntax:[[dn objectForKey:@"TransferSyntax"] intValue]
//                                                                                              compression:0
//                                                                                          extraParameters:dn];
//                                                
//                                                [queryNode setChildren:iqns];
//                                            }
//                                            else
                                            {
                                                athread.status = [NSString stringWithFormat:NSLocalizedString(@"Retrieving %@...", nil), studyName];

                                                DcmDataset mdataset;
                                                mdataset.putAndInsertString(DCM_QueryRetrieveLevel, "STUDY");
                                                switch (mode) {
                                                    case 0:
                                                        mdataset.putAndInsertString(DCM_StudyInstanceUID, studyInstanceUID.UTF8String);
                                                        break;
                                                    case 1:
                                                        mdataset.putAndInsertString(DCM_AccessionNumber, accessionNumber.UTF8String);
                                                        break;
                                                }
                                                
                                                switch (mode) {
                                                    case 0:
                                                        queryNode = [DCMTKStudyQueryNode queryNodeWithDataset:(DcmDataset*)mdataset.clone()
                                                                                               callingAET:[NSUserDefaults.standardUserDefaults stringForKey:@"AETITLE"]
                                                                                                calledAET:[dn objectForKey:@"AETitle"]
                                                                                                 hostname:[dn objectForKey:@"Address"]
                                                                                                     port:[[dn objectForKey:@"Port"] intValue]
                                                                                           transferSyntax:[[dn objectForKey:@"TransferSyntax"] intValue]
                                                                                              compression:0
                                                                                          extraParameters:dn];
                                                        break;
                                                    case 1:
                                                    queryNode = [WorklistImagesQueryNode queryNodeWithDataset:&mdataset
                                                                                                  moveDataset:(DcmDataset*)mdataset.clone()
                                                                                                   callingAET:[NSUserDefaults.standardUserDefaults stringForKey:@"AETITLE"]
                                                                                                    calledAET:[dn objectForKey:@"AETitle"]
                                                                                                     hostname:[dn objectForKey:@"Address"]
                                                                                                         port:[[dn objectForKey:@"Port"] intValue]
                                                                                               transferSyntax:[[dn objectForKey:@"TransferSyntax"] intValue]
                                                                                                  compression:0
                                                                                              extraParameters:dn];
                                                        break;
                                                }
                                            }
                                            
                                            NSMutableDictionary* params = [[dn mutableCopy] autorelease];
                                            [params setObject:[NSUserDefaults.standardUserDefaults stringForKey:@"AETITLE"] forKey:@"moveDestination"];

                                            [queryNode setShowErrorMessage:NO];
                                            [queryNode setDontCatchExceptions:YES];
                                            [queryNode setIsAutoRetrieve:YES];
                                            queryNode.noSmartMode = YES;

                                            @synchronized (_currentAutoretrieves) {
                                                [studyCurrentAutoretrieves addObject:instanceUIDs];
                                            }

                                            @try {
                                                [queryNode move:params retrieveMode:[[dn objectForKey:@"retrieveMode"] intValue]];
                                            } @catch (NSException* e) {
                                                if (imageLevel)
                                                    continue;
                                                else @throw e;
                                            } @finally {
                                                @synchronized (_currentAutoretrieves) {
                                                    [studyCurrentAutoretrieves removeObjectIdenticalTo:instanceUIDs];
                                                }
                                            }
                                            
                                            // the move is done... did we actually fetch any new image?
                                            
                                            if ([queryNode respondsToSelector:@selector(countOfSuccessfulSuboperations)] && !queryNode.countOfSuccessfulSuboperations)
                                                if (mode == 0 && imageLevel)
                                                    continue;
                                            
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                        
                        @synchronized (mySyncObject) {
                            ++(*progressp);
                            arthread.progress = 1.0/astudies.count*(*progressp);
                        }
                    } @catch (NSException* e) {
                        // potentially, these are faults for destroyed studies... we should ignore them :P
                        @throw e;
                    } @finally {
                        @synchronized (mySyncObject) {
                            --(*subthreadsp);
                        }
                    }
                }
//                ];
            }
            
            while (subthreads)
                [NSThread sleepForTimeInterval:0.01];
        }
    } @catch (...) {
        @throw;
    } @finally {
        [_autoretrieveLock unlock];
    }
}

- (void)autoretrieve {
    [self autoretrieveWithDatabase:[[DicomDatabase defaultDatabase] independentDatabase]];
}

- (void)_threadAutoretrieve {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try {
        [self autoretrieve];
    } @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    } @finally {
        [pool release];
    }
}

-(void)initiateAutoretrieve {
    [self performSelectorInBackground:@selector(_threadAutoretrieve) withObject:nil];
}

@end


@implementation WorklistImagesQueryNode

- (id)initWithDataset:(const DcmDataset*)dataset
          moveDataset:(const DcmDataset*)moveDataset
           callingAET:(NSString*)myAET
            calledAET:(NSString*)theirAET
             hostname:(NSString*)hostname
                 port:(int)port
       transferSyntax:(int)transferSyntax
          compression:(float)compression
      extraParameters:(NSDictionary *)extraParameters
{
    if ((self = [super initWithDataset:(DcmDataset*)dataset callingAET:myAET calledAET:theirAET hostname:hostname port:port transferSyntax:transferSyntax compression:compression extraParameters:extraParameters])) {
        _moveDataset = moveDataset;
    }
    
    return self;
}

+ (id)queryNodeWithDataset:(const DcmDataset*)dataset
               moveDataset:(const DcmDataset*)moveDataset
                callingAET:(NSString*)myAET
                 calledAET:(NSString*)theirAET
                  hostname:(NSString*)hostname
                      port:(int)port
            transferSyntax:(int)transferSyntax
               compression:(float)compression
           extraParameters:(NSDictionary *)extraParameters
{
    return [[[[self class] alloc] initWithDataset:dataset
                                      moveDataset:moveDataset
                                       callingAET:myAET
                                        calledAET:theirAET
                                         hostname:hostname
                                             port:port
                                   transferSyntax:transferSyntax
                                      compression:compression
                                  extraParameters:extraParameters] autorelease];
}

-(void)dealloc {
    delete _moveDataset;
    [super dealloc];
}

- (DcmDataset*)moveDataset {
	return (DcmDataset*)_moveDataset->clone();
}

@end



