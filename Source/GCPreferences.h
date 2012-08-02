//
//  GCPreferences.h
//  GraphClick
//
//  Created by Simon Bovet on 19.03.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GCPreferences : NSWindowController {
	IBOutlet NSView *mGeneralView;
	IBOutlet NSView *mNumberView;
	IBOutlet NSView *mDetectionView;
	IBOutlet NSView *mAdvancedView;
	IBOutlet NSView *mUpdateView;
	
	NSArray *mPaneViews;
	NSArray *mPaneImageNames;
	NSArray *mPaneLabels;
}

-(void)selectPaneAtIndex:(unsigned)inIndex;

@end

@interface GCPreferences (Public)

+(id)sharedWindowController;

-(void)show;
-(NSView *)updateView;

@end
