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


@implementation Worklist (POD)

- (void)autoretrieveWithDatabase:(DicomDatabase*)db {
    @synchronized (self) {
        if (![_refreshLock tryLock])
            return;
        
        NSThread* thread = [NSThread isMainThread]? nil : [NSThread currentThread];
        thread.name = [NSString stringWithFormat:NSLocalizedString(@"Refreshing Worklist: %@", nil), [_properties objectForKey:WorklistNameKey]];
        thread.status = [NSString stringWithFormat:NSLocalizedString(@"Autoretrieving studies...", nil), [_properties objectForKey:WorklistCalledAETKey]];
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
        NSMutableSet* astudies = [album mutableSetValueForKey:@"studies"];
        
        // do the querying...
        
        NSString* stringEncoding = [[NSUserDefaults standardUserDefaults] stringForKey:@"STRINGENCODING"];
        if (!stringEncoding) stringEncoding = @"ISO_IR 100";
        NSStringEncoding encoding = [NSString encodingForDICOMCharacterSet:stringEncoding];
        
        for (DicomStudy* study in astudies) { // TODO: parallelize this...
            NSMutableArray* availableSOPInstanceUIDs = [[[study.images.allObjects valueForKey:@"sopInstanceUID"] mutableCopy] autorelease];
            // NSLog(@"Querying %@ ...", study.studyInstanceUID);
            
            DcmDataset dataset;
            dataset.putAndInsertString(DCM_QueryRetrieveLevel, "IMAGE");
            dataset.putAndInsertString(DCM_SpecificCharacterSet, stringEncoding.UTF8String);
            dataset.putAndInsertString(DCM_StudyInstanceUID, [study.studyInstanceUID cStringUsingEncoding:encoding]);
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
                
                // NSLog(@"-------> Children: %@", query.children);
                // for (DCMTKImageQueryNode* iqn in query.children)
                //    NSLog(@"------------> %@", iqn.uid);
                
                NSMutableArray* iqns = [NSMutableArray array];
                for (DCMTKImageQueryNode* imageQueryNode in studyQueryNode.children)
                    if (![availableSOPInstanceUIDs containsObject:imageQueryNode.uid]) {
                        [availableSOPInstanceUIDs addObject:imageQueryNode.uid];
                        [iqns addObject:imageQueryNode];
                    }
                
                // images in sopInstanceUIDs are to be transferred from the dicom node
                for (DCMTKImageQueryNode* imageQueryNode in iqns) { // TODO: do this with ONE custom moveDataset
                    [imageQueryNode move:[NSDictionary dictionaryWithObjectsAndKeys:
                                          studyQueryNode, @"study",
                                          studyQueryNode.callingAET, @"moveDestination",
                                          nil]
                            retrieveMode:[[dn objectForKey:@"retrieveMode"] intValue]];
                }
            }
        }
        
        [_refreshLock unlock];
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
