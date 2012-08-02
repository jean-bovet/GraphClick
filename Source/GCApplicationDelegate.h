//
//  GCApplicationDelegate.h
//  GraphClick
//
//  Created by Simon Bovet on 17.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GCApplicationDelegate : NSDocumentController {
}

-(IBAction)showPreferences:(id)inSender;
-(IBAction)toggleInspector:(id)inSender;
-(IBAction)newInspector:(id)inSender;

@end
