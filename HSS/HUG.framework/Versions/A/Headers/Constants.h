/*
 *  Constants.h
 *  Compacs
 *
 *  Created by Alessandro Volz on 12.10.09.
 *  Copyright 2009 HUG. All rights reserved.
 *
 */

//#define PathToCardUser @"/tmp/osirix_card_user"
#define PathToXploreUser @"/tmp/osirix_user"

extern NSString* const HUGModeFilePath;

#define HUGTrickMask (NSCommandKeyMask|NSAlternateKeyMask)
#define HUGTrick (([[NSApp currentEvent] modifierFlags]&HUGTrickMask)==HUGTrickMask)
 