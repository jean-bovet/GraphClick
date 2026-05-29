//
//  GCFrame.m
//  GraphClick
//
//  Created by Simon Bovet on 03.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GCFrame.h"

#import "GCFoundation.h"
#import "GCCustomProjection.h"

@interface GCFrame (Private)

-(NSPoint)convert:(NSPoint)inPoint;
-(NSPoint)unconvert:(NSPoint)inPoint;
-(void)sortDeformations;

@end

@implementation GCFrame

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"coordinateSystemType"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"customProjection"]];
    }
    if ([key isEqualToString:@"customProjectionName"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"customProjection"]];
    }
    if ([key isEqualToString:@"customProjectionIcon"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"customProjection"]];
    }
    return keyPaths;
}

-(id)initWithCoder:(NSCoder *)inCoder
{
	if (self = [super init]) {
		mSeries = [[inCoder decodeObject] retain];
		mCorners = [[inCoder decodeObject] retain];
		if ([inCoder versionForClassName:@"GCFrame"] >= 1)
			mDeformations = [[inCoder decodeObject] retain];
		else
			mDeformations = [[NSMutableArray alloc] initWithCapacity:0];
		[self sortDeformations];
		if ([inCoder versionForClassName:@"GCFrame"] >= 2)
			mMask = [[inCoder decodeObject] retain];
		mMin = [inCoder gcDecodePoint];
		mMax = [inCoder gcDecodePoint];
		[inCoder decodeValueOfObjCType:@encode(GCScale) at:&mXScale];
		[inCoder decodeValueOfObjCType:@encode(GCScale) at:&mYScale];
		if ([inCoder versionForClassName:@"GCFrame"] >= 3)
			[inCoder decodeValueOfObjCType:@encode(GCScale) at:&mUsePixelCoordinates];
		if ([inCoder versionForClassName:@"GCFrame"] >= 4) {
			mFrameLimits = [[inCoder decodeObject] retain];
			[inCoder decodeValueOfObjCType:@encode(int) at:&mCurrentFrameLimitIndex];
		}
		if ([inCoder versionForClassName:@"GCFrame"] >= 5)
			mCustomProjection = [[inCoder decodeObject] retain];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)inCoder
{
	[GCFrame setVersion:5];
	[inCoder encodeObject:mSeries];
	[inCoder encodeObject:mCorners];
	if ([GCFrame version] >= 1)
		[inCoder encodeObject:mDeformations];
	if ([GCFrame version] >= 2)
		[inCoder encodeObject:mMask];
	[inCoder encodeObject:[NSValue valueWithPoint:mMin]];
	[inCoder encodeObject:[NSValue valueWithPoint:mMax]];
	[inCoder encodeValueOfObjCType:@encode(GCScale) at:&mXScale];
	[inCoder encodeValueOfObjCType:@encode(GCScale) at:&mYScale];
	if ([inCoder versionForClassName:@"GCFrame"] >= 3)
		[inCoder encodeValueOfObjCType:@encode(GCScale) at:&mUsePixelCoordinates];
	if ([inCoder versionForClassName:@"GCFrame"] >= 4) {
		[self saveCurrentFrameLimits];
		[inCoder encodeObject:mFrameLimits];
		[inCoder encodeValueOfObjCType:@encode(int) at:&mCurrentFrameLimitIndex];
	}
	if ([inCoder versionForClassName:@"GCFrame"] >= 5)
		[inCoder encodeObject:mCustomProjection];
}

-(id)init
{
	if (self = [super init]) {
		mSeries = [[NSMutableArray alloc] initWithCapacity:10];
		mDeformations = [[NSMutableArray alloc] initWithCapacity:0];
		mGuideLines = [[NSMutableArray alloc] initWithCapacity:0];
		
		GCSerie *serie = [[GCSerie alloc] init];
		[serie setFrame:self];
		[mSeries addObject:serie];
		[serie release];
	}
	return self;
}

-(void)dealloc
{
	[mSeries release];
	[mGuideLines release];
	[mCorners release];
	[mDeformations release];
	[mSelectedDeformations release];
	[mMask release];
	[mFrozenCorners release];
	[mFrameLimits release];
	[super dealloc];
}

-(void)didChange
{
	NSEnumerator *serieEnumerator = [mSeries objectEnumerator];
	GCSerie *serie;
	while (serie = [serieEnumerator nextObject]) {
		[serie invalidateAreaParameters];
		
		NSEnumerator *pointEnumerator = [[serie points] objectEnumerator];
		GCPoint *point;
		while (point = [pointEnumerator nextObject]) {
			[point willChangeValueForKey:@"xCoordinate"];
			[point willChangeValueForKey:@"yCoordinate"];
			[point didChangeValueForKey:@"xCoordinate"];
			[point didChangeValueForKey:@"yCoordinate"];
		}
	}

	NSEnumerator *deformationEnumerator = [mDeformations objectEnumerator];
	GCDeformation *deformation;
	while (deformation = [deformationEnumerator nextObject]) {
		[deformation willChangeValueForKey:@"yCoordinate"];
		[deformation didChangeValueForKey:@"yCoordinate"];
	}

	[self appearanceDidChange];
}

-(void)appearanceDidChange
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GCFrameAppearanceDidChangeNotification object:self];
}

float scale(float x, GCScale scale, float min, float max)
{
	switch (scale) {
		case GCLinearScale:
			return min + x * (max - min);
		case GCLogScale:
			return pow(10.0, log10(min) + x * (log10(max) - log10(min)));
		case GCInverseScale:
			return 1.0 / (1.0 / min + x * (1 / max - 1.0 / min));
	}
}

-(NSPoint)convert:(NSPoint)inPoint
{
	NSArray *corners = mFrozen ? mFrozenCorners : mCorners;
	NSPoint a = [[corners objectAtIndex:0] pointValue];
	NSPoint b = [[corners objectAtIndex:1] pointValue];
	NSPoint c = [[corners objectAtIndex:2] pointValue];
	NSPoint d = [[corners objectAtIndex:3] pointValue];
	
	NSPoint A = NSMakePoint(inPoint.x - a.x, inPoint.y - a.y);
	NSPoint B = NSMakePoint(b.x - a.x, b.y - a.y);
	NSPoint C = NSMakePoint(d.x - a.x, d.y - a.y);
	NSPoint D = NSMakePoint(a.x - b.x + c.x - d.x, a.y - b.y + c.y - d.y);
	
	float alpha = D.x * C.y - C.x * D.y;
	float beta = B.x * C.y + A.x * D.y - D.x * A.y - C.x * B.y;
	float gamma = A.x * B.y - B.x * A.y;

	NSPoint pt;
	if (alpha == 0.0) {
		pt.y = -gamma / beta;
	} else {
		if (beta == 0.0)
			pt.y = sqrt(-gamma / alpha);
		else {
			alpha /= beta;
			gamma /= beta;
			float delta = 4.0 * alpha * gamma;
			if (fabs(delta) < 1e-10)
				pt.y = -delta / (4.0 * alpha);
			else
				pt.y = (-1.0 + sqrt(1.0 - delta)) / (2.0 * alpha);
		}
	}
	pt.x = (A.x - pt.y * C.x) / (B.x + pt.y * D.x);
	
	return pt;
}

-(NSPoint)scale:(NSPoint)inPoint
{
	if (mFrozen)
		return NSMakePoint(scale(inPoint.x, mXScale, mFrozenMin.x, mFrozenMax.x), scale(inPoint.y, mYScale, mFrozenMin.y, mFrozenMax.y));
	else
		return NSMakePoint(scale(inPoint.x, mXScale, mMin.x, mMax.x), scale(inPoint.y, mYScale, mMin.y, mMax.y));
}

-(NSPoint)convertToCoordinate:(NSPoint)inPoint
{
	if (mCustomProjection)
		return [mCustomProjection convertToCoordinate:inPoint];
	else if (mUsePixelCoordinates)
		return NSMakePoint(inPoint.x - mImageOrigin.x, inPoint.y - mImageOrigin.y);
	else
		return [self scale:[self undeform:[self convert:inPoint]]];
}

float unscale(float x, GCScale scale, float min, float max)
{
	switch (scale) {
		case GCLinearScale:
			return (x - min) / (max - min);
		case GCLogScale:
			return (log10(x) - log10(min)) / (log10(max) - log10(min));
		case GCInverseScale:
			return (1.0 / x - 1.0 / min) / (1.0 / max - 1.0 / min);
	}
}

-(NSPoint)unscale:(NSPoint)inPoint
{
	NSPoint pt;
	if (mFrozen) {
		pt.x = unscale(inPoint.x, mXScale, mFrozenMin.x, mFrozenMax.x);
		pt.y = unscale(inPoint.y, mYScale, mFrozenMin.y, mFrozenMax.y);
	} else {
		pt.x = unscale(inPoint.x, mXScale, mMin.x, mMax.x);
		pt.y = unscale(inPoint.y, mYScale, mMin.y, mMax.y);
	}
	return pt;
}
	
-(NSPoint)unconvert:(NSPoint)inPoint
{
	NSArray *corners = mFrozen ? mFrozenCorners : mCorners;
	NSPoint a = [[corners objectAtIndex:0] pointValue];
	NSPoint b = [[corners objectAtIndex:1] pointValue];
	NSPoint c = [[corners objectAtIndex:2] pointValue];
	NSPoint d = [[corners objectAtIndex:3] pointValue];
	
	NSPoint pt;
	pt.x = a.x + inPoint.x * (b.x - a.x) + inPoint.y * (d.x - a.x) + inPoint.x * inPoint.y * (a.x - b.x + c.x - d.x);
	pt.y = a.y + inPoint.x * (b.y - a.y) + inPoint.y * (d.y - a.y) + inPoint.x * inPoint.y * (a.y - b.y + c.y - d.y);
	return pt;
}

-(NSPoint)convertFromCoordinate:(NSPoint)inPoint
{
	if (mCustomProjection)
		return [mCustomProjection convertFromCoordinate:inPoint];
	else if (mUsePixelCoordinates)
		return NSMakePoint(inPoint.x + mImageOrigin.x, inPoint.y + mImageOrigin.y);
	else
		return [self unconvert:[self deform:[self unscale:inPoint]]];
}

-(BOOL)canShowFrame
{
	if (mCustomProjection)
		return [mCustomProjection canShowFrame];
	return ![self usePixelCoordinates];
}

-(NSArray *)customProjectionDependentKeys
{
	return [NSArray arrayWithObjects:@"customProjection", @"canShowFrame", @"abscissaVariable", @"abscissaName", @"ordinateVariable", @"ordinateName", nil];
}

-(int)coordinateSystemType
{
	if ([self customProjection])
		return 1;
	else
		return 0;
}

-(GCCustomProjection *)customProjection
{
	return mCustomProjection;
}

-(NSString *)customProjectionName
{
	return [mCustomProjection name];
}

-(NSData *)customProjectionIcon
{
	return [[mCustomProjection icon] TIFFRepresentation];
}

-(void)setCustomProjection:(GCCustomProjection *)inCustomProjection
{
	if (mCustomProjection != inCustomProjection) {
		NSEnumerator *enumerator = [[self customProjectionDependentKeys] objectEnumerator];
		NSString *key;
		while (key = [enumerator nextObject])
			[self willChangeValueForKey:key];
		[mCustomProjection release];
		mCustomProjection = [inCustomProjection retain];
		enumerator = [[self customProjectionDependentKeys] objectEnumerator];
		while (key = [enumerator nextObject])
			[self didChangeValueForKey:key];
	}
}

@end

@implementation GCFrame (Corners)

-(void)setFrameRect:(NSRect)inRect
{
	[mCorners release];
	mCorners = [[NSMutableArray alloc] initWithCapacity:4];
	[mCorners addObject:[NSValue valueWithPoint:NSMakePoint(NSMinX(inRect), NSMinY(inRect))]];
	[mCorners addObject:[NSValue valueWithPoint:NSMakePoint(NSMaxX(inRect), NSMinY(inRect))]];
	[mCorners addObject:[NSValue valueWithPoint:NSMakePoint(NSMaxX(inRect), NSMaxY(inRect))]];
	[mCorners addObject:[NSValue valueWithPoint:NSMakePoint(NSMinX(inRect), NSMaxY(inRect))]];

	[self willChangeValueForKey:@"xMin"];
	[self willChangeValueForKey:@"yMin"];
	[self willChangeValueForKey:@"xMax"];
	[self willChangeValueForKey:@"yMax"];
	[self willChangeValueForKey:@"xScale"];
	[self willChangeValueForKey:@"yScale"];
	mMin = NSMakePoint(0.0, 0.0);
	mMax = NSMakePoint(10.0, 10.0);
	mXScale = GCLinearScale;
	mYScale = GCLinearScale;
	[self didChangeValueForKey:@"xMin"];
	[self didChangeValueForKey:@"yMin"];
	[self didChangeValueForKey:@"xMax"];
	[self didChangeValueForKey:@"yMax"];
	[self didChangeValueForKey:@"xScale"];
	[self didChangeValueForKey:@"yScale"];
}

-(NSPoint)cornerPoint:(int)inIndex
{
	return [[mCorners objectAtIndex:inIndex] pointValue];
}

-(void)setCorner:(int)inIndex point:(NSPoint)inPoint
{
	if (mFrozen) {
		NSPoint coordinate = [self convertToCoordinate:inPoint];
		if (inIndex == 0) {
			[self setXMin:coordinate.x];
			[self setYMin:coordinate.y];
		} else if (inIndex == 2) {
			[self setXMax:coordinate.x];
			[self setYMax:coordinate.y];
		}
	}
	[mCorners replaceObjectAtIndex:inIndex withObject:[NSValue valueWithPoint:inPoint]];
}

-(void)setNilValueForKey:(NSString *)inKey
{
	[self setValue:[NSNumber numberWithFloat:0.0] forKey:inKey];
}

-(void)setLimit:(id)inLimit
{
	[self setValue:[inLimit objectForKey:@"Value"] forKey:[inLimit objectForKey:@"Key"]];
}

-(void)checkValueOfKey:(NSString *)inKey withScale:(GCScale)inScale displayAlert:(BOOL)inDisplay
{
	float value = [[self valueForKey:inKey] floatValue];
	switch (inScale) {
		case GCLinearScale:
			break;
		case GCLogScale:
			if (value <= 0) {
				NSDictionary *limit = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:1.0], @"Value", inKey, @"Key", nil];
				if (inDisplay) {
					NSRunInformationalAlertPanel(NSLocalizedString(@"Invalid Log Limit Value Title", @""), NSLocalizedString(@"Invalid Log Limit Value Message", @""), nil, nil, nil);
					[self performSelector:@selector(setLimit:) withObject:limit afterDelay:0.0];
				} else
					[self setLimit:limit];
			}
			break;
		case GCInverseScale:
			if (value == 0) {
				NSDictionary *limit = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:1.0], @"Value", inKey, @"Key", nil];
				if (inDisplay) {
					NSRunInformationalAlertPanel(NSLocalizedString(@"Invalid Inverse Limit Value Title", @""), NSLocalizedString(@"Invalid Inverse Limit Value Message", @""), nil, nil, nil);
					[self performSelector:@selector(setLimit:) withObject:limit afterDelay:0.0];
				} else
					[self setLimit:limit];
			}
			break;
	}
}

-(float)xMin
{
	return mMin.x;
}

-(float)xMax
{
	return mMax.x;
}

-(float)yMin
{
	return mMin.y;
}

-(float)yMax
{
	return mMax.y;
}

-(void)setXMin:(float)inValue
{
	if (mMin.x != inValue) {
		[self willChangeValueForKey:@"xMin"];
		mMin.x = inValue;
		[self checkValueOfKey:@"xMin" withScale:mXScale displayAlert:YES];
		[self didChange];
		[self didChangeValueForKey:@"xMin"];
	}
}

-(void)setXMax:(float)inValue
{
	if (mMax.x != inValue) {
		[self willChangeValueForKey:@"xMax"];
		mMax.x = inValue;
		[self checkValueOfKey:@"xMax" withScale:mXScale displayAlert:YES];
		[self didChange];
		[self didChangeValueForKey:@"xMax"];
	}
}

-(void)setYMin:(float)inValue
{
	if (mMin.y != inValue) {
		[self willChangeValueForKey:@"yMin"];
		mMin.y = inValue;
		[self checkValueOfKey:@"yMin" withScale:mYScale displayAlert:YES];
		[self didChange];
		[self didChangeValueForKey:@"yMin"];
	}
}

-(void)setYMax:(float)inValue
{
	if (mMax.y != inValue) {
		[self willChangeValueForKey:@"yMax"];
		mMax.y = inValue;
		[self checkValueOfKey:@"yMax" withScale:mYScale displayAlert:YES];
		[self didChange];
		[self didChangeValueForKey:@"yMax"];
	}
}

-(GCScale)xScale
{
	return mXScale;
}

-(GCScale)yScale
{
	return mYScale;
}

-(void)setXScale:(GCScale)inScale
{
	if (mXScale != inScale) {
		[self willChangeValueForKey:@"xScale"];
		mXScale = inScale;
		[self checkValueOfKey:@"xMin" withScale:mXScale displayAlert:NO];
		[self checkValueOfKey:@"xMax" withScale:mXScale displayAlert:NO];
		[self didChange];
		[self didChangeValueForKey:@"xScale"];
	}
}

-(void)setYScale:(GCScale)inScale
{
	if (mYScale != inScale) {
		[self willChangeValueForKey:@"yScale"];
		mYScale = inScale;
		[self checkValueOfKey:@"yMin" withScale:mYScale displayAlert:NO];
		[self checkValueOfKey:@"yMax" withScale:mYScale displayAlert:NO];
		[self didChange];
		[self didChangeValueForKey:@"yScale"];
	}
}

-(BOOL)usePixelCoordinates
{
	return mUsePixelCoordinates;
}

-(void)setUsePixelCoordinates:(BOOL)inFlag
{
	if (mUsePixelCoordinates != inFlag) {
		mUsePixelCoordinates = inFlag;
		[self didChange];
	}
}

@end

@implementation GCFrame (Series)

-(NSArray *)series
{
	return mSeries;
}

-(unsigned)countOfSeries
{
	return [mSeries count];
}

-(GCPoint *)objectInSeriesAtIndex:(unsigned)inIndex
{
	return [mSeries objectAtIndex:inIndex];
}

-(void)insertObject:(GCSerie *)inSerie inSeriesAtIndex:(unsigned)inIndex
{
	[self beginEditing];
	[inSerie setFrame:self];
	[mSeries insertObject:inSerie atIndex:inIndex];
	[self endEditing];
}

-(void)removeObjectFromSeriesAtIndex:(unsigned)inIndex
{
	[self beginEditing];
	[mSeries removeObjectAtIndex:inIndex];
	[self endEditing];
}

@end

@implementation GCFrame (Editing)

-(void)freeze
{
	mFrozen = YES;
	[mFrozenCorners release];
	mFrozenCorners = [mCorners copy];
	mFrozenMin = mMin;
	mFrozenMax = mMax;
}

-(void)unfreeze
{
	mFrozen = NO;
	[mFrozenCorners release];
	mFrozenCorners = nil;
}

-(void)beginEditing
{
	[self beginEditingImageWillChange:NO];
}

-(void)beginEditingImageWillChange:(BOOL)inImageWillChange
{
	if (mEditCount++ == 0) {
		[[NSNotificationCenter defaultCenter] postNotificationName:GCFrameWillChangeNotification object:self
			userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:inImageWillChange] forKey:@"ImageWillChange"]];
		[self freeze];
	}
}

-(void)endEditing
{
	if (--mEditCount == 0) {
		[self unfreeze];
		[[NSNotificationCenter defaultCenter] postNotificationName:GCFrameDidChangeNotification object:self];
	}
}

@end

@implementation GCFrame (Deformation)

NSInteger compareDeformations(id a, id b, void *context)
{
	float delta = [(GCDeformation *)b offset] - [(GCDeformation *)a offset];
	return delta == 0 ? 0 : delta < 0 ? -1 : 1;
}

-(void)sortDeformations
{
	[mDeformations sortUsingFunction:compareDeformations context:nil];
}

-(NSPoint)directionBetween:(NSPoint)inA and:(NSPoint)inB length:(float *)outLength
{
	NSPoint d = NSMakePoint(inB.x - inA.x, inB.y - inA.y);
	float dl = hypot(d.x, d.y);
	if (outLength)
		*outLength = dl;
	if (dl > 0) {
		d.x /= dl;
		d.y /= dl;
	}
	return d;
}

-(unsigned)addDeformationAtPoint:(NSPoint)inPoint withOffset:(float)inOffset
{
	NSPoint pt = [self convert:inPoint];
	if (pt.y <= 0.0 || pt.y >= 1.0)
		return NSNotFound;
	[self beginEditing];
	[self willChangeValueForKey:@"deformations"];
	if (pt.x > 0.5)
		pt.x -= 1.0;
	float offset = inOffset;
	if (offset < 0)
		offset = [self undeform:pt].y;
	id deformation = [GCDeformation deformationWithFrame:self position:pt offset:offset];
	[mDeformations addObject:deformation];
	[self sortDeformations];
	[self didChangeValueForKey:@"deformations"];
	[self endEditing];
	return [mDeformations indexOfObjectIdenticalTo:deformation];
}

-(void)removeDeformation:(unsigned)inIndex
{
	if (inIndex != NSNotFound) {
		[self willChangeValueForKey:@"deformations"];
		[mDeformations removeObjectAtIndex:inIndex];
		[self didChangeValueForKey:@"deformations"];
	}
}

-(void)removeDeformations
{
	[self willChangeValueForKey:@"deformations"];
	[mDeformations removeAllObjects];
	[self didChangeValueForKey:@"deformations"];
}

-(unsigned)numberOfDeformations
{
	return [mDeformations count];
}

-(float)offsetOfDeformationAtIndex:(unsigned)inIndex
{
	return [(GCDeformation *)[mDeformations objectAtIndex:inIndex] offset];
}

-(NSPoint)positionOfDeformationAtIndex:(unsigned)inIndex leftSide:(BOOL)inLeft
{
	return [self positionOfDeformation:[mDeformations objectAtIndex:inIndex] leftSide:inLeft];
}

-(NSPoint)positionOfDeformation:(id)inDeformation leftSide:(BOOL)inLeft
{
	NSPoint pt = [(GCDeformation *)inDeformation position];
	if (!inLeft)
		pt.x += 1.0;
	BOOL frozen = mFrozen;
	mFrozen = NO;
	pt = [self unconvert:pt];
	mFrozen = frozen;
	return pt;
}

-(NSPoint)deform:(NSPoint)inPoint
{
	unsigned n = [mDeformations count];
	if (n == 0)
		return inPoint;
	unsigned i = 0;
	float y0 = 0.0;
	float y1;
	while (i < n && inPoint.y > (y1 = [(GCDeformation *)[mDeformations objectAtIndex:n - i - 1] offset])) {
		y0 = y1;
		i++;
	}
	if (y1 == y0)
		y1 = 1.0;
	
	NSPoint before = NSMakePoint(0.0, 0.0);
	if (i > 0)
		before = [(GCDeformation *)[mDeformations objectAtIndex:n - i] position];
	NSPoint after = NSMakePoint(0.0, 1.0);
	if (i < n)
		after = [(GCDeformation *)[mDeformations objectAtIndex:n - i - 1] position];
	
	float k = (inPoint.y - y0) / (y1 - y0);
	inPoint.y = (1.0 - k) * before.y + k * after.y;
	inPoint.x += (1.0 - k) * before.x + k * after.x;
	return inPoint;
}

-(NSPoint)undeform:(NSPoint)inPoint
{
	unsigned n = [mDeformations count];
	if (n == 0)
		return inPoint;
	unsigned i = 0;
	float y0 = 0.0;
	float y1;
	while (i < n && inPoint.y > (y1 = [(GCDeformation *)[mDeformations objectAtIndex:n - i - 1] position].y)) {
		y0 = y1;
		i++;
	}
	if (y1 == y0)
		y1 = 1.0;
	
	NSPoint before = NSMakePoint(0.0, 0.0);
	float beforeOffset = 0.0;
	if (i > 0) {
		before = [(GCDeformation *)[mDeformations objectAtIndex:n - i] position];
		beforeOffset = [(GCDeformation *)[mDeformations objectAtIndex:n - i] offset];
	}
	NSPoint after = NSMakePoint(0.0, 1.0);
	float afterOffset = 1.0;
	if (i < n) {
		after = [(GCDeformation *)[mDeformations objectAtIndex:n - i - 1] position];
		afterOffset = [(GCDeformation *)[mDeformations objectAtIndex:n - i -1] offset];
	}
	
	float k = (inPoint.y - y0) / (y1 - y0);
	inPoint.y = (1.0 - k) * beforeOffset + k * afterOffset;
	inPoint.x -= (1.0 - k) * before.x + k * after.x;
	return inPoint;
}

-(unsigned)countOfDeformations
{
	return [mDeformations count];
}

-(GCDeformation *)objectInDeformationsAtIndex:(unsigned)inIndex
{
	return [mDeformations objectAtIndex:inIndex];
}

-(void)insertObject:(GCDeformation *)inDeformation inDeformationsAtIndex:(unsigned)inIndex
{
}

-(void)removeObjectFromDeformationsAtIndex:(unsigned)inIndex
{
	[self beginEditing];
	[mDeformations removeObject:[mDeformations objectAtIndex:inIndex]];
	[self endEditing];
}

-(id)selectedDeformations
{
	return mSelectedDeformations;
}

-(void)setSelectedDeformations:(id)inSelectedDeformations
{
	[self willChangeValueForKey:@"canRemoveDeformations"];
	[self willChangeValueForKey:@"selectedDeformations"];
	if (mSelectedDeformations != inSelectedDeformations) {
		[mSelectedDeformations release];
		mSelectedDeformations = [inSelectedDeformations retain];
	}
	[self didChangeValueForKey:@"canRemoveDeformations"];
	[self didChangeValueForKey:@"selectedDeformations"];
}

-(BOOL)isDeformationSelectedAtIndex:(unsigned)inIndex;
{
	return [mSelectedDeformations containsIndex:inIndex];
}

-(void)selectDeformationAtIndex:(unsigned)inIndex
{
	[self setSelectedDeformations:[NSIndexSet indexSetWithIndex:inIndex]];
}

-(BOOL)canRemoveDeformations
{
	return [mSelectedDeformations count] > 0;
}

-(void)removeSelectedDeformations
{
	if ([mSelectedDeformations count] > 0) {
		[self beginEditing];
		int i;
		for (i = [mDeformations count] - 1; i >= 0; i--)
			if ([self isDeformationSelectedAtIndex:i])
				[self removeDeformation:i];
		[self setSelectedDeformations:[NSIndexSet indexSet]];
		[self endEditing];
	}
}

@end

@implementation GCFrame (Mask)

-(GCMask *)mask
{
	return mMask;
}

-(GCMask *)maskWithBounds:(NSRect)inBounds
{
	if (!mMask)
		mMask = [[GCMask alloc] initWithBounds:inBounds];
	return mMask;
}
-(void)setMask:(GCMask *)inMask
{
	if (mMask != inMask) { 
		[mMask release];
		mMask = [inMask retain];
	}
}

@end

@implementation GCFrame (Image)

-(void)setImageOrigin:(NSPoint)inOrigin
{
	mImageOrigin = inOrigin;
	mImageOrigin.y += 1.0;
}

@end

@implementation GCFrame (GuideLines)

-(NSArray *)guideLines
{
	return mGuideLines;
}

-(void)addGuideLine:(GCGuideLine *)inGuideLine
{
	[mGuideLines addObject:inGuideLine];
}

-(void)removeGuideLine:(GCGuideLine *)inGuideLine
{
	[mGuideLines removeObject:inGuideLine];
}

-(void)removeGuideLines
{
	[mGuideLines removeAllObjects];
}

@end

@implementation GCFrame (FrameLimits)

enum {
	kHorizontalFrameLimitsMask = 1 << 0,
	kVerticalFrameLimitsMask = 1 << 1
};

-(void)saveCurrentFrameLimits
{
	if (!mFrameLimits)
		return;
	NSMutableDictionary *limits = [mFrameLimits objectAtIndex:mCurrentFrameLimitIndex];
	unsigned int mask = [[limits objectForKey:@"Mask"] unsignedIntValue];
	
	if ((mask & kHorizontalFrameLimitsMask) != 0) {
		[limits setFloat:mMin.x forKey:@"xMin"];
		[limits setFloat:mMax.x forKey:@"xMax"];
		[limits setInt:mXScale forKey:@"xScale"];
	}
	if ((mask & kVerticalFrameLimitsMask) != 0) {
		[limits setFloat:mMin.y forKey:@"yMin"];
		[limits setFloat:mMax.y forKey:@"yMax"];
		[limits setInt:mYScale forKey:@"yScale"];
	}
}

-(void)restoreCurrentFrameLimits
{
	if (!mFrameLimits)
		return;
	NSDictionary *limits = [mFrameLimits objectAtIndex:mCurrentFrameLimitIndex];
	unsigned int mask = [[limits objectForKey:@"Mask"] unsignedIntValue];
	id value;
	
	if ((mask & kHorizontalFrameLimitsMask) != 0) {
		[self willChangeValueForKey:@"xMin"];
		[self willChangeValueForKey:@"xMax"];
		[self willChangeValueForKey:@"xScale"];
		if ((value = [limits objectForKey:@"xMin"]))
			mMin.x = [value floatValue];
		if ((value = [limits objectForKey:@"xMax"]))
			mMax.x = [value floatValue];
		if ((value = [limits objectForKey:@"xScale"]))
			mXScale = [value intValue];
		[self didChangeValueForKey:@"xMin"];
		[self didChangeValueForKey:@"xMax"];
		[self didChangeValueForKey:@"xScale"];
	}
	if ((mask & kVerticalFrameLimitsMask) != 0) {
		[self willChangeValueForKey:@"yMin"];
		[self willChangeValueForKey:@"yMax"];
		[self willChangeValueForKey:@"yScale"];
		if ((value = [limits objectForKey:@"yMin"]))
			mMin.y = [value floatValue];
		if ((value = [limits objectForKey:@"yMax"]))
			mMax.y = [value floatValue];
		if ((value = [limits objectForKey:@"yScale"]))
			mYScale = [value intValue];
		[self didChangeValueForKey:@"yMin"];
		[self didChangeValueForKey:@"yMax"];
		[self didChangeValueForKey:@"yScale"];
	}
}

-(int)currentFrameLimitIndex
{
	return mCurrentFrameLimitIndex;
}

-(void)setCurrentFrameLimitIndex:(int)inIndex
{
	if (mCurrentFrameLimitIndex != inIndex) {
		[self willChangeValueForKey:@"currentFrameLimitIndex"];
		[self saveCurrentFrameLimits];
		mCurrentFrameLimitIndex = inIndex;
		[self restoreCurrentFrameLimits];
		[self didChange];
		[self didChangeValueForKey:@"currentFrameLimitIndex"];
	}
}

-(void)removeFrameLimitsAtIndex:(int)inIndex
{
	if (mCurrentFrameLimitIndex >= inIndex) {
		[self willChangeValueForKey:@"currentFrameLimitIndex"];
		[self saveCurrentFrameLimits];
		mCurrentFrameLimitIndex--;
		[self didChangeValueForKey:@"currentFrameLimitIndex"];
	}
	
	NSEnumerator *enumerator = [mSeries objectEnumerator];
	GCSerie *serie;
	while (serie = [enumerator nextObject])
		if ([serie frameLimitIndex] >= inIndex)
			[serie setFrameLimitIndex:[serie frameLimitIndex] - 1];
			
	[mFrameLimits removeObjectAtIndex:inIndex];
}

-(void)addFrameLimitsWithMask:(unsigned int)inMask
{
	if (!mFrameLimits)
		mFrameLimits = [[NSMutableArray alloc] initWithCapacity:0];
	[mFrameLimits addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:inMask], @"Mask", nil]];
}

-(BOOL)useAlternateOrdinateAxis
{
	return [mFrameLimits count] > 1;
}

-(void)setUseAlternateOrdinateAxis:(BOOL)inFlag
{
	if (inFlag) {
		while ([mFrameLimits count] < 2)
			[self addFrameLimitsWithMask:kVerticalFrameLimitsMask];
	} else
		if ([mFrameLimits count] > 1) {
			[self setCurrentFrameLimitIndex:0];
			[self removeFrameLimitsAtIndex:1];
		}
}

@end

@implementation GCFrame (Variables)

-(NSString *)abscissaVariable
{
	return mCustomProjection ? [mCustomProjection abscissaVariable] : @"x";
}

-(NSString *)abscissaName
{
	return mCustomProjection ? [mCustomProjection abscissaName] : @"x";
}

-(NSString *)ordinateVariable
{
	return mCustomProjection ? [mCustomProjection ordinateVariable] : @"y";
}

-(NSString *)ordinateName
{
	return mCustomProjection ? [mCustomProjection ordinateName] : @"y";
}

-(NSString *)deltaXMinus
{
	return [NSString stringWithFormat:NSLocalizedString(@"Delta %@ -", @""), [self abscissaVariable]];
}

-(NSString *)deltaXPlus
{
	return [NSString stringWithFormat:NSLocalizedString(@"Delta %@ +", @""), [self abscissaVariable]];
}

-(NSString *)deltaYMinus
{
	return [NSString stringWithFormat:NSLocalizedString(@"Delta %@ -", @""), [self ordinateVariable]];
}

-(NSString *)deltaYPlus
{
	return [NSString stringWithFormat:NSLocalizedString(@"Delta %@ +", @""), [self ordinateVariable]];
}

@end