//
//  GCLineFinder.h
//  GrowTest
//
//  Created by Simon Bovet on 15.11.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GCLineFinder : NSObject {
	int mWidth;
	int mHeight;
	float mSpacingTolerance;
	float *mPixels;
	BOOL mOwnPixels;
	float *mDepth;
	BOOL *mRead;
	
	int mX;
	int mY;
	int mDeltaX;
	int mDeltaY;
	float mDirection;
	BOOL mReverse;
	BOOL *mKeepOn;
}

-(id)initWithWidth:(int)inWidth height:(int)inHeight pixels:(float *)inPixels;
-(int)width;
-(int)height;

-(void)setPixel:(float)inValue atX:(int)inX y:(int)inY;
-(float)pixelAtX:(int)inX y:(int)inY;
-(float)depthAtX:(int)inX y:(int)inY;
-(BOOL)maximumAtX:(int)inX y:(int)inY;

-(void)startAroundX:(int)inX y:(int)inY spacingTolerance:(float)inSpacingTolerance extremity:(BOOL)inExtremity rightToLeft:(BOOL)inRightToLeft keepOnFlag:(BOOL *)inKeepOn;
-(BOOL)followLineAtX:(float *)outX y:(float *)outY;

@end
