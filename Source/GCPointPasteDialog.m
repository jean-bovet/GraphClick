//
//  GCPointPasteDialog.m
//  GraphClick
//
//  Created by Simon Bovet on 25.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GCPointPasteDialog.h"


@implementation GCPointPasteDialog

+(GCPointPasteDialog *)sharedDialog
{
	static GCPointPasteDialog *sharedDialog = nil;
	if (!sharedDialog)
		sharedDialog = [[self alloc] initWithWindowNibName:@"GCPointPasteDialog"];
	return sharedDialog;
}

-(int)runModal
{
	int response = [NSApp runModalForWindow:[self window]];
	if (response == NSCancelButton)
		return kGCPointPasteCancel;
	else
		return [[NSUserDefaults standardUserDefaults] integerForKey:GCPointPasteItemToKeep] + 1;
}

-(IBAction)confirm:(id)inSender
{
	[[self window] orderOut:nil];
	[NSApp stopModalWithCode:[inSender tag]];
}

@end
