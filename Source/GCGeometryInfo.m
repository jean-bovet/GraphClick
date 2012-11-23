//
//  GCGeometryInfo.m
//  GraphClick
//
//  Created by Simon Bovet on 09.03.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GCGeometryInfo.h"

#import "GCFoundation.h"
#import "GCNumberFormatter.h"

#define GCGeometryInfoRecomputeNotification @"GCGeometryInfoRecomputeNotification"

//static float nan = 1.0 / 0.0;

@interface GCGeometryInfo (Private)

-(BOOL)isVisible;
-(BOOL)computing;

@end

@interface GCSerie (Private)

-(void)setDefinesArea:(BOOL)inDefinesArea;

@end

@implementation GCGeometryInfo

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"computedValues"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"computedPoints", @"length", @"area", @"definesArea", @"lengthTitle"]];
    }
    return keyPaths;
}

+(id)sharedInspector
{
	static id sharedInspector = nil;
	if (!sharedInspector)
		sharedInspector = [[self alloc] init];
	return sharedInspector;
}

-(void)awake
{
	[super awake];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recompute:)
						name:GCGeometryInfoRecomputeNotification object:self];
	
	[[GCDefaultsObserver sharedObserver] addObserver:self forValues:GCGeometryMinPixelError, GCGeometryShowError, GCGeometryAngleMeasure, nil];
	
	mPointsLock = [[NSConditionLock alloc] initWithCondition:0];
	
	[self startComputationThread];
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[mDataToCompute release];
	[mPointsLock release];
	[mComputedValues release];
	[super dealloc];
}

-(void)observeValueForKeyPath:(NSString *)inKeyPath ofObject:(id)inObject
	change:(NSDictionary *)inChange context:(void *)inContext
{
	[super observeValueForKeyPath:inKeyPath ofObject:inObject change:inChange context:inContext];
	if ([inKeyPath isEqual:@"values.GCGeometryMinPixelError"] || [inKeyPath isEqual:@"values.angleMeasure"])
		[self recompute];
	else if ([inKeyPath isEqual:@"values.GCGeometryShowError"]) {
		[self willChangeValueForKey:@"computedValues"];
		[self didChangeValueForKey:@"computedValues"];
	}
}

-(void)pointDidChange
{
	[super pointDidChange];
	[self recompute];
}

-(void)serieDidChange
{
	[super serieDidChange];
	[self recompute];
}

-(void)setNilValueForKey:(NSString *)inKey
{
	[self setValue:[NSNumber numberWithFloat:0.0] forKey:inKey];
}

@end

@implementation GCGeometryInfo (Defaults)

-(void)saveInspectorState:(id)inSender
{
	[super saveInspectorState:inSender];
	[self stopComputationThread];
}

@end

@implementation GCGeometryInfo (Public)

-(IBAction)copy:(id)inSender
{
	if ([self computing]) {
		NSBeep();
		return;
	}
	
	NSArray *columns = [mTableView tableColumns];
	if ([mTableView numberOfSelectedColumns] > 0)
		columns = [columns subarrayWithIndexes:[mTableView selectedColumnIndexes]];
	
	NSArray *rows = [mArrayController selectedObjects];
	if ([rows count] == 0)
		rows = [mArrayController arrangedObjects];
	
	NSMutableDictionary *columnSplits = [NSMutableDictionary dictionary];
	NSString *plusMinus = [NSString stringWithFormat:@" %C ", (unichar)0x00B1];
	
	NSEnumerator *rowEnumerator = [rows objectEnumerator];
	id row;
	while (row = [rowEnumerator nextObject]) {
		NSEnumerator *columnEnumerator = [columns objectEnumerator];
		GCGeometryTableColumn *column;
		while (column = [columnEnumerator nextObject]) {
			id value = [row valueForKey:[column boundValue]];
			int splits;
			if (![value isKindOfClass:[NSString class]])
				splits = 1;
			else if ([(NSString *)value length] == 0)
				splits = 0;
			else
				splits = [[value componentsSeparatedByString:plusMinus] count];
			id key = [NSValue valueWithPointer:column];
			[columnSplits setInt:MAX(splits, [columnSplits intForKey:key]) forKey:key];
		}
	}
	
	NSMutableString *string = [NSMutableString string];
	GCNumberFormatter *formatter = [GCNumberFormatter sharedFormatter];

	if ([rows count] > 0) {
		[string appendFormat:@"%@%@%@", [self lengthTitle], [NSString columnSeparator], [self length]];
		if ([self definesArea])
			[string appendFormat:@"%@%@%@%@", [NSString lineSeparator], NSLocalizedString(@"Area Export Title", @""), [NSString columnSeparator], [self area]];
/*		GCPoint *point = [(GCGeometryPoint *)[rows lastObject] point];
		if (isdefined([point distance])) {
			[string appendFormat:@"%@\t%@", NSLocalizedString(@"Length Export Title", @""), [formatter stringForFloat:[point distance]]];
			if ([[NSUserDefaults standardUserDefaults] boolForKey:GCGeometryShowError] && isdefined([point distanceError]))
				[string appendFormat:@"\t%C\t%@", 0x00B1, [formatter stringForFloat:[point distanceError]]];
		} */
		[string appendFormat:@"%@%@", [NSString lineSeparator], [NSString lineSeparator]];
	}

	NSEnumerator *columnEnumerator = [columns objectEnumerator];
	GCGeometryTableColumn *column;
	BOOL hasContent = NO;
	while (column = [columnEnumerator nextObject]) {
		int splits = [columnSplits intForKey:[NSValue valueWithPointer:column]];
		if (splits > 0) {
			hasContent = YES;
			[string appendString:[[column headerCell] stringValue]];
			[string appendString:[NSString columnSeparator]];
			for (; splits > 1; splits--)
				[string appendFormat:@"%C%@", (unichar)0x00B1, [NSString columnSeparator]];
		}
	}
	if (hasContent) {
		int l = [[NSString columnSeparator] length];
		[string replaceCharactersInRange:NSMakeRange([string length] - l, l) withString:[NSString lineSeparator]];

		BOOL unregistered = NO; //![[ARRegisterManager sharedManager] hasRegisteredApplication];
		int count = 0;
		rowEnumerator = [rows objectEnumerator];
		while (row = [rowEnumerator nextObject]) {
			NSEnumerator *columnEnumerator = [columns objectEnumerator];
			GCGeometryTableColumn *column;
			while (column = [columnEnumerator nextObject]) {
				int splits = [columnSplits intForKey:[NSValue valueWithPointer:column]];
				id value = [row valueForKey:[column boundValue]];
				if (![value isKindOfClass:[NSString class]]) {
					if ([[column identifier] isEqual:@"Number"])
						value = [NSString stringWithFormat:@"%i", [value intValue]];
					else
						value = [formatter stringForFloat:[value floatValue]];                    
                }
				id values = [value componentsSeparatedByString:plusMinus];
				int i;
				for (i = 0; i < splits; i++) {
					if (i < [values count])
						[string appendString:[values objectAtIndex:i]];
					[string appendString:[NSString columnSeparator]];
				}
			}
			int l = [[NSString columnSeparator] length];
			[string replaceCharactersInRange:NSMakeRange([string length] - l, l) withString:[NSString lineSeparator]];

			if (unregistered && ++count == 10) {
				[self displayLimitationTitle:NSLocalizedString(@"Unregistered Number Alert Title", @"")
					message:NSLocalizedString(@"Unregistered Number Alert Message", @"")];
				break;
			}
		}
	}
	
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[pasteboard setString:string forType:NSStringPboardType];
}

@end

@implementation GCGeometryInfo (Computation)

#define NEW_POINTS_AVAILABLE 1

-(BOOL)shouldRestartComputation
{
	return [mPointsLock condition] == NEW_POINTS_AVAILABLE;
}

-(NSPoint)pointOnErrorBoundsFrom:(GCPoint *)inPoint direction:(NSPoint)inDirection
{
	NSPoint pixelPoint = [inPoint point];
	NSPoint minPoint = [mFrame convertToCoordinate:NSMakePoint(pixelPoint.x - mMinPixelError, pixelPoint.y - mMinPixelError)];
	NSPoint maxPoint = [mFrame convertToCoordinate:NSMakePoint(pixelPoint.x + mMinPixelError, pixelPoint.y + mMinPixelError)];
	NSPoint point = [inPoint coordinatePoint];
	float errX = inDirection.x >= 0 ? MAX([inPoint xMaxError], maxPoint.x - point.x) : MIN([inPoint xMinError], point.x - minPoint.x);
	float errY = inDirection.y >= 0 ? MAX([inPoint yMaxError], maxPoint.y - point.y) : MAX([inPoint yMinError], point.y - minPoint.y);
	float dx = 0, dy = 0;
	if (inDirection.x == 0) {
		if (inDirection.y == 0)
			return point;
		dy = 1.0;
	} else
		if (errY == 0)
			dx = 1.0;
		else {
			float angle = atan(inDirection.y / inDirection.x * errX / errY);
			dx = cos(angle);
			dy = sin(angle);
		}
	point.x += dx * errX;
	point.y += dy * errY;
	return point;
}

-(float)angleFrom:(NSPoint)a at:(NSPoint)b to:(NSPoint)c
{
	if ((a.x == b.x && a.y == b.y) || (c.x == b.x && c.y == b.y))
		return nan(nil);
	float alpha;
	switch ([[NSUserDefaults standardUserDefaults] integerForKey:GCGeometryAngleMeasure]) {
		case 1:
			alpha = atan2(b.y - c.y, b.x - c.x) - atan2(b.y - a.y, b.x - a.x);
			break;
		default:
			alpha = atan2(c.y - b.y, c.x - b.x) - atan2(b.y - a.y, b.x - a.x);
			break;
	}
	if (alpha > pi)
		return alpha - 2 * pi;
	else if (alpha < -pi)
		return alpha + 2 * pi;
	else
		return alpha;
}

-(NSPoint)rotatePoint:(NSPoint)inPoint withAngle:(float)inAngle
{
	float c = cos(inAngle), s = sin(inAngle);
	return NSMakePoint(c * inPoint.x - s * inPoint.y, s * inPoint.x + c * inPoint.y);
}

-(void)calculateSpeed:(float *)outSpeed min:(float *)outMinSpeed max:(float *)outMaxSpeed
	xComponent:(float *)outSpeedX min:(float *)outMinSpeedX max:(float *)outMaxSpeedX
	yComponent:(float *)outSpeedY min:(float *)outMinSpeedY max:(float *)outMaxSpeedY
	from:(GCPoint *)inSource to:(GCPoint *)inTarget
{
	float dt = [inTarget time] - [inSource time];
	if (dt == 0) {
		*outSpeed = *outMinSpeed = *outMaxSpeed = 
		*outSpeedX = *outMinSpeedX = *outMaxSpeedX = 
		*outSpeedY = *outMinSpeedY = *outMaxSpeedY = nan(nil);
		return;
	}
	NSPoint source = [inSource coordinatePoint];
	NSPoint target = [inTarget coordinatePoint];
	NSPoint forward = NSMakePoint(target.x - source.x, target.y - source.y);
	if (forward.x == 0 && forward.y == 0) {
		*outSpeed = *outMinSpeed = *outMaxSpeed = 0;
		return;
	}
	NSPoint backward = NSMakePoint(-forward.x, -forward.y);
	NSPoint farthestBack = [self pointOnErrorBoundsFrom:inSource direction:backward];
	NSPoint closestBack = [self pointOnErrorBoundsFrom:inSource direction:forward];
	NSPoint closestForward = [self pointOnErrorBoundsFrom:inTarget direction:backward];
	NSPoint farthestForward = [self pointOnErrorBoundsFrom:inTarget direction:forward];
	float d = hypot(target.x - source.x, target.y - source.y);
	float d1 = hypot(target.x - closestBack.x, target.y - closestBack.y);
	float d2 = hypot(closestForward.x - closestBack.x, closestForward.y - closestBack.y);
	float d3 = hypot(closestForward.x - source.x, closestForward.y - source.y);
	
	float k = 1.0 / dt;
	*outSpeed = d * k;
	*outMinSpeed = MIN(MIN(d, d1), MIN(d2, d3)) * k;
	*outMaxSpeed = hypot(farthestForward.x - farthestBack.x, farthestForward.y - farthestBack.y) * k;

	*outSpeedX = (target.x - source.x) * k;
	*outMinSpeedX = MIN(MIN(target.x - source.x, target.x - closestBack.x), MIN(closestForward.x - closestBack.x, closestForward.x - source.x)) * k;
	*outMaxSpeedX = (farthestForward.x - farthestBack.x) * k;

	*outSpeedY = (target.y - source.y) * k;
	*outMinSpeedY = MIN(MIN(target.y - source.y, target.y - closestBack.y), MIN(closestForward.y - closestBack.y, closestForward.y - source.y)) * k;
	*outMaxSpeedY = (farthestForward.y - farthestBack.y) * k;
}

float mean(float x, float y)
{
	if (!isdefined(x))
		return y;
	else if (!isdefined(y))
		return x;
	else
		return 0.5 * (x + y);
}

-(NSDictionary *)compute:(NSDictionary *)inData
{
	NSMutableArray *computedPoints = [NSMutableArray array];
	NSArray *points = [inData objectForKey:@"Points"];
	GCSerie *serie = nil;
	if (!points)
		points = [(serie = [inData objectForKey:@"Serie"]) points];
	int i, n = [points count];
	if (n > 0) {
		GCPoint *previousPoint;
		GCPoint *currentPoint;
		GCPoint *nextPoint;
		currentPoint = nextPoint = [points objectAtIndex:0];
		mFrame = [[nextPoint serie] frame];
		mMinPixelError = MAX(0, [[NSUserDefaults standardUserDefaults] floatForKey:GCGeometryMinPixelError]);
		NSPoint previous, current, next;
		current = next = [nextPoint coordinatePoint];
		NSPoint previousDir, currentDir, nextDir = NSZeroPoint;
		float actualLength = 0, minLength = 0, maxLength = 0;
		NSPoint previousTightest, currentTightest;
		NSPoint previousLoosest, currentLoosest;
		float nextSpeed[3], nextMinSpeed[3], nextMaxSpeed[3];
		float prevSpeed[3], prevMinSpeed[3], prevMaxSpeed[3];
		int j;
		for (i = 0; i < n; i++) {
			if ([self shouldRestartComputation])
				return nil;
				
			previous = current;
			previousPoint = currentPoint;
			currentPoint = nextPoint;
			current = next;
			previousDir.x = -nextDir.x;
			previousDir.y = -nextDir.y;
			for (j = 0; j < 3; j++) {
				prevSpeed[j] = nextSpeed[j];
				prevMinSpeed[j] = nextMinSpeed[j];
				prevMaxSpeed[j] = nextMaxSpeed[j];
			}
			
			GCGeometryPoint *computedPoint = [[[GCGeometryPoint alloc] init] autorelease];
			[computedPoint setPoint:currentPoint];
			[computedPoint setAngle:nan(nil)];
			[computedPoint setMinAngle:nan(nil)];
			[computedPoint setMaxAngle:nan(nil)];
			
			if (i != n - 1) {
				nextPoint = [points objectAtIndex:i + 1];
				next = [nextPoint coordinatePoint];
				[self calculateSpeed:&nextSpeed[0] min:&nextMinSpeed[0] max:&nextMaxSpeed[0]
						xComponent:&nextSpeed[1] min:&nextMinSpeed[1] max:&nextMaxSpeed[1]
						yComponent:&nextSpeed[2] min:&nextMinSpeed[2] max:&nextMaxSpeed[2]
						from:currentPoint to:nextPoint];
			}
			
			if (i == 0 || i == n - 1) {
				[computedPoint setSpeed:nextSpeed[0] x:nextSpeed[1] y:nextSpeed[2]];
				[computedPoint setMinSpeed:nextMinSpeed[0] x:nextMinSpeed[1] y:nextMinSpeed[2]];
				[computedPoint setMaxSpeed:nextMaxSpeed[0] x:nextMaxSpeed[1] y:nextMaxSpeed[2]];
			} else {
				[computedPoint setSpeed:mean(prevSpeed[0], nextSpeed[0]) x:mean(prevSpeed[1], nextSpeed[1]) y:mean(prevSpeed[2], nextSpeed[2])];
				[computedPoint setMinSpeed:mean(prevMinSpeed[0], nextMinSpeed[0])
								x:mean(prevMinSpeed[1], nextMinSpeed[1]) y:mean(prevMinSpeed[2], nextMinSpeed[2])];
				[computedPoint setMaxSpeed:mean(prevMaxSpeed[0], nextMaxSpeed[0])
								x:mean(prevMaxSpeed[1], nextMaxSpeed[1]) y:mean(prevMaxSpeed[2], nextMaxSpeed[2])];
			}
			
			nextDir.x = next.x - current.x;
			nextDir.y = next.y - current.y;
			float dirNorm = hypot(nextDir.x, nextDir.y);
			if (dirNorm > 0) {
				nextDir.x /= dirNorm;
				nextDir.y /= dirNorm;
			}
						
			previousTightest = currentTightest;
			previousLoosest = currentLoosest;
			currentDir.x = nextDir.x + previousDir.x;
			currentDir.y = nextDir.y + previousDir.y;
			currentTightest = [self pointOnErrorBoundsFrom:currentPoint direction:currentDir];
			currentLoosest = [self pointOnErrorBoundsFrom:currentPoint direction:NSMakePoint(-currentDir.x, -currentDir.y)];

			if (i > 0) {
				float actualIncrement = hypot(current.x - previous.x, current.y - previous.y);
				
				NSPoint farthest = [self pointOnErrorBoundsFrom:currentPoint direction:NSMakePoint(-previousDir.x, -previousDir.y)];
				NSPoint closest = [self pointOnErrorBoundsFrom:currentPoint direction:previousDir];
				float d1 = hypot(current.x - previousTightest.x, current.y - previousTightest.y);
				float d2 = hypot(closest.x - previousTightest.x, closest.y - previousTightest.y);
				float d3 = hypot(closest.x - previous.x, closest.y - previous.y);
				float dMin = MIN(MIN(actualIncrement, d1), MIN(d2, d3));
				float dMax = hypot(farthest.x - previousLoosest.x, farthest.y - previousLoosest.y);
				float shortestLength = minLength + dMin;
				float longestLength = maxLength + dMax;
				
				float inc1 = hypot(currentTightest.x - previous.x, currentTightest.y - previous.y);
				float inc2 = hypot(currentTightest.x - previousTightest.x, currentTightest.y - previousTightest.y);
				float inc3 = hypot(current.x - previousTightest.x, current.y - previousTightest.y);
				float minIncrement = MIN(MIN(actualIncrement, inc1), MIN(inc2, inc3));
				float maxIncrement = hypot(currentLoosest.x - previousLoosest.x, currentLoosest.y - previousLoosest.y);
				
				actualLength += actualIncrement;
				minLength += minIncrement;
				maxLength += maxIncrement;
				
				[computedPoint setMinDistance:shortestLength];
				[computedPoint setMaxDistance:longestLength];
				
				if (i < n - 1) {
					float angle = [self angleFrom:previous at:current to:next];
					if (isdefined(angle)) {
						NSPoint dir1 = NSMakePoint(previousDir.y, -previousDir.x);
						NSPoint dir2 = [self rotatePoint:dir1 withAngle:angle / 2];
						NSPoint dir3 = [self rotatePoint:dir1 withAngle:angle];
						NSPoint a0 = [self pointOnErrorBoundsFrom:previousPoint direction:dir1];
						NSPoint b0 = [self pointOnErrorBoundsFrom:previousPoint direction:NSMakePoint(-dir1.x, -dir1.y)];
						NSPoint a1 = [self pointOnErrorBoundsFrom:currentPoint direction:dir2];
						NSPoint b1 = [self pointOnErrorBoundsFrom:currentPoint direction:NSMakePoint(-dir2.x, -dir2.y)];
						NSPoint a2 = [self pointOnErrorBoundsFrom:nextPoint direction:dir3];
						NSPoint b2 = [self pointOnErrorBoundsFrom:nextPoint direction:NSMakePoint(-dir3.x, -dir3.y)];
						float angle0 = [self angleFrom:a0 at:b1 to:a2];
						if (angle0 - angle > pi)
							angle0 -= 2 * pi;
						if (angle0 - angle < -pi)
							angle0 += 2 * pi;
						float angle1 = [self angleFrom:b0 at:a1 to:b2];
						if (angle1 - angle > pi)
							angle1 -= 2 * pi;
						if (angle1 - angle < -pi)
							angle1 += 2 * pi;
						[computedPoint setAngle:angle];
						[computedPoint setMinAngle:MIN(angle, MIN(angle0, angle1))];
						[computedPoint setMaxAngle:MAX(angle, MAX(angle0, angle1))];
					}
				}
			} else {
				[computedPoint setMinDistance:actualLength];
				[computedPoint setMaxDistance:actualLength];
			}
			[computedPoint setDistance:actualLength];
			[computedPoints addObject:computedPoint];
		}
	}

	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	if (computedPoints)
		[dictionary setObject:computedPoints forKey:@"Points"];
	if ([inData boolForKey:@"IsArea"] && !serie) {
		serie = [[[GCSerie alloc] init] autorelease];
		[serie setDefinesArea:YES];
		[(NSMutableArray *)[serie points] addObjectsFromArray:points];
	}
	BOOL isArea = [serie definesArea];
	id length = isArea ? [[GCNumberFormatter sharedFormatter] stringForFloat:[serie perimeter]]
					: [(GCGeometryPoint *)[computedPoints lastObject] distance];
	if (length)
		[dictionary setObject:length forKey:@"Length"];
	if (isArea)
		[dictionary setObject:[[GCNumberFormatter sharedFormatter] stringForFloat:[serie area]] forKey:@"Area"];
	return dictionary;
}

-(NSArray *)computedPoints
{
	return [mComputedValues objectForKey:@"Points"];
}

-(NSDictionary *)computedValues
{
	return mComputedValues;
}

-(void)setComputedValues:(NSDictionary *)inComputedValues
{
	[self willChangeValueForKey:@"computedValues"];
	if (mComputedValues != inComputedValues) {
		[mComputedValues release];
		mComputedValues = [inComputedValues retain];
	}
	[self didChangeValueForKey:@"computedValues"];
}

-(BOOL)computing
{
	return mComputing;
}

-(void)setComputingValue:(id)inValue
{
	BOOL computing = [inValue boolValue];
	if (mComputing != computing) {
		[self willChangeValueForKey:@"computing"];
		mComputing = computing;
		[self didChangeValueForKey:@"computing"];
	}
}

-(void)setComputing:(BOOL)inComputing
{
	[self performSelectorOnMainThread:@selector(setComputingValue:) withObject:[NSNumber numberWithBool:inComputing] waitUntilDone:YES];
}

-(void)computeThread:(id)inSender
{
	NSAutoreleasePool *threadPool = [[NSAutoreleasePool alloc] init];
	
	mAbortComputationThread = NO;
	NSDictionary *data = nil;
	for (;;) {
		[mPointsLock lockWhenCondition:NEW_POINTS_AVAILABLE];
		[data release];
		data = [mDataToCompute copy];
		[mPointsLock unlockWithCondition:0];
		[self setComputing:YES];
		
		if (mAbortComputationThread)
			break;
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSDictionary *computedValues = [self compute:data];
		if (computedValues) {
			[self performSelectorOnMainThread:@selector(setComputedValues:) withObject:computedValues waitUntilDone:YES];
			[self setComputing:NO];
		}
		[pool release];
	}
	
	[data release];
	[threadPool release];
}

-(void)startComputationThread
{
	[NSThread detachNewThreadSelector:@selector(computeThread:) toTarget:self withObject:nil];
}

-(void)stopComputationThread
{
	[mPointsLock lock];
	mAbortComputationThread = YES;
	[mPointsLock unlockWithCondition:NEW_POINTS_AVAILABLE];
}

-(void)recompute
{
	NSNotification *notification = [NSNotification notificationWithName:GCGeometryInfoRecomputeNotification object:self];
	[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostWhenIdle
		coalesceMask:NSNotificationCoalescingOnName forModes:nil];
}

-(void)recompute:(NSNotification *)inNotification
{
	[mPointsLock lock];
	if (!mDataToCompute)
		mDataToCompute = [[NSMutableDictionary alloc] initWithCapacity:0];
	else
		[mDataToCompute removeAllObjects];
	if ([self isVisible]) {
		NSArray *points = [[[mSerie points] copy] autorelease];
		if (points)
			[mDataToCompute setObject:points forKey:@"Points"];
		[mDataToCompute setBool:[mSerie definesArea] forKey:@"IsArea"];
	}
	[mPointsLock unlockWithCondition:NEW_POINTS_AVAILABLE];
}

@end

@implementation GCGeometryInfo (Measures)

-(BOOL)definesArea
{
	return [mSerie definesArea];
}

-(NSString *)lengthTitle
{
	if ([self definesArea])
		return NSLocalizedString(@"Perimeter Export Title", @"");
	else
		return NSLocalizedString(@"Length Export Title", @"");
}

-(id)length
{
	return [mComputedValues objectForKey:@"Length"];
}

-(id)area
{
	return [mComputedValues objectForKey:@"Area"];
}

@end

@implementation GCGeometryPoint

-(id)init
{
	if (self = [super init]) {
		mDistance = mShortestDistance = mLongestDistance = 0.0;
		mAngle = mMinAngle = mMaxAngle = sqrt(-1.0);
	}
	return self;
}

-(void)dealloc
{
	[mPoint release];
	[super dealloc];
}

-(GCPoint *)point
{
	return mPoint;
}

-(void)setPoint:(GCPoint *)inPoint
{
	if (mPoint != inPoint) {
		[mPoint release];
		mPoint = [inPoint retain];
	}
}

-(id)valueForFloat:(float)inValue error:(float)inError
{
	if (!isdefined(inValue))
		return @"";

	GCNumberFormatter *formatter = [GCNumberFormatter sharedFormatter];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:GCGeometryShowError])
		return [NSString stringWithFormat:@"%@ %C %@", [formatter stringForFloat:inValue], (unichar)0x00B1, [formatter stringForFloat:inError]];
	else
		return [formatter stringForFloat:inValue];
}

-(id)distance
{
	return [self valueForFloat:[mPoint distance] error:[mPoint distanceError]];
}

-(void)setDistance:(float)inDistance
{
	[mPoint setDistance:inDistance];
}

-(void)setMinDistance:(float)inDistance
{
	[mPoint setMinDistance:inDistance];
}

-(void)setMaxDistance:(float)inDistance
{
	[mPoint setMaxDistance:inDistance];
}

-(id)angle
{
	return [self valueForFloat:[mPoint angle] error:[mPoint angleError]];
}

-(float)convertAngle:(float)inAngle
{
	return 180.0 / pi * inAngle;
}

-(void)setAngle:(float)inAngle
{
	[mPoint setAngle:[self convertAngle:inAngle]];
}

-(void)setMinAngle:(float)inAngle
{
	[mPoint setMinAngle:[self convertAngle:inAngle]];
}

-(void)setMaxAngle:(float)inAngle
{
	[mPoint setMaxAngle:[self convertAngle:inAngle]];
}

-(id)speed
{
	return [self valueForFloat:[mPoint speed] error:[mPoint speedError]];
}

-(id)xSpeed
{
	return [self valueForFloat:[mPoint xSpeed] error:[mPoint xSpeedError]];
}

-(id)ySpeed
{
	return [self valueForFloat:[mPoint ySpeed] error:[mPoint ySpeedError]];
}

-(void)setSpeed:(float)inSpeed x:(float)inSpeedX y:(float)inSpeedY
{
	[mPoint setSpeed:inSpeed];
	[mPoint setXSpeed:inSpeedX];
	[mPoint setYSpeed:inSpeedY];
}

-(void)setMinSpeed:(float)inSpeed x:(float)inSpeedX y:(float)inSpeedY
{
	[mPoint setMinSpeed:inSpeed];
	[mPoint setMinXSpeed:inSpeedX];
	[mPoint setMinYSpeed:inSpeedY];
}

-(void)setMaxSpeed:(float)inSpeed x:(float)inSpeedX y:(float)inSpeedY
{
	[mPoint setMaxSpeed:inSpeed];
	[mPoint setMaxXSpeed:inSpeedX];
	[mPoint setMaxYSpeed:inSpeedY];
}

-(id)valueForUndefinedKey:(NSString *)inKey
{
	return [mPoint valueForKey:inKey];
}

@end
