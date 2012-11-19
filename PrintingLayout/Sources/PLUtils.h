//
//  PLUtils.h
//  PrintingLayout
//
//  Created by Benoit Deville on 14.11.12.
//
//

#ifndef __PrintingLayout__PLUtils__
#define __PrintingLayout__PLUtils__

typedef enum {
    paper_none      = 0,
    paper_A4,       // 1
    paper_USletter, // 2
    paper_8x10,     // 3
    paper_11x14,    // 4
    paper_14x17,    // 5
} paperSize;

CGFloat getRatioFromPaperFormat(paperSize format);

#endif /* defined(__PrintingLayout__PLUtils__) */
