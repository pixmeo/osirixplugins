//
//  DicomUnEnhancerDCMTK.mm
//  DicomUnEnhancer
//
//  Created by Alessandro Volz on 11.10.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "DicomUnEnhancerDCMTK.h"
#import <OsiriXAPI/NSFileManager+N2.h>
#import <OsiriXAPI/NSThread+N2.h>
#import <OsiriXAPI/dcfilefo.h>
#import <OsiriXAPI/dcuid.h>
#import <OsiriXAPI/dcmimage.h>

/*void describe(DcmSequenceOfItems* items) {
    for (unsigned int i = 0; i < items->card(); ++i) {
        DcmItem* item = items->getItem(i);
        NSLog(@"%04x,%04x", item->getGTag(), item->getETag());
        for (unsigned int i = 0; i < item->card(); ++i) {
            DcmElement* element = item->getElement(i);
            NSLog(@"\telement %04x,%04x", element->getGTag(), element->getETag());
        }
    }
}*/

static void _copyItem(DcmItem* origin, DcmItem* destination) {
    for (unsigned int i = 0; i < origin->card(); ++i)
        destination->insert((DcmElement*)origin->getElement(i)->clone(), OFTrue);
}

static void _copySequenceOfItems(DcmSequenceOfItems* origin, DcmItem* destination) {
    for (unsigned int i = 0; i < origin->card(); ++i) // there usually is only one
        _copyItem(origin->getItem(i), destination);
}

static BOOL _copyItem(DcmItem* from, const DcmTagKey& key, DcmItem* destination) {
    DcmElement* element = nil;
    if (from->findAndGetElement(key, element).bad())
        return NO;
    
    if (element->ident() == EVR_SQ)
        _copySequenceOfItems((DcmSequenceOfItems*)element, destination);
    else destination->insert((DcmElement*)element->clone(), OFTrue);
    
    return YES;
}

@implementation DicomUnEnhancerDCMTK

+(NSString*)processFileAtPath:(NSString*)path intoDirInPath:(NSString*)outputDirPath {
    NSThread* thread = [NSThread currentThread];
    
    @try {
        [thread enterSubthreadWithRange:0:1];
        
        if ([outputDirPath isEqualToString:@"/tmp"])
            outputDirPath = [NSFileManager.defaultManager tmpFilePathInTmp];
        else outputDirPath = [NSFileManager.defaultManager tmpFilePathInDir:outputDirPath];
        [NSFileManager.defaultManager confirmDirectoryAtPath:outputDirPath];
        
        NSUInteger outCounter = 0;
        
        NSLog(@"Reading %@", path);
        thread.progress = -1;
        
        DcmFileFormat fileformat;
        if (fileformat.loadFile(path.fileSystemRepresentation).bad())
            [NSException raise:NSGenericException format:@"Error: unable to load file at %@", path];
        
        // describe(&fileformat);
        DcmItem* originalElements = fileformat.getItem(1); // element 0 contains (0002,****) and element 1 contains all the rest.. it seems
        DcmSequenceOfItems* originalSharedFunctionalGroupsSequence = nil;
        originalElements->findAndGetElement(DcmTagKey(0x5200,0x9229), (DcmElement*&)originalSharedFunctionalGroupsSequence);
        DcmItem* originalSharedFunctionalGroup = originalSharedFunctionalGroupsSequence->getItem(0);
        DcmSequenceOfItems* originalPerFrameFunctionalGroupsSequence = nil;
        originalElements->findAndGetElement(DcmTagKey(0x5200,0x9230), (DcmElement*&)originalPerFrameFunctionalGroupsSequence);
        
        DicomImage image(&fileformat, EXS_Unknown);
        
        if (image.getStatus() != EIS_Normal)
            [NSException raise:NSGenericException format:@"Error: unable to read image at %@", path];
        
        for (Uint32 frameIndex = 0; frameIndex < image.getFrameCount(); ++frameIndex) {
            thread.progress = 1.0*frameIndex/image.getFrameCount();
            
            DcmFileFormat outfileformat;
            DcmDataset* outdataset = outfileformat.getDataset();
            
            DcmElement* tmpElement;
            DcmSequenceOfItems* tmpSequenceOfItems;
            DcmItem* tmpItem;
            
//          NSLog(@"Frame %d", frameIndex);
            
            // copy the pixels
            image.writeFrameToDataset(*outdataset, image.getDepth(), frameIndex);
            
            // copy generic tags
            for (unsigned int i = 0; i < originalElements->card(); ++i) {
                tmpElement = originalElements->getElement(i);
                
//              NSLog(@"%04X,%04X", tmpElement->getGTag(), tmpElement->getETag());
                
                if (tmpElement->getGTag() == 0x5200) // we skip group 5200
                    continue;
                if (tmpElement->getGTag() == 0x7fe0 && tmpElement->getETag() == 0x0010) // we skip pixel data
                    continue;
                
                outdataset->insert((DcmElement*)tmpElement->clone());
            }
            
            // handle SharedFunctionalGroupsSequence
            if (originalSharedFunctionalGroup) {
                // just copy it
                //output.insert((DcmElement*)originalSharedFunctionalGroupsSequence->clone());
                
                // sequence (0008,1140) contains a list of sequences that seem to describe Localizers, and we don't know what to do with them
                
                // sequence (0018,9006) is complex
                if (originalSharedFunctionalGroup->findAndGetElement(DcmTagKey(0x0018,0x9006), (DcmElement*&)tmpSequenceOfItems).good())
                    for (unsigned int i = 0; i < tmpSequenceOfItems->card(); ++i) { // there should only be one
                        tmpItem = tmpSequenceOfItems->getItem(i);
                        // (0018,0095) is moved to the root
                        _copyItem(tmpItem, DcmTagKey(0x0018,0x0095), outdataset);
                        // (0018,9020), (0018,9022) and (0018,9028) should go in sequence (2005,140f)
                        // (0018,9098) wasn't available on the original monoframe, looks a lot like (0018,0084), but we extract that one from PerFrameFunctionalGroupsSequence
                    }
                
                // sequence (0018,9042) is complex
                if (originalSharedFunctionalGroup->findAndGetElement(DcmTagKey(0x0018,0x9042), (DcmElement*&)tmpSequenceOfItems).good())
                    for (unsigned int i = 0; i < tmpSequenceOfItems->card(); ++i) { // there should only be one
                        tmpItem = tmpSequenceOfItems->getItem(i);
                        // (0018,1250) is moved to the root
                        _copyItem(tmpItem, DcmTagKey(0x0018,0x1250), outdataset);
                        // (0018,9041), (0018,9043), (0018,9044) and items in (0018,9045) should go in sequence (2005,140f)
                    }
                
                // sequence (0018,9049) is complex
                if (originalSharedFunctionalGroup->findAndGetElement(DcmTagKey(0x0018,0x9049), (DcmElement*&)tmpSequenceOfItems).good())
                    for (unsigned int i = 0; i < tmpSequenceOfItems->card(); ++i) { // there should only be one
                        tmpItem = tmpSequenceOfItems->getItem(i);
                        // (0018,1251) is moved to the root
                        _copyItem(tmpItem, DcmTagKey(0x0018,0x1251), outdataset);
                        // (0018,9050) wasn't available on the original monoframe, probably should go in sequence (2005,140f)
                        // (0018,9051) should go in sequence (2005,140f)
                    }
                
                // items in (0018,9107) should be split into sequence (2005,1083)
                
                // sequence (0018,9112) is complex
                if (originalSharedFunctionalGroup->findAndGetElement(DcmTagKey(0x0018,0x9112), (DcmElement*&)tmpSequenceOfItems).good())
                    for (unsigned int i = 0; i < tmpSequenceOfItems->card(); ++i) { // there should only be one
                        tmpItem = tmpSequenceOfItems->getItem(i);
                        // (0018,0080), (0018,0091) and (0018,1314) are moved to the root
                        _copyItem(tmpItem, DcmTagKey(0x0018,0x0080), outdataset);
                        _copyItem(tmpItem, DcmTagKey(0x0018,0x0091), outdataset);
                        _copyItem(tmpItem, DcmTagKey(0x0018,0x1314), outdataset);
                        // items in (0018,9176) should be concatenated into (2005,1418) and (2005,1419)
                        // (0018,9180, (0018,9182), items in (0018,9239), (0018,9240) and (0018,9241) should go in sequence (2005,140f)
                    }
                
                // items in (0018,9115) should go in sequence (2005,140f)
                
                // items in (0018,9119) are moved to the root
                _copyItem(originalSharedFunctionalGroup, DcmTagKey(0x0018,0x9119), outdataset);
                
                // sequence (0018,9125) is complex 
                if (originalSharedFunctionalGroup->findAndGetElement(DcmTagKey(0x0018,0x9125), (DcmElement*&)tmpSequenceOfItems).good())
                    for (unsigned int i = 0; i < tmpSequenceOfItems->card(); ++i) { // there should only be one
                        tmpItem = tmpSequenceOfItems->getItem(i);
                        // (0018,0093), (0018,0094) and (0018,1312) are moved to the root
                        _copyItem(tmpItem, DcmTagKey(0x0018,0x0093), outdataset);
                        _copyItem(tmpItem, DcmTagKey(0x0018,0x0094), outdataset);
                        _copyItem(tmpItem, DcmTagKey(0x0018,0x1312), outdataset);
                        // (0018,9058), (0018,9231) and (0018,9232) should go in sequence (2005,140f), but we don't
                    }
                
                // sequence (0020,9071) should have its contents concatenated into (2005,1397)
                
                // items in (2005,140e) are moved to the root
                _copyItem(originalSharedFunctionalGroup, DcmTagKey(0x2005,0x140e), outdataset);
            }
            
            // handle PerFrameFunctionalGroupsSequence for this frame
            if (originalPerFrameFunctionalGroupsSequence) {
                DcmItem* originalFunctionalGroup = originalPerFrameFunctionalGroupsSequence->getItem(frameIndex);
                
                // copy the item at the current frame's index
                //DcmSequenceOfItems* newPerFrameFunctionalGroupsSequence = new DcmSequenceOfItems(DcmTag(0x5200,0x9230));
                //newPerFrameFunctionalGroupsSequence->append((DcmItem*)originalFunctionalGroup->clone());
                //output.insert(newPerFrameFunctionalGroupsSequence);
                
                // (0018,9114) contains a value that is already available in other frames
                _copyItem(originalSharedFunctionalGroup, DcmTagKey(0x0018,0x9114), outdataset);
                
                // (0018,9117)
                
                // (0018,9152) contains items that should go in sequence (2005,140f) 
                
                // (0018,9226) contains items that should go in sequence (2005,140f) 
                
                // (0020,9111) replicate time and index information that seems to be already available in other tags
                
                // items in (0020,9113) are moved to the root
                _copyItem(originalFunctionalGroup, DcmTagKey(0x0020,0x9113), outdataset);
                
                // items in (0020,9116) are moved to the root
                _copyItem(originalFunctionalGroup, DcmTagKey(0x0020,0x9116), outdataset);
                
                // (0028,9110) contain slice thickness and pixel spacing, which we also get from (2005,140f)
                _copyItem(originalFunctionalGroup, DcmTagKey(0x0028,0x9110), outdataset);
                
                // (0028,9132) contain wl/ww
                _copyItem(originalFunctionalGroup, DcmTagKey(0x0028,0x9132), outdataset);
                
                // (0028,9145) contain wl/ww transformation data
                _copyItem(originalFunctionalGroup, DcmTagKey(0x0028,0x9145), outdataset);
                
                // (2005,0014) is everywhere, wtf?
                
                // items in (2005,140f) are moved to the root
                _copyItem(originalFunctionalGroup, DcmTagKey(0x2005,0x140f), outdataset);
            }
            
            // save
            NSString* outputFilePath = [outputDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.dcm", ++outCounter]];
            outfileformat.saveFile(outputFilePath.fileSystemRepresentation, EXS_LittleEndianExplicit, EET_ExplicitLength);
        }
    } @catch (...) {
        @throw;
    } @finally {
        [thread exitSubthread];
    }
    
    return outputDirPath;
}

@end
