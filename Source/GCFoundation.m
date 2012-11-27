//
//  GCFoundation.m
//  GraphClick
//
//  Created by Simon Bovet on 07.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GCFoundation.h"

#import <QuickTime/QuickTime.h>
#import "GCNumberFormatter.h"

#define GCDefaultsValueDidChangeNotification @"GCDefaultsValueDidChangeNotification"

@implementation NSImage (GCFoundation)

-(void)drawInRect:(NSRect)inRect
{
	[self dissolveToRect:inRect fraction:1.0];
}

-(void)dissolveToRect:(NSRect)inRect fraction:(float)inFraction
{
    [self dissolveToRect:inRect fraction:inFraction flipped:NO clipRect:NSZeroRect];
}

-(void)dissolveToRect:(NSRect)inRect fraction:(float)inFraction clipRect:(NSRect)inClipRect
{
    [self dissolveToRect:inRect fraction:inFraction flipped:NO clipRect:inClipRect];
}

-(void)dissolveToRect:(NSRect)inRect fraction:(float)inFraction flipped:(BOOL)inFlipped clipRect:(NSRect)inClipRect
{
    if (inFlipped) {
        inRect.origin.y += inRect.size.height;
        inRect.size.height = -inRect.size.height;
    }

    [NSGraphicsContext saveGraphicsState];
    NSAffineTransform *transform = [NSAffineTransform transform];
    float sx = 1.0, sy = 1.0;
    if (inRect.size.width < 0) {
        inRect.size.width = -inRect.size.width;
        sx = -sx;
    }
    if (inRect.size.height < 0) {
        inRect.size.height = -inRect.size.height;
        sy = -sy;
    }
    [transform translateXBy:inRect.origin.x yBy:inRect.origin.y];
    inRect.origin = NSZeroPoint;
    [transform scaleXBy:sx yBy:sy];
    [transform concat];
    
    NSRect source = NSZeroRect;
    source.size = [self size];
	
	NSRect dest = inRect;
/*	if (!NSIsEmptyRect(inClipRect)) {
		dest = NSIntersectionRect(inRect, inClipRect);
		source.origin.x = NSMinX(source) + source.size.width * (NSMinX(dest) - NSMinX(inRect)) / inRect.size.width;
		source.origin.y = NSMinY(source) + source.size.height * (NSMinY(dest) - NSMinY(inRect)) / inRect.size.height;
		source.size.width *= dest.size.width / inRect.size.width;
		source.size.height *= dest.size.height / inRect.size.height;
	} */

    [self drawInRect:dest fromRect:source operation:NSCompositeSourceOver fraction:inFraction];
    
    [NSGraphicsContext restoreGraphicsState];
}

-(NSSize)pixelSize
{
	NSImageRep *imageRep = [[self representations] lastObject];
	if (imageRep)
		return NSMakeSize([imageRep pixelsWide], [imageRep pixelsHigh]);
	else
		return [self size];
}

@end

@implementation NSColor (GCFoundation)

-(float)distanceToColor:(NSColor *)inColor
{
	float dr = [self redComponent] - [inColor redComponent];
	float dg = [self greenComponent] - [inColor greenComponent];
	float db = [self blueComponent] - [inColor blueComponent];
	const float k = 1.0 / sqrt(3);
	return hypot(hypot(dr, dg), db) * k;
}

@end

@interface GCNoCursor : NSCursor

@end

@implementation GCNoCursor

-(void)set
{
}

@end

@implementation NSCursor (GCFoundation)

+(NSCursor *)emptyCrosshairCursor
{
	static NSCursor *cursor = nil;
	if (!cursor)
		cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosshair"] hotSpot:NSMakePoint(7, 7)];
	return cursor;
}

+(NSCursor *)diagonalResizeCursor
{
	static NSCursor *cursor = nil;
	if (!cursor)
		cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"diag1"] hotSpot:NSMakePoint(7, 7)];
	return cursor;
}

+(NSCursor *)backDiagonalResizeCursor
{
	static NSCursor *cursor = nil;
	if (!cursor)
		cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"diag2"] hotSpot:NSMakePoint(7, 7)];
	return cursor;
}

+(NSCursor *)noCursor
{
	static NSCursor *cursor = nil;
	if (!cursor)
		cursor = [[GCNoCursor alloc] initWithImage:[NSImage imageNamed:@"diag2"] hotSpot:NSMakePoint(7, 7)];
	return cursor;
}

@end

@implementation NSDictionary (GCFoundation)

-(BOOL)boolForKey:(id)inKey
{
	return [[self objectForKey:inKey] boolValue];
}

-(int)intForKey:(id)inKey
{
	return [[self objectForKey:inKey] intValue];
}

-(float)floatForKey:(id)inKey
{
	id object = [self objectForKey:inKey];
	return object ? [object floatValue] : 0.0;
}

@end

@implementation NSMutableDictionary (GCFoundation)

-(void)setBool:(BOOL)inValue forKey:(id)inKey
{
	static NSNumber *yes = nil;
	static NSNumber *no = nil;
	if (!yes) {
		yes = [[NSNumber numberWithBool:YES] retain];
		no = [[NSNumber numberWithBool:NO] retain];
	}
	[self setObject:inValue ? yes : no forKey:inKey];
}

-(void)setInt:(int)inValue forKey:(id)inKey
{
	NSNumber *number = [[NSNumber alloc] initWithInt:inValue];
	[self setObject:number forKey:inKey];
	[number release];
}

-(void)setFloat:(float)inValue forKey:(id)inKey
{   
	NSNumber *number = [[NSNumber alloc] initWithFloat:inValue];
	[self setObject:number forKey:inKey];
	[number release];
}

@end

@implementation NSMutableAttributedString (GCFoundation)

-(void)appendString:(NSString *)inString attributes:(NSDictionary *)inAttributes
{
	NSAttributedString *string = [[NSAttributedString alloc] initWithString:inString attributes:inAttributes];
	[self appendAttributedString:string];
	[string release];
}

-(void)insertString:(NSString *)inString attributes:(NSDictionary *)inAttributes atIndex:(unsigned)inIndex
{
	NSAttributedString *string = [[NSAttributedString alloc] initWithString:inString attributes:inAttributes];
	[self insertAttributedString:string atIndex:inIndex];
	[string release];
}

@end

@implementation NSString (GCFoundation)

-(NSString *)stringByIncreasingIndexBy:(int)inDelta
{
	int firstDigit = [self length];
	while (firstDigit > 0 && [[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[self characterAtIndex:firstDigit - 1]])
		firstDigit--;
	int index = [[self substringFromIndex:firstDigit] intValue];
	NSMutableString *string = [[self mutableCopy] autorelease];
	index += inDelta;
	[string replaceCharactersInRange:NSMakeRange(firstDigit, [self length] - firstDigit) withString:[NSString stringWithFormat:@"%i", index]];
	return string;
}

@end

@implementation NSToolbar (GCFoundation)

-(NSToolbarItem *)itemWithIdentifier:(NSString *)inIdentifier
{
	NSEnumerator *enumerator = [[self items] objectEnumerator];
	NSToolbarItem *item;
	while (item = [enumerator nextObject])
		if ([[item itemIdentifier] isEqual:inIdentifier])
			break;
	return item;
}

@end

@implementation NSAffineTransform (GCFoundation)

-(NSRect)transformRect:(NSRect)inRect
{
	inRect.origin = [self transformPoint:inRect.origin];
	inRect.size = [self transformSize:inRect.size];
	if (inRect.size.width < 0) {
		inRect.origin.x += inRect.size.width;
		inRect.size.width = -inRect.size.width;
	}
	if (inRect.size.height < 0) {
		inRect.origin.y += inRect.size.height;
		inRect.size.height = -inRect.size.height;
	}
	return inRect;
}

@end

@implementation GCZoomFactorTransformer 

+(Class)transformedValueClass
{
    return [NSNumber class];
}

+(BOOL)allowsReverseTransformation
{
    return YES;   
}

-(id)transformedValue:(id)inValue
{
	if ([inValue respondsToSelector:@selector(floatValue)])
		return [NSNumber numberWithFloat:log2([inValue floatValue])];
	else
		return nil;
}

-(id)reverseTransformedValue:(id)inValue
{
	if ([inValue respondsToSelector:@selector(floatValue)])
		return [NSNumber numberWithFloat:pow(2.0, [inValue floatValue])];
	else
		return nil;
}

@end

@implementation GCAngleTransformer 

+(Class)transformedValueClass
{
    return [NSNumber class];
}

+(BOOL)allowsReverseTransformation
{
    return YES;   
}

-(id)transformedValue:(id)inValue
{
	if ([inValue respondsToSelector:@selector(floatValue)])
		return [NSNumber numberWithFloat:90.0 - [inValue floatValue]];
	else
		return nil;
}

-(id)reverseTransformedValue:(id)inValue
{
	if ([inValue respondsToSelector:@selector(floatValue)])
		return [NSNumber numberWithFloat:90.0 - [inValue floatValue]];
	else
		return nil;
}

@end

@implementation GCPercentTransformer 

+(Class)transformedValueClass
{
    return [NSNumber class];
}

+(BOOL)allowsReverseTransformation
{
    return YES;   
}

-(id)transformedValue:(id)inValue
{
	if ([inValue respondsToSelector:@selector(floatValue)])
		return [NSNumber numberWithFloat:[inValue floatValue] * 100];
	else
		return nil;
}

-(id)reverseTransformedValue:(id)inValue
{
	if ([inValue respondsToSelector:@selector(floatValue)])
		return [NSNumber numberWithFloat:[inValue floatValue] / 100];
	else
		return nil;
}

@end

@implementation GCNumberTransformer 

+(Class)transformedValueClass
{
    return [NSString class];
}

+(BOOL)allowsReverseTransformation
{
    return YES;   
}

-(id)transformedValue:(id)inValue
{
	return [[GCNumberFormatter sharedFormatter] stringForObjectValue:inValue];
}

-(id)reverseTransformedValue:(id)inValue
{
	if ([inValue isKindOfClass:[NSString class]]) {
		NSString *separator = [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator];
		if (![separator isEqualToString:@"."]) {
			NSMutableString *string = [[inValue mutableCopy] autorelease];
			[string replaceOccurrencesOfString:separator withString:@"." options:NSLiteralSearch range:NSMakeRange(0, [string length])];
			inValue = string;
		}
	}
	
	if ([inValue respondsToSelector:@selector(floatValue)])
		return [NSNumber numberWithFloat:[inValue floatValue]];
	else
		return nil;
}

@end

@implementation GCTimeTransformer

-(id)transformedValue:(id)inValue
{
	return [[GCTimeFormatter sharedFormatter] stringForObjectValue:inValue];
}

@end

@implementation GCEqualityTransformer

+(Class)transformedValueClass
{
    return [NSString class];
}

+(BOOL)allowsReverseTransformation
{
    return NO;
}

-(id)transformedValue:(id)inValue
{
	if (![inValue respondsToSelector:@selector(length)])
		return nil;
	return [NSString stringWithFormat:@"%@ =", inValue];
}

@end

@implementation GCValidMarkerTransformer

+(Class)transformedValueClass
{
    return [NSNumber class];
}

+(BOOL)allowsReverseTransformation
{
    return NO;  
}

-(id)transformedValue:(id)inValue
{
	if ([inValue respondsToSelector:@selector(intValue)])
		return [NSNumber numberWithBool:[inValue intValue] >= 0];
	else
		return nil;
}

@end

@implementation GCSeparatorTransformer

+(Class)transformedValueClass
{
    return [NSString class];
}

+(BOOL)allowsReverseTransformation
{
    return YES;
}

-(id)transformedValue:(id)inValue
{
	NSMutableString *copy = [[inValue mutableCopy] autorelease];
	if (![copy respondsToSelector:@selector(replaceOccurrencesOfString:withString:options:range:)])
		return nil;
	[copy replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0, [copy length])];
	[copy replaceOccurrencesOfString:@"\t" withString:@"\\t" options:0 range:NSMakeRange(0, [copy length])];
	return copy;
}

-(id)reverseTransformedValue:(id)inValue
{
	NSMutableString *copy = [[inValue mutableCopy] autorelease];
	if (![copy respondsToSelector:@selector(replaceOccurrencesOfString:withString:options:range:)])
		return nil;
	[copy replaceOccurrencesOfString:@"\\n" withString:@"\n" options:0 range:NSMakeRange(0, [copy length])];
	[copy replaceOccurrencesOfString:@"\\t" withString:@"\t" options:0 range:NSMakeRange(0, [copy length])];
	return copy;
}

@end

@implementation GCEnabledTextColorTransformer

+(Class)transformedValueClass
{
    return [NSColor class];
}

+(BOOL)allowsReverseTransformation
{
    return NO;   
}

-(id)transformedValue:(id)inValue
{
	if (![inValue respondsToSelector:@selector(boolValue)] || [inValue boolValue])
		return [NSColor controlTextColor];
	else
		return [NSColor disabledControlTextColor];
}

@end

@implementation NSMovie (GCFoundation)

-(float)duration
{
	Movie movie = [self QTMovie];
	return (float)GetMovieDuration(movie) / GetMovieTimeScale(movie);
}

-(NSImage *)imageAtTimeValue:(TimeValue)inTime
{
	Movie movie = [self QTMovie];
	SetMovieTimeValue(movie, inTime);
	NSImage *image = nil;
	PicHandle picture = GetMoviePict(movie, inTime);
	if (picture) {
		NSData *data = [NSData dataWithBytes:*picture length:GetHandleSize((Handle)picture)];
		NSImageRep *imageRep = [NSPICTImageRep imageRepWithData:data];
		image = [[[NSImage alloc] initWithSize:[imageRep size]] autorelease];
		[image lockFocus];
		[imageRep drawAtPoint:NSZeroPoint];
		[image unlockFocus];
		KillPicture(picture);
	}
	return image;
}

-(NSImage *)imageAtTime:(float)inTime
{
	return [self imageAtTimeValue:round(inTime * GetMovieTimeScale([self QTMovie]))];
}

-(NSImage *)imageAtTimeFromPoster:(float)inTime
{
	Movie movie = [self QTMovie];
	return [self imageAtTimeValue:round(inTime * GetMovieTimeScale(movie)) + GetMoviePosterTime(movie)];
}

-(float)posterTime
{
	Movie movie = [self QTMovie];
	return (float)GetMoviePosterTime(movie) / GetMovieTimeScale(movie);
}

-(void)setPosterTime:(float)inTime
{
	Movie movie = [self QTMovie];
	SetMoviePosterTime(movie, round(inTime * GetMovieTimeScale(movie)));
}

@end

@implementation NSBezierPath (RoundRect)

+(NSBezierPath *)bezierPathWithRoundRectInRect:(NSRect)aRect radius:(float)radius
{
   NSBezierPath* path = [self bezierPath];
   radius = MIN(radius, 0.5f * MIN(NSWidth(aRect), NSHeight(aRect)));
   NSRect rect = NSInsetRect(aRect, radius, radius);
   [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMinY(rect)) radius:radius startAngle:180.0 endAngle:270.0];
   [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMinY(rect)) radius:radius startAngle:270.0 endAngle:360.0];
   [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMaxY(rect)) radius:radius startAngle:  0.0 endAngle: 90.0];
   [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMaxY(rect)) radius:radius startAngle: 90.0 endAngle:180.0];
   [path closePath];
   return path;
}

@end

bool isdefined(float x)
{
	return !isnan(x) && isfinite(x);
}

@implementation NSArray (IndexSetAddition)

-(NSArray *)subarrayWithIndexes:(NSIndexSet *)inIndexes
{
	NSMutableArray *targetArray = [NSMutableArray array];
	unsigned count = [self count];

	unsigned index = [inIndexes firstIndex];
	while (index != NSNotFound) {
		if ( index < count )
			[targetArray addObject:[self objectAtIndex: index]];
		index = [inIndexes indexGreaterThanIndex: index];
	}

	return targetArray;
}

@end

@implementation NSAttributedString (GCFoundation)

-(float)heightForWidth:(float)inWidth
{
	NSTextStorage *textStorage = [[[NSTextStorage alloc] initWithAttributedString:self] autorelease];
	NSTextContainer *textContainer = [[[NSTextContainer alloc] initWithContainerSize:NSMakeSize(inWidth, FLT_MAX)] autorelease];
	NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];
	
	[layoutManager addTextContainer:textContainer];
	[textStorage addLayoutManager:layoutManager];
	[textContainer setLineFragmentPadding:0.0];
	
	[layoutManager glyphRangeForTextContainer:textContainer];
	return [layoutManager usedRectForTextContainer:textContainer].size.height;
}

@end

@implementation GCDefaultsObserver

+(GCDefaultsObserver *)sharedObserver
{
	static GCDefaultsObserver *sharedObserver = nil;
	if (!sharedObserver)
		sharedObserver = [[self alloc] init];
	return sharedObserver;
}

-(id)init
{
	if (self = [super init]) {
		mObservedValues = [[NSMutableSet alloc] initWithCapacity:0];
	}
	return self;
}

-(void)dealloc
{
	[mObservedValues release];
	[super dealloc];
}

-(void)addObserver:(id)inObserver forValues:(NSString *)inFirstValue, ...
{
	[[NSNotificationCenter defaultCenter] addObserver:inObserver selector:@selector(defaultsValueDidChange:)
											name:GCDefaultsValueDidChangeNotification object:nil];
	va_list args;
	va_start(args, inFirstValue);
	NSString *value = inFirstValue;
	while (value) {
		if (![mObservedValues containsObject:value]) {
			[mObservedValues addObject:value];
		    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[NSString stringWithFormat:@"values.%@", value] options:NSKeyValueObservingOptionNew context:nil];
		}
		value = va_arg(args, id);
	}
	va_end(args);
}

-(void)observeValueForKeyPath:(NSString *)inKeyPath ofObject:(id)inObject
	change:(NSDictionary *)inChange context:(void *)inContext
{
	NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:inKeyPath, @"KeyPath", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:GCDefaultsValueDidChangeNotification object:nil userInfo:userInfo];
	[userInfo release];
}

@end

@implementation NSObject (GCDefaultsObserver)

-(void)defaultsValueDidChange:(NSNotification *)inNotification
{
	[self observeValueForKeyPath:[[inNotification userInfo] objectForKey:@"KeyPath"] ofObject:nil change:nil context:nil];
}

@end

@implementation NSApplication (GCFoundation)

-(unsigned long)systemVersion
{
	unsigned long response;
	if (Gestalt(gestaltSystemVersion, (SInt32 *)&response) == noErr)
		return response;
	else
		return 0x00000;
}

@end

@implementation NSWindow (GCFoundation)

-(void)setContentSize:(NSSize)inSize animate:(BOOL)inAnimate;
{
	NSView *view = [self contentView];
	float deltaHeight = inSize.height - [view frame].size.height;
	NSRect frameRect = [self frame];
	frameRect.origin.y -= deltaHeight;
	frameRect.size.height += deltaHeight;
	frameRect.size.width = inSize.width;
	[self setFrame:frameRect display:YES animate:inAnimate];
}

-(void)setContentHeight:(float)inHeight animate:(BOOL)inAnimate
{
	NSSize size = [self frame].size;
	size.height = inHeight;
	[self setContentSize:size animate:inAnimate];
}

@end
