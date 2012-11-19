//
//  PLUtils.mm
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
            return 14./11.;
            
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
