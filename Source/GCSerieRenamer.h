//
//  GCSerieRenamer.h
//  GraphClick
//
//  Created by Simon Bovet on 23.08.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GCSerieRenamer : NSWindowController {
	IBOutlet NSTextField *mNewName;
	IBOutlet NSButton *mAddIndex;
}

+(GCSerieRenamer *)renamer;
-(void)renameSeries:(NSArray *)inSeries modalForWindow:(NSWindow *)inWindow;

-(IBAction)confirmName:(id)inSender;
-(IBAction)cancelName:(id)inSender;

@end
