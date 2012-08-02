//
//  GCOptionalAlert.h
//  GraphClick
//
//  Created by Simon Bovet on 06.04.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GCOptionalAlert : NSWindowController {
	IBOutlet NSTextField *mTitleTextField;
	IBOutlet NSTextField *mMessageTextField;
	
	NSString *mTitle;
	NSString *mMessage;
	BOOL mDontShowAnymore;
	NSMutableSet *mHiddenSet;
}

-(IBAction)confirm:(id)inSender;

@end

void GCRunOptionalAlertPanel(id inIdentifier, NSString *inTitle, NSString *inMessage);
