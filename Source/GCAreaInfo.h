//
//  GCAreaInfo.h
//  GraphClick
//
//  Created by Simon Bovet on 23.08.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GCGeometryInspector.h"

@interface GCAreaInfo : GCGeometryInspector {
	IBOutlet NSTableView *mTableView;
	IBOutlet NSArrayController *mArrayController;
}

-(IBAction)copy:(id)inSender;

@end
