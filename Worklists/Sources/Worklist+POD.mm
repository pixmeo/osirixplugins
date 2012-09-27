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
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/N2Debug.h>
#import <OsiriXAPI/N2Stuff.h>
#import <OsiriXAPI/NSThread+N2.h>
#import <OsiriXAPI/ThreadsManager.h>
#import <OsiriXAPI/DCMTKStudyQueryNode.h>
#import <OsiriXAPI/DCMTKImageQueryNode.h>
#import <OsiriXAPI/dcfilefo.h>
#import <OsiriXAPI/dcelem.h>
#import <OsiriXAPI/dctag.h>
#import <OsiriXAPI/dcdeftag.h>
#import <OsiriX/DCMNetServiceDelegate.h>
#import <OsiriXAPI/DICOMToNSString.h>


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
            NSThread* thread = [NSThread isMainThread]? nil : [NSThread currentThread];
            thread.name = [NSString stringWithFormat:NSLocalizedString(@"Refreshing Worklist: %@", nil), [_properties objectForKey:WorklistNameKey]];
            thread.status = [NSString stringWithFormat:NSLocalizedString(@"Querying for images...", nil), [_properties objectForKey:WorklistCalledAETKey]];
            thread.supportsCancel = YES;
            if (thread) [ThreadsManager.defaultManager addThreadAndStart:thread];
            
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
            
            if (!astudies.count)
                return;
            
            // do the querying...
            
            for (NSInteger i = 0; i < astudies.count; ++i)
                @try {
                    if (thread.isCancelled)
                        return;
                    
                    thread.progress = 1.0/astudies.count*i;
                    
                    DicomStudy* study = [astudies objectAtIndex:i];
                    
                    NSMutableArray* availableSOPInstanceUIDs = [[[study.images.allObjects valueForKey:@"sopInstanceUID"] mutableCopy] autorelease];
                    NSMutableArray* studyCurrentAutoretrieves = nil;
                    @synchronized (_currentAutoretrieves) {
                        studyCurrentAutoretrieves = [_currentAutoretrieves objectForKey:study.studyInstanceUID];
                        if (!studyCurrentAutoretrieves) [_currentAutoretrieves setObject:(studyCurrentAutoretrieves = [NSMutableArray array]) forKey:study.studyInstanceUID];
                        // current transfers are considered as already available to avoid transferring them twice
                        for (NSArray* iSOPInstanceUIDs in studyCurrentAutoretrieves)
                            [availableSOPInstanceUIDs addObjectsFromArray:iSOPInstanceUIDs];
                    }
                    
                    // NSLog(@"Querying %@ ...", study.studyInstanceUID);
                    
                    DcmDataset dataset;
                    dataset.putAndInsertString(DCM_QueryRetrieveLevel, "IMAGE");
                    //dataset.putAndInsertString(DCM_SpecificCharacterSet, stringEncoding.UTF8String);
                    dataset.putAndInsertString(DCM_StudyInstanceUID, study.studyInstanceUID.UTF8String);
                    // dataset.putAndInsertString(DCM_PatientID, [study.patientID cStringUsingEncoding:encoding]);
                    // dataset.putAndInsertString(DCM_AccessionNumber, [study.accessionNumber cStringUsingEncoding:encoding]);

                    for (NSDictionary* dn in dicomNodes) {
                        DCMTKStudyQueryNode* studyQueryNode = [DCMTKStudyQueryNode queryNodeWithDataset:&dataset
                                                                                             callingAET:[NSUserDefaults.standardUserDefaults stringForKey:@"AETITLE"]
                                                                                              calledAET:[dn objectForKey:@"AETitle"]
                                                                                               hostname:[dn objectForKey:@"Address"]
                                                                                                   port:[[dn objectForKey:@"Port"] intValue]
                                                                                         transferSyntax:[[dn objectForKey:@"TransferSyntax"] intValue]
                                                                                            compression:0
                                                                                        extraParameters:dn];
                        [studyQueryNode setShowErrorMessage:NO];

                        [studyQueryNode setupNetworkWithSyntax:UID_FINDStudyRootQueryRetrieveInformationModel dataset:&dataset destination:nil];
                        
                        if (thread.isCancelled)
                            return;
                        
                        // NSLog(@"-------> Children: %@", query.children);
                        // for (DCMTKImageQueryNode* iqn in query.children)
                        //    NSLog(@"------------> %@", iqn.uid);
                        
                        // TODO: if availableSOPInstanceUIDs.count is zero, retrieve at STUDY level - avoid retrieving a study that's currently being retrieved
                        
                        NSMutableArray* iqns = [NSMutableArray array];
                        for (DCMTKImageQueryNode* imageQueryNode in studyQueryNode.children)
                            if (![availableSOPInstanceUIDs containsObject:imageQueryNode.uid]) {
                                [availableSOPInstanceUIDs addObject:imageQueryNode.uid];
                                [iqns addObject:imageQueryNode];
                            }
                        
                        if (iqns.count) {
                            NSArray* sopInstanceUIDs = [iqns valueForKey:@"uid"];
                            
                            @synchronized (_currentAutoretrieves) {
                                [studyCurrentAutoretrieves addObject:sopInstanceUIDs];
                            }
                            
                            // images in sopInstanceUIDs are to be transferred from the dicom node
                            [NSThread performBlockInBackground:^{
                                NSThread* thread = [NSThread currentThread];
                                thread.name = [NSString stringWithFormat:NSLocalizedString(@"Autoretrieving %@", nil), study.name];
                                [ThreadsManager.defaultManager addThreadAndStart:thread];
                                
                                BOOL imageLevel = YES;
                                if (!availableSOPInstanceUIDs.count)
                                    imageLevel = NO;
                                
                                while (true) {
                                    DCMTKQueryNode* queryNode = nil;

                                    thread.status = [NSString stringWithFormat:NSLocalizedString(@"Retrieving %@...", nil), imageLevel? N2SingularPluralCount(iqns.count, NSLocalizedString(@"image", nil), NSLocalizedString(@"images", nil)) : NSLocalizedString(@"study", nil)];
                                    
                                    if (imageLevel) {
                                        DcmDataset mdataset;
                                        mdataset.putAndInsertString(DCM_QueryRetrieveLevel, "IMAGE");
                                        mdataset.putAndInsertOFStringArray(DCM_SOPInstanceUID, [[sopInstanceUIDs componentsJoinedByString:@"\\"] UTF8String]);
                                        NSArray* seriesInstanceUIDs = [iqns valueForKey:@"seriesInstanceUID"];
                                        mdataset.putAndInsertOFStringArray(DCM_SeriesInstanceUID, [[seriesInstanceUIDs componentsJoinedByString:@"\\"] UTF8String]);
                                        NSArray* studyInstanceUIDs = [iqns valueForKey:@"studyInstanceUID"];
                                        mdataset.putAndInsertOFStringArray(DCM_StudyInstanceUID, [[studyInstanceUIDs componentsJoinedByString:@"\\"] UTF8String]);
                                        
                                        queryNode = [WorklistImagesQueryNode queryNodeWithDataset:&dataset
                                                                                      moveDataset:(DcmDataset*)mdataset.clone()
                                                                                       callingAET:[NSUserDefaults.standardUserDefaults stringForKey:@"AETITLE"]
                                                                                        calledAET:[dn objectForKey:@"AETitle"]
                                                                                         hostname:[dn objectForKey:@"Address"]
                                                                                             port:[[dn objectForKey:@"Port"] intValue]
                                                                                   transferSyntax:[[dn objectForKey:@"TransferSyntax"] intValue]
                                                                                      compression:0
                                                                                  extraParameters:dn];
                                    }
                                    
                                    if (!imageLevel) {
                                        DcmDataset mdataset;
                                        mdataset.putAndInsertString(DCM_QueryRetrieveLevel, "STUDY");
                                        mdataset.putAndInsertString(DCM_StudyInstanceUID, study.studyInstanceUID.UTF8String);

                                        queryNode = [DCMTKStudyQueryNode queryNodeWithDataset:(DcmDataset*)mdataset.clone()
                                                                                   callingAET:[NSUserDefaults.standardUserDefaults stringForKey:@"AETITLE"]
                                                                                    calledAET:[dn objectForKey:@"AETitle"]
                                                                                     hostname:[dn objectForKey:@"Address"]
                                                                                         port:[[dn objectForKey:@"Port"] intValue]
                                                                               transferSyntax:[[dn objectForKey:@"TransferSyntax"] intValue]
                                                                                  compression:0
                                                                              extraParameters:dn];
                                    }

                                    [queryNode setChildren:iqns];
                                    
                                    NSMutableDictionary* params = [[dn mutableCopy] autorelease];
                                    [params setObject:studyQueryNode.callingAET forKey:@"moveDestination"];

                                    [queryNode setShowErrorMessage:NO];
                                    [queryNode setDontCatchExceptions:YES];

                                    @try {
                                        [queryNode move:params retrieveMode:[[dn objectForKey:@"retrieveMode"] intValue]];
                                    } @catch (NSException* e) {
                                        if (imageLevel) {
                                            imageLevel = NO;
                                            continue;
                                        } else
                                            @throw e;
                                    }
                                    
                                    break;
                                }
                                
                                @synchronized (_currentAutoretrieves) {
                                    [studyCurrentAutoretrieves removeObjectIdenticalTo:sopInstanceUIDs];
                                }
                            }];
                        }
                    }
                } @catch (NSException* e) {
                    // potentially, these are faults for destroyed studies... we should ignore them :P
                    @throw e;
                }
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

- (DcmDataset*)moveDataset {
	return (DcmDataset*)_moveDataset->clone();
}

@end



