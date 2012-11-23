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

- (void)autoretrieveWithDatabase:(DicomDatabase*)db {
    // don't autoretrieve if a refresh is running...
    if (![_refreshLock tryLock])
        return;
    [_refreshLock unlock];
    // ok...
    if (![_autoretrieveLock tryLock])
        return;
    @try {
        @synchronized (self) {
            NSThread* arthread = [NSThread isMainThread]? nil : [NSThread currentThread];
            arthread.name = [NSString stringWithFormat:NSLocalizedString(@"Refreshing %@", nil), [_properties objectForKey:WorklistNameKey]];
            arthread.status = [NSString stringWithFormat:NSLocalizedString(@"Synchronizing with POD nodes...", nil)];
            arthread.supportsCancel = YES;
            if (arthread) [ThreadsManager.defaultManager addThreadAndStart:arthread];
            
            if (![NSUserDefaults.standardUserDefaults boolForKey:@"searchForComparativeStudiesOnDICOMNodes"])
                return;
            
            // get POD servers list
            
            NSMutableArray* dicomNodes = [NSMutableArray array];
            NSArray* allDicomNodes = [DCMNetServiceDelegate DICOMServersList];
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
            NSArray* astudies = album.studies.allObjects;
            NSString* mySyncObject = [NSString string];
            
            if (!astudies.count)
                return;
            
            // do the querying...
            
            //static dispatch_semaphore_t globalQuerySemaphore = dispatch_semaphore_create(4); // we allow N concurrent queries...
            
            int progress = 0, *progressp = &progress;
            int subthreads = 0, *subthreadsp = &subthreads;
            
            for (int i = 0; i < astudies.count; ++i) {
                if (arthread.isCancelled)
                    break;

                while (*subthreadsp >= 4)
                    [NSThread sleepForTimeInterval:0.01];
                @synchronized(mySyncObject) {
                    ++(*subthreadsp);
                }

                [NSThread performBlockInBackground:^{
                    @try {
                        NSMutableArray* availableInstanceUIDs = [NSMutableArray array];
                        NSString* studyInstanceUID;
                        NSString* accessionNumber;
                        NSString* studyPatientName;
                        NSString* studyName;
                        
                        DicomStudy* study;
                        @synchronized(mySyncObject) {
                            study = [astudies objectAtIndex:i];
                            
                            for (DicomImage* image in study.images.allObjects)
                                [availableInstanceUIDs addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                  image.series.seriesInstanceUID, @"seriesInstanceUID",
                                                                  image.sopInstanceUID, @"sopInstanceUID",
                                                                  nil]];
                                
                            studyInstanceUID = study.studyInstanceUID;
                            accessionNumber = study.accessionNumber;
                            studyPatientName = study.name;
                            studyName = study.studyName;
                        }
                        
                        NSMutableArray* studyCurrentAutoretrieves = nil;
                        @synchronized (_currentAutoretrieves) {
                            studyCurrentAutoretrieves = [_currentAutoretrieves objectForKey:studyInstanceUID];
                            if (!studyCurrentAutoretrieves) [_currentAutoretrieves setObject:(studyCurrentAutoretrieves = [NSMutableArray array]) forKey:studyInstanceUID];
                            // current transfers are considered as already available to avoid transferring them twice
                            for (NSArray* iInstanceUIDs in studyCurrentAutoretrieves)
                                [availableInstanceUIDs addObjectsFromArray:iInstanceUIDs];
                        }
                        
                        NSThread* athread = [NSThread currentThread];
                        athread.name = [NSString stringWithFormat:NSLocalizedString(@"Autoretrieving %@", nil), studyPatientName];
                        [ThreadsManager.defaultManager addThreadAndStart:athread];
                        
                        // NSLog(@"Querying %@ ...", studyInstanceUID);
                        
                        BOOL matched = NO;
                        
                        for (NSDictionary* dn in dicomNodes) {
                            BOOL imageLevel = [[NSUserDefaults standardUserDefaults] boolForKey:@"TryIMAGELevelDICOMRetrieveIfLocalImages"];
                            if (!availableInstanceUIDs.count) // if locally there are no images, just get the whole study
                                imageLevel = NO;
                            
                            NSArray* distinctAvailableInstanceUIDs = [availableInstanceUIDs valueForKeyPath:@"@distinctUnionOfObjects.sopInstanceUID"];
                            
                            BOOL useAccessionNumberMode = [[self.properties objectForKey:@"ifNothingThenSearchAccessionNumbers"] boolValue];
                            
                            for (int mode = 0; mode < useAccessionNumberMode? 2 : 1; ++mode) { // 0 -> StudyInstanceUID, 1 -> AccessionNumber
                                DCMTKQueryNode* queryNode = nil;
                                
                                NSMutableArray* instanceUIDs = [NSMutableArray array]; // [iqns valueForKey:@"uid"];
                                
                                //...
                                
                                athread.status = [NSString stringWithFormat:NSLocalizedString(@"Querying %@...", nil), [dn objectForKey:@"Description"]];
                                
                                DcmDataset slDataset;
                                slDataset.putAndInsertString(DCM_QueryRetrieveLevel, "STUDY");
                                slDataset.insert(newDicomElement(DcmTag(DCM_NumberOfStudyRelatedInstances)));
                                switch (mode) {
                                    case 0:
                                        slDataset.putAndInsertString(DCM_StudyInstanceUID, studyInstanceUID.UTF8String);
                                        break;
                                    case 1:
                                        slDataset.insert(newDicomElement(DcmTag(DCM_StudyInstanceUID)));
                                        slDataset.putAndInsertString(DCM_AccessionNumber, accessionNumber.UTF8String);
                                        break;
                                }
                                
                                DCMTKRootQueryNode* slQueryNode = [DCMTKRootQueryNode queryNodeWithDataset:&slDataset
                                                                                                callingAET:[NSUserDefaults.standardUserDefaults stringForKey:@"AETITLE"]
                                                                                                 calledAET:[dn objectForKey:@"AETitle"]
                                                                                                  hostname:[dn objectForKey:@"Address"]
                                                                                                      port:[[dn objectForKey:@"Port"] intValue]
                                                                                            transferSyntax:[[dn objectForKey:@"TransferSyntax"] intValue]
                                                                                               compression:0
                                                                                           extraParameters:dn];
                                [slQueryNode setShowErrorMessage:NO];
                                
                                [slQueryNode setupNetworkWithSyntax:UID_FINDStudyRootQueryRetrieveInformationModel dataset:&slDataset destination:nil];
                                
                                DCMTKStudyQueryNode* studyInfoNode = nil;
                                if (mode == 0) {
                                    if (slQueryNode.children.count)
                                        studyInfoNode = [slQueryNode.children objectAtIndex:0];
                                } else {
                                    // hmm, how many exams with this AccessionNumber?
                                    if (slQueryNode.children.count == 1)
                                        studyInfoNode = [slQueryNode.children objectAtIndex:0];
                                    else if (slQueryNode.children.count) { // more than 1 ! grrrrrrr
                                        // try matching by name...
                                        for (DCMTKStudyQueryNode* sqn in slQueryNode.children)
                                            if ([sqn.studyName isEqualToString:studyName]) {
                                                studyInfoNode = sqn;
                                                break;
                                            }
                                    }
                                }
                                if (!studyInfoNode) {
                                    break; // just lie there with zero images..... maybe for another POD server!
                                }
                                
                                matched = YES;
                                
                                if (studyInfoNode && ![studyInfoNode.studyInstanceUID isEqualToString:studyInstanceUID]) { // wrong StudyInstanceUID............
                                    studyInstanceUID = studyInfoNode.studyInstanceUID;
                                    @synchronized(mySyncObject) {
                                        // do we already have a correct DicomStudy?
                                        NSArray* dss = studyInstanceUID? [db objectsForEntity:db.studyEntity predicate:[NSPredicate predicateWithFormat:@"studyInstanceUID = %@", studyInstanceUID]] : nil;
                                        if (studyInstanceUID && dss.count) { // yes! kill this one
                                            [db.managedObjectContext deleteObject:study];
                                            [db save];
                                            [BrowserController.currentBrowser performSelectorOnMainThread:@selector(outlineViewRefresh) withObject:nil waitUntilDone:NO];
                                            break;
                                        } else { // no we don't
                                            study.studyInstanceUID = studyInstanceUID;
                                            [db save];
                                        }
                                    }
                                }
                                
                                if (studyInfoNode.numberOfImages.intValue == 0)
                                    continue; // will either switch from mode 0 to 1, or stop
                                
                                if (studyInfoNode.numberOfImages.intValue <= distinctAvailableInstanceUIDs.count)
                                    break; // nothing to retrieve, we have all...
                                
                                BOOL stop = NO;
                                while (true) {
                                    if (imageLevel) {
                                        if (studyInfoNode.numberOfImages.intValue - distinctAvailableInstanceUIDs.count > distinctAvailableInstanceUIDs.count) {
                                            imageLevel = NO;
                                            continue; // retrieve the whole study, it'll take less time than querying etc etc... we have less than half the images on the server anyway
                                        }
                                        
                                        athread.status = [NSString stringWithFormat:NSLocalizedString(@"Querying %@...", nil), N2SingularPluralCount(studyInfoNode.numberOfImages.intValue, NSLocalizedString(@"image", nil), NSLocalizedString(@"images", nil))];
                                        
                                        DcmDataset ilDataset;
                                        ilDataset.putAndInsertString(DCM_QueryRetrieveLevel, "IMAGE");
                                        ilDataset.insert(newDicomElement(DcmTag(DCM_SOPInstanceUID)));
                                        //dataset.putAndInsertString(DCM_SpecificCharacterSet, stringEncoding.UTF8String);
                                        // dataset.putAndInsertString(DCM_PatientID, [study.patientID cStringUsingEncoding:encoding]);
                                        // dataset.putAndInsertString(DCM_AccessionNumber, [study.accessionNumber cStringUsingEncoding:encoding]);
                                        switch (mode) {
                                            case 0:
                                                ilDataset.putAndInsertString(DCM_StudyInstanceUID, studyInstanceUID.UTF8String);
                                                break;
                                            case 1:
                                                ilDataset.putAndInsertString(DCM_StudyInstanceUID, studyInfoNode.studyInstanceUID.UTF8String);
                                                ilDataset.putAndInsertString(DCM_AccessionNumber, accessionNumber.UTF8String);
                                                break;
                                        }

                                        DCMTKStudyQueryNode* ilQueryNode = [DCMTKStudyQueryNode queryNodeWithDataset:&ilDataset
                                                                                                          callingAET:[NSUserDefaults.standardUserDefaults stringForKey:@"AETITLE"]
                                                                                                           calledAET:[dn objectForKey:@"AETitle"]
                                                                                                            hostname:[dn objectForKey:@"Address"]
                                                                                                                port:[[dn objectForKey:@"Port"] intValue]
                                                                                                      transferSyntax:[[dn objectForKey:@"TransferSyntax"] intValue]
                                                                                                         compression:0
                                                                                                     extraParameters:dn];
                                        [ilQueryNode setShowErrorMessage:NO];
                                        
                                        [ilQueryNode setupNetworkWithSyntax:UID_FINDStudyRootQueryRetrieveInformationModel dataset:&ilDataset destination:nil];
                                        
                                        if (arthread.isCancelled || athread.isCancelled)
                                            return;
                                        
                                        NSMutableArray* iqns = [NSMutableArray array];
                                        
                                        NSArray* availableSOPInstanceUIDs = [availableInstanceUIDs valueForKey:@"sopInstanceUID"];
                                        for (DCMTKImageQueryNode* imageQueryNode in ilQueryNode.children)
                                            if (imageQueryNode.uid && ![availableSOPInstanceUIDs containsObject:imageQueryNode.uid]) {
                                                [availableInstanceUIDs addObject:imageQueryNode.uid];
                                                [iqns addObject:imageQueryNode];
                                            }
                                        
                                        if (!iqns.count) {
                                            stop = YES;
                                            break; // nothing to retrieve
                                        }
                                        
                                        for (DCMTKImageQueryNode* iqn in iqns)
                                            [instanceUIDs addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                     iqn.seriesInstanceUID, @"seriesInstanceUID",
                                                                     iqn.uid, @"sopInstanceUID",
                                                                     nil]];
                                        
                                        athread.status = [NSString stringWithFormat:NSLocalizedString(@"Retrieving %@ for %@...", nil), N2SingularPluralCount(iqns.count, NSLocalizedString(@"image", nil), NSLocalizedString(@"images", nil)), studyName];
                                        
                                        DcmDataset mdataset;
                                        mdataset.putAndInsertString(DCM_QueryRetrieveLevel, "IMAGE");
                                        mdataset.putAndInsertOFStringArray(DCM_SOPInstanceUID, [[[instanceUIDs valueForKey:@"sopInstanceUID"] componentsJoinedByString:@"\\"] UTF8String]);
                                        mdataset.putAndInsertOFStringArray(DCM_SeriesInstanceUID, [[[instanceUIDs valueForKey:@"seriesInstanceUID"] componentsJoinedByString:@"\\"] UTF8String]);
                                        mdataset.putAndInsertOFStringArray(DCM_StudyInstanceUID, [[[iqns valueForKey:@"studyInstanceUID"] componentsJoinedByString:@"\\"] UTF8String]);
                                        
                                        queryNode = [WorklistImagesQueryNode queryNodeWithDataset:&ilDataset
                                                                                      moveDataset:(DcmDataset*)mdataset.clone()
                                                                                       callingAET:[NSUserDefaults.standardUserDefaults stringForKey:@"AETITLE"]
                                                                                        calledAET:[dn objectForKey:@"AETitle"]
                                                                                         hostname:[dn objectForKey:@"Address"]
                                                                                             port:[[dn objectForKey:@"Port"] intValue]
                                                                                   transferSyntax:[[dn objectForKey:@"TransferSyntax"] intValue]
                                                                                      compression:0
                                                                                  extraParameters:dn];
                                        
                                        [queryNode setChildren:iqns];
                                    }
                                    else
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
                                        if (imageLevel) {
                                            imageLevel = NO;
                                            continue;
                                        } else
                                            @throw e;
                                    } @finally {
                                        @synchronized (_currentAutoretrieves) {
                                            [studyCurrentAutoretrieves removeObjectIdenticalTo:instanceUIDs];
                                        }
                                    }
                                    
                                    // the move is done... did we actually fetch any new image?
                                    
                                    if ([queryNode respondsToSelector:@selector(countOfSuccessfulSuboperations)] && !queryNode.countOfSuccessfulSuboperations)
                                        if (mode == 0 && useAccessionNumberMode) {
                                            // modeAccessionNumber = YES;
                                            imageLevel = [[NSUserDefaults standardUserDefaults] boolForKey:@"TryIMAGELevelDICOMRetrieveIfLocalImages"]; // maybe try imagelevel with accessionnumber...
                                            continue;
                                        }
                                    
                                    stop = YES;
                                    break;
                                }
                                
                                if (stop)
                                    break;
                            }
                        }
                        
                        if (!matched) // this study couldn't be found on any of the POD servers...
                            if ([[self.properties objectForKey:@"ifNothingThenDelete"] boolValue] && ![study isDeleted])
                                @synchronized(mySyncObject) {
                                    [db.managedObjectContext deleteObject:study];
                                    [db save];
                                    [BrowserController.currentBrowser performSelectorOnMainThread:@selector(outlineViewRefresh) withObject:nil waitUntilDone:NO];
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
                }];
            };
            
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



