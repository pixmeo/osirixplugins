#import "HL7toDICOMPDF.h"
#import <OsiriXAPI/browserController.h>
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/DicomStudy+Report.h>
#import <OsiriXAPI/DicomDatabase.h>
#import <OsiriXAPI/WebPortal.h>
#import <OsiriXAPI/NSManagedObject+N2.h>

@implementation HL7toDICOMPDF

- (IBAction) okButton:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject: [[pathControl URL] path] forKey: @"ReportsFolderPath"];
    
    [NSApp endSheet: settings];
}

- (long) filterImage:(NSString*) menuName
{
    [pathControl setURL: [NSURL URLWithString: [[NSUserDefaults standardUserDefaults] objectForKey: @"ReportsFolderPath"]]];
    
    [NSApp beginSheet: settings modalForWindow: [[BrowserController currentBrowser] window] modalDelegate:self didEndSelector:@selector( settingsDidEnd:returnCode:contextInfo:) contextInfo: nil];
    
	[settings orderFront:self];
    
	return 0;
}

-(void)settingsDidEnd:(NSPanel*)panel returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
	[settings close];
}

- (void) scanReportsFolder: (NSTimer*) timer
{
    NSString *reportsPath = [[NSUserDefaults standardUserDefaults] objectForKey: @"ReportsFolderPath"];
    NSError *error = nil;
    
    for( NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: reportsPath error: nil])
    {
        if( [[file pathExtension] isEqualToString: @"txt"])
        {
            NSString *rawText = [NSString stringWithContentsOfFile: [reportsPath stringByAppendingPathComponent: file] encoding: NSUTF8StringEncoding error: &error];
            if( error)
                NSLog( @"HL7 Plugin: %@", error);
            
            if( rawText && [rawText rangeOfString: @"<AccessionNumber>"].location != NSNotFound && [rawText rangeOfString: @"</AccessionNumber>"].location != NSNotFound)
            {
                NSUInteger start = [rawText rangeOfString: @"<AccessionNumber>"].location + @"<AccessionNumber>".length;
                NSRange range = NSMakeRange( start, [rawText rangeOfString: @"</AccessionNumber>"].location - start);
                NSString *accessionNumber = [rawText substringWithRange: range];
                
                if( accessionNumber.length)
                {
                    if( rawText && [rawText rangeOfString: @"<PatientID>"].location != NSNotFound && [rawText rangeOfString: @"</PatientID>"].location != NSNotFound)
                    {
                        NSUInteger start = [rawText rangeOfString: @"<PatientID>"].location + @"<PatientID>".length;
                        NSRange range = NSMakeRange( start, [rawText rangeOfString: @"</PatientID>"].location - start);
                        NSString *patientID = [rawText substringWithRange: range];
                        
                        if( patientID.length)
                        {
                            //Find the corresponding UID
                            DicomDatabase *db = [[BrowserController currentBrowser] database];
                            
                            
                            NSArray *studyArray = nil;
                            NSError *error = nil;
                            NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
                            NSManagedObjectContext *context = [db managedObjectContext];
                            NSPredicate	 *predicate = [NSPredicate predicateWithFormat: @"(accessionNumber == %@) && (patientID == %@)", accessionNumber, patientID];
                            
                            [request setEntity: [[[db managedObjectModel] entitiesByName] objectForKey:@"Study"]];
                            [request setPredicate: predicate];
                            
                            @try
                            {
                                studyArray = [context executeFetchRequest:request error:&error];
                            }
                            @catch (NSException * e)
                            {
                                NSLog( @"%@", e);
                            }
                            
                            DicomStudy * s = nil;
                            
                            if( [studyArray count])
                                s = [studyArray objectAtIndex: 0];
                            
                            if( s == nil) // Try to find it with studyDate/birthdate/patientID
                            {
                                NSString *studyDate = nil;
                                NSString *birthDate = nil;
                                
                                if( [rawText rangeOfString: @"<PatientBirthdate>"].location != NSNotFound && [rawText rangeOfString: @"</PatientBirthdate>"].location != NSNotFound)
                                {
                                    NSUInteger start = [rawText rangeOfString: @"<PatientBirthdate>"].location + @"<PatientBirthdate>".length;
                                    NSRange range = NSMakeRange( start, [rawText rangeOfString: @"</PatientBirthdate>"].location - start);
                                    birthDate = [rawText substringWithRange: range];
                                }
                                
                                if( [rawText rangeOfString: @"<StudyDate>"].location != NSNotFound && [rawText rangeOfString: @"</StudyDate>"].location != NSNotFound)
                                {
                                    NSUInteger start = [rawText rangeOfString: @"<StudyDate>"].location + @"<StudyDate>".length;
                                    NSRange range = NSMakeRange( start, [rawText rangeOfString: @"</StudyDate>"].location - start);
                                    studyDate = [rawText substringWithRange: range];
                                }
                                
                                if( studyDate.length >= 8 && patientID.length > 0)
                                {
                                    NSLog( @"--- Trying to find the study with studyDate and patientID (AccessionNumber search failed)");
                                    
                                    NSDate *timeIntervalStart = [[[NSCalendarDate alloc] initWithString: [studyDate substringToIndex: 8]  calendarFormat:@"%Y%m%d"] autorelease];
                                    NSDate *timeIntervalEnd = [timeIntervalStart dateByAddingTimeInterval: 24 * 60 * 60];
                                    
                                    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
                                    NSManagedObjectContext *context = [db managedObjectContext];
                                    NSPredicate	 *predicate = [NSPredicate predicateWithFormat: @"(date >= CAST(%lf, \"NSDate\") AND date <= CAST(%lf, \"NSDate\")) && (patientID == %@)", [timeIntervalStart timeIntervalSinceReferenceDate], [timeIntervalEnd timeIntervalSinceReferenceDate], patientID];
                                    
                                    [request setEntity: [[[db managedObjectModel] entitiesByName] objectForKey:@"Study"]];
                                    [request setPredicate: predicate];
                                    
                                    @try
                                    {
                                        studyArray = [context executeFetchRequest:request error:&error];
                                    }
                                    @catch (NSException * e)
                                    {
                                        NSLog( @"%@", e);
                                    }
                                    
                                    if( studyArray.count)
                                    {
                                        s = [studyArray lastObject];
                                        NSLog( @"--- Trying to find the study with studyDate and patientID (AccessionNumber search failed) : SUCCEEDED !");
                                    }
                                }
                                
                                if( s == nil && studyDate.length >= 8 && birthDate.length >= 8)
                                {
                                    NSLog( @"--- Trying to find the study with studyDate and birthDate (AccessionNumber search failed)");
                                    
                                    NSDate *timeIntervalStart = [[[NSCalendarDate alloc] initWithString: [studyDate substringToIndex: 8]  calendarFormat:@"%Y%m%d"] autorelease];
                                    NSDate *timeIntervalEnd = [timeIntervalStart dateByAddingTimeInterval: 24 * 60 * 60];
                                    NSDate *birthNSDate = [[[NSCalendarDate alloc] initWithString: [birthDate substringToIndex: 8]  calendarFormat:@"%Y%m%d"] autorelease];
                                    
                                    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
                                    NSManagedObjectContext *context = [db managedObjectContext];
                                    NSPredicate	 *predicate = [NSPredicate predicateWithFormat: @"(date >= CAST(%lf, \"NSDate\") AND date <= CAST(%lf, \"NSDate\")) && (dateOfBirth == CAST(%lf, \"NSDate\"))", [timeIntervalStart timeIntervalSinceReferenceDate], [timeIntervalEnd timeIntervalSinceReferenceDate], [birthNSDate timeIntervalSinceReferenceDate]];
                                    
                                    [request setEntity: [[[db managedObjectModel] entitiesByName] objectForKey:@"Study"]];
                                    [request setPredicate: predicate];
                                    
                                    @try
                                    {
                                        studyArray = [context executeFetchRequest:request error:&error];
                                    }
                                    @catch (NSException * e)
                                    {
                                        NSLog( @"%@", e);
                                    }
                                    
                                    if( studyArray.count)
                                    {
                                        s = [studyArray lastObject];
                                        NSLog( @"--- Trying to find the study with studyDate and birthDate (AccessionNumber search failed) : SUCCEEDED !");
                                    }
                                }
                            }
                            
                            if( s)
                            {
                                //Extract the report text
                                if( [rawText rangeOfString: @"<Report>"].location != NSNotFound && [rawText rangeOfString: @"</Report>"].location != NSNotFound)
                                {
                                    start = [rawText rangeOfString: @"<Report>"].location + @"<Report>".length;
                                    range = NSMakeRange( start, [rawText rangeOfString: @"</Report>"].location - start);
                                    NSMutableString *text = [NSMutableString stringWithString: [rawText substringWithRange: range]];
                                    
                                    NSUInteger start = [rawText rangeOfString: @"<PatientName>"].location + @"<PatientName>".length;
                                    NSRange range = NSMakeRange( start, [rawText rangeOfString: @"</PatientName>"].location - start);
                                    NSString *patientName = [rawText substringWithRange: range];
                                    
                                    if( patientName.length)
                                    {
                                        [text insertString: [NSString stringWithFormat: @"RAPPORT DE RADIOLOGIE<br><br>------------------------------<br><b>Concerne: %@</b><br>------------------------------<br><br>", patientName] atIndex: 0];
                                        
                                        [text replaceOccurrencesOfString: @"\n" withString:@"<br>" options: NSCaseInsensitiveSearch range: NSMakeRange(0, text.length)];
                                        [text replaceOccurrencesOfString: @"\r" withString:@"<br>" options: NSCaseInsensitiveSearch range: NSMakeRange(0, text.length)];
                                        
                                        [text replaceOccurrencesOfString: @"<br>Renseignements cliniques" withString: @"<br><b>Renseignements Cliniques</b>" options: NSCaseInsensitiveSearch range: NSMakeRange(0, text.length)];
                                        [text replaceOccurrencesOfString: @"<br>Renseignements" withString: @"<br><b>Renseignements</b>" options: NSCaseInsensitiveSearch range: NSMakeRange(0, text.length)];
                                        [text replaceOccurrencesOfString: @"<br>Indication" withString: @"<br><b>Indication</b>" options: NSCaseInsensitiveSearch range: NSMakeRange(0, text.length)];
                                        [text replaceOccurrencesOfString: @"<br>Conclusion" withString: @"<br><b>Conclusion</b>" options: NSCaseInsensitiveSearch range: NSMakeRange(0, text.length)];
                                        [text replaceOccurrencesOfString: @"<br>Description" withString: @"<br><b>Description</b>" options: NSCaseInsensitiveSearch range: NSMakeRange(0, text.length)];
                                        [text replaceOccurrencesOfString: @"<br>Technique" withString: @"<br><b>Technique</b>" options: NSCaseInsensitiveSearch range: NSMakeRange(0, text.length)];
                                        [text replaceOccurrencesOfString: @"<br>Commentaires" withString: @"<br><b>Commentaires</b>" options: NSCaseInsensitiveSearch range: NSMakeRange(0, text.length)];
                                        
                                        // Take the template folder and copy it to tmp
                                        NSString *templateFolder = [[[NSBundle bundleForClass: self.class] resourcePath] stringByAppendingPathComponent: @"template"];
                                        NSString *htmlFolder = [[NSString stringWithFormat: @"/tmp/"] stringByAppendingPathComponent: @"template"];
                                        [NSFileManager.defaultManager removeItemAtPath: htmlFolder error: nil];
                                        
                                        [NSFileManager.defaultManager copyItemAtPath: templateFolder toPath: htmlFolder error: &error];
                                        if( error)
                                            NSLog( @"HL7 Plugin: %@", error);
                                        
                                        NSMutableString *template = [NSMutableString stringWithContentsOfFile: [htmlFolder stringByAppendingPathComponent: @"template.html"] encoding: NSUTF8StringEncoding error: nil];
                                        
                                        [template replaceOccurrencesOfString:@"REPORT" withString: text options: NSLiteralSearch range: NSMakeRange( 0, template.length)];
                                        
                                        // Add a direct URL to images
                                        NSString *imagesURL = [NSString stringWithFormat: @"%@/study?xid=%@", [WebPortal.defaultWebPortal URL], [s XID]];
                                        NSString *formattedImagesURL = [NSString stringWithFormat: @"<a href=\"%@\">%@</a>", imagesURL, imagesURL];
                                        [template replaceOccurrencesOfString:@"IMAGESURL" withString: formattedImagesURL options: NSLiteralSearch range: NSMakeRange( 0, template.length)];
                                        
                                        // Add a QR picture?
                                        // todo
                                        
                                        // Write the html file
                                        NSString *htmlPath = [[htmlFolder stringByAppendingPathComponent: file] stringByAppendingPathExtension: @"html"];
                                        
                                        [template writeToFile: htmlPath atomically: YES encoding: NSUTF8StringEncoding error: &error];
                                        if( error)
                                            NSLog( @"HL7 Plugin: %@", error);
                                        
                                        // Convert to PDF
                                        
                                        NSTask *aTask = [[[NSTask alloc] init] autorelease];
                                        [aTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
                                        [aTask setArguments: [NSArray arrayWithObjects: htmlPath, @"pdfFromURL", nil]];
                                        [aTask launch];
                                        while( [aTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
                                        [aTask interrupt];
                                        
                                        NSString *pdfPath = [htmlPath stringByAppendingPathExtension: @"pdf"];
                                        NSString *DICOMPDFPath = [htmlPath stringByAppendingPathExtension: @"dcm"];
                                        
                                        
                                        // Convert to DICOM PDF
                                        
                                        [s transformPdfAtPath: pdfPath toDicomAtPath: DICOMPDFPath];
                                        
                                        // Delete existing DICOM reports
                                        for( DicomSeries *series in [s valueForKey: @"series"])
                                        {
                                            if( [[series valueForKey: @"name"] isEqualToString: @"Rapport"])
                                            {
                                                [[s managedObjectContext] deleteObject: series];
                                            }
                                        }
                                        
                                        NSString *studyDescription = s.studyName;
                                        
                                        [db save];
                                        
                                        // Add to the current DB
                                        NSString *dstPath =  [db uniquePathForNewDataFileWithExtension: @"dcm"];
                                        
                                        [NSFileManager.defaultManager moveItemAtPath: DICOMPDFPath toPath: dstPath error: &error];
                                        if( error)
                                            NSLog( @"HL7 Plugin: %@", error);
                                        
                                        [db addFilesAtPaths: [NSArray arrayWithObject: dstPath] postNotifications:YES dicomOnly:YES rereadExistingItems:YES generatedByOsiriX:YES];
                                        
                                        s.studyName = studyDescription;
                                        
                                        // Set the ReferringPhysician
                                        
                                        NSUInteger start = [rawText rangeOfString: @"<ReferringPhysician>"].location + @"<ReferringPhysician>".length;
                                        NSRange range = NSMakeRange( start, [rawText rangeOfString: @"</ReferringPhysician>"].location - start);
                                        NSString *referringPhysician = [rawText substringWithRange: range];
                                        
                                        if( referringPhysician.length)
                                        {
                                            if( s.referringPhysician.length)
                                            {
                                                if( [s.referringPhysician rangeOfString: referringPhysician options: NSCaseInsensitiveSearch].location == NSNotFound)
                                                    s.referringPhysician = [s.referringPhysician stringByAppendingFormat: @" / %@", referringPhysician];
                                            }
                                            else
                                                s.referringPhysician = referringPhysician;
                                            
                                            NSLog( @"ReferringPhysician: %@", s.referringPhysician);
                                        }
                                        
                                        // Set the PerformingPhysician
                                        
                                        start = [rawText rangeOfString: @"<PerformingPhysician>"].location + @"<PerformingPhysician>".length;
                                        range = NSMakeRange( start, [rawText rangeOfString: @"</PerformingPhysician>"].location - start);
                                        NSString *performingPhysician = [rawText substringWithRange: range];
                                        
                                        if( performingPhysician.length && [s.performingPhysician isEqualToString: performingPhysician] == NO)
                                        {
                                            s.performingPhysician = performingPhysician;
                                            
                                            NSLog( @"PerformingPhysician: %@", s.performingPhysician);
                                        }
                                        
                                        [db save];
                                        [[BrowserController currentBrowser] outlineViewRefresh];
                                        [[BrowserController currentBrowser] refreshAlbums];
                                        
                                        [NSFileManager.defaultManager removeItemAtPath: htmlPath error: &error];
                                        if( error)
                                            NSLog( @"HL7 Plugin: %@", error);
                                        
                                        [NSFileManager.defaultManager removeItemAtPath: pdfPath error: NULL];
                                        if( error)
                                            NSLog( @"HL7 Plugin: %@", error);
                                        
                                        [NSFileManager.defaultManager removeItemAtPath: [reportsPath stringByAppendingPathComponent: file] error: nil];
                                        if( error)
                                            NSLog( @"HL7 Plugin: %@", error);
                                        
                                        
                                        NSLog( @"HL7 Plugin: %@ - %@ / %@ / %@", file, s.name, s.modality, s.date);
                                    }
                                    else
                                    {
                                        NSLog( @"HL7 Plugin: --- No patient ID found in the file: %@ - %@", accessionNumber, file);
                                        [NSFileManager.defaultManager removeItemAtPath: [reportsPath stringByAppendingPathComponent: file] error: nil];
                                        if( error)
                                            NSLog( @"%@", error);
                                    }
                                }
                                else
                                {
                                    NSLog( @"HL7 Plugin: --- No report found in the file: %@ - %@", accessionNumber, file);
                                    [NSFileManager.defaultManager removeItemAtPath: [reportsPath stringByAppendingPathComponent: file] error: nil];
                                    if( error)
                                        NSLog( @"%@", error);
                                }
                            }
                            else
                            {
                                NSLog( @"HL7 Plugin: --- No study found for this accessionNumber: %@ - %@", accessionNumber, file);
                                [NSFileManager.defaultManager removeItemAtPath: [reportsPath stringByAppendingPathComponent: file] error: nil];
                                if( error)
                                    NSLog( @"HL7 Plugin: %@", error);
                            }
                        }
                    }
                    else
                    {
                        NSLog( @"HL7 Plugin: --- No patientID found for this file: %@", file);
                        [NSFileManager.defaultManager removeItemAtPath: [reportsPath stringByAppendingPathComponent: file] error: nil];
                        if( error)
                            NSLog( @"HL7 Plugin: %@", error);
                    }
                }
                else
                {
                    NSLog( @"HL7 Plugin: --- No accessionNumber found for this file: %@", file);
                    [NSFileManager.defaultManager removeItemAtPath: [reportsPath stringByAppendingPathComponent: file] error: nil];
                    if( error)
                        NSLog( @"HL7 Plugin: %@", error);
                }
            }
            else
            {
                NSLog( @"HL7 Plugin: --- No studyInstanceUID found for this file: %@", file);
                [NSFileManager.defaultManager removeItemAtPath: [reportsPath stringByAppendingPathComponent: file] error: nil];
                if( error)
                    NSLog( @"HL7 Plugin: %@", error);
            }
        }
    }
}

- (void) initPlugin
{
    [NSBundle loadNibNamed: @"Settings" owner:self];
    
    [[NSUserDefaults standardUserDefaults] setObject: @"Rapport" forKey: @"ReportName"];
    
    scanReportsFolderTimer = [NSTimer scheduledTimerWithTimeInterval: 10 target: self selector: @selector( scanReportsFolder:) userInfo: nil repeats: YES];
}

- (void) willUnload
{
    [scanReportsFolderTimer invalidate];
}

@end
