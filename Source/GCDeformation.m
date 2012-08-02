//
//  GCDeformation.m
//  GraphClick
//
//  Created by Simon Bovet on 06.01.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GCDeformation.h"

#import "GCFrame.h"

@implementation GCDeformation

+(id)deformationWithFrame:(GCFrame *)inFrame position:(NSPoint)inPosition offset:(float)inOffset
{
	return [[[self alloc] initWithFrame:inFrame position:inPosition offset:inOffset] autorelease];
}

-(id)initWithCoder:(NSCoder *)inCoder
{
	if (self = [super init]) {
		mFrame = [inCoder decodeObject];
		[inCoder decodeValueOfObjCType:@encode(NSPoint) at:&mPosition];
		[inCoder decodeValueOfObjCType:@encode(float) at:&mOffset];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)inCoder
{
	[inCoder encodeConditionalObject:mFrame]; 
	[inCoder encodeValueOfObjCType:@encode(NSPoint) at:&mPosition];
	[inCoder encodeValueOfObjCType:@encode(float) at:&mOffset];
}

-(id)initWithFrame:(GCFrame *)inFrame position:(NSPoint)inPosition offset:(float)inOffset
{
	if (self = [super init]) {
		mFrame = inFrame;
		mPosition = inPosition;
		mOffset = inOffset;
	}
	return self;
}

-(NSPoint)position
{
	return mPosition;
}

-(float)offset
{
	return mOffset;
}

-(float)yCoordinate
{
	return [mFrame scale:NSMakePoint(0, mOffset)].y;
}

-(void)setYCoordinate:(float)inCoordinate
{
	[mFrame beginEditing];
	mOffset = [mFrame unscale:NSMakePoint(0, inCoordinate)].y;
	[mFrame endEditing];
	[mFrame didChange];
}

@end
