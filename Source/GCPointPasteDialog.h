//
//  GCPointPasteDialog.h
//  GraphClick
//
//  Created by Simon Bovet on 25.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define GCPointPasteItemToKeep @"pointPasteItemToKeep"

enum {
	kGCPointPasteCancel = 0,
	kGCPointPasteKeepCoordinates = 1,
	kGCPointPasteKeepPosition = 2
};

@interface GCPointPasteDialog : NSWindowController {

}

+(GCPointPasteDialog *)sharedDialog;
-(int)runModal;

-(IBAction)confirm:(id)inSender;

@end
