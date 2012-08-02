//
//  GCMask.m
//  GraphClick
//
//  Created by Simon Bovet on 06.01.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GCMask.h"


@implementation GCMask

-(id)initWithCoder:(NSCoder *)inCoder
{
	if (self = [super init]) {
		[inCoder decodeValueOfObjCType:@encode(NSRect) at:&mBounds];
		mImage = [[inCoder decodeObject] retain];
		if ([inCoder versionForClassName:@"GCMask"] >= 1)
			[inCoder decodeValueOfObjCType:@encode(NSRect) at:&mContentBounds];
		else
			mContentBounds = mBounds;
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)inCoder
{
	[GCMask setVersion:1];
	[inCoder encodeValueOfObjCType:@encode(NSRect) at:&mBounds];
	[inCoder encodeObject:mImage];
	if ([GCMask version] >= 1)
		[inCoder encodeValueOfObjCType:@encode(NSRect) at:&mContentBounds];
}

-(id)initWithBounds:(NSRect)inBounds
{
	if (self = [super init]) {
		mBounds = inBounds;
		mContentBounds = NSZeroRect;
		NSBitmapImageRep *imageRep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
										pixelsWide:mBounds.size.width pixelsHigh:mBounds.size.height bitsPerSample:8
										samplesPerPixel:2 hasAlpha:YES isPlanar:YES
										colorSpaceName:NSDeviceWhiteColorSpace
										bytesPerRow:0 bitsPerPixel:0] autorelease];
		if (!imageRep) {
			NSLog(@"Not enough memory to allocate mask of size %@", NSStringFromSize(mBounds.size));
			[self release];
			return nil;
		}

		mImage = [[NSImage alloc] initWithSize:mBounds.size];
		[mImage addRepresentation:imageRep];
	}
	return self;
}

-(void)dealloc
{
	[mImage release];
	[super dealloc];
}

-(NSRect)bounds
{
	return mBounds;
}

-(NSRect)contentBounds
{
	return NSIntersectionRect(mBounds, mContentBounds);
}

-(BOOL)hasContent
{
	NSSize size = [self contentBounds].size;
	return size.width > 0 && size.height > 0;
}

-(NSImage *)image
{
	return mImage;
}

-(void)lockFocus
{
	[mImage lockFocus];
	[[self color] set];
}

-(float)valueAt:(NSPoint)inPoint
{
	NSColor *color = NSReadPixel(NSMakePoint(inPoint.x - mBounds.origin.x, inPoint.y - mBounds.origin.y));
	float red, green, blue, alpha;
	[color getRed:&red green:&green blue:&blue alpha:&alpha];
	return alpha > 0 && (red + green + blue < 3) ? 1 : 0;
}

-(void)unlockFocus
{
	[mImage unlockFocus];
}

-(NSAffineTransform *)paintTransform
{
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform translateXBy:-mBounds.origin.x yBy:-mBounds.origin.y];
	return transform;
}

-(NSColor *)paintClearColor
{
	if (mCurrentPaintKind == 1)
		return [NSColor clearColor];
	else
		return [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
}

-(void)singlePaintPath:(NSBezierPath *)inPath
{
	if (mCurrentPaintKind == 1)
		NSRectFill([inPath bounds]);
	else {
		mContentBounds = NSUnionRect(mContentBounds, [inPath bounds]);
		[inPath fill];
	}
}

-(NSRect)brushAtPoint:(NSPoint)inPoint size:(NSSize)inSize kind:(int)inKind
{
	mCurrentPaintKind = inKind;
	NSRect rect = [super brushAtPoint:inPoint size:inSize kind:inKind];
	mCurrentPaintKind = 0;
	return rect;
}

-(NSRect)brushFromPoint:(NSPoint)inSource toPoint:(NSPoint)inDestination size:(NSSize)inSize kind:(int)inKind
{
	mCurrentPaintKind = inKind;
	NSRect rect = [super brushFromPoint:inSource toPoint:inDestination size:inSize kind:inKind];
	mCurrentPaintKind = 0;
	return rect;
}

+(NSColor *)color
{
	NSColor *color = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"GCMaskColor"]];
	if (!color)
		color = [NSColor blackColor];
	return color;
}

-(NSColor *)color
{
	return [[self class] color];
}

@end

@implementation NSObject (Paintable)

-(void)lockFocus
{
}

-(void)unlockFocus
{
}

-(id)paintTarget
{
	return self;
}

-(NSAffineTransform *)paintTransform
{
	static NSAffineTransform *transform;
	if (!transform)
		transform = [[NSAffineTransform alloc] init];
	return transform;
}

-(void)singlePaintPath:(NSBezierPath *)inPath
{
	[inPath fill];
}

-(void)singleBrushAtPoint:(NSPoint)inPoint size:(NSSize)inSize transform:(NSAffineTransform *)inTransform
{
	if (!inTransform)
		inTransform = [self paintTransform];
	[self singlePaintPath:[inTransform transformBezierPath:[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(inPoint.x - inSize.width / 2, inPoint.y - inSize.height / 2, inSize.width, inSize.height)]]];
}

-(NSColor *)paintClearColor
{
	return [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
}

-(NSRect)brushAtPoint:(NSPoint)inPoint size:(NSSize)inSize kind:(int)inKind
{
	[[self paintTarget] lockFocus];
	if (inKind >= 1)
		[[self paintClearColor] set];
	[self singleBrushAtPoint:inPoint size:inSize transform:nil];
	[[self paintTarget] unlockFocus];
	return NSMakeRect(inPoint.x - inSize.width / 2, inPoint.y - inSize.height / 2, inSize.width, inSize.height);
}

-(NSRect)brushFromPoint:(NSPoint)inSource toPoint:(NSPoint)inDestination size:(NSSize)inSize kind:(int)inKind
{
	[[self paintTarget] lockFocus];
	if (inKind >= 1)
		[[self paintClearColor] set];
	NSAffineTransform *transform = [self paintTransform];
	NSPoint point = inSource;
	for (;;) {
		NSPoint d = NSMakePoint(inDestination.x - point.x, inDestination.y - point.y);
		float dl = hypot(d.x, d.y);
		if (dl < 1)
			break;
		point.x += d.x / dl;
		point.y += d.y / dl;
		[self singleBrushAtPoint:point size:inSize transform:transform];
	}
	[[self paintTarget] unlockFocus];
	return NSUnionRect(NSMakeRect(inSource.x - inSize.width / 2, inSource.y - inSize.height / 2, inSize.width, inSize.height),
			NSMakeRect(inDestination.x - inSize.width / 2, inDestination.y - inSize.height / 2, inSize.width, inSize.height));
}

-(void)paintPath:(NSBezierPath *)inBezierPath
{
	[[self paintTarget] lockFocus];
	[self singlePaintPath:[[self paintTransform] transformBezierPath:inBezierPath]];
	[[self paintTarget] unlockFocus];
}

@end
