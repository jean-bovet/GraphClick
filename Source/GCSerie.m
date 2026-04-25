//
//  GCSerie.m
//  GraphClick
//
//  Created by Simon Bovet on 02.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GCSerie.h"

#import "GCFoundation.h"
#import "GCFrame.h"
#import "GCNumberFormatter.h"
#import "GCArrayController.h"
#import "GCGeometryInfo.h"


@interface NSString (Private)

-(int)numberOfRows;
-(int)numberOfColumns;

@end

@interface NSMutableString (Private)

-(void)padToRows:(int)inRows;
-(void)padToColumns:(int)inColumns;

-(void)appendStringAsTable:(NSString *)inString;

@end

@interface GCPoint (Private)

-(id)index;

@end

@interface GCSerie (Private)

-(void)displayLimitationTitle:(NSString *)inTitle message:(NSString *)inMessage;

@end

@interface GCNumberFormatter (GCSerie)

-(NSString *)stringForDefinedFloat:(float)inValue;

@end

@implementation GCSerie

-(void)awake
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willRemovePoints:)
				name:GCArrayControllerWillRemove object:mPoints];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRemovePoints:)
				name:GCArrayControllerDidRemove object:mPoints];
}

-(id)initWithCoder:(NSCoder *)inCoder
{
	if (self = [super init]) {
		mFrame = [inCoder decodeObject];
		mPoints = [[inCoder decodeObject] retain];
		mName = [[inCoder decodeObject] retain];
		[inCoder decodeValueOfObjCType:@encode(BOOL) at:&mVisible];
		mColor = [[inCoder decodeObject] retain];
		[inCoder decodeValueOfObjCType:@encode(int) at:&mMarker];
		[inCoder decodeValueOfObjCType:@encode(float) at:&mMarkerSize];
		[inCoder decodeValueOfObjCType:@encode(BOOL) at:&mConnected];
		if ([inCoder versionForClassName:@"GCSerie"] >= 1) {
			[inCoder decodeValueOfObjCType:@encode(BOOL) at:&mDefinesArea];
			[inCoder decodeValueOfObjCType:@encode(float) at:&mAreaFill];
		}
		if ([inCoder versionForClassName:@"GCSerie"] >= 2)
			[inCoder decodeValueOfObjCType:@encode(int) at:&mFrameLimitIndex];
		[self awake];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)inCoder
{
	[GCSerie setVersion:2];
	[inCoder encodeConditionalObject:mFrame];
	[inCoder encodeObject:mPoints];
	[inCoder encodeObject:mName];
	[inCoder encodeValueOfObjCType:@encode(BOOL) at:&mVisible];
	[inCoder encodeObject:mColor];
	[inCoder encodeValueOfObjCType:@encode(int) at:&mMarker];
	[inCoder encodeValueOfObjCType:@encode(float) at:&mMarkerSize];
	[inCoder encodeValueOfObjCType:@encode(BOOL) at:&mConnected];
	if ([GCSerie version] >= 1) {
		[inCoder encodeValueOfObjCType:@encode(BOOL) at:&mDefinesArea];
		[inCoder encodeValueOfObjCType:@encode(float) at:&mAreaFill];
	}
	if ([GCSerie version] >= 2)
		[inCoder encodeValueOfObjCType:@encode(int) at:&mFrameLimitIndex];
}

-(id)init
{
	if (self = [super init]) {
		mVisible = YES;
		mPoints = [[NSMutableArray alloc] initWithCapacity:10];
		mColor = [[NSColor redColor] retain];
		mMarker = 3;
		mMarkerSize = 2.0;
		mAreaFill = 0.25;
		[self awake];
	}
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[mPoints release];
	[mName release];
	[mColor release];
	[super dealloc];
}

-(GCFrame *)frame
{
	return mFrame;
}

-(void)setFrame:(GCFrame *)inFrame
{
	mFrame = inFrame;
}

@end

@implementation GCSerie (Points)

-(NSArray *)points
{
	return mPoints;
}

-(unsigned)countOfPoints
{
	return [mPoints count];
}

-(GCPoint *)objectInPointsAtIndex:(unsigned)inIndex
{
	return [mPoints objectAtIndex:inIndex];
}

-(void)insertObject:(GCPoint *)inPoint inPointsAtIndex:(unsigned)inIndex
{
	[mFrame beginEditing];
	[inPoint willChangeValueForKey:@"index"];
	[inPoint setSerie:self];
	[mPoints insertObject:inPoint atIndex:inIndex];
	[inPoint didChangeValueForKey:@"index"];
	[mFrame endEditing];
}

-(void)willRemovePoints:(NSNotification *)inNotification
{
	[mFrame beginEditing];
}

-(void)didRemovePoints:(NSNotification *)inNotification
{
	[mFrame endEditing];
}

-(void)removeObjectFromPointsAtIndex:(unsigned)inIndex
{
	[mFrame beginEditing];
	[mPoints removeObjectAtIndex:inIndex];
	[mFrame endEditing];
}

-(void)insertPoint:(NSPoint)inPoint atIndex:(unsigned)inIndex
{
	GCPoint *point = [[GCPoint alloc] initWithPoint:inPoint];
	[self insertObject:point inPointsAtIndex:inIndex];
	[point release];
}

NSInteger compare(id ptA, id ptB, void *info)
{
	float a = 0, b = 0;
	switch (((int *)info)[0]) {
		case 0:
			a = [ptA xCoordinate];
			b = [ptB xCoordinate];
			break;
		case 1:
			a = [ptA yCoordinate];
			b = [ptB yCoordinate];
			break;
		case 2:
			a = [ptA time];
			b = [ptB time];
			break;
	}
	if (((int *)info)[1] == 1) {
		a = -a;
		b = -b;
	}
	
	if (a > b)
		return 1;
	else if (a < b)
		return -1;
	else
		return 0;
}

-(void)sortCoordinate:(int)inCoordinate order:(int)inOrder
{
	int info[2] = {inCoordinate, inOrder};
	[self willChangeValueForKey:@"points"];
	[mPoints sortUsingFunction:compare context:info];
	[self didChangeValueForKey:@"points"];
}

@end

@implementation GCSerie (Interface)

-(unsigned)index
{
	return [[mFrame series] indexOfObjectIdenticalTo:self] + 1;
}

-(NSString *)name
{
	if (!mName) {
		unsigned index = [self index];
		mName = [[NSString alloc] initWithFormat:NSLocalizedString(@"Name for new serie with index %i", @""), index];
		
		static NSArray *colors = nil;
		if (!colors)
			colors = [[NSArray alloc] initWithObjects:[NSColor redColor], [NSColor blueColor], [NSColor greenColor],
														[NSColor orangeColor], [NSColor magentaColor], [NSColor cyanColor], nil];
		[mColor release];
		mColor = [[colors objectAtIndex:(index - 1) % [colors count]] retain];
	}
	return mName;
}

-(void)setName:(NSString *)inName
{
	[mName autorelease];
	mName = [inName retain];
}

-(BOOL)visible
{
	return mVisible;
}

-(void)setVisible:(BOOL)inVisible
{
	if (mVisible != inVisible) {
		mVisible = inVisible;
		[mFrame appearanceDidChange];
		[[NSNotificationCenter defaultCenter] postNotificationName:GCSerieDidChangeVisibleStateNotification object:self];
	}
}

-(NSColor *)color
{
	return mColor;
}

-(void)setColor:(NSColor *)inColor
{
	if (![mColor isEqual:inColor]) {
		[mColor release];
		mColor = [inColor retain];
		[mFrame appearanceDidChange];
	}
}

-(int)marker
{
	return mMarker;
}

-(void)setMarker:(int)inMarker
{
	if (mMarker != inMarker) {
		mMarker = inMarker;
		[mFrame appearanceDidChange];
	}
}

-(float)markerSize
{
	return mMarkerSize;
}

-(void)setMarkerSize:(float)inMarkerSize
{
	if (mMarkerSize != inMarkerSize) {
		mMarkerSize = inMarkerSize;
		[mFrame appearanceDidChange];
	}
}

-(BOOL)connected
{
	return mConnected;
}

-(void)setConnected:(BOOL)inConnected
{
	if (mConnected != inConnected) {
		mConnected = inConnected;
		[mFrame appearanceDidChange];
	}
}

-(BOOL)definesArea
{
	return mDefinesArea;
}

-(void)setDefinesArea:(BOOL)inDefinesArea
{
	if (mDefinesArea != inDefinesArea) {
		[self willChangeValueForKey:@"definesArea"];
		mDefinesArea = inDefinesArea;
		[self didChangeValueForKey:@"definesArea"];
		[mFrame appearanceDidChange];
	}
}

-(float)areaFill
{
	return mAreaFill;
}

-(void)setAreaFill:(float)inAreaFill
{
	if (mAreaFill != inAreaFill) {
		mAreaFill = inAreaFill;
		[mFrame appearanceDidChange];
	}
}

-(BOOL)containsXErrors
{
	NSEnumerator *enumerator = [mPoints objectEnumerator];
	GCPoint *point;
	while (point = [enumerator nextObject])
		if ([point xMinError] != 0 || [point xMaxError] != 0)
			return YES;
	return NO;
}

-(BOOL)containsYErrors
{
	NSEnumerator *enumerator = [mPoints objectEnumerator];
	GCPoint *point;
	while (point = [enumerator nextObject])
		if ([point yMinError] != 0 || [point yMaxError] != 0)
			return YES;
	return NO;
}

-(void)displayLimitationTitle:(NSString *)inTitle message:(NSString *)inMessage
{
//	int choice = NSRunAlertPanel(inTitle, inMessage, nil, NSLocalizedString(@"Register Button", @""), nil);
//	if (choice == NSAlertAlternateReturn)
//		[[ARRegisterManager sharedManager] performSelector:@selector(displayLicenseWindow:) withObject:nil afterDelay:0.0];
}

-(NSString *)stringForValuesWithSettings:(id)inSettings
{
	BOOL stacked = [inSettings boolForKey:@"StackedValues"];
	BOOL includeTime = [inSettings boolForKey:@"ContainsMovie"] && ![inSettings boolForKey:@"IgnoreTimeValues"];
	BOOL includeHeaders = ![inSettings boolForKey:@"IgnoreHeaders"];
	BOOL includeGeometryInfo = [inSettings boolForKey:@"IncludeGeometryInfo"];
	BOOL includeIndexes = [inSettings boolForKey:@"IncludeIndexes"];
	BOOL includeGeometryErrors = includeGeometryInfo && [[NSUserDefaults standardUserDefaults] boolForKey:GCGeometryShowError];
	int what = [inSettings intForKey:@"CoordinatesToExport"];
	BOOL exportX = what != 2;
	BOOL exportY = what != 1;
	BOOL includeXErrors = [self containsXErrors];
	BOOL includeYErrors = [self containsYErrors];
	BOOL unregistered = NO; //![[ARRegisterManager sharedManager] hasRegisteredApplication];
	if (unregistered && (includeXErrors || includeYErrors)) {
		[self displayLimitationTitle:NSLocalizedString(@"Unregistered Error Bar Alert Title", @"")
			message:NSLocalizedString(@"Unregistered Error Bar Alert Message", @"")];
		includeXErrors = includeYErrors = NO;
	}
	if (unregistered && includeGeometryInfo) {
		[self displayLimitationTitle:NSLocalizedString(@"Unregistered Geometry Info Alert Title", @"")
			message:NSLocalizedString(@"Unregistered Geometry Info Alert Message", @"")];
		includeGeometryInfo = NO;
	}
	NSDictionary *computedData = nil;
	if (includeGeometryInfo)
		computedData = [[GCGeometryInfo sharedInspector] compute:[NSDictionary dictionaryWithObject:self forKey:@"Serie"]];
	GCNumberFormatter *formatter = [GCNumberFormatter sharedFormatter];
	NSMutableString *string = [NSMutableString string];
	if (includeGeometryInfo && [mPoints count] > 0) {
		if ([self definesArea]) {
			[string appendFormat:@"%@%@%@%@%@%@%@", NSLocalizedString(@"Perimeter Export Title", @""),
							[computedData valueForKey:@"Length"], [NSString columnSeparator],
							NSLocalizedString(@"Area Export Title", @""), [NSString lineSeparator],
							[computedData valueForKey:@"Area"], [NSString columnSeparator]];
		} else {
			GCPoint *point = [mPoints lastObject];
			[string appendFormat:@"%@%@%@", NSLocalizedString(@"Length Export Title", @""), [NSString columnSeparator], [formatter stringForDefinedFloat:[point distance]]];
			if (includeGeometryErrors)
				[string appendFormat:@"%@%C%@%@", [NSString columnSeparator], (unichar)0x00B1, [NSString columnSeparator], [formatter stringForDefinedFloat:[point distanceError]]];
		}
		[string appendFormat:@"%@%@", [NSString lineSeparator], [NSString lineSeparator]];
	}
	if (includeHeaders) {
		BOOL first = YES;
		if (includeIndexes) {
			if (!first)
				[string appendString:[NSString columnSeparator]];
			[string appendString:NSLocalizedString(@"Index Export Column Header", @"")];
			first = NO;
		}
		if (includeTime) {
			if (!first)
				[string appendString:[NSString columnSeparator]];
			[string appendString:stacked ? NSLocalizedString(@"Stacked Time Export Column Header", @"") : NSLocalizedString(@"Time Export Column Header", @"")];
			first = NO;
		}
		if (exportX) {
			if (!first)
				[string appendString:[NSString columnSeparator]];
			[string appendString:stacked ? NSLocalizedString(@"Stacked Abscissa Export Column Header", @"") : NSLocalizedString(@"Abscissa Export Column Header", @"")];
			first = NO;
		}
		if (exportY) {
			if (!first)
				[string appendString:[NSString columnSeparator]];
			[string appendString:stacked ? NSLocalizedString(@"Stacked Ordinate Export Column Header", @"") : NSLocalizedString(@"Ordinate Export Column Header", @"")];
			first = NO;
		}
		if (includeXErrors)
			[string appendFormat:@"%@%@%@%@", [NSString columnSeparator], NSLocalizedString(@"Delta X Min Export Column Header", @""),
												[NSString columnSeparator], NSLocalizedString(@"Delta X Max Export Column Header", @"")];
		if (includeYErrors)
			[string appendFormat:@"%@%@%@%@", [NSString columnSeparator], NSLocalizedString(@"Delta Y Min Export Column Header", @""),
												[NSString columnSeparator], NSLocalizedString(@"Delta Y Max Export Column Header", @"")];
		if (includeGeometryInfo) {
			[string appendFormat:@"%@%@", [NSString columnSeparator], NSLocalizedString(@"Distance Export Column Header", @"")];
			if (includeGeometryErrors)
				[string appendFormat:@"%@%@", [NSString columnSeparator], NSLocalizedString(@"Distance Error Export Column Header", @"")];
			[string appendFormat:@"%@%@", [NSString columnSeparator], NSLocalizedString(@"Angle Export Column Header", @"")];
			if (includeGeometryErrors)
				[string appendFormat:@"%@%@", [NSString columnSeparator], NSLocalizedString(@"Angle Error Export Column Header", @"")];
			if (includeTime) {
				[string appendFormat:@"%@%@", [NSString columnSeparator], NSLocalizedString(@"Speed Export Column Header", @"")];
				if (includeGeometryErrors)
					[string appendFormat:@"%@%@", [NSString columnSeparator], NSLocalizedString(@"Speed Error Export Column Header", @"")];
			}
		}
		[string appendString:[NSString lineSeparator]];
	}
	NSEnumerator *enumerator = [mPoints objectEnumerator];
	GCPoint *point;
	int count = 0;
	float lastX = 0, lastY = 0, lastTime = 0, nextX, nextY, nextTime;
	while (point = [enumerator nextObject]) {
		BOOL first = YES;
		if (includeIndexes) {
			if (!first)
				[string appendString:[NSString columnSeparator]];
			id index = [point index];
			if ([index respondsToSelector:@selector(length)])
				[string appendString:index];
			else
				[string appendFormat:@"%i", [index intValue]];
			first = NO;
		}
		if (includeTime) {
			if (!first)
				[string appendString:[NSString columnSeparator]];
			[string appendFormat:@"%@", [formatter stringForFloat:(nextTime = [point time]) - lastTime]];
			first = NO;
		}
		if (exportX) {
			if (!first)
				[string appendString:[NSString columnSeparator]];
			[string appendFormat:@"%@", [formatter stringForFloat:(nextX = [point xCoordinate]) - lastX]];
			first = NO;
		}
		if (exportY) {
			if (!first)
				[string appendString:[NSString columnSeparator]];
			[string appendFormat:@"%@", [formatter stringForFloat:(nextY = [point yCoordinate]) - lastY]];
			first = NO;
		}
		if (includeXErrors)
			[string appendFormat:@"%@%@%@%@", [NSString columnSeparator], [formatter stringForFloat:[point xMinError]],
												[NSString columnSeparator], [formatter stringForFloat:[point xMaxError]]];
		if (includeYErrors)
			[string appendFormat:@"%@%@%@%@", [NSString columnSeparator], [formatter stringForFloat:[point yMinError]],
												[NSString columnSeparator], [formatter stringForFloat:[point yMaxError]]];
		if (includeGeometryInfo) {
			[string appendFormat:@"%@%@", [NSString columnSeparator], [formatter stringForDefinedFloat:[point distance]]];
			if (includeGeometryErrors)
				[string appendFormat:@"%@%@", [NSString columnSeparator], [formatter stringForDefinedFloat:[point distanceError]]];
			[string appendFormat:@"%@%@", [NSString columnSeparator], [formatter stringForDefinedFloat:[point angle]]];
			if (includeGeometryErrors)
				[string appendFormat:@"%@%@", [NSString columnSeparator], [formatter stringForDefinedFloat:[point angleError]]];
			if (includeTime) {
				[string appendFormat:@"%@%@", [NSString columnSeparator], [formatter stringForDefinedFloat:[point speed]]];
				if (includeGeometryErrors)
					[string appendFormat:@"%@%@", [NSString columnSeparator], [formatter stringForDefinedFloat:[point speedError]]];
			}
		}
		[string appendString:[NSString lineSeparator]];
		if (unregistered && ++count == 10) {
			[self displayLimitationTitle:NSLocalizedString(@"Unregistered Number Alert Title", @"")
				message:NSLocalizedString(@"Unregistered Number Alert Message", @"")];
			break;
		}
		if (stacked)
			lastX = nextX, lastY = nextY, lastTime = nextTime;
	}
	return string;
}

@end

@implementation GCNumberFormatter (GCSerie)

-(NSString *)stringForDefinedFloat:(float)inValue
{
	return isdefined(inValue) ? [self stringForFloat:inValue] : @"";
}

@end

@implementation GCSerie (Area)

-(float)perimeter
{
	[self computeAreaParameters];
	return mPerimeter;
}

-(void)setPerimeter:(float)inPerimeter
{
	if (mPerimeter != inPerimeter) {
		[self willChangeValueForKey:@"perimeter"];
		mPerimeter = inPerimeter;
		[self didChangeValueForKey:@"perimeter"];
	}
}

-(float)area
{
	[self computeAreaParameters];
	return mArea;
}

-(void)setArea:(float)inArea
{
	if (mArea != inArea) {
		[self willChangeValueForKey:@"area"];
		mArea = inArea;
		[self didChangeValueForKey:@"area"];
	}
}

-(void)invalidateAreaParameters
{
	if (mValidAreaParameters) {
		mValidAreaParameters = NO;
		[self performSelector:@selector(computeAreaParameters) withObject:nil afterDelay:0.0];
	}
}

-(void)computePerimeterAndArea
{
	mArea = mPerimeter = 0.0;
	NSPoint firstCoords, previousCoords;
	BOOL first = YES;
	BOOL last = YES;
	NSEnumerator *enumerator = [mPoints objectEnumerator];
	GCPoint *point;
	while ((point = [enumerator nextObject]) || last) {
		NSPoint coords = point ? [point coordinatePoint] : firstCoords;
		if (!point)
			last = NO;
		if (first) {
			first = NO;
			firstCoords = coords;
		} else {
			NSPoint delta = NSMakePoint(coords.x - previousCoords.x, coords.y - previousCoords.y);
			mPerimeter += hypot(delta.x, delta.y);
			mArea += 0.5 * delta.x * (coords.y + previousCoords.y);
		}
		previousCoords = coords;
	}
}


-(void)computeAreaParameters
{
	if (!mValidAreaParameters) {
		[self computePerimeterAndArea];
		mValidAreaParameters = YES;
	}
}

@end

@implementation GCSerie (FrameLimits)

-(int)frameLimitIndex
{
	return mFrameLimitIndex;
}

-(void)setFrameLimitIndex:(int)inIndex
{
	if (mFrameLimitIndex != inIndex) {
		[self willChangeValueForKey:@"frameLimitIndex"];
		mFrameLimitIndex = inIndex;
		[self didChangeValueForKey:@"frameLimitIndex"];
		[[NSNotificationCenter defaultCenter] postNotificationName:GCSerieDidChangeFrameLimitIndexNotification object:self];
	}
}

-(void)useFrameLimits
{
	[[self frame] setCurrentFrameLimitIndex:[self frameLimitIndex]];
}

@end

@implementation NSArray (GCSerie)

-(NSString *)stringForValuesWithSettings:(id)inSettings
{
	BOOL includeNames = [self count] > 1;
	BOOL first = YES;
	BOOL asColumns = [inSettings boolForKey:@"DataSetsAsColumns"];
	NSMutableString *wholeString = [NSMutableString string];
	NSEnumerator *enumerator = [self objectEnumerator];
	BOOL unregistered = NO; //![[ARRegisterManager sharedManager] hasRegisteredApplication];
	int count = 0;
	GCSerie *serie;
	while (serie = [enumerator nextObject]) {
		NSMutableString *string = [[[NSMutableString alloc] initWithCapacity:0] autorelease];
		if (++count > 2 && unregistered) {
			[serie displayLimitationTitle:NSLocalizedString(@"Unregistered Multiple Data Sets Alert Title", @"")
				message:NSLocalizedString(@"Unregistered Multiple Data Sets Alert Message", @"")];
			break;
		}
		if (includeNames)
			[string appendFormat:@"%@:%@", [serie name], [NSString lineSeparator]];
		[string appendString:[serie stringForValuesWithSettings:inSettings]];
		if (first) {
			[wholeString setString:string];
			first = NO;
		} else if (asColumns)
			[wholeString appendStringAsTable:string];
		else {
			[wholeString appendString:[NSString lineSeparator]];
			[wholeString appendString:string];
		}
	}
	return wholeString;
}

@end

@implementation NSString (GCSerie)

+(NSString *)columnSeparator
{
	NSString *separator = [[NSUserDefaults standardUserDefaults] objectForKey:GCColumnSeparator];
	if ([separator length] == 0)
		separator = @"\t";
	return separator;
}

+(NSString *)lineSeparator
{
	NSString *separator = [[NSUserDefaults standardUserDefaults] objectForKey:GCLineSeparator];
	if ([separator length] == 0)
		separator = @"\n";
	return separator;
}

-(int)numberOfRows
{
	int rows = [[self componentsSeparatedByString:[NSString lineSeparator]] count];
	if ([self hasSuffix:[NSString lineSeparator]])
		rows--;
	return rows;
}

-(int)numberOfColumns
{
	if ([self rangeOfString:[NSString lineSeparator]].location == NSNotFound)
		return [[self componentsSeparatedByString:[NSString columnSeparator]] count];
	else {
		NSEnumerator *enumerator = [[self componentsSeparatedByString:[NSString lineSeparator]] objectEnumerator];
		NSString *line;
		int columns = 1;
		while (line = [enumerator nextObject])
			columns = MAX(columns, [line numberOfColumns]);
		return columns;
	}
}

@end

@implementation NSMutableString (GCSerie)

-(void)padWithLastLineSeparator
{
	if (![self hasSuffix:[NSString lineSeparator]])
		[self appendString:[NSString lineSeparator]];
}

-(void)padToRows:(int)inRows
{
	[self padWithLastLineSeparator];

	int rows = [self numberOfRows];
	if (rows < inRows) {
		NSMutableString *padding = [NSMutableString string];
		int columns = [self numberOfColumns];
		while (columns > 1) {
			[padding appendString:[NSString columnSeparator]];
			columns--;
		}
		[padding appendString:[NSString lineSeparator]];
		
		while (rows < inRows) {
			[self appendString:padding];
			rows++;
		}
	}
}

-(void)padToColumns:(int)inColumns
{
	[self padWithLastLineSeparator];
	
	NSRange range = NSMakeRange(0, [self length] - [[NSString lineSeparator] length]);
	while (YES) {
		NSRange lineBreak = [self rangeOfString:[NSString lineSeparator] options:0 range:range];
		if (lineBreak.location == NSNotFound)
			break;
		
		NSRange lineRange;
		lineRange.location = range.location;
		lineRange.length = lineBreak.location - lineRange.location;
		int lineColumns = [[self substringWithRange:lineRange] numberOfColumns];
		range.length -= NSMaxRange(lineBreak) - range.location;
		range.location = NSMaxRange(lineBreak);
		while (lineColumns < inColumns) {
			[self insertString:[NSString columnSeparator] atIndex:NSMaxRange(lineRange)];
			range.location += [[NSString columnSeparator] length];
			lineColumns++;
		}
	}
}

-(void)appendStringAsTable:(NSString *)inString
{
	NSMutableString *string = [[inString mutableCopy] autorelease];
	int columns = [self numberOfColumns];
	[self padToColumns:columns];
	int otherColumns = [string numberOfColumns];
	[string padToColumns:otherColumns];
	int rows = MAX([self numberOfRows], [string numberOfRows]);
	[self padToRows:rows];
	[string padToRows:rows];
	
	NSArray *myRows = [self componentsSeparatedByString:[NSString lineSeparator]];
	NSArray *otherRows = [string componentsSeparatedByString:[NSString lineSeparator]];
	
	int r;
	[self setString:@""];
	for (r = 0; r < rows; r++) {
		[self appendString:[myRows objectAtIndex:r]];
		[self appendString:[NSString columnSeparator]];
		[self appendString:[otherRows objectAtIndex:r]];
		[self appendString:[NSString lineSeparator]];
	}
}

@end