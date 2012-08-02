//
//  GCCustomProjection.m
//  GraphClick
//
//  Created by Simon Bovet on 24.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GCCustomProjection.h"

#import "GCAdjustmentWizard.h"
#import "GCView.h"

@implementation GCCustomProjection

-(id)init
{
	if (self = [super init]) {
		int n = [self numberOfParameters];
		if (n > 0)
			mParameters = (float *)malloc(n * sizeof(float));
		int i;
		for (i = 0; i < n; i++)
			mParameters[i] = 0.0;
	}
	return self;
}

-(id)initWithCoder:(NSCoder *)inCoder
{
	if (self = [super init]) {
		int n;
		[inCoder decodeValueOfObjCType:@encode(int) at:&n];
		if (n > 0)
			mParameters = (float *)malloc(n * sizeof(float));
		int i;
		for (i = 0; i < n; i++)
			[inCoder decodeValueOfObjCType:@encode(float) at:mParameters + i];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)inCoder
{
	int n = [self numberOfParameters];
	[inCoder encodeValueOfObjCType:@encode(int) at:&n];
	int i;
	for (i = 0; i < n; i++)
		[inCoder encodeValueOfObjCType:@encode(float) at:mParameters + i];
}

-(void)dealloc
{
	free(mParameters);
	[super dealloc];
}

-(BOOL)canShowFrame
{
	return NO;
}

-(NSString *)abscissaVariable
{
	return @"?";
}

-(NSString *)abscissaName
{
	return @"?";
}

-(NSString *)ordinateVariable
{
	return @"?";
}

-(NSString *)ordinateName
{
	return @"?";
}

-(NSPoint)convertToCoordinate:(NSPoint)inPoint
{
	[self doesNotRecognizeSelector:_cmd];
	return inPoint;
}

-(NSPoint)convertFromCoordinate:(NSPoint)inPoint
{
	[self doesNotRecognizeSelector:_cmd];
	return inPoint;
}

-(NSString *)name
{
	return NSStringFromClass([self class]);
}

-(NSString *)infoString
{
	return nil;
}

-(NSImage *)icon
{
	return nil;
}

-(int)numberOfParameters
{
	return 0;
}

-(float *)parameters
{
	return mParameters;
}

-(float)param:(int)inIndex
{
	return [self parameters][inIndex];
}

-(void)setParam:(int)inIndex value:(float)inValue
{
	[self parameters][inIndex] = inValue;
}

-(void)initializeParameters:(GCAdjustmentWizard *)inAdjustmentWizard
{
	int i, n = [self numberOfParameters];
	for (i = 0; i < n; i++)
		mParameters[i] = 0.0;
}

@end
