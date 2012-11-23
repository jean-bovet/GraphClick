//
//  GCLineFinder.m
//  GrowTest
//
//  Created by Simon Bovet on 15.11.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GCLineFinder.h"


@implementation GCLineFinder

-(id)initWithWidth:(int)inWidth height:(int)inHeight pixels:(float *)inPixels
{
	if (self = [super init]) {
		mWidth = inWidth;
		mHeight = inHeight;
		mOwnPixels = inPixels == nil;
		mPixels = mOwnPixels ? (float *)calloc(mWidth * mHeight, sizeof(float)) : inPixels;
		mDepth = (float *)calloc(mWidth * mHeight, sizeof(float));
		mRead = (BOOL *)calloc(mWidth * mHeight, sizeof(BOOL));
		if (!mPixels || !mDepth || !mRead) {
			[self release];
			return nil;
		}
	}
	return self;
}

-(void)dealloc
{
	if (mOwnPixels)
		free(mPixels);
	free(mDepth);
	free(mRead);
	[super dealloc];
}

-(int)width
{
	return mWidth;
}

-(int)height
{
	return mHeight;
}

-(void)setPixel:(float)inValue atX:(int)inX y:(int)inY
{
	if (inX >= 0 && inX < mWidth && inY >= 0 && inY < mHeight)
		mPixels[inX + inY * mWidth] = inValue;
}

-(float)pixelAtX:(int)inX y:(int)inY
{
	if (inX >= 0 && inX < mWidth && inY >= 0 && inY < mHeight)
		return mPixels[inX + inY * mWidth];
	else
		return 0.0;
}

-(float)depthAtX:(int)inX y:(int)inY
{
	if (inX >= 0 && inX < mWidth && inY >= 0 && inY < mHeight)
		return fabs(mDepth[inX + inY * mWidth]);
	else
		return 0.0;
}

-(BOOL)maximumAtX:(int)inX y:(int)inY
{
	if (inX >= 0 && inX < mWidth && inY >= 0 && inY < mHeight)
		return mDepth[inX + inY * mWidth] < 0.0;
	else
		return NO;
}

-(BOOL)unreadMaximumAtX:(int)inX y:(int)inY
{
	if (inX >= 0 && inX < mWidth && inY >= 0 && inY < mHeight) {
		int index = inX + inY * mWidth;
		return mDepth[index] < 0.0 && !mRead[index];
	} else
		return NO;
}

-(BOOL)increaseDepth
{
	BOOL increased = NO;
	int x, y;
	float *pixel = mPixels;
	float *depth = mDepth;
	for (y = 0; y < mHeight; y++) 
		for (x = 0; x < mWidth; x++) {
			float newDepth = (*pixel++) + MIN(MIN([self depthAtX:x - 1 y:y], [self depthAtX:x + 1 y:y]), MIN([self depthAtX:x y:y - 1], [self depthAtX:x y:y + 1]));
			if (newDepth > *depth) {
				*depth = newDepth;
				increased = YES;
			}
			depth++;
		}
	return increased;
}

-(void)computeDepth
{
	int i, imax = mWidth * mHeight;
	float *buffer = mDepth;
	for (i = 0; i < imax; i++)
		*buffer++ = 0.0;

	while (*mKeepOn && [self increaseDepth])
		;
}

static int _dx[] = {1, 1, 0, -1, -1, -1, 0, 1};
static int _dy[] = {0, 1, 1, 1, 0, -1, -1, -1};

-(void)findDepthMaxima
{
	int x, y;
	for (y = 0; *mKeepOn && y < mWidth; y++) 
		for (x = 0; *mKeepOn && x < mWidth; x++) {
			float depth = [self depthAtX:x y:y];
			if (depth > 0.5) {
				int d;
				BOOL found = NO;
				for (d = 0; d < 4 && !found; d += 2) {
					int dx = _dx[d], dy = _dy[d];
					float steepness = fabs([self depthAtX:x + dy y:y - dx] - [self depthAtX:x - dy y:y + dx]);
					if (steepness < 1.0) {
						float prev = [self depthAtX:x - dx y:y - dy];
						float next = [self depthAtX:x + dx y:y + dy];
						if ((depth > prev && (depth > next || (depth == next && depth > [self depthAtX:x + 2 * dx y:y + 2 * dy])))
							|| (depth == prev && depth > next && depth > [self depthAtX:x - 2 * dx y:y - 2 * dy]))
							found = YES;
					}
				}
				if (found)
/*				float xm, xp, ym, yp;
				if (depth > MAX(xp = [self depthAtX:x + 1 y:y], xm = [self depthAtX:x - 1 y:y])
					|| depth > MAX(yp = [self depthAtX:x y:y + 1], ym = [self depthAtX:x y:y - 1])
					|| depth > xp && depth == xm && depth > [self depthAtX:x - 2 y:y]
					|| depth == xp && depth > xm && depth > [self depthAtX:x + 2 y:y]
					|| depth > yp && depth == ym && depth > [self depthAtX:x y:y - 2]
					|| depth == yp && depth > ym && depth > [self depthAtX:x y:y + 2]) */
					mDepth[x + y * mWidth] = -depth;
			}
		}
}

#define MAXIMUM_IN_DIR(d) [self maximumAtX:x + _dx[(d0 + (d)) % 8] y:y + _dy[(d0 + (d)) % 8]]

-(void)pruneDepthMaxima
{
	int pass;
	BOOL repass = YES;
	BOOL keepOn;
	while (*mKeepOn && repass) {
		repass = NO;
		for (pass = 0; *mKeepOn && pass < 2; pass++)
			// Pass 0: Eliminate T's
			// Pass 1: Eliminate L's
			do {
				keepOn = NO;
				int x, y, d0;
				for (y = 0; *mKeepOn && y < mWidth; y++) 
					for (x = 0; *mKeepOn && x < mWidth; x++)
						if ([self maximumAtX:x y:y]) 
							for (d0 = 0; d0 < 8; d0 += pass == 0 ? 1 : 2)
								if ((pass == 1 && MAXIMUM_IN_DIR(0) && MAXIMUM_IN_DIR(2) && !MAXIMUM_IN_DIR(5))
									|| (pass == 0 && MAXIMUM_IN_DIR(7) && MAXIMUM_IN_DIR(0) && MAXIMUM_IN_DIR(1)
												 && !MAXIMUM_IN_DIR(3) && !MAXIMUM_IN_DIR(4) && !MAXIMUM_IN_DIR(5)) ) {
									mDepth[x + y * mWidth] = fabs(mDepth[x + y * mWidth]);
									keepOn = YES;
									if (pass > 0)
										repass = YES;
									break;
								}
			} while (keepOn);
	}
}

-(void)process
{
	[self computeDepth];
	[self findDepthMaxima];
	[self pruneDepthMaxima];
}

-(BOOL)gotoNextMaximumInRange:(float)inRange direction:(float)inDirection minAngle:(float)inMinAngle maxAngle:(float)inMaxAngle
{
	int x, y;
	float radius, angle;
	for (radius = 0.0; radius <= inRange; radius += 0.5) {
		float da = 0.25 / MAX(0.5, radius);
		for (angle = inMinAngle; angle < inMaxAngle; angle += da)
			if ([self unreadMaximumAtX:x = mX + radius * cos(inDirection + angle) y:y = mY + radius * sin(inDirection + angle)] ||
				[self unreadMaximumAtX:x = mX + radius * cos(inDirection - angle) y:y = mY + radius * sin(inDirection - angle)]) {
				mX = x;
				mY = y;
				return YES;
			}
	}
	return NO;
}

-(BOOL)gotoNextMaximumInRange:(float)inRange
{
	float angle, da = 0.1;
	for (angle = 0.0; angle <= (mReverse ? pi * 0.75 : pi); angle += da)
		if ([self gotoNextMaximumInRange:inRange direction:mDirection minAngle:angle maxAngle:angle + da])
			return YES;
	return NO;
}

-(BOOL)gotoMaximumAround:(int)inX y:(int)inY direction:(float)inDirection pixelDistance:(int)inPixelDistance
{
	float radius, angle;
	int dx, dy;
	int x, y, s;
	for (radius = 0.5 * inPixelDistance; radius <= 1.5 * inPixelDistance; radius += 0.5) {
		float da = 0.25 / MAX(0.5, radius);
		for (angle = 0.0; angle <= pi; angle += da)
			for (s = -1; s <= 1; s += 2) {
				dx = radius * cos(inDirection + s * angle);
				dy = radius * sin(inDirection + s * angle);
				if (MAX(abs(dx), abs(dy)) == inPixelDistance && [self unreadMaximumAtX:x = inX + dx y:y = inY + dy]) {
					mX = x;
					mY = y;
					return YES;
				}
			}
	}
	return NO;
}

-(BOOL)gotoMaximumAround:(int)inX y:(int)inY
{
	float radius, angle;
	int x, y;
	for (radius = 0.0; *mKeepOn && radius < MAX(mWidth, mHeight); radius += 0.5) {
		float da = 0.25 / MAX(0.5, radius);
		for (angle = 0.0; *mKeepOn && angle < 2.0 * pi; angle += da)
			if ([self unreadMaximumAtX:x = inX + radius * cos(angle) y:y = inY + radius * sin(angle)]) {
				mX = x;
				mY = y;
				return YES;
			}
	}
	return NO;
}

-(void)clearRead
{
	int x, y;
	BOOL *read = mRead;
	for (y = 0; y < mHeight; y++) 
		for (x = 0; x < mWidth; x++)
			*read++ = NO;
}

-(void)startAroundX:(int)inX y:(int)inY spacingTolerance:(float)inSpacingTolerance extremity:(BOOL)inExtremity rightToLeft:(BOOL)inRightToLeft keepOnFlag:(BOOL *)inKeepOn
{
	static BOOL keepOn = YES;
	mKeepOn = inKeepOn ? inKeepOn : &keepOn;
	[self process];
	mSpacingTolerance = inSpacingTolerance;
	mX = mY = -1;
	[self clearRead];
	if (inExtremity) {
		mReverse = !inRightToLeft;
		mDeltaX = inRightToLeft ? 1 : -1;
		mDeltaY = 0;
		mDirection = atan2(mDeltaY, mDeltaX);
		[self gotoMaximumAround:inX y:inY];
		while (*mKeepOn && [self followLineAtX:nil y:nil])
			;

		if (*mKeepOn) {
			mDeltaX = inRightToLeft ? -1 : 1; //-mDeltaX;
			mDeltaY = 0; //-mDeltaY;
			mDirection = atan2(mDeltaY, mDeltaX);
			[self clearRead];
			mReverse = inRightToLeft;
		}
	} else {
		mReverse = inRightToLeft;
		mDeltaX = inRightToLeft ? -1 : 1;
		mDeltaY = 0;
		mDirection = atan2(mDeltaY, mDeltaX);
		[self gotoMaximumAround:inX y:inY];
	}
}

-(void)rotateCW90
{
	int x = mReverse ? -mDeltaY : mDeltaY;
	mDeltaY = mReverse ? mDeltaX : -mDeltaX;
	mDeltaX = x;
}

-(void)rotateCCW90
{
	int x = mReverse ? mDeltaY : -mDeltaY;
	mDeltaY = mReverse ? -mDeltaX : mDeltaX;
	mDeltaX = x;
}

-(void)rotateCCW45
{
	int x = mReverse ? mDeltaX + mDeltaY : mDeltaX - mDeltaY;
	int y = mReverse ? -mDeltaX + mDeltaY : mDeltaX + mDeltaY;
	mDeltaX = x < 0 ? -1 : x > 0 ? 1 : 0;
	mDeltaY = y < 0 ? -1 : y > 0 ? 1 : 0;
}

-(BOOL)followMaximum
{
	int d;
	for (d = 0; d < 8; d++) {
		if ([self unreadMaximumAtX:mX + mDeltaX y:mY + mDeltaY]) {
			mX += mDeltaX;
			mY += mDeltaY;
			return YES;
		}
		[self rotateCCW45];
	}
	return NO;
}

-(float)weightedPositionAt:(int)x previous:(float)y0 current:(float)y1 next:(float)y2
{
	float a = y1 - y0;
	float b = y1 - y2;
	float k = a + b;
	if (k == 0)
		k = 0.5;
	else
		k = a / k;
	if (k > 1.0)
		k = 1.0;
	else if (k < 0.0)
		k = 0.0;
	return k + x;
}

-(BOOL)followLineAtX:(float *)outX y:(float *)outY
{
	if (mX < 0 || mX >= mWidth || mY < 0 || mY >= mHeight)
		return NO;
	if (![self unreadMaximumAtX:mX y:mY])
		return NO;

	if (outX)
		*outX = [self weightedPositionAt:mX
					previous:[self depthAtX:mX - 1 y:mY]
					current:[self depthAtX:mX y:mY]
					next:[self depthAtX:mX + 1 y:mY]];
	if (outY)
		*outY = [self weightedPositionAt:mY
					previous:[self depthAtX:mX y:mY - 1]
					current:[self depthAtX:mX y:mY]
					next:[self depthAtX:mX y:mY + 1]];
	mRead[mX + mY * mWidth] = YES;

	[self rotateCW90];
	if ([self followMaximum]) {
		float direction = atan2(mDeltaY, mDeltaX);
		float da = direction - mDirection;
		while (da > pi)
			da -= 2 * pi;
		while (da < -pi)
			da += 2 * pi;
		mDirection += 0.25 * da;
	} else {
		[self rotateCCW90];
		if (![self gotoMaximumAround:mX y:mY direction:mDirection pixelDistance:2] && ![self gotoMaximumAround:mX y:mY direction:mDirection pixelDistance:3])
			[self gotoNextMaximumInRange:3.0 + mSpacingTolerance];
	}
	return YES;
}

@end
