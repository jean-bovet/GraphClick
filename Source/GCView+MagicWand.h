//
//  GCView+MagicWand.h
//  GraphClick
//
//  Created by Simon Bovet on 21.08.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GCView.h"

@interface GCView (MagicWand)

-(IBAction)confirmMagicWand:(id)inSender;
-(IBAction)cancelMagicWand:(id)inSender;
-(IBAction)abortMagicWand:(id)inSender;

-(IBAction)confirmSymbol:(id)inSender;
-(IBAction)cancelSymbol:(id)inSender;

@end
