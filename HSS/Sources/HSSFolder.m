//
//  HSSFolder.m
//  HSS
//
//  Created by Alessandro Volz on 06.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "HSSFolder.h"
#import "HSSMedcase.h"
#import "OsiriXAPI/NSString+N2.h"

@interface NSObject (HSS)

- (id)ofClass:(Class)c;

@end

@implementation HSSFolder

@synthesize desc = _desc;
@synthesize numCases = _numCases;

+ (id)mutableArray:(NSMutableArray*)items findAndRemoveItemWithOid:(NSString*)oid {
    for (HSSItem* item in items)
        if ([item.oid isEqualToString:oid]) {
            [items removeObject:item];
            return item;
        }
    return nil;
}

/*+(NSSet*)keyPathsForValuesAffectingIsLeaf {
    return [NSSet setWithObject:@"arrangedObjects"];
}*/

- (void)syncWithAPIFolders:(NSArray*)items {
    NSMutableArray* folders = [[[self.content filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"className = %@", [HSSFolder className]]] mutableCopy] autorelease];

    for (NSDictionary* item in items) {
        NSString* oid = [[item valueForKey:@"oid"] ofClass:[NSString class]];
        
        HSSFolder* folder = [[self class] mutableArray:folders findAndRemoveItemWithOid:oid];
        if (!folder) {
            folder = [[[[self class] alloc] init] autorelease];
            folder.oid = oid;
        }
        
        folder.name = [[item valueForKey:@"name"] ofClass:[NSString class]];
        folder.assignable = YES; // [[[item valueForKey:@"assignable"] ofClass:[NSString class]] boolValue]; // since feb 10 2012 the API only returns assignable folders
        folder.numCases = [[[item valueForKey:@"num_cases"] ofClass:[NSString class]] integerValue];

        id descTmp = [item valueForKey:@"description"];
        
        NSMutableAttributedString* desc = [[[NSMutableAttributedString alloc] initWithHTML:[descTmp==[NSNull null]?@"":descTmp dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:NULL] autorelease];
        [desc setAttributes:[NSDictionary dictionary] range:desc.range]; // this removes all formatting, including links
        [desc addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:NSFont.smallSystemFontSize] range:desc.range];
        folder.desc = desc;
        
//        NSLog(@"  syncWithAPIFolders:");
        [folder syncWithAPIFolders:[[item valueForKey:@"children"] ofClass:[NSArray class]]];
//        NSLog(@"  …done");
        
        if (![self.content containsObject:folder])
            [self addObject:folder];
    }
    
    [self removeObjects:folders];
}

- (void)syncWithAPIMedcases:(NSArray*)items {
    NSMutableArray* medcases = [[[self.content filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"className = %@", [HSSMedcase className]]] mutableCopy] autorelease];
    
    for (NSDictionary* item in items) {
        NSString* oid = [[item valueForKey:@"oid"] ofClass:[NSString class]];
        
        HSSMedcase* medcase = [[self class] mutableArray:medcases findAndRemoveItemWithOid:oid];
        if (!medcase) {
            medcase = [[[HSSMedcase alloc] init] autorelease];
            medcase.oid = oid;
        }
        
        medcase.name = [[item valueForKey:@"title"] ofClass:[NSString class]];
        
        medcase.assignable = YES;
        
        if (![self.content containsObject:medcase])
            [self addObject:medcase];
    }
    
    [self removeObjects:medcases];
}

- (BOOL)isLeaf {
    return NO; // [self.content count] == 0
}

- (NSMutableString*)descriptionWithTab:(NSInteger)t {
    NSMutableString* desc = [super descriptionWithTab:t];
    [desc appendString:@" {\n"];
    for (HSSItem* folder in self.arrangedObjects)
        [desc appendFormat:@"%@\n", [folder descriptionWithTab:t+1]];
    for (int i = 0; i < t; ++i) [desc appendString:HSSTab];
    [desc appendString:@"}"];
    return desc;
}

@end

@implementation NSObject (HSS)

- (id)ofClass:(Class)c {
    if ([self isKindOfClass:c])
        return self;
    return nil;
}

@end







