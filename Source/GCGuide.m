//
//  GCGuide.m
//  GraphClick
//
//  Created by Simon Bovet on 20.02.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GCGuide.h"


@implementation GCGuide

-(id)initWithCoder:(NSCoder *)inCoder
{
	if (self = [super init]) {
		[inCoder decodeValueOfObjCType:@encode(BOOL) at:&mVisible];
		[inCoder decodeValueOfObjCType:@encode(float) at:&mAddRadius];
		[inCoder decodeValueOfObjCType:@encode(float) at:&mMinRadius];
		[inCoder decodeValueOfObjCType:@encode(float) at:&mDeltaRadius];
		[inCoder decodeValueOfObjCType:@encode(int) at:&mKind];
		[inCoder decodeValueOfObjCType:@encode(BOOL) at:&mRadii];
		mColor = [[inCoder decodeObject] retain];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)inCoder
{
	[inCoder encodeValueOfObjCType:@encode(BOOL) at:&mVisible];
	[inCoder encodeValueOfObjCType:@encode(float) at:&mAddRadius];
	[inCoder encodeValueOfObjCType:@encode(float) at:&mMinRadius];
	[inCoder encodeValueOfObjCType:@encode(float) at:&mDeltaRadius];
	[inCoder encodeValueOfObjCType:@encode(int) at:&mKind];
	[inCoder encodeValueOfObjCType:@encode(BOOL) at:&mRadii];
	[inCoder encodeObject:mColor];
}

-(id)init
{
	if (self = [super init]) {
		mVisible = YES;
		mAddRadius = 0;
		mMinRadius = 10;
		mDeltaRadius = 10;
		mKind = 0;
		mRadii = NO;
		mColor = [[NSColor redColor] retain];
	}
	return self;
}

-(void)dealloc
{
	[mColor release];
	[super dealloc];
}

-(BOOL)visible
{
	return mVisible;
}

-(void)setVisible:(BOOL)inVisible
{
	mVisible = inVisible;
}

-(float)radius
{
	return mMinRadius + mAddRadius;
}

-(float)addRadius
{
	return mAddRadius;
}

-(void)setAddRadius:(float)inAddRadius
{
	mAddRadius = inAddRadius;
}

-(float)minRadius
{
	return mMinRadius;
}

-(void)setMinRadius:(float)inMinRadius
{
	mMinRadius = inMinRadius;
}

-(float)deltaRadius
{
	return mDeltaRadius;
}

-(void)setDeltaRadius:(float)inDeltaRadius
{
	mDeltaRadius = inDeltaRadius;
}

-(int)kind
{
	return mKind;
}

-(void)setKind:(int)inKind
{
	mKind = inKind;
}

-(BOOL)radii
{
	return mRadii;
}

-(void)setRadii:(BOOL)inRadii
{
	mRadii = inRadii;
}

-(NSColor *)color
{
	return mColor;
}

-(void)setColor:(NSColor *)inColor
{
	if (inColor != mColor) {
		[mColor release];
		mColor = [inColor retain];
	}
}

-(void)drawAtPoint:(NSPoint)inPoint withWidth:(float)inWidth
{
	[NSBezierPath setDefaultLineWidth:inWidth];
	[[self color] set];
	NSRect rect = NSZeroRect;
	rect.origin = inPoint;
	rect = NSInsetRect(rect, -mMinRadius, -mMinRadius);
	float maxWidth = 2 * [self radius];
	while (rect.size.width <= maxWidth) {
		switch (mKind) {
			case 0:
				[[NSBezierPath bezierPathWithOvalInRect:rect] stroke];
				break;
			case 1:
				[NSBezierPath strokeRect:rect];
				break;
		}
		rect = NSInsetRect(rect, -mDeltaRadius, -mDeltaRadius);
	}
	rect = NSInsetRect(rect, mDeltaRadius, mDeltaRadius);

	if (mRadii) {
		float r;
		int alpha;
		for (alpha = 0; alpha < 180; alpha += 45) {
			float rad = pi * alpha / 180;
			if (mKind == 0 || (alpha / 45) % 2 == 0)
				r = rect.size.width / 2;
			else
				r = rect.size.width / sqrt(2);
			NSPoint radius = NSMakePoint(cos(rad) * r, sin(rad) * r);
			[NSBezierPath strokeLineFromPoint:NSMakePoint(inPoint.x + radius.x, inPoint.y + radius.y) toPoint:NSMakePoint(inPoint.x - radius.x, inPoint.y - radius.y)];
		}
	}
}

@end

@implementation GCGuidePreview

-(void)dealloc
{
	[self setGuide:nil];
	[super dealloc];
}

-(void)setGuide:(GCGuide *)inGuide
{
	if (mGuide != inGuide) {
		[mGuide removeObserver:self forKeyPath:@"addRadius"];
		[mGuide removeObserver:self forKeyPath:@"minRadius"];
		[mGuide removeObserver:self forKeyPath:@"deltaRadius"];
		[mGuide removeObserver:self forKeyPath:@"kind"];
		[mGuide removeObserver:self forKeyPath:@"radii"];
		[mGuide removeObserver:self forKeyPath:@"color"];
		[mGuide release];
		mGuide = [inGuide retain];
		[mGuide addObserver:self forKeyPath:@"addRadius" options:NSKeyValueObservingOptionNew context:nil];
		[mGuide addObserver:self forKeyPath:@"minRadius" options:NSKeyValueObservingOptionNew context:nil];
		[mGuide addObserver:self forKeyPath:@"deltaRadius" options:NSKeyValueObservingOptionNew context:nil];
		[mGuide addObserver:self forKeyPath:@"kind" options:NSKeyValueObservingOptionNew context:nil];
		[mGuide addObserver:self forKeyPath:@"radii" options:NSKeyValueObservingOptionNew context:nil];
		[mGuide addObserver:self forKeyPath:@"color" options:NSKeyValueObservingOptionNew context:nil];
	}
}

-(void)drawRect:(NSRect)inRect
{
	[mGuide drawAtPoint:NSMakePoint(NSMidX([self bounds]), NSMidY([self bounds])) withWidth:1.0];
}

-(void)observeValueForKeyPath:(NSString *)inKeyPath ofObject:(id)inObject
	change:(NSDictionary *)inChange context:(void *)context
{
	[self setNeedsDisplay:YES];
}

@end