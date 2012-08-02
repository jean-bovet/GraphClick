//
//  GCGuideLine.m
//  GraphClick
//
//  Created by Simon Bovet on 16.11.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GCGuideLine.h"


@implementation GCGuideLine

-(id)initWithPosition:(float)inPosition isVertical:(BOOL)inIsVertical
{
	if (self = [super init]) {
		mPosition = inPosition;
		mIsVertical = inIsVertical;
	}
	return self;
}

-(float)position
{
	return mPosition;
}

-(void)setPosition:(float)inPosition
{
	mPosition = inPosition;
}

-(BOOL)isVertical
{
	return mIsVertical;
}

@end
