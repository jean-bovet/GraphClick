//
//  GCWindow.h
//  GraphClick
//
//  Created by Simon Bovet on 07.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GCView.h"

@interface GCWindow : NSWindow {
	IBOutlet GCView *mView;
}

@end
