//
//  GCSnapGridController.h
//  GraphClick
//
//  Created by Simon Bovet on 02.02.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GCView;

@interface GCSnapGridController : NSWindowController {
	GCView *mView;
	NSMutableDictionary *mPreviousValues;
}

-(id)initWithView:(GCView *)inView;
-(void)startSnapGridEdition:(id)inSender;

-(IBAction)finishSnapGridEdition:(id)inSender;

@end
