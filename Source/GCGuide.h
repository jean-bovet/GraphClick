//
//  GCGuide.h
//  GraphClick
//
//  Created by Simon Bovet on 20.02.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GCGuide : NSObject <NSCoding> {
	BOOL mVisible;
	float mAddRadius;
	float mMinRadius;
	float mDeltaRadius;
	int mKind;
	BOOL mRadii;
	NSColor *mColor;
}

-(BOOL)visible;
-(void)setVisible:(BOOL)inVisible;
-(float)radius;

-(void)drawAtPoint:(NSPoint)inPoint withWidth:(float)inWidth;

@end

@interface GCGuidePreview : NSView {
	GCGuide *mGuide;
}

-(void)setGuide:(GCGuide *)inGuide;

@end
