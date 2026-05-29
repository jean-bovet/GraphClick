//
//  GCPoint.m
//  GraphClick
//
//  Created by Simon Bovet on 02.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GCPoint.h"

#import "GCSerie.h"
#import "GCFrame.h"
#import "GCFoundation.h"

static float sTime = 0.0;

@implementation GCPoint

-(id)initWithCoder:(NSCoder *)inCoder
{
	if (self = [self init]) {
		mSerie = [inCoder decodeObject];
		mPoint = [inCoder gcDecodePoint];
		if ([inCoder versionForClassName:@"GCPoint"] >= 1) {
			[inCoder decodeValueOfObjCType:@encode(float) at:&mXMinError];
			[inCoder decodeValueOfObjCType:@encode(float) at:&mXMaxError];
			[inCoder decodeValueOfObjCType:@encode(float) at:&mYMinError];
			[inCoder decodeValueOfObjCType:@encode(float) at:&mYMaxError];
		}
		if ([inCoder versionForClassName:@"GCPoint"] >= 2)
			[inCoder decodeValueOfObjCType:@encode(float) at:&mTime];
		if ([inCoder versionForClassName:@"GCPoint"] >= 3)
			mLabel = [[inCoder decodeObject] retain];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)inCoder
{
	[GCPoint setVersion:3];
	[inCoder encodeConditionalObject:mSerie];
	[inCoder encodeObject:[NSValue valueWithPoint:mPoint]];
	if ([GCPoint version] >= 1) {
		[inCoder encodeValueOfObjCType:@encode(float) at:&mXMinError];
		[inCoder encodeValueOfObjCType:@encode(float) at:&mXMaxError];
		[inCoder encodeValueOfObjCType:@encode(float) at:&mYMinError];
		[inCoder encodeValueOfObjCType:@encode(float) at:&mYMaxError];
	}
	if ([GCPoint version] >= 2)
		[inCoder encodeValueOfObjCType:@encode(float) at:&mTime];
	if ([GCPoint version] >= 3)
		[inCoder encodeObject:mLabel];
}

-(id)initWithPoint:(NSPoint)inPoint
{
	if (self = [super init]) {
		mPoint = inPoint;
		mTime = sTime;
	}
	return self;
}

-(void)dealloc
{
	[mLabel release];
	[super dealloc];
}

-(GCSerie *)serie
{
	return mSerie;
}

-(void)setSerie:(GCSerie *)inSerie
{
	mSerie = inSerie;
}

-(NSPoint)point
{
	return mPoint;
}

-(void)setPoint:(NSPoint)inPoint
{
	mPoint = inPoint;
}

@end

@implementation GCPoint (Coordinates)

-(id)index
{
	if (mLabel)
		return mLabel;
	unsigned i = [[mSerie points] indexOfObjectIdenticalTo:self];
	i = i == NSNotFound ? 0 : i + 1;
	return [NSNumber numberWithUnsignedInt:i];
}

-(void)setIndex:(id)inIndex
{
	[mLabel autorelease];
	mLabel = nil;
	if ([inIndex respondsToSelector:@selector(length)] && [inIndex length] > 0)
		mLabel = [inIndex retain];
}

-(NSPoint)convertToCoordinate:(NSPoint)inPoint
{
	[mSerie useFrameLimits];
	return [[mSerie frame] convertToCoordinate:inPoint];
}

-(NSPoint)convertFromCoordinate:(NSPoint)inPoint
{
	[mSerie useFrameLimits];
	return [[mSerie frame] convertFromCoordinate:inPoint];
}

-(void)beginEditing
{
	[[mSerie frame] beginEditing];
}

-(void)endEditing
{
	[[mSerie frame] endEditing];
}

-(NSPoint)pointWithError:(NSPoint)inDelta
{
	NSPoint pt = [self convertToCoordinate:mPoint];
	pt.x += inDelta.x;
	pt.y += inDelta.y;
	return [self convertFromCoordinate:pt];
}

-(NSPoint)coordinatePoint
{
	return [self convertToCoordinate:mPoint];
}

-(float)xCoordinate
{
	return [self convertToCoordinate:mPoint].x;
}

-(void)setXCoordinate:(float)inValue
{
	NSPoint pt = [self convertToCoordinate:mPoint];
	if (pt.x != inValue) {
		[self beginEditing];
		pt.x = inValue;
		mPoint = [self convertFromCoordinate:pt];
		[self endEditing];
	}
}

-(float)yCoordinate
{
	return [self convertToCoordinate:mPoint].y;
}

-(void)setYCoordinate:(float)inValue
{
	NSPoint pt = [self convertToCoordinate:mPoint];
	if (pt.y != inValue) {
		[self beginEditing];
		pt.y = inValue;
		mPoint = [self convertFromCoordinate:pt];
		[self endEditing];
	}
}

-(float)xMinError
{
	return mXMinError;
}

-(void)setXMinError:(float)inError
{
	if (mXMinError != inError) {
		[self beginEditing];
		mXMinError = inError;
		[self endEditing];
	}
}

-(float)xMaxError
{
	return mXMaxError;
}

-(void)setXMaxError:(float)inError
{
	if (mXMaxError != inError) {
		[self beginEditing];
		mXMaxError = inError;
		[self endEditing];
	}
}

-(float)yMinError
{
	return mYMinError;
}

-(void)setYMinError:(float)inError
{
	if (mYMinError != inError) {
		[self beginEditing];
		mYMinError = inError;
		[self endEditing];
	}
}

-(float)yMaxError
{
	return mYMaxError;
}

-(void)setYMaxError:(float)inError
{
	if (mYMaxError != inError) {
		[self beginEditing];
		mYMaxError = inError;
		[self endEditing];
	}
}

-(float)distance
{
	return mDistance;
}

-(void)setDistance:(float)inDistance
{
	mDistance = inDistance;
}

-(float)minDistance
{
	return mMinDistance;
}

-(void)setMinDistance:(float)inMinDistance
{
	mMinDistance = inMinDistance;
}

-(float)maxDistance
{
	return mMaxDistance;
}

-(void)setMaxDistance:(float)inMaxDistance
{
	mMaxDistance = inMaxDistance;
}

-(float)angle
{
	return mAngle;
}

-(void)setAngle:(float)inAngle
{
	mAngle = inAngle;
}

-(float)minAngle
{
	return mMinAngle;
}

-(void)setMinAngle:(float)inMinAngle
{
	mMinAngle = inMinAngle;
}

-(float)maxAngle
{
	return mMaxAngle;
}

-(void)setMaxAngle:(float)inMaxAngle
{
	mMaxAngle = inMaxAngle;
}

-(float)speed
{
	return mSpeed;
}

-(void)setSpeed:(float)inSpeed
{
	mSpeed = inSpeed;
}

-(float)minSpeed
{
	return mMinSpeed;
}

-(void)setMinSpeed:(float)inMinSpeed
{
	mMinSpeed = inMinSpeed;
}

-(float)maxSpeed
{
	return mMaxSpeed;
}

-(void)setMaxSpeed:(float)inMaxSpeed
{
	mMaxSpeed = inMaxSpeed;
}

-(float)xSpeed
{
	return mXSpeed;
}

-(void)setXSpeed:(float)inSpeed
{
	mXSpeed = inSpeed;
}

-(float)minXSpeed
{
	return mMinXSpeed;
}

-(void)setMinXSpeed:(float)inMinSpeed
{
	mMinXSpeed = inMinSpeed;
}

-(float)maxXSpeed
{
	return mMaxXSpeed;
}

-(void)setMaxXSpeed:(float)inMaxSpeed
{
	mMaxXSpeed = inMaxSpeed;
}

-(float)ySpeed
{
	return mYSpeed;
}

-(void)setYSpeed:(float)inSpeed
{
	mYSpeed = inSpeed;
}

-(float)minYSpeed
{
	return mMinYSpeed;
}

-(void)setMinYSpeed:(float)inMinSpeed
{
	mMinYSpeed = inMinSpeed;
}

-(float)maxYSpeed
{
	return mMaxYSpeed;
}

-(void)setMaxYSpeed:(float)inMaxSpeed
{
	mMaxYSpeed = inMaxSpeed;
}

-(float)errorOn:(float)inValue min:(float)inMin max:(float)inMax
{
	return MAX(fabs(inValue - inMin), fabs(inMax - inValue));
}

-(float)distanceError
{
	return [self errorOn:mDistance min:mMinDistance max:mMaxDistance];
}

-(float)angleError
{
	return [self errorOn:mAngle min:mMinAngle max:mMaxAngle];
}

-(float)speedError
{
	return [self errorOn:mSpeed min:mMinSpeed max:mMaxSpeed];
}

-(float)xSpeedError
{
	return [self errorOn:mXSpeed min:mMinXSpeed max:mMaxXSpeed];
}

-(float)ySpeedError
{
	return [self errorOn:mYSpeed min:mMinYSpeed max:mMaxYSpeed];
}

@end

@implementation GCPoint (Time)

+(void)setCurrentTime:(float)inTime
{
	sTime = inTime;
}

-(float)time
{
	return mTime;
}

-(void)setTime:(float)inTime
{
	mTime = inTime;
}

@end
