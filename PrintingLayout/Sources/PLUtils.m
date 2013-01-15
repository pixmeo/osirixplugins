//
//  PLUtils.m
//  PrintingLayout
//
//  Created by Benoit Deville on 14.11.12.
//
//

#import "PLUtils.h"

CGFloat getRatioFromPaperFormat(paperSize format)
{
    switch (format)
    {
        case paper_A4:
            return 1.4142;
            
        case paper_11x14:
            return 14./11;
            
        case paper_14x17:
            return 17./14;
            
        case paper_8x10:
            return 1.25;
            
        case paper_USletter:
            return 1.2941;
            
        default: //paper_none
            return 0.;
    }
}

NSRect  getPDFPageBoundsFromPaperFormat(paperSize format)
{
    CGFloat widthInch, heightInch;
    switch (format)
    {
        case paper_A4:
            widthInch = 8.3;
            heightInch = 11.7;
            break;
            
        case paper_11x14:
            widthInch = 11.;
            heightInch = 14.;
            break;
            
        case paper_14x17:
            widthInch = 14.;
            heightInch = 17.;
            break;
            
        case paper_8x10:
            widthInch = 8.;
            heightInch = 10.;
            break;
            
        case paper_USletter:
            widthInch = 8.5;
            heightInch = 11.;
            break;
            
        default: //paper_none
            widthInch = 0.;
            heightInch = 0.;
            break;
    }
    
    return NSMakeRect(0, 0, 72 * widthInch, 72 * heightInch);
}