//
//  HSSMedcaseCreation.m
//  HSS
//
//  Created by Alessandro Volz on 09.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "HSSMedcaseCreation.h"
#import "HSSAPISession.h"
#import "HSSFolder.h"
#import "HSSMedcase.h"
#import <OsiriXAPI/NSThread+N2.h>
#import <OsiriXAPI/NSFileManager+N2.h>
#import <OsiriXAPI/NSXMLNode+N2.h>
#import <OsiriXAPI/DicomImage.h>
#import <OsiriXAPI/DicomDatabase.h>
#import <OsiriXAPI/DicomDatabase+DCMTK.h>
#import <OsiriXAPI/ThreadModalForWindowController.h>

@implementation HSSMedcaseCreation

@synthesize session = _session;
@synthesize caseName = _caseName;
@synthesize images = _images;
@synthesize destination = _destination;
//@synthesize destinationMedcaseOid = _destinationMedcaseOid;
@synthesize diagnosis = _diagnosis;
@synthesize history = _history;
@synthesize openFlag = _openFlag;
@synthesize docWindow = _docWindow;

- (id)initWithSession:(HSSAPISession*)session {
    if ((self = [super init])) {
        self.name = NSLocalizedString(@"HSS Submission", nil);
        self.session = session;
    }
    
    return self;
}

- (void)dealloc {
    self.history = nil;
    self.diagnosis = nil;
    self.destination = nil;
//  self.destinationMedcaseOid = nil;
    self.images = nil;
    self.caseName = nil;
    self.session = nil;
    self.docWindow = nil;
    [super dealloc];
}

+ (NSArray*)arrayWithUniqueObjectsInArray:(NSArray*)array {
    NSMutableArray* r = [NSMutableArray array];
    
    for (id obj in array)
        if (![r containsObject:obj])
            [r addObject:obj];
    
    return r;
}

- (void)main {
    NSString* tempDirPath = nil;
    NSString* tempZipPath = nil;
    NSDictionary* response = nil;
    
    @try {
        self.status = NSLocalizedString(@"Copying and decompressing DICOM files...", nil);
        if (self.docWindow) [self startModalForWindow:self.docWindow];
        if ([self respondsToSelector:@selector(setSupportsBackgrounding:)])
            [self setSupportsBackgrounding:YES];
        
        NSArray* completePaths = [[self class] arrayWithUniqueObjectsInArray:[self.images valueForKey:@"completePath"]];
        
        tempDirPath = [NSFileManager.defaultManager tmpFilePathInTmp];
        [NSFileManager.defaultManager confirmDirectoryAtPath:tempDirPath];
        
        NSError* error = nil;
        [NSFileManager.defaultManager setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                     NSUserName(), NSFileOwnerAccountName,
                                                     [NSNumber numberWithInt:0755], NSFilePosixPermissions, nil]
                                       ofItemAtPath:tempDirPath error:&error];
        if (error)
            NSLog(@"setAttributes error: %@", error);
            
        // decompress JPEG2000 DICOM files: first copy, then decompress them
        
        /*{
            BOOL d, e = [NSFileManager.defaultManager fileExistsAtPath:tempDirPath isDirectory:&d];
            NSLog(@"check 0: tempDirPath is %@, exists? %d, dir? %d", tempDirPath, e, d);
            NSLog(@"check 1: completePaths count is %d {", (int)completePaths.count);
            for (NSString* path in completePaths) {
                NSLog(@"\texists? %d for %@", [NSFileManager.defaultManager fileExistsAtPath:path], path);
            }
        }*/
        
        NSMutableArray* dcmFilePaths = [NSMutableArray array];
        NSInteger dcmIndex = 0;
        for (NSString* path in completePaths) {
            NSString* destPath = [tempDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.dcm", (int)(dcmIndex++)]];
            NSError* error = nil;
            if ([NSFileManager.defaultManager copyItemAtPath:path toPath:destPath error:&error])
                [dcmFilePaths addObject:destPath];
            else NSLog(@"HSS plugin copy file error: %@", error);
        }
        
        /*{
            NSLog(@"check 2: dcmFilePaths count is %d {", (int)dcmFilePaths.count);
            for (NSString* path in dcmFilePaths) {
                NSLog(@"\texists? %d for %@", [NSFileManager.defaultManager fileExistsAtPath:path], path);
            }
        }*/

        [DicomDatabase decompressDicomFilesAtPaths: dcmFilePaths];
        
//        [DicomCompressor decompressFiles:dcmFilePaths toDirectory:@"sameAsDestination"];

        /*{
            NSLog(@"check 3: dcmFilePaths count is %d, decompression done... {", (int)dcmFilePaths.count);
            for (NSString* path in dcmFilePaths) {
                NSLog(@"\texists? %d for %@", [NSFileManager.defaultManager fileExistsAtPath:path], path);
            }
        }*/

        if ([self.destination isKindOfClass:[HSSFolder class]]) {
            // XML

            self.status = NSLocalizedString(@"Creating MIRC index file...", nil);
            
            NSString* tempXmlPath = [tempDirPath stringByAppendingPathComponent:@"mirc.xml"];

            NSXMLElement* root = [NSXMLElement elementWithName:@"MIRCdocument"];
            // hopefully unnecessary: [root addAttribute:[NSXMLNode attributeWithName:@"login" stringValue:self.session.userLogin]];
            //[root addAttribute:[NSXMLNode attributeWithName:@"login" stringValue:self.session.userLogin]];
            // hopefully unnecessary: [root addAttribute:[NSXMLNode attributeWithName:@"password" stringValue:self.session.userPassword]];
            //[root addAttribute:[NSXMLNode attributeWithName:@"password" stringValue:self.session.userPassword]];
            NSXMLDocument* xml = [[NSXMLDocument alloc] initWithRootElement:root];
            
            NSXMLElement* section;
            
            [root addChild:[NSXMLElement elementWithName:@"title" text:self.caseName]];
            // hopefully unnecessary: <publication-date>2011-12-31</publication-date>
            // hopefully unnecessary: <keywords>MIRC Mona Bomb Psuedoscorpion</keywords>
            
            if (self.history.length){
                section = [NSXMLElement elementWithName:@"section"];
                [section addAttribute:[NSXMLNode attributeWithName:@"heading" stringValue:@"history"]];
                [root addChild:section];
                [section addChild:[NSXMLElement elementWithName:@"history" text:self.history]];
            }
            
            // hopefully unnecessary: <section heading="findings"><findings>The &lt;a href=&quot;&#104;ttp://rsna.org&quot;&gt;RSNA&lt;/a&gt; ate my findings.</findings></section>
            
            if (self.diagnosis.length) {
                section = [NSXMLElement elementWithName:@"section"];
                [section addAttribute:[NSXMLNode attributeWithName:@"heading" stringValue:@"diagnosis"]];
                [root addChild:section];
                [section addChild:[NSXMLElement elementWithName:@"diagnosis" text:self.diagnosis]];
            }
            
            // hopefully unnecessary: <section heading="discussion"><discussion>I never talk about my cases at dinner because I have 144 of them.</discussion></section>
            // hopefully unnecessary: <section heading="references">Ref: ibid, ¥€$.</section>
            // hopefully unnecessary: <section heading="notes">§ Content containing PHI shouldn&apos;t be exported.</section>
            
            section = [NSXMLElement elementWithName:@"section"];
            [section addAttribute:[NSXMLNode attributeWithName:@"heading" stringValue:@"images"]];
            [root addChild:section];
            for (NSString* dcmFileName in [dcmFilePaths valueForKey:@"lastPathComponent"]) {
                NSXMLElement* image = [NSXMLElement elementWithName:@"image"];
                [image addAttribute:[NSXMLNode attributeWithName:@"src" stringValue:dcmFileName]];
                [section addChild:image];
                // hopefully unnecessary: <text-caption>O HAI! IM IN UR CR, BOMMING UR RADEEOLAJIST</text-caption>
            }
            
            // hopefully unnecessary: <code coding-system="ACR">343.4444</code>
            // hopefully unnecessary: <document-type>radiologic teaching file</document-type>
            // hopefully unnecessary: <pathology>Neoplasm</pathology>
            // hopefully unnecessary: <anatomy>Face and Neck</anatomy>
            // hopefully unnecessary: <modality>CR, Photograph, Other</modality>
            // hopefully unnecessary: <access>restricted</access>
            // hopefully unnecessary: <patient><pt-sex>female</pt-sex><pt-age><years>497</years></pt-age></patient>
            
            xml.characterEncoding = @"UTF-8";
            xml.standalone = YES;
            
            [[xml XMLData] writeToFile:tempXmlPath atomically:YES];
            
            // ZIP
            
            self.status = NSLocalizedString(@"Archiving image data...", nil);
            
            // TODO: if two files have the same name (even on different paths), the zip will probably fail...
            
            tempZipPath = [[NSFileManager.defaultManager tmpFilePathInTmp] stringByAppendingPathExtension:@"zip"];

            NSMutableArray* args = [NSMutableArray arrayWithObjects: @"-rj", tempZipPath, tempXmlPath, nil];
            [args addObjectsFromArray:dcmFilePaths];
            
            /*{
                NSLog(@"Zip command arguments: %@", args);
            }*/
            
            NSTask* task = [[[NSTask alloc] init] autorelease];
            task.launchPath = @"/usr/bin/zip";
            task.arguments = args;
            //  task.standardOutput = [NSPipe pipe];
            [task launch];
            while( [task isRunning]) [NSThread sleepForTimeInterval: 0.01];
            [task interrupt];
            //  NSLog(@"zip output: %@", [[[NSString alloc] initWithData:[[(NSPipe*)task.standardOutput fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease]);
            
            // UPLOAD
            
            self.status = NSLocalizedString(@"Posting data to HSS...", nil);
            
            NSError* error = nil;
            response = [self.session postMedcaseWithZipFileAtPath:tempZipPath folderOid:self.destination.oid progressDelegate:self error:&error];
            if (error)
                [NSException raise:NSGenericException format:@"%@", error.localizedDescription];
        }
        else // so, if destination is not a folder, it must be a medcase....
        {
            self.status = NSLocalizedString(@"Posting data to HSS...", nil);

            for (NSInteger i = 0; i < dcmFilePaths.count; ++i) {
                self.progress = 1.0/dcmFilePaths.count*i;
                
                NSString* path = [dcmFilePaths objectAtIndex:i];
                
                NSError* error = nil;
                response = [self.session putFileAtPath:path intoMedcaseWithOid:self.destination.oid error:&error];
                if (error)
                    [NSException raise:NSGenericException format:@"%@", error.localizedDescription];
            }
            
            self.progress = -1;
        }
        
        if (_openFlag)
            [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:[response valueForKey:@"viewer"]]];
    } @catch (NSException* e) {
        [self performSelectorOnMainThread:@selector(_reportException:) withObject:e waitUntilDone:NO];
    } @finally {
        if (tempDirPath) [NSFileManager.defaultManager removeItemAtPath:tempDirPath error:NULL];
        if (tempZipPath) [NSFileManager.defaultManager removeItemAtPath:tempZipPath error:NULL];
    }
}

- (void)HSSAPIProgress:(NSNumber*)progress {
    self.progress = progress.floatValue;
    if (progress.floatValue == 1) {
        self.progress = -1;
        self.status = NSLocalizedString(@"Waiting on HSS...", nil);
    }
}

- (void)_reportException:(NSException*)e {
    [[NSAlert alertWithMessageText:NSLocalizedString(@"HSS Medcase Creation Error", nil) defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", e.reason] beginSheetModalForWindow:nil modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

@end
