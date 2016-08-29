/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import <Cocoa/Cocoa.h>

// WARNING: If you add or modify this list, check ViewerController.m, DCMView.h and HotKey Pref Pane

typedef enum HotKeyActions {DefaultWWWLHotKeyAction = 0, FullDynamicWWWLHotKeyAction,
	Preset1WWWLHotKeyAction, Preset2WWWLHotKeyAction, Preset3WWWLHotKeyAction, 
	Preset4WWWLHotKeyAction, Preset5WWWLHotKeyAction, Preset6WWWLHotKeyAction, 
	Preset7WWWLHotKeyAction, Preset8WWWLHotKeyAction, Preset9WWWLHotKeyAction,
	FlipVerticalHotKeyAction, FlipHorizontalHotKeyAction,
	WWWLToolHotKeyAction, MoveHotKeyAction, ZoomHotKeyAction, RotateHotKeyAction,
	ScrollHotKeyAction, LengthHotKeyAction, AngleHotKeyAction, RectangleHotKeyAction,
	OvalHotKeyAction, TextHotKeyAction, ArrowHotKeyAction, OpenPolygonHotKeyAction,
	ClosedPolygonHotKeyAction, PencilHotKeyAction, ThreeDPointHotKeyAction, PlainToolHotKeyAction,
    BoneRemovalHotKeyAction, Rotate3DHotKeyAction, Camera3DotKeyAction, scissors3DHotKeyAction, RepulsorHotKeyAction, SelectorHotKeyAction, EmptyHotKeyAction, UnreadHotKeyAction, ReviewedHotKeyAction, DictatedHotKeyAction, ValidatedHotKeyAction, OrthoMPRCrossHotKeyAction, Preset1OpacityHotKeyAction, Preset2OpacityHotKeyAction, Preset3OpacityHotKeyAction, Preset4OpacityHotKeyAction, Preset5OpacityHotKeyAction, Preset6OpacityHotKeyAction, Preset7OpacityHotKeyAction, Preset8OpacityHotKeyAction, Preset9OpacityHotKeyAction, FullScreenAction, Sync3DAction, SetKeyImageAction, ThreeDBallHotKeyAction, OvalAngleHotKeyAction, PreviousROIsOrKeyImageAction, NextROIsOrKeyImageAction, FuseDeFusePETSPECTCTAction, AxialResliceAction, CoronalResliceAction,SagittalResliceAction,ActivateInactivateThickSlabAction,
    
    Preset1CLUTHotKeyAction, Preset2CLUTHotKeyAction, Preset3CLUTHotKeyAction, Preset4CLUTHotKeyAction, Preset5CLUTHotKeyAction, Preset6CLUTHotKeyAction, Preset7CLUTHotKeyAction, Preset8CLUTHotKeyAction, Preset9CLUTHotKeyAction,
    
    LastAction // Key this enum ALWAYS as last enum !
} HotKeyActions;

/** \brief Sets up user defaults */
@interface DefaultsOsiriX : NSObject {

}

//+ (BOOL) isHUG;
//+ (BOOL) isUniGE;
//+ (BOOL) isLAVIM;
+ (NSMutableDictionary*) getDefaults;
//+ (NSString*) hostName;
+ (NSHost*) currentHost;
+ (void) DNSResolve:(id) o;
+ (NSArray*) currentHostNames;
+ (NSArray*) currentHostAddresses;
@end
