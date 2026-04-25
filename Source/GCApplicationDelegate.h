//
//  GCApplicationDelegate.h
//  GraphClick
//
//  Created by Simon Bovet on 17.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>


@interface GCApplicationDelegate : NSDocumentController {
	SPUStandardUpdaterController *_updaterController;
}

@property (nonatomic, retain) SPUStandardUpdaterController *updaterController;

-(IBAction)showPreferences:(id)inSender;
-(IBAction)toggleInspector:(id)inSender;
-(IBAction)newInspector:(id)inSender;
-(IBAction)checkForUpdate:(id)inSender;

@end
