//
//  GCView.m
//  GraphClick
//
//  Created by Simon Bovet on 02.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GCView.h"

#import "GCFoundation.h"
#import "GCNumberFormatter.h"
#import "GCGuide.h"
#import "GCDocument.h"
#import "GCOptionalAlert.h"
#import "GCFilterController.h"
#import "GCHistogram.h"
#import "GCInspector.h"
#import "GCSnapGridController.h"
#import "GCAdjustmentWizard.h"
#import "GCPointPasteDialog.h"

@interface GCView (Private)

-(void)setImageFraction:(float)inFraction;
-(void)setImageAngle:(float)inAngle;
-(void)setImageScale:(float)inScale;
-(void)setImageContent:(int)inContent;
-(void)setSymbolDetect:(int)inDetect;
-(int)frameCornerForLocation:(NSPoint)inLocation;
-(int)frameSideForLocation:(NSPoint)inLocation direction:(NSPoint *)outDirection;
-(int)symbolDetect;
-(void)moveSelectedPointsBy:(NSPoint)inDelta;
-(NSSize)imageBoundsSize;
-(NSAffineTransform *)imageTransform;
-(NSPoint)imageOriginWithZoomFactor:(float)inZoomFactor;
-(NSRect)guideBounds;
-(NSRect)brushBounds;
-(NSRect)boundsForRect:(NSRect)inRect;
-(float)magnifyingRadius;
-(NSRect)magnifyingRect;
-(NSBezierPath *)framePath;
-(NSAffineTransform *)zoomTransform;
-(void)setFrameCursorForLocation:(NSPoint)inLocation;

-(NSArray *)pointsInRect:(NSRect)inRect;
-(BOOL)isPointVisible:(GCPoint *)inPoint;
-(void)insertPoint:(NSPoint)inPoint;

-(NSBezierPath *)abscissaCoordinatePathAt:(float)inAbscissa;
-(NSBezierPath *)ordinateCoordinatePathAt:(float)inAbscissa;
-(NSBezierPath *)crossCoordinatePathAt:(NSPoint)inPoint;
-(void)promptCoordinates;
-(void)promptScale;

-(void)magicWandParameterDidChange;
-(void)drawImageWithFraction:(float)inFraction zoomFactor:(float)inZoomFactor;
-(void)detachMagicWandThreadWithPoint:(NSPoint)inPoint type:(int)inType;
-(void)focusPoints:(NSArray *)inPoints withColor:(NSColor *)inColor grow:(float)inGrow shadowRadius:(float)inShadowRadius zoom:(float)inZoom;
-(float)focusRadius;

-(void)stepForwardIfNeeded;
-(void)displayMagicWandView:(int)inIndex;

-(void)extendLineBetween:(NSPoint)inFrom and:(NSPoint)inTo to:(NSPoint *)outFrom and:(NSPoint *)outTo;
-(void)appendMarker:(int)inMarker origin:(NSPoint)inOrigin radius:(float)inRadius toBezierPath:(NSBezierPath *)ioPath fill:(BOOL *)outFill;

-(BOOL)shouldDisplayGuide;

-(void)requestMovieImageAtTime:(float)inTime;

-(void)updateZoomPopUp;
-(float)adjustedZoomFactor;

-(NSImage *)checkedImage:(NSImage *)inImage;

-(BOOL)snapGridActive;

-(void)preparePointInsertion;
-(void)finishPointInsertion;

-(NSPoint)roundedPoint:(NSPoint)inPoint withZoomFactor:(float)inZoom;

-(void)setAdjustmentWizard:(GCAdjustmentWizard *)inAdjustmentWizard;

@end

@interface GCSerie (Private)

-(void)insertObject:(GCPoint *)inPoint inPointsAtIndex:(unsigned)inIndex;
-(void)removeObjectFromPointsAtIndex:(unsigned)inIndex;

@end

@interface GCFrame (Private)

-(NSPoint)convert:(NSPoint)inPoint;
-(NSPoint)unconvert:(NSPoint)inPoint;

@end

@interface GCPoint (Private)

-(void)setXCoordinate:(float)inValue;
-(void)setYCoordinate:(float)inValue;

-(NSPoint)convertFromCoordinate:(NSPoint)inPoint;

@end

@implementation GCView

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"xCoordinate"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"coordinates"]];
    }
    if ([key isEqualToString:@"yCoordinate"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"coordinates"]];
    }
    if ([key isEqualToString:@"magicWandFinalProgress"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"magicWandProgress"]];
    }
    return keyPaths;
}

-(NSArray *)acceptedDragTypes
{
	return [NSArray arrayWithObjects:NSFilenamesPboardType, NSURLPboardType, NSPDFPboardType, NSTIFFPboardType, nil];
}

-(void)awakeFromNib
{
	[self setSelectedTool:GCSelectTool];
	mPointsToSelect = [[NSMutableIndexSet alloc] init];
	[self setMagnificationLocation:NSMakePoint(-1, -1)];
	mZoomFactor = 1.0;
	mImageFraction = 1.0;
	mImageAngle = 0.0;
	mImageScale = 1.0;
	mTimeStep = 0.2;
	[self setSymbolDetect:1 << (1 + 1 * 3)]; // center only
	mBounds = [self bounds];
	mPromptedCoordinates = [[NSMutableDictionary alloc] initWithCapacity:2];
	mPromptedPositions = [[NSMutableDictionary alloc] initWithCapacity:2];
	mPromptedOriginalCoordinates = [[NSMutableDictionary alloc] initWithCapacity:2];
	mSnapGridNumber[0] = mSnapGridNumber[1] = 10;
    
	int i;
	for (i = 0; i < 4; i++)
		mLastFrameLimit[i] = sqrt(-1.0);
	mSpriteRects = [[NSMutableDictionary alloc] initWithCapacity:0];

	mGuide = [[GCGuide alloc] init];
	mHistogram = [[GCHistogram alloc] init];
	
    [[mSerieController retain] addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionNew context:nil];
    [[mPointController retain] addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionNew context:nil];
    [mFrame addObserver:self forKeyPath:@"selectedDeformations" options:NSKeyValueObservingOptionNew context:nil];

	[[GCDefaultsObserver sharedObserver] addObserver:self forValues:GCMagicWandTolerance, GCMagicWandSpacing, GCMagicWandNumberOfPoints, GCMagicWandSpacingDefinition, GCMagicWandHorizontalOffset,
							GCUseMagnifyingGlass, GCFrameColor, GCFrameColor, GCFrameDotted, GCFrameBackgroundOpacity, GCFrameLabelled, GCMaskOpacity,
							GCNumberNumberOfDigits, GCNumberScientificNotation, GCNumberScientificNotationFrom, GCNumberRemoveTrailingZeros, GCNumberDecimalSeparator, nil];
	[[self window] invalidateCursorRectsForView:self];

	[self willChangeValueForKey:@"zoomFactor"];
	[self didChangeValueForKey:@"zoomFactor"];
	[self willChangeValueForKey:@"coordinates"];
	[self didChangeValueForKey:@"coordinates"];
	[self willChangeValueForKey:@"imageFraction"];
	[self didChangeValueForKey:@"imageFraction"];
	[self willChangeValueForKey:@"imageAngle"];
	[self didChangeValueForKey:@"imageAngle"];
	[self willChangeValueForKey:@"imageScale"];
	[self didChangeValueForKey:@"imageScale"];
	[self willChangeValueForKey:@"width"];
	[self didChangeValueForKey:@"width"];
	[self willChangeValueForKey:@"height"];
	[self didChangeValueForKey:@"height"];
	[self willChangeValueForKey:@"guide"];
	[self didChangeValueForKey:@"guide"];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appearanceDidChange:)
											name:GCFrameAppearanceDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mouseMoved:)
											name:NSWindowDidBecomeKeyNotification object:[self window]];

	[self registerForDraggedTypes:[self acceptedDragTypes]];
	
	[self updateZoomPopUp];
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
    [mSerieController removeObserver:self forKeyPath:@"selection"];
	[mSerieController release];
    [mPointController removeObserver:self forKeyPath:@"selection"];
	[mPointController release];
    [mFrame removeObserver:self forKeyPath:@"selectedDeformations"];
		
	int i;
	for (i = 0; i < 4; i++)
		[mFrameLabelString[i] release];
	[mSpriteRects release];
	[mMagicWandImage release];
	[mMagicWandBitmapImageRep release];
	
	[mPointsToSelect release];
	[mFrame release];
	[mImage release];
	[mHistogram release];
	[mMovie release];
	[mURL release];
	[mFrameColor release];
	[mThreadedPointsToInsert release];
	[mGuide release];
	[mCoordinatePath release];
	[mPromptedCoordinates release];
	[mPromptedPositions release];
	[mPromptedOriginalCoordinates release];
	[mFocusedPoints release];
	[mSnapGridController release];
	[mAdjustmentWizard release];
	[mPreviousCustomProjection release];
	
	[super dealloc];
}

-(void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSize
{
	NSSize superSize = [[self superview] frame].size;
	NSSize size = [self frame].size;
	[self setFrameOrigin:NSMakePoint(MAX(0, round((superSize.width - size.width) / 2)),
									MAX(0, round((superSize.height - size.height) / 2)))];
	superSize = [[[self superview] superview] frame].size;
	if (!NSEqualSizes(NSZeroSize, superSize))
		[[self superview] setFrameSize:NSMakeSize(MAX(size.width, superSize.width), MAX(size.height, superSize.height))];
}

-(void)resetCursorRects
{
	if (mSelectedTool != GCFrameTool && mSelectedTool != GCSelectTool)
		[self addCursorRect:[self visibleRect] cursor:mScrollView ? [NSCursor openHandCursor] : [NSCursor emptyCrosshairCursor]];
	else
		[self addCursorRect:[self visibleRect] cursor:[NSCursor arrowCursor]];
}

-(GCFrame *)frameObject
{
	return mFrame;
}

-(void)setFrameObject:(GCFrame *)inFrame
{
	if (mFrame != inFrame) {
		[self willChangeValueForKey:@"coordinateVariables"];
		[mFrame removeObserver:self forKeyPath:@"selectedDeformations"];
		[mFrame release];
		mFrame = [inFrame retain];
		[mFrame setImageOrigin:[self imageOriginWithZoomFactor:1.0]];
		[mFrame addObserver:self forKeyPath:@"selectedDeformations" options:NSKeyValueObservingOptionNew context:nil];
		[self didChangeValueForKey:@"coordinateVariables"];
	}
}

-(void)observeValueForKeyPath:(NSString *)inKeyPath ofObject:(id)inObject
	change:(NSDictionary *)inChange context:(void *)inContext
{
	if ([inKeyPath isEqual:@"values.GCMagicWandTolerance"] || [inKeyPath isEqual:@"values.GCMagicWandSpacing"] || [inKeyPath isEqual:@"values.GCMagicWandHorizontalOffset"]
				|| [inKeyPath isEqual:@"values.GCMagicWandNumberOfPoints"] || [inKeyPath isEqual:@"values.GCMagicWandSpacingDefinition"]
				|| [inKeyPath isEqual:@"values.GCMagicWandLineFinderSpacing"]|| [inKeyPath isEqual:@"values.GCMagicWandLineFinderExtremity"]|| [inKeyPath isEqual:@"values.GCMagicWandLineFinderRightToLeft"])
		[self magicWandParameterDidChange];
	
	if ([inKeyPath isEqual:@"values.GCUseMagnifyingGlass"])
		[self setMagnificationLocation:mMagnificationLocation];
	if ([inKeyPath isEqual:@"values.GCFrameColor"]) {
		[mFrameColor release];
		mFrameColor = nil;
	}
	
	if ([inKeyPath isEqual:@"values.GCNumberNumberOfDigits"] || [inKeyPath isEqual:@"values.GCNumberScientificNotation"] ||
			[inKeyPath isEqual:@"values.GCNumberScientificNotationFrom"] || [inKeyPath isEqual:@"values.GCNumberRemoveTrailingZeros"] ||
			[inKeyPath isEqual:@"values.GCNumberDecimalSeparator"]) {
		[mSerieController willChangeValueForKey:@"selection"];
		[mSerieController didChangeValueForKey:@"selection"];
	}
	
	[self setNeedsDisplay:YES];
}

-(BOOL)acceptsFirstResponder
{
	return YES;
}

-(BOOL)becomeFirstResponder
{
	[self setNeedsDisplay:YES];
	return YES;
}

-(BOOL)resignFirstResponder
{
	[self setNeedsDisplay:YES];
	return YES;
}

-(BOOL)acceptsFirstMouse:(NSEvent *)inEvent
{
	return NO;
}

-(id)parameters
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setFloat:mZoomFactor forKey:@"ZoomFactor"];
	[parameters setObject:[NSValue valueWithSize:mBounds.size] forKey:@"BoundsSize"];
	if (mImage)
		[parameters setObject:mImage forKey:@"Image"];
	[parameters setFloat:mImageFraction forKey:@"ImageFraction"];
	[parameters setFloat:mImageAngle forKey:@"ImageAngle"];
	[parameters setFloat:mImageScale forKey:@"ImageScale"];
	if (mMovie)
		[parameters setObject:mMovie forKey:@"Movie"];
	if (mURL)
		[parameters setObject:mURL forKey:@"URL"];
	[parameters setFloat:mTime forKey:@"Time"];
	[parameters setFloat:mTimeStep forKey:@"TimeStep"];
	[parameters setBool:mDisplayTimeFrameOnly forKey:@"DisplayTimeFrameOnly"];
	[parameters setBool:mAutoStepForward forKey:@"AutoStepForward"];
	[parameters setInt:[self selectedTool] forKey:@"SelectedTool"];
	[parameters setInt:[self symbolDetect] forKey:@"SymbolDetect"];
	[parameters setBool:[self hideFrame] forKey:@"HideFrame"];
	[parameters setObject:[NSArchiver archivedDataWithRootObject:mGuide] forKey:@"Guide"];
	
	NSEnumerator *enumerator = [[self snapGridParameterKeys] objectEnumerator];
	NSString *key;
	while (key = [enumerator nextObject])
		[parameters setObject:[self valueForKey:key] forKey:key];
		
	return parameters;
}

-(void)setParameters:(id)inParameters afterLoading:(BOOL)inLoading
{
	id value;
	if ((value = [inParameters objectForKey:@"BoundsSize"]))
		[self setSize:[value sizeValue]];
	if ((value = [inParameters objectForKey:@"ZoomFactor"]))
		[self setZoomFactor:[value floatValue]];
	if ((value = [inParameters objectForKey:@"Image"]))
		[self setImage:value adjustIfNeeded:NO];
	if ((value = [inParameters objectForKey:@"ImageFraction"]))
		[self setImageFraction:[value floatValue]];
	if ((value = [inParameters objectForKey:@"ImageAngle"]))
		[self setImageAngle:[value floatValue]];
	if ((value = [inParameters objectForKey:@"ImageScale"]))
		[self setImageScale:[value floatValue]];
	[self setMovie:[inParameters objectForKey:@"Movie"]];
	if ((value = [inParameters objectForKey:@"Time"]))
		[self setTime:[value floatValue]];
	[mURL release];
	mURL = [[inParameters objectForKey:@"URL"] retain];
	
	NSEnumerator *enumerator = [[self snapGridParameterKeys] objectEnumerator];
	NSString *key;
	while (key = [enumerator nextObject])
		if ((value = [inParameters objectForKey:key]))
			[self setValue:value forKey:key];

	if (inLoading) {
		if ((value = [inParameters objectForKey:@"SelectedTool"]))
			[self setSelectedTool:[value intValue]];
		if ((value = [inParameters objectForKey:@"ImageContent"]))
			[self setImageContent:[value intValue]];
		if ((value = [inParameters objectForKey:@"SymbolDetect"]))
			[self setSymbolDetect:[value intValue]];
		if ((value = [inParameters objectForKey:@"HideFrame"]))
			[self setHideFrame:[value boolValue]];
		if ((value = [inParameters objectForKey:@"TimeStep"]))
			[self setTimeStep:[value floatValue]];
		if ((value = [inParameters objectForKey:@"DisplayTimeFrameOnly"]))
			[self setDisplayTimeFrameOnly:[value boolValue]];
		if ((value = [inParameters objectForKey:@"AutoStepForward"]))
			[self setAutoStepForward:[value boolValue]];
		if ((value = [inParameters objectForKey:@"Guide"])) {
			[self willChangeValueForKey:@"guide"];
			[mGuide release];
			mGuide = [[NSUnarchiver unarchiveObjectWithData:value] retain];
			[self didChangeValueForKey:@"guide"];
		}
	}
}

-(GCSerie *)selectedSerie
{
	return [[mSerieController selectedObjects] lastObject];
}

-(NSArray *)selectedSeries
{
	return [mSerieController selectedObjects];
}

-(BOOL)respondsToSelector:(SEL)inSelector
{
	if (inSelector == @selector(paste:))
		return [self canPaste];
	else
		return [super respondsToSelector:inSelector];
}

@end

@implementation GCView (Drawing)

-(NSAffineTransform *)imageTransform
{
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform translateXBy:mBounds.size.width / 2 yBy:mBounds.size.height / 2];
	[transform rotateByDegrees:mImageAngle];
	[transform scaleBy:mImageScale];
	[transform translateXBy:-mBounds.size.width / 2 yBy:-mBounds.size.height / 2];
	return transform;
}

-(NSPoint)imageOriginWithZoomFactor:(float)inZoomFactor
{
	NSPoint origin;
	origin.x = floor(NSMidX(mBounds) - [mImage size].width / 2);
	origin.y = floor(NSMidY(mBounds) - [mImage size].height / 2);
	if (inZoomFactor > 1) {
		origin.x -= 0.5 - 1./(inZoomFactor + 1);
		origin.y += 0.5 - 1./(inZoomFactor + 1);
	}
	return origin;
}

-(void)drawImageWithFraction:(float)inFraction zoomFactor:(float)inZoomFactor
{
	[NSGraphicsContext saveGraphicsState];
	NSAffineTransform *transform = [self imageTransform];
//	NSBezierPath *clip = [NSBezierPath bezierPathWithRect:mRectBeingDrawn];
	[transform concat];
	[transform invert];
//	clip = [transform transformBezierPath:clip];
	NSRect r;
	r.origin = [self imageOriginWithZoomFactor:inZoomFactor];
	r.size = [mImage size];
	[mImage dissolveToRect:r fraction:inFraction];
//	[mImage dissolveToRect:r fraction:inFraction clipRect:[clip bounds]];
	[NSGraphicsContext restoreGraphicsState];
}

-(void)drawErrorBarFrom:(NSPoint)inOrigin to:(NSPoint)inPoint correction:(NSPoint)inPixelCorrection
{
	NSPoint d = NSMakePoint(inPoint.x - inOrigin.x, inPoint.y - inOrigin.y);
	float dl = hypot(d.x, d.y);
	if (dl > 0) {
		NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
		BOOL antialias = [currentContext shouldAntialias];
		[currentContext setShouldAntialias:NO];
		NSBezierPath *path = [[NSBezierPath alloc] init];
		[path moveToPoint:inPixelCorrection];
		[path lineToPoint:NSMakePoint(d.x + inPixelCorrection.x, d.y + inPixelCorrection.y)];
		dl /= 5.0;
		NSPoint p = NSMakePoint(d.y / dl, -d.x / dl);
		[path relativeMoveToPoint:p];
		p.x *= -2;
		p.y *= -2;
		[path relativeLineToPoint:p];
		[path stroke];
		[path release];
		[currentContext setShouldAntialias:antialias];
	}
}

-(NSPoint)roundedPoint:(NSPoint)inPoint withZoomFactor:(float)inZoom
{
	inPoint.x = (round(inPoint.x * inZoom) - 0.5) / inZoom;
	inPoint.y = (round(inPoint.y * inZoom) - 0.5) / inZoom;
	return inPoint;
}

-(void)extendLineBetween:(NSPoint)inFrom and:(NSPoint)inTo to:(NSPoint *)outFrom and:(NSPoint *)outTo
{
	float k = 5;
	if (outFrom) {
		outFrom->x = k * inFrom.x - (k - 1.0) * inTo.x;
		outFrom->y = k * inFrom.y - (k - 1.0) * inTo.y;
	}
	if (outTo) {
		outTo->x = k * inTo.x - (k - 1.0) * inFrom.x;
		outTo->y = k * inTo.y - (k - 1.0) * inFrom.y;
	}
}

-(NSBezierPath *)fullFramePathWithZoomFactor:(float)inZoom
{
	NSBezierPath *framePath = [NSBezierPath bezierPath];
	int i, n = [mFrame numberOfDeformations];
	NSPoint bottomRight = [mFrame cornerPoint:1];
	NSPoint topRight = [mFrame cornerPoint:2];
	NSPoint A;
	NSPoint B;

	if (n == 0)
		[self extendLineBetween:bottomRight and:topRight to:&A and:&B];
	else {
		[self extendLineBetween:bottomRight and:[mFrame positionOfDeformationAtIndex:n - 1 leftSide:NO] to:&A and:nil];
		[self extendLineBetween:[mFrame positionOfDeformationAtIndex:0 leftSide:NO] and:topRight to:nil and:&B];
	}
	[framePath moveToPoint:[self roundedPoint:A withZoomFactor:inZoom]];
	[framePath lineToPoint:[self roundedPoint:bottomRight withZoomFactor:inZoom]];
	for (i = n - 1; i >= 0; i--)
		[framePath lineToPoint:[mFrame positionOfDeformationAtIndex:i leftSide:NO]];
	[framePath lineToPoint:[self roundedPoint:topRight withZoomFactor:inZoom]];
	[framePath lineToPoint:[self roundedPoint:B withZoomFactor:inZoom]];
	NSPoint bottomLeft = [mFrame cornerPoint:0];
	NSPoint topLeft = [mFrame cornerPoint:3];

	[self extendLineBetween:bottomRight and:bottomLeft to:&A and:&B];
	[framePath moveToPoint:[self roundedPoint:A withZoomFactor:inZoom]];
	[framePath lineToPoint:[self roundedPoint:bottomRight withZoomFactor:inZoom]];
	[framePath lineToPoint:[self roundedPoint:bottomLeft withZoomFactor:inZoom]];
	[framePath lineToPoint:[self roundedPoint:B withZoomFactor:inZoom]];

	[self extendLineBetween:topRight and:topLeft to:&A and:&B];
	[framePath moveToPoint:[self roundedPoint:A withZoomFactor:inZoom]];
	[framePath lineToPoint:[self roundedPoint:topRight withZoomFactor:inZoom]];
	[framePath lineToPoint:[self roundedPoint:topLeft withZoomFactor:inZoom]];
	[framePath lineToPoint:[self roundedPoint:B withZoomFactor:inZoom]];

	if (n == 0)
		[self extendLineBetween:bottomLeft and:topLeft to:&A and:&B];
	else {
		[self extendLineBetween:bottomLeft and:[mFrame positionOfDeformationAtIndex:n - 1 leftSide:YES] to:&A and:nil];
		[self extendLineBetween:[mFrame positionOfDeformationAtIndex:0 leftSide:YES] and:topLeft to:nil and:&B];
	}
	[framePath moveToPoint:[self roundedPoint:B withZoomFactor:inZoom]];
	[framePath lineToPoint:[self roundedPoint:topLeft withZoomFactor:inZoom]];
	for (i = 0; i < n; i++)
		[framePath lineToPoint:[mFrame positionOfDeformationAtIndex:i leftSide:YES]];
	[framePath lineToPoint:[self roundedPoint:bottomLeft withZoomFactor:inZoom]];
	[framePath lineToPoint:[self roundedPoint:A withZoomFactor:inZoom]];
	return framePath;
}

-(NSBezierPath *)framePathWithZoomFactor:(float)inZoom
{
	NSBezierPath *framePath = [NSBezierPath bezierPath];
	int i, n = [mFrame numberOfDeformations];
	NSPoint bottom = [mFrame cornerPoint:1];
	NSPoint top = [mFrame cornerPoint:2];
	[framePath moveToPoint:[self roundedPoint:bottom withZoomFactor:inZoom]];
	for (i = n - 1; i >= 0; i--)
		[framePath lineToPoint:[mFrame positionOfDeformationAtIndex:i leftSide:NO]];
	[framePath lineToPoint:[self roundedPoint:top withZoomFactor:inZoom]];
	bottom = [mFrame cornerPoint:0];
	top = [mFrame cornerPoint:3];
	[framePath lineToPoint:[self roundedPoint:top withZoomFactor:inZoom]];
	for (i = 0; i < n; i++)
		[framePath lineToPoint:[mFrame positionOfDeformationAtIndex:i leftSide:YES]];
	[framePath lineToPoint:[self roundedPoint:bottom withZoomFactor:inZoom]];
	[framePath closePath];
	return framePath;
}

-(NSBezierPath *)framePath
{
	return [self framePathWithZoomFactor:mZoomFactor];
}

-(NSColor *)frameColor
{
	if (!mFrameColor)
		mFrameColor = [[NSUnarchiver unarchiveObjectWithData:[[[NSUserDefaultsController sharedUserDefaultsController] values]
							valueForKey:@"GCFrameColor"]] retain];
	return mFrameColor;
}

-(void)drawFrameLabelText:(NSAttributedString *)inString size:(NSSize)inSize atPoint:(NSPoint)inPoint
{
	NSRect rect;
	rect.origin = inPoint;
	rect.size = inSize;
	rect = NSInsetRect(rect, -2, 0);
	
	if (NSIntersectsRect(mRectBeingDrawn, rect)) {
		NSColor *rectColor = [[NSColor colorWithCalibratedWhite:1.0 alpha:0.6] blendedColorWithFraction:[[NSUserDefaults standardUserDefaults] floatForKey:GCFrameBackgroundOpacity] ofColor:[self frameColor]];
		[rectColor set];
		[[NSBezierPath bezierPathWithRoundRectInRect:rect radius:4] fill];
		[[self frameColor] set];
		[inString drawAtPoint:inPoint];
	}
}

-(void)drawFrameWithZoomFactor:(float)inZoom
{
	if ([self hideFrame] || ![mFrame canShowFrame])
		return;
	
	float lineWidth = 1.0 / mZoomFactor;
	NSBezierPath *framePath = [self framePathWithZoomFactor:inZoom];
	NSBezierPath *backPath = [NSBezierPath bezierPathWithRect:mBounds];
	[backPath appendBezierPath:framePath];
	[backPath setWindingRule:NSEvenOddWindingRule];
	
	[[[self frameColor] colorWithAlphaComponent:[[NSUserDefaults standardUserDefaults] floatForKey:GCFrameBackgroundOpacity]] set];
	[backPath fill];
	
	[[self frameColor] set];

	framePath = [self fullFramePathWithZoomFactor:inZoom];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:GCFrameDotted]) {
		static float pattern[2] = {5.0, 3.0};
		[framePath setLineDash:pattern count:2 phase:0.0];
	}
	[framePath setLineWidth:lineWidth];
	[framePath stroke];
	
	NSRect rect;
	rect.size.width = rect.size.height = 5 * lineWidth;
	int side;
	unsigned i, n = [mFrame numberOfDeformations];
	for (i = 0; i < n; i++)
		if ([mFrame isDeformationSelectedAtIndex:i])
			for (side = 0; side < 2; side++) {
				rect.origin = [mFrame positionOfDeformationAtIndex:i leftSide:side == 0];
				rect.origin.x -= rect.size.width / 2;
				rect.origin.y -= rect.size.height / 2;
				[[NSBezierPath bezierPathWithOvalInRect:rect] fill];
			}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:GCFrameLabelled]) {
		GCNumberFormatter *formatter = [GCNumberFormatter sharedFormatter];
		id attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSFont labelFontOfSize:11], NSFontAttributeName,
				mFrameColor, NSForegroundColorAttributeName,
				nil];
		id subscript = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSFont labelFontOfSize:9], NSFontAttributeName,
				mFrameColor, NSForegroundColorAttributeName,
				[NSNumber numberWithInt:-1], NSSuperscriptAttributeName,
				nil];
				
		static NSMutableAttributedString *string = nil;
		if (!string)
			string = [[NSMutableAttributedString alloc] initWithString:@""];
		float limitValue;

		limitValue = [mFrame xMin];
		if (limitValue != mLastFrameLimit[0]) {
			mLastFrameLimit[0] = limitValue;
			[string deleteCharactersInRange:NSMakeRange(0, [string length])];
			[string appendString:[NSString stringWithFormat:@"x = %@", [formatter stringForFloat:limitValue]] attributes:attributes];
			[string insertString:@"min" attributes:subscript atIndex:1];
			[mFrameLabelString[0] release];
			mFrameLabelString[0] = [string copy];
			mFrameLabelSize[0] = [string size];
		}
		NSPoint pt = [mFrame cornerPoint:0];
		pt.x += 4;
		pt.y -= 2 + mFrameLabelSize[0].height;
		[self drawFrameLabelText:mFrameLabelString[0] size:mFrameLabelSize[0] atPoint:pt];

		limitValue = [mFrame xMax];
		if (limitValue != mLastFrameLimit[1]) {
			mLastFrameLimit[1] = limitValue;
			[string deleteCharactersInRange:NSMakeRange(0, [string length])];
			[string appendString:[NSString stringWithFormat:@"x = %@", [formatter stringForFloat:limitValue]] attributes:attributes];
			[string insertString:@"max" attributes:subscript atIndex:1];
			[mFrameLabelString[1] release];
			mFrameLabelString[1] = [string copy];
			mFrameLabelSize[1] = [string size];
		}
		pt = [mFrame cornerPoint:1];
		pt.x -= mFrameLabelSize[1].width + 4;
		pt.y -= 2 + mFrameLabelSize[1].height;
		[self drawFrameLabelText:mFrameLabelString[1] size:mFrameLabelSize[1] atPoint:pt];

		limitValue = [mFrame yMin];
		if (limitValue != mLastFrameLimit[2]) {
			mLastFrameLimit[2] = limitValue;
			[string deleteCharactersInRange:NSMakeRange(0, [string length])];
			[string appendString:[NSString stringWithFormat:@"y = %@", [formatter stringForFloat:limitValue]] attributes:attributes];
			[string insertString:@"min" attributes:subscript atIndex:1];
			[mFrameLabelString[2] release];
			mFrameLabelString[2] = [string copy];
			mFrameLabelSize[2] = [string size];
		}
		pt = [mFrame cornerPoint:0];
		NSAffineTransform *transform = [NSAffineTransform transform];
		[transform translateXBy:pt.x yBy:pt.y];
		[transform rotateByDegrees:90];
		[transform translateXBy:-pt.x yBy:-pt.y];
		pt.x += 4;
		pt.y += 2;
		NSRect rectBeingDrawn = mRectBeingDrawn;
		[transform concat];
		[transform invert];
		mRectBeingDrawn = [transform transformRect:rectBeingDrawn];
		[self drawFrameLabelText:mFrameLabelString[2] size:mFrameLabelSize[2] atPoint:pt];
		[transform concat];

		limitValue = [mFrame yMax];
		if (limitValue != mLastFrameLimit[3]) {
			mLastFrameLimit[3] = limitValue;
			[string deleteCharactersInRange:NSMakeRange(0, [string length])];
			[string appendString:[NSString stringWithFormat:@"y = %@", [formatter stringForFloat:limitValue]] attributes:attributes];
			[string insertString:@"max" attributes:subscript atIndex:1];
			[mFrameLabelString[3] release];
			mFrameLabelString[3] = [string copy];
			mFrameLabelSize[3] = [string size];
		}
		pt = [mFrame cornerPoint:3];
		transform = [NSAffineTransform transform];
		[transform translateXBy:pt.x yBy:pt.y];
		[transform rotateByDegrees:90];
		[transform translateXBy:-pt.x yBy:-pt.y];
		pt.x -= mFrameLabelSize[3].width + 4;
		pt.y += 2;
		[transform concat];
		[transform invert];
		mRectBeingDrawn = [transform transformRect:rectBeingDrawn];
		[self drawFrameLabelText:mFrameLabelString[3] size:mFrameLabelSize[3] atPoint:pt];
		[transform concat];
		mRectBeingDrawn = rectBeingDrawn;
	}
}

-(NSAffineTransform *)zoomTransform
{
	static NSAffineTransform *zoomTransform = nil;
	static float zoomFactor = -1.0;
	if (zoomFactor != mZoomFactor) {
		[zoomTransform release];
		zoomTransform = [[NSAffineTransform alloc] init];
		[zoomTransform scaleBy:zoomFactor = mZoomFactor];
	}
	return zoomTransform;
}

-(NSRect)brushRect
{
	float r = [self brushSize];
	return NSMakeRect(mMagnificationLocation.x - r, mMagnificationLocation.y - r, 2 * r, 2 * r);
}

-(BOOL)shouldDisplayBrush
{
	return (mValidMagnificationLocation &&  (mSelectedTool == GCMaskBrushTool || mSelectedTool == GCMaskEraseTool || mSelectedTool == GCImageEraseTool));
}

-(NSRect)boundsForRect:(NSRect)inRect
{
	float r = 1.0;
	return NSInsetRect([[self zoomTransform] transformRect:inRect], -r, -r);
}

-(NSRect)brushBounds
{
	if ([self shouldDisplayBrush])
		return [self boundsForRect:[self brushRect]];
	else
		return NSZeroRect;
}

-(NSRect)guideRect
{
	float r = 0;
	if ([mGuide visible])
		r = [mGuide radius];
	return NSMakeRect(mMagnificationLocation.x - r, mMagnificationLocation.y - r, 2 * r, 2 * r);
}

-(BOOL)shouldDisplayGuide
{
	return (mSelectedTool == GCAddPointTool && NSPointInRect(mMagnificationLocation, mBounds) && [mGuide visible] && !mScrollView);
}

-(NSRect)guideBounds
{
	if ([self shouldDisplayGuide]) {
		NSRect guideRect;
		if (mCoordinatePath)
			guideRect = [mCoordinatePath bounds];
		else
			guideRect = [self guideRect];
		return [self boundsForRect:guideRect];
	} else
		return NSZeroRect;
}

-(BOOL)transparentDocument
{
	return ![[self window] isOpaque];
}

static float sTMin, sTMax;

-(void)prepareVisiblePoints
{
	sTMin = -1e10;
	sTMax = 1e10;
	if ([self displayTimeFrameOnly]) {
		sTMin = [self time] - [self timeStep] / 2;
		sTMax = [self time] + [self timeStep] / 2;
	}
}

-(BOOL)isSinglePointVisible:(GCPoint *)inPoint
{
	float time = [inPoint time];
	return time >= sTMin && time <= sTMax;
}

-(BOOL)isPointVisible:(GCPoint *)inPoint
{
	[self prepareVisiblePoints];
	return [self isSinglePointVisible:inPoint];	
}

-(NSArray *)pointsInRect:(NSRect)inRect
{
	if (inRect.size.width < 0) {
		inRect.origin.x += inRect.size.width;
		inRect.size.width = -inRect.size.width;
	}
	if (inRect.size.height < 0) {
		inRect.origin.y += inRect.size.height;
		inRect.size.height = -inRect.size.height;
	}
	
	NSMutableArray *points = [NSMutableArray array];
	GCSerie *serie = [self selectedSerie];
	NSEnumerator *enumerator = [[serie points] objectEnumerator];
	GCPoint *point;
	[self prepareVisiblePoints];
	while (point = [enumerator nextObject]) {
		NSPoint pt = [point point];
		if ([self isPointVisible:point] && NSPointInRect(pt, inRect))
			[points addObject:point];
	}
	
	return points;
}

-(void)appendMarker:(int)inMarker origin:(NSPoint)inOrigin radius:(float)inRadius toBezierPath:(NSBezierPath *)ioPath fill:(BOOL *)outFill
{
	if (outFill)
		*outFill = NO;
	switch (inMarker) {
		case 0:
			[ioPath moveToPoint:NSMakePoint(inOrigin.x - inRadius, inOrigin.y)];
			[ioPath lineToPoint:NSMakePoint(inOrigin.x + inRadius, inOrigin.y)];
			[ioPath moveToPoint:NSMakePoint(inOrigin.x, inOrigin.y - inRadius)];
			[ioPath lineToPoint:NSMakePoint(inOrigin.x, inOrigin.y + inRadius)];
			break;
		case 1:
			[ioPath moveToPoint:NSMakePoint(inOrigin.x - inRadius, inOrigin.y - inRadius)];
			[ioPath lineToPoint:NSMakePoint(inOrigin.x + inRadius, inOrigin.y + inRadius)];
			[ioPath moveToPoint:NSMakePoint(inOrigin.x + inRadius, inOrigin.y - inRadius)];
			[ioPath lineToPoint:NSMakePoint(inOrigin.x - inRadius, inOrigin.y + inRadius)];
			break;
		case 2:
			[ioPath appendBezierPathWithOvalInRect:NSMakeRect(inOrigin.x - inRadius, inOrigin.y - inRadius, 2 * inRadius, 2 * inRadius)];
			break;
		case 3:
			[ioPath appendBezierPathWithOvalInRect:NSMakeRect(inOrigin.x - inRadius, inOrigin.y - inRadius, 2 * inRadius, 2 * inRadius)];
			if (outFill)
				*outFill = YES;
			break;
		default:
			break;
	}
}

-(void)drawSelectionInRect:(NSRect)inRect withZoomFactor:(float)inZoom
{
	static NSColor *color = nil;
	if (!color)
		color = [[NSColor colorWithCalibratedRed:0.4 green:0.6 blue:0.8 alpha:1.0] retain];
	static NSMutableArray *points = nil;
	if (!points)
		points = [[NSMutableArray alloc] initWithCapacity:0];
	else
		[points removeAllObjects];
	NSEnumerator *enumerator = [[mPointController selectedObjects] objectEnumerator];
	GCPoint *point;
	while (point = [enumerator nextObject])
		if (![mFocusedPoints containsObject:point] && [[point serie] visible] && [self isPointVisible:point])
			[points addObject:point];

	[NSGraphicsContext saveGraphicsState];
	[self focusPoints:points withColor:color grow:1.0 / inZoom shadowRadius:5 zoom:inZoom];

	[points removeAllObjects];
	enumerator = [mFocusedPoints objectEnumerator];
	while (point = [enumerator nextObject])
		if ([[mPointController selectedObjects] containsObject:point])
			[points addObject:point];
	if ([points count] > 0)
		[self focusPoints:points withColor:color grow:1.0 / inZoom shadowRadius:10 zoom:inZoom];
	[NSGraphicsContext restoreGraphicsState];
}

-(void)drawContentInRect:(NSRect)inRect withZoomFactor:(float)inZoom
{
	float lineWidth = 1.0 / inZoom;
	mRectBeingDrawn = inRect;
	if (![self transparentDocument]) {
		[[NSColor whiteColor] set];
		NSRectFill(mRectBeingDrawn);
	}
	
	[self drawImageWithFraction:mImageFraction zoomFactor:inZoom];
	[self drawFrameWithZoomFactor:inZoom];
	if ([NSGraphicsContext currentContextDrawingToScreen]) {
		[self drawMaskWithZoomFactor:inZoom];
		[self drawFocusInRect:inRect withZoomFactor:inZoom];
		[self drawSelectionInRect:inRect withZoomFactor:inZoom];
	}

	float defaultLineWidth = [NSBezierPath defaultLineWidth];
	[NSBezierPath setDefaultLineWidth:lineWidth];

	NSEnumerator *serieEnumerator = [[mFrame series] objectEnumerator];
	GCSerie *serie;
	while (serie = [serieEnumerator nextObject])
		if ([serie visible]) {
			BOOL serieSelected = [[mSerieController selectedObjects] containsObject:serie];
			[[serie color] set];
			int marker = [serie marker];
			float markerSize = [serie markerSize];
				
			if ([serie connected] || ([serie definesArea] && [serie areaFill] > 0)) {
				NSBezierPath *polygon = [NSBezierPath bezierPath];
				NSEnumerator *pointEnumerator = [[serie points] objectEnumerator];
				GCPoint *point;
				while (point = [pointEnumerator nextObject]) {
					NSPoint pt = [point point];
					if ([polygon isEmpty])
						[polygon moveToPoint:pt];
					else
						[polygon lineToPoint:pt];
				}
				if ([serie definesArea]) {
					[polygon closePath];
					if ([serie areaFill] > 0) {
						[[[serie color] colorWithAlphaComponent:[serie areaFill]] set];
						[polygon fill];
						[[serie color] set];
					}
				}
				if ([serie connected]) {
					[polygon setLineWidth:lineWidth];
					[polygon stroke];
				}
			}

			NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
			BOOL antialias = [currentContext shouldAntialias];
			[currentContext setShouldAntialias:marker != 0];

			NSRect updateRect = NSInsetRect(inRect, -2 * markerSize, -2 * markerSize);
			BOOL fillPath = NO;
			NSPoint pixelCorrection = NSMakePoint(0.5 * lineWidth, -0.5 * lineWidth);
			NSBezierPath *markerPath = [[[NSBezierPath alloc] init] autorelease];
			[self appendMarker:marker origin:pixelCorrection radius:markerSize / inZoom toBezierPath:markerPath fill:&fillPath];

			[NSGraphicsContext saveGraphicsState];
			NSEnumerator *pointEnumerator = [[serie points] objectEnumerator];
			GCPoint *point;
			NSAffineTransform *affineTransform = [NSAffineTransform transform];
			NSAffineTransformStruct transformStruct = [affineTransform transformStruct];
			NSPoint pt;
			NSPoint prv = NSZeroPoint;
			float xMin, xMax, yMin, yMax;
			[self prepareVisiblePoints];
			while (point = [pointEnumerator nextObject])
				if ([self isPointVisible:point]) {
					pt = [point point];
					xMin = [point xMinError];
					xMax = [point xMaxError];
					yMin = [point yMinError];
					yMax = [point yMaxError];
					if (NSPointInRect(pt, updateRect) || xMin != 0 || xMax != 0 || yMin != 0 || yMax != 0) {
						[affineTransform setTransformStruct:transformStruct];
						[affineTransform translateXBy:pt.x - prv.x yBy:pt.y - prv.y];
						[affineTransform concat];
						if (fillPath)
							[markerPath fill];
						else
							[markerPath stroke];
						prv = pt;
						
						if (xMin != 0)
							[self drawErrorBarFrom:pt to:[point pointWithError:NSMakePoint(xMin, 0)] correction:pixelCorrection];
						if (xMax != 0)
							[self drawErrorBarFrom:pt to:[point pointWithError:NSMakePoint(xMax, 0)] correction:pixelCorrection];
						if (yMin != 0)
							[self drawErrorBarFrom:pt to:[point pointWithError:NSMakePoint(0, yMin)] correction:pixelCorrection];
						if (yMax != 0)
							[self drawErrorBarFrom:pt to:[point pointWithError:NSMakePoint(0, yMax)] correction:pixelCorrection];
					}
				}
			[NSGraphicsContext restoreGraphicsState];
			
			[currentContext setShouldAntialias:antialias];
		}
	
	if (mSelectionPath && [NSGraphicsContext currentContextDrawingToScreen]) {
		const float lineDash[2] = {5.0, 2.0};
		NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
		BOOL antialias = [currentContext shouldAntialias];
		[currentContext setShouldAntialias:NO];
		[[NSColor colorWithCalibratedWhite:0.0 alpha:0.05] set];
		[mSelectionPath fill];
		[[NSColor grayColor] set];
		[mSelectionPath setLineDash:lineDash count:2 phase:mSelectionPathPhase];
		[mSelectionPath setLineWidth:lineWidth];
		[mSelectionPath stroke];
		[currentContext setShouldAntialias:antialias];
	}
	
	if ([[mFrame guideLines] count] > 0 && [NSGraphicsContext currentContextDrawingToScreen]) {
		NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
		BOOL antialias = [currentContext shouldAntialias];
		[currentContext setShouldAntialias:NO];
		NSEnumerator *enumerator = [[mFrame guideLines] objectEnumerator];
		GCGuideLine *guideLine;
		[[NSColor blueColor] set];
		while (guideLine = [enumerator nextObject])
			if ([guideLine isVertical]) {
				float x = [guideLine position] + 0.5 * lineWidth;
				[NSBezierPath strokeLineFromPoint:NSMakePoint(x, NSMinY(mRectBeingDrawn)) toPoint:NSMakePoint(x, NSMaxY(mRectBeingDrawn))]; 
			} else {
				float y = [guideLine position] - 0.5 * lineWidth;
				[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(mRectBeingDrawn), y) toPoint:NSMakePoint(NSMaxX(mRectBeingDrawn), y)]; 
			}
		[currentContext setShouldAntialias:antialias];
	}
	
	if ([self shouldDisplayGuide] && [NSGraphicsContext currentContextDrawingToScreen])
		[mGuide drawAtPoint:mMagnificationLocation withWidth:lineWidth];
		
	if (mCoordinatePath && [NSGraphicsContext currentContextDrawingToScreen]) {
		[mCoordinatePath setLineWidth:lineWidth];
		[[self frameColor] set];
		[mCoordinatePath stroke];
	}
	[NSBezierPath setDefaultLineWidth:defaultLineWidth];
	
}

-(void)drawRect:(NSRect)inRect
{
	[NSGraphicsContext saveGraphicsState];
	NSAffineTransform *zoomTransform = [NSAffineTransform transform];
	[zoomTransform scaleBy:mZoomFactor];
	[zoomTransform concat];
	[zoomTransform invert];
	NSRect updateRect = [zoomTransform transformRect:inRect];
	[self drawContentInRect:updateRect withZoomFactor:mZoomFactor];

	if (mValidMagnificationLocation && [NSGraphicsContext currentContextDrawingToScreen]) {
		if (mSelectedTool == GCMaskBrushTool || mSelectedTool == GCMaskEraseTool || mSelectedTool == GCImageEraseTool) {
			NSBezierPath *brushPath = mSelectedTool == GCMaskEraseTool ? [NSBezierPath bezierPathWithRect:[self brushRect]]
				: [NSBezierPath bezierPathWithOvalInRect:[self brushRect]];
			[brushPath setLineWidth:1.0 / mZoomFactor];
			[[NSColor grayColor] set];
			[brushPath stroke];
		} else if ([[NSUserDefaults standardUserDefaults] boolForKey:GCUseMagnifyingGlass] && !mHideMagnifyingGlass) {
			float k = 5.0;
			float r = [self magnifyingRadius];
			NSRect magnifyingRect = [self magnifyingRect];
			NSBezierPath *clipPath = [NSBezierPath bezierPathWithOvalInRect:magnifyingRect];
			[[NSColor blackColor] set];
			[NSGraphicsContext saveGraphicsState];
			[clipPath addClip];
			NSAffineTransform *transform = [NSAffineTransform transform];
			[transform translateXBy:mMagnificationLocation.x yBy:mMagnificationLocation.y];
			[transform scaleBy:k];
			[transform translateXBy:-mMagnificationLocation.x yBy:-mMagnificationLocation.y];
			[transform concat];
			[transform invert];
			NSRect zoomedUpdateRect = NSIntersectionRect(magnifyingRect, updateRect);
			if (!NSIsEmptyRect(zoomedUpdateRect)) {
				zoomedUpdateRect = [transform transformRect:zoomedUpdateRect];
				if ([self transparentDocument]) {
					[[NSColor colorWithCalibratedWhite:0.0 alpha:0.0625] set];
					NSRectFill(mBounds);
				}
				[self drawContentInRect:zoomedUpdateRect withZoomFactor:k * mZoomFactor];
			}
			[NSGraphicsContext restoreGraphicsState];
			
			switch ([[NSUserDefaults standardUserDefaults] integerForKey:GCMagnifyingGlassType]) {
				case 0: {
					[clipPath setLineWidth:1.0 / mZoomFactor];
					float r0 = 10;
					[clipPath moveToPoint:NSMakePoint(mMagnificationLocation.x - r, mMagnificationLocation.y - [clipPath lineWidth] / 2)];
					[clipPath lineToPoint:NSMakePoint(mMagnificationLocation.x - r0 + 1, mMagnificationLocation.y - [clipPath lineWidth] / 2)];
					[clipPath moveToPoint:NSMakePoint(mMagnificationLocation.x + r0, mMagnificationLocation.y - [clipPath lineWidth] / 2)];
					[clipPath lineToPoint:NSMakePoint(mMagnificationLocation.x + r, mMagnificationLocation.y - [clipPath lineWidth] / 2)];
					[clipPath moveToPoint:NSMakePoint(mMagnificationLocation.x + [clipPath lineWidth] / 2, mMagnificationLocation.y - r)];
					[clipPath lineToPoint:NSMakePoint(mMagnificationLocation.x + [clipPath lineWidth] / 2, mMagnificationLocation.y - r0)];
					[clipPath moveToPoint:NSMakePoint(mMagnificationLocation.x + [clipPath lineWidth] / 2, mMagnificationLocation.y + r0 - 1)];
					[clipPath lineToPoint:NSMakePoint(mMagnificationLocation.x + [clipPath lineWidth] / 2, mMagnificationLocation.y + r)];
					if (NSIntersectsRect(updateRect, [clipPath bounds]))
						[clipPath stroke];
					break;
				}
				case 1: {
					NSImage *image = [NSImage imageNamed:@"MagnifyingGlass"];
					NSPoint pt = mMagnificationLocation;
					NSSize size = [image pixelSize];
					pt.x -= size.width / (2 * mZoomFactor);
					pt.y -= size.height / (2 * mZoomFactor);
					[image dissolveToPoint:pt fraction:1.0];
					break;
				}
			}
		}
    }
	[NSGraphicsContext restoreGraphicsState];
}

@end

@implementation GCView (MagnifyingGlass)

-(float)magnifyingRadius
{
	return 100 / mZoomFactor;
}

-(NSRect)magnifyingRect
{
	float r = [self magnifyingRadius];
	return NSMakeRect(mMagnificationLocation.x - r, mMagnificationLocation.y - r, 2 * r, 2 * r);
}

-(BOOL)shouldDisplayMagnifyingGlass
{
	if (!mValidMagnificationLocation)
		return NO;
	else if (mSelectedTool == GCMaskBrushTool || mSelectedTool == GCMaskEraseTool || mSelectedTool == GCImageEraseTool)
		return NO;
	else
		return [[NSUserDefaults standardUserDefaults] boolForKey:GCUseMagnifyingGlass] && !mHideMagnifyingGlass;
}

-(NSRect)magnifyingBounds
{
	if ([self shouldDisplayMagnifyingGlass])
		return [self boundsForRect:[self magnifyingRect]];
	else
		return NSZeroRect;
}

-(void)removeMagnifyingGlass
{
	[self setMagnificationLocation:mMagnificationLocation];
	mHideMagnifyingGlass = YES;
}

-(void)setSprite:(id)inSprite rect:(NSRect)inRect
{
	id previous = [mSpriteRects objectForKey:inSprite];
	if (previous)
		[self setNeedsDisplayInRect:[previous rectValue]];
	[self setNeedsDisplayInRect:inRect];
	[mSpriteRects setObject:[NSValue valueWithRect:inRect] forKey:inSprite];
}

static BOOL sSkipMagnifyingGlass = NO;

-(void)setMagnificationLocation:(NSPoint)inLocation
{
	inLocation = [self snapPointToGrid:inLocation];
	mHideMagnifyingGlass = NO;
	mMagnificationLocation = inLocation;
	BOOL valid = !sSkipMagnifyingGlass && !mScrollView && mSelectedTool != GCMaskRectangleTool;
	valid &= NSPointInRect(mMagnificationLocation, mBounds);
	NSPoint realLocation = NSMakePoint(inLocation.x * mZoomFactor, inLocation.y * mZoomFactor);
	valid &= NSPointInRect(realLocation, [self visibleRect]);
	[self willChangeValueForKey:@"coordinates"];
	mCoordinates = [mFrame convertToCoordinate:mMagnificationLocation];
	[self didChangeValueForKey:@"coordinates"];
	if (mValidMagnificationLocation != valid) {
		[self willChangeValueForKey:@"validCoordinates"];
		mValidMagnificationLocation = valid;
		[self didChangeValueForKey:@"validCoordinates"];
	}
	if (mValidMagnificationLocation && mSelectedTool == GCFrameTool)
		[self setFrameCursorForLocation:inLocation];
		
	if (mCoordinatePath) {
		[mCoordinatePath release];
		mCoordinatePath = nil;
	}
	switch (mSelectedTool) {
		case GCAdjustAbscissa1:
		case GCAdjustAbscissa2:
		case GCAdjustPositionB2:
		case GCAdjustAbscissaOrdinate1:
		case GCAdjustAbscissaOrdinate2:
			mCoordinatePath = [[self ordinateCoordinatePathAt:mCoordinates.x] retain];
			break;
		case GCAdjustOrdinate1:
		case GCAdjustOrdinate2:
		case GCAdjustPositionB3:
		case GCAdjustAbscissaOrdinate3:
		case GCAdjustAbscissaOrdinate4:
			mCoordinatePath = [[self abscissaCoordinatePathAt:mCoordinates.y] retain];
			break;
		case GCAdjustPosition1:
		case GCAdjustPosition2:
		case GCAdjustPositionB1:
		case GCAdjustOrigin:
			mCoordinatePath = [[self abscissaCoordinatePathAt:mCoordinates.y] retain];
			[mCoordinatePath appendBezierPath:[self ordinateCoordinatePathAt:mCoordinates.x]];
			break;
		case GCAdjust3Points1:
		case GCAdjust3Points2:
		case GCAdjust3Points3:
		case GCAdjust4Points1:
		case GCAdjust4Points2:
		case GCAdjust4Points3:
		case GCAdjust4Points4:
			mCoordinatePath = [[self crossCoordinatePathAt:mMagnificationLocation] retain];
			break;
		case GCAdjustScale2:
			mCoordinatePath = [[NSBezierPath bezierPath] retain];
			[mCoordinatePath moveToPoint:[[mPromptedPositions objectForKey:[NSNumber numberWithInt:GCAdjustScale1]] pointValue]];
			[mCoordinatePath lineToPoint:mMagnificationLocation];
			break;
		case GCAdjustWithWizard: {
			switch ([mAdjustmentWizard coordinatePromptKind]) {
				case 1:
					mCoordinatePath = [[NSBezierPath bezierPath] retain];
					[mCoordinatePath moveToPoint:NSMakePoint(mMagnificationLocation.x, -1e6)];
					[mCoordinatePath lineToPoint:NSMakePoint(mMagnificationLocation.x, 1e6)];
					break;
				case 2:
					mCoordinatePath = [[NSBezierPath bezierPath] retain];
					[mCoordinatePath moveToPoint:NSMakePoint(-1e6, mMagnificationLocation.y)];
					[mCoordinatePath lineToPoint:NSMakePoint(1e6, mMagnificationLocation.y)];
					break;
				case 3:
					mCoordinatePath = [[NSBezierPath bezierPath] retain];
					[mCoordinatePath moveToPoint:NSMakePoint(mMagnificationLocation.x, -1e6)];
					[mCoordinatePath lineToPoint:NSMakePoint(mMagnificationLocation.x, 1e6)];
					[mCoordinatePath moveToPoint:NSMakePoint(-1e6, mMagnificationLocation.y)];
					[mCoordinatePath lineToPoint:NSMakePoint(1e6, mMagnificationLocation.y)];
					break;
			}
		}
		default:
			break;
	}
	[self focusElementsAtLocation:inLocation];
	
	[self setSprite:@"MagnifyingGlass" rect:[self magnifyingBounds]];
	[self setSprite:@"Guide" rect:[self guideBounds]];
	[self setSprite:@"Brush" rect:[self brushBounds]];
	[self setSprite:@"Coordinates" rect:mCoordinatePath ? [self boundsForRect:[mCoordinatePath bounds]] : NSZeroRect];
}

@end

@implementation GCView (Focus)

static BOOL sDontFocus = NO;

-(void)setFocusedPoints:(NSArray *)inPoints
{
    [mFocusedPoints removeAllObjects];
    if (inPoints) {
        if (nil == mFocusedPoints) {
            mFocusedPoints = [[NSMutableArray alloc] init];
        }
        [mFocusedPoints addObjectsFromArray:inPoints];
    }
	[self setSprite:@"FocusedPoints" rect:[self focusBounds]];
	if (mSelectedTool == GCSelectTool)
		[[NSCursor arrowCursor] set];
}

-(void)focusPoint:(GCPoint *)inPoint
{
	[self setFocusedPoints:inPoint ? [NSArray arrayWithObject:inPoint] : nil];
}

-(void)focusLineBetween:(GCPoint *)inPointA and:(GCPoint *)inPointB
{
	[self setFocusedPoints:[NSArray arrayWithObjects:inPointA, inPointB, nil]];
}

-(float)focusRadius
{
	return [[self selectedSerie] markerSize] + 6;
}

-(void)focusGuideLine:(GCGuideLine *)inGuideLine
{
	[self setFocusedPoints:nil];
	[([inGuideLine isVertical] ? [NSCursor resizeLeftRightCursor] : [NSCursor resizeUpDownCursor]) set];
}

-(void)focusElementsAtLocation:(NSPoint)inLocation
{
	if (sDontFocus)
		return;
	if (mSelectedTool != GCSelectTool)
		[self focusPoint:nil];
	else {
		if ([[mFrame guideLines] count] > 0) {
			NSEnumerator *enumerator = [[mFrame guideLines] objectEnumerator];
			GCGuideLine *guideLine;
			while (guideLine = [enumerator nextObject]) {
				float distance = fabs(([guideLine isVertical] ? inLocation.x : inLocation.y) - [guideLine position]);
				if (distance < 3) {
					[self focusGuideLine:guideLine];
					return;
				}
			}
		}
		
		float distToClosestPoint = [[self selectedSerie] markerSize] + 3;
		GCPoint *closestPoint = nil;
		float distToClosestLine = [[self selectedSerie] connected] ? 5 : -1;
		GCPoint *closestLinePointA = nil;
		GCPoint *closestLinePointB = nil;
		
		BOOL first = YES;
		GCSerie *serie = [self selectedSerie];
		if (![serie visible])
			serie = nil;
		NSArray *points = [serie points];
		if ([[self selectedSerie] definesArea] && [points count] > 0) {
			NSMutableArray *array = [points mutableCopy];
			[array addObject:[array objectAtIndex:0]];
			points = [array autorelease];
		}
		NSEnumerator *enumerator = [points objectEnumerator];
		GCPoint *point;
		NSPoint lastPt;
		float lastDist;
		BOOL lastVisible;
		GCPoint *lastPoint;
		while (point = [enumerator nextObject]) {
			NSPoint pt = [point point];
			float dist = hypot(pt.x - inLocation.x, pt.y - inLocation.y);
			BOOL visible = [self isPointVisible:point];
			if (dist < distToClosestPoint && visible) {
				distToClosestPoint = dist;
				closestPoint = point;
			}
			
			if (!first && visible && lastVisible) {
				float distLine = MIN(lastDist, dist);
				NSPoint v = NSMakePoint(pt.x - lastPt.x, pt.y - lastPt.y);
				NSPoint p = NSMakePoint(inLocation.x - lastPt.x, inLocation.y - lastPt.y);
				float l = hypot(v.x, v.y);
				if (l > 0.0) {
					float k = 1.0 / l;
					v.x *= k;
					v.y *= k;
					float proj = p.x * v.x + p.y * v.y;
					if (proj > 0 && proj < l) {
						float dPerp = p.x * v.y - p.y * v.x;
						distLine = MIN(distLine, fabs(dPerp));
					}
				}
				if (distLine < distToClosestLine) {
					distToClosestLine = distLine;
					closestLinePointA = lastPoint; 
					closestLinePointB = point; 
				}
			}
			
			first = NO;
			lastPt = pt;
			lastDist = dist;
			lastVisible = visible;
			lastPoint = point;
		}
		
		if (closestPoint && closestLinePointA)
			if (distToClosestLine < 0.25 * distToClosestPoint)
				closestPoint = nil;
		if (closestPoint)
			[self focusPoint:closestPoint];
		else
			[self focusLineBetween:closestLinePointA and:closestLinePointB];
	}
}

-(NSRect)focusBounds
{
	if ([mFocusedPoints count] > 0) {
		NSRect rect = NSZeroRect;
		float r = [self focusRadius];
		NSEnumerator *enumerator = [mFocusedPoints objectEnumerator];
		GCPoint *point;
		while (point = [enumerator nextObject]) {
			NSPoint pt = [point point];
			rect = NSUnionRect(rect, NSMakeRect(pt.x - r, pt.y - r, 2 * r, 2 * r));
		}
		return [self boundsForRect:rect];
	} else
		return NSZeroRect;
}

-(void)focusPoints:(NSArray *)inPoints withColor:(NSColor *)inColor grow:(float)inGrow shadowRadius:(float)inShadowRadius zoom:(float)inZoom
{
	if ([inPoints count] == 0)
		return;
		
	static NSShadow *shadow = nil;
	if (!shadow) {
		shadow = [[NSShadow alloc] init];
		[shadow setShadowOffset:NSZeroSize];
	}
	GCSerie *serie = [self selectedSerie];
	[shadow setShadowBlurRadius:inShadowRadius];
	[shadow setShadowColor:inColor];
	
	[shadow set];
	
	float lineWidth = 1.0 / inZoom;
	[[shadow shadowColor] set];
	if ([inPoints count] >= 1) {
		NSBezierPath *bezierPath = [NSBezierPath bezierPath];
		BOOL fill = NO;
		float r = [self focusRadius] - [shadow shadowBlurRadius];
		NSEnumerator *enumerator = [inPoints objectEnumerator];
		GCPoint *point;
		while (point = [enumerator nextObject]) {
			NSPoint pt = [point point];
			pt.x += 0.5 * lineWidth;
			pt.y -= 0.5 * lineWidth;
			[self appendMarker:[serie marker] origin:pt radius:inGrow + [serie markerSize] * lineWidth toBezierPath:bezierPath fill:&fill];
		}
		if (fill)
			[bezierPath fill];
		else
			[bezierPath stroke];
	}
}

-(void)drawFocusInRect:(NSRect)inRect withZoomFactor:(float)inZoom
{
	[NSGraphicsContext saveGraphicsState];
	NSColor *color = [[[self selectedSerie] color] colorWithAlphaComponent:1.0];
	[self focusPoints:mFocusedPoints withColor:color grow:1.0 / inZoom shadowRadius:5 zoom:inZoom];
	if ([mFocusedPoints count] > 1) {
		BOOL first = YES;
		NSBezierPath *bezierPath = [NSBezierPath bezierPath];
		NSEnumerator *enumerator = [mFocusedPoints objectEnumerator];
		GCPoint *point;
		while (point = [enumerator nextObject]) {
			NSPoint pt = [point point];
			if (first)
				[bezierPath moveToPoint:pt];
			else
				[bezierPath lineToPoint:pt];
			first = NO;
		}
		[bezierPath setLineWidth:1.0 / inZoom];
		[bezierPath stroke];
	}
	
	[NSGraphicsContext restoreGraphicsState];
}

-(void)focusMouseDown:(NSEvent *)inEvent
{
	BOOL add = ([inEvent modifierFlags] & NSShiftKeyMask) != 0;
	
	BOOL selectionContainsFocusedPoints = YES;
	NSEnumerator *enumerator = [mFocusedPoints objectEnumerator];
	GCPoint *point;
	while (point = [enumerator nextObject])
		if (![[mPointController selectedObjects] containsObject:point]) {
			selectionContainsFocusedPoints = NO;
			break;
		}
	
	if (!selectionContainsFocusedPoints) {
		NSMutableSet *selection;
		if (!add)
			selection = [NSMutableSet set];
		else
			selection = [NSMutableSet setWithArray:[mPointController selectedObjects]];
		[selection addObjectsFromArray:mFocusedPoints];
		[mPointController setSelectedObjects:[selection allObjects]];
	}
	
	NSPoint mouse = [self convertEventLocation:inEvent];

	sDontFocus = YES;
	BOOL keepOn = YES;
	while (keepOn) {
		NSEvent *event = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];

		switch ([event type]) {
			case NSLeftMouseDragged: {
				NSPoint pt = [self convertEventLocation:event];
				[self setMagnificationLocation:pt];
				[self moveSelectedPointsBy:NSMakePoint(pt.x - mouse.x, pt.y - mouse.y)];
				mouse = pt;
				break;
			}
			case NSLeftMouseUp:
				keepOn = NO;
				break;
			default:
				break;
		}
	}
	sDontFocus = NO;

	[self setMagnificationLocation:mouse];
}

@end

@implementation GCView (Events)

-(void)selectAll:(id)inSender
{
	[mPointController setSelectionIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[[self selectedSerie] points] count])]];
	[self setNeedsDisplay:YES];
}

-(void)selectNone:(id)inSender
{
	[mPointController setSelectionIndexes:[NSIndexSet indexSet]];
	[self setNeedsDisplay:YES];
}

-(void)selectionMouseDown:(NSEvent *)inEvent
{
	NSPoint pt = [self convertEventLocation:inEvent];
	NSEnumerator *enumerator = [[mFrame guideLines] objectEnumerator];
	GCGuideLine *guideLine;
	while (guideLine = [enumerator nextObject]) {
		float distance = fabs(([guideLine isVertical] ? pt.x : pt.y) - [guideLine position]);
		if (distance < 3) {
			[self focusGuideLine:guideLine mouseDown:inEvent];
			return;
		}
	}
	
	if ([mFocusedPoints count] > 0)
		[self focusMouseDown:inEvent];
	else {
		BOOL add = ([inEvent modifierFlags] & NSShiftKeyMask) != 0;
		NSRect rect;
		NSPoint pt = [self convertEventLocation:inEvent];
		rect.origin = pt;
		rect.size = NSZeroSize;
		mSelectionPath = [NSBezierPath bezierPathWithRect:rect];
		mSelectionPathPhase = 0.0;
		[NSEvent startPeriodicEventsAfterDelay:0 withPeriod:0.1];
		NSArray *initialSelection = add ? [mPointController selectedObjects] : [NSArray array];
		NSMutableArray *selection = [NSMutableArray array];
		
		sDontFocus = YES;
		sSkipMagnifyingGlass = YES;
		float inset = -[self focusRadius];
		BOOL keepOn = YES;
		BOOL dragged = NO;
		while (keepOn) {
			NSEvent *event = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];

			switch ([event type]) {
				case NSLeftMouseDragged:
					pt = [self convertEventLocation:event];
					[self setMagnificationLocation:pt];
					[self setNeedsDisplayInRect:[self boundsForRect:rect]];
					rect.size = NSMakeSize(pt.x - rect.origin.x, pt.y - rect.origin.y);
					mSelectionPath = [NSBezierPath bezierPathWithRect:rect];
					
					[selection setArray:initialSelection];
					[selection addObjectsFromArray:[self pointsInRect:rect]];
					[mPointController setSelectedObjects:selection];
					[self setNeedsDisplayInRect:NSInsetRect([self boundsForRect:rect], inset, inset)];
					dragged = YES;
					break;
				case NSLeftMouseUp:
					keepOn = NO;
					break;
				case NSPeriodic:
					mSelectionPathPhase += 1.0;
					[self setNeedsDisplayInRect:[self boundsForRect:rect]];
					break;
				default:
					break;
			}
		}
		
		sDontFocus = NO;
		sSkipMagnifyingGlass = NO;
		[self setMagnificationLocation:pt];
		[NSEvent stopPeriodicEvents];
		mSelectionPath = nil;
		if (!dragged && !add)
			[mPointController setSelectedObjects:[NSArray array]];
		[self setNeedsDisplay:YES];
	}
}

-(void)scroll:(NSEvent *)inEvent
{
	id clipView = self;
	while (![clipView isKindOfClass:[NSClipView class]])
		if ((clipView = [clipView superview]) == nil)
			return;
	id scrollView = [clipView superview];
	NSPoint mouse = [self convertPoint:[inEvent locationInWindow] fromView:clipView];
	
	[[NSCursor closedHandCursor] push];
	BOOL keepOn = YES;
	while (keepOn) {
		NSEvent *event = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];

		switch ([event type]) {
			case NSLeftMouseDragged: {
				NSPoint pt = [self convertPoint:[event locationInWindow] fromView:clipView];
				NSPoint origin = [clipView bounds].origin;
				origin.x -= pt.x - mouse.x;
				origin.y -= pt.y - mouse.y;
				origin = [clipView constrainScrollPoint:origin];
				[clipView scrollToPoint:origin];
				[scrollView reflectScrolledClipView:clipView];
				mouse = pt;
				break;
			}
			case NSLeftMouseUp:
				keepOn = NO;
				break;
			default:
				break;
		}
	}
	[NSCursor pop];
}

-(void)moveSelectedPoints:(NSEvent *)inEvent
{
	NSPoint mouse = [self convertPoint:[inEvent locationInWindow] fromView:nil];
	
	[[NSCursor closedHandCursor] push];
	BOOL keepOn = YES;
	while (keepOn) {
		NSEvent *event = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];

		switch ([event type]) {
			case NSLeftMouseDragged: {
				NSPoint pt = [self convertPoint:[event locationInWindow] fromView:nil];
				[self moveSelectedPointsBy:NSMakePoint(pt.x - mouse.x, pt.y - mouse.y)];
				mouse = pt;
				break;
			}
			case NSLeftMouseUp:
				keepOn = NO;
				break;
			default:
				break;
		}
	}
	[NSCursor pop];
}

-(GCPoint *)closestPointTo:(NSPoint)inPoint
{
	float minDist = 15;
	GCPoint *closestPoint = nil;
	GCSerie *serie = [self selectedSerie];
	NSEnumerator *enumerator = [[serie points] objectEnumerator];
	GCPoint *point;
	while (point = [enumerator nextObject]) {
		NSPoint pt = [point point];
		float dist = hypot(pt.x - inPoint.x, pt.y - inPoint.y);
		if ([self isPointVisible:point] && dist < minDist) {
			minDist = dist;
			closestPoint = point;
		}
	}
	return closestPoint;
}

-(void)selectPoint:(NSPoint)inPoint
{
	GCPoint *point = [self closestPointTo:inPoint];
	if (point)
		[mPointController setSelectedObjects:[NSArray arrayWithObject:point]];
}

-(void)insertError:(NSPoint)inPoint symmetric:(BOOL)inSymmetric
{
	NSArray *selection = [mPointController selectedObjects];
	if ([selection count] != 1) {
		NSRunAlertPanel(NSLocalizedString(@"Insert error bar alert title", @""), NSLocalizedString(@"Insert error bar alert message", @""), nil, nil, nil);
		return;
	}
	GCPoint *point = [selection objectAtIndex:0];
	NSPoint pt = [mFrame convertToCoordinate:[point point]];
	NSPoint e = [mFrame convertToCoordinate:inPoint];
	e.x -= pt.x;
	e.y -= pt.y;
	float k = 0.5;
	if (fabs([point point].x - inPoint.x) < k * fabs([point point].y - inPoint.y))
		e.x = 0;
	else if (fabs([point point].y - inPoint.y) < k * fabs([point point].x - inPoint.x))
		e.y = 0;
	if (e.x < 0) {
		[point setXMinError:e.x];
		if (inSymmetric)
			[point setXMaxError:-e.x];
	}
	if (e.x > 0) {
		[point setXMaxError:e.x];
		if (inSymmetric)
			[point setXMinError:-e.x];
	}
	if (e.y < 0) {
		[point setYMinError:e.y];
		if (inSymmetric)
			[point setYMaxError:-e.y];
	}
	if (e.y > 0) {
		[point setYMaxError:e.y];
		if (inSymmetric)
			[point setYMinError:-e.y];
	}
	[self setNeedsDisplay:YES];
}

-(unsigned)deformationPointNear:(NSPoint)inPoint
{
	float minDist = 10;
	unsigned i, iMin = NSNotFound, n = [mFrame numberOfDeformations];
	int side;
	for (side = 0; side < 2; side++) {
		NSPoint bottom = [mFrame cornerPoint:side == 0 ? 0 : 1];
		NSPoint top = [mFrame cornerPoint:side == 0 ? 3 : 2];
		for (i = 0; i < n; i++) {
			NSPoint pt = [mFrame positionOfDeformationAtIndex:i leftSide:side == 0];
			float dist = hypot(pt.x - inPoint.x, pt.y - inPoint.y);
			if (dist < minDist) {
				minDist = dist;
				iMin = i;
			}
		}
	}
	return iMin;
}

-(void)deformMouseDown:(NSEvent *)inEvent
{
	NSPoint point = [self convertEventLocation:inEvent];
	unsigned deformation = [self deformationPointNear:point];
	if (deformation == NSNotFound)
		deformation = [mFrame addDeformationAtPoint:point withOffset:-1];
	if (deformation == NSNotFound) {
		NSBeep();
		return;
	}
	[mFrame selectDeformationAtIndex:deformation];
	float offset = [mFrame offsetOfDeformationAtIndex:deformation];
	[self setNeedsDisplay:YES];

	BOOL keepOn = YES;
	while (keepOn) {
		NSEvent *event = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];

		switch ([event type]) {
			case NSLeftMouseDragged:
				point = [self convertEventLocation:event];
				[self setMagnificationLocation:point];
				[mFrame removeDeformation:deformation];
				deformation = [mFrame addDeformationAtPoint:point withOffset:offset];
				if (deformation != NSNotFound)
					[mFrame selectDeformationAtIndex:deformation];
				[self setNeedsDisplay:YES];
				break;
			case NSLeftMouseUp:
				keepOn = NO;
				break;
			default:
				break;
		}
	}

	[mFrame didChange];
}

-(int)frameCornerForLocation:(NSPoint)inLocation
{
	float minDist = 10;
	int i, corner = -1;
	for (i = 0; i < 4; i++) {
		NSPoint point = [mFrame cornerPoint:i];
		float dist = hypot(point.x - inLocation.x, point.y - inLocation.y);
		if (dist < minDist) {
			minDist = dist;
			corner = i;
		}
	}
	return corner;
}

-(int)frameSideForLocation:(NSPoint)inLocation direction:(NSPoint *)outDirection
{
	int i, line = -1;
	float minDist = 10;
	NSPoint dir;
	for (i = 0; i < 4; i++) {
		NSPoint a = [mFrame cornerPoint:i];
		NSPoint b = [mFrame cornerPoint:(i + 1) % 4];
		if ((b.x - a.x) * (inLocation.x - a.x) + (b.y - a.y) * (inLocation.y - a.y) > 0 && 
			(a.x - b.x) * (inLocation.x - b.x) + (a.y - b.y) * (inLocation.y - b.y) > 0) {
				NSPoint d = NSMakePoint(b.x - a.x, b.y - a.y);
				float dl = hypot(d.x, d.y);
				d.x /= dl;
				d.y /= dl;
				NSPoint m = NSMakePoint(inLocation.x - a.x, inLocation.y - a.y);
				float dist = fabs(d.y * m.x - d.x * m.y);
				if (dist < minDist) {
					line = i;
					minDist = dist;
					dir = d;
				}
		}
	}
	if (outDirection)
		*outDirection = dir;
	return line;
}

-(void)frameMouseDown:(NSEvent *)inEvent
{
	mModifyingFrame = YES;
	
	NSPoint mouse = [self convertEventLocation:inEvent];
	int corner = [self frameCornerForLocation:mouse];
	if (corner >= 0) {
		[mFrame beginEditing];
		BOOL keepOn = YES;
		while (keepOn) {
			NSEvent *event = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];

			switch ([event type]) {
				case NSLeftMouseDragged:
					mouse = [self convertEventLocation:event];
					[self setMagnificationLocation:mouse];
					if (([event modifierFlags] & (NSShiftKeyMask | NSControlKeyMask)) != 0) {
						NSPoint delta = [mFrame cornerPoint:corner];
						delta.x = mouse.x - delta.x;
						delta.y = mouse.y - delta.y;
						int c = (corner + (((corner % 2 == 0) == (([event modifierFlags] & NSControlKeyMask) == 0)) ? 1 : 3)) % 4;
						NSPoint pt = [mFrame cornerPoint:c];
						pt.x += delta.x;
						pt.y += delta.y;
						[mFrame setCorner:c point:pt];
					} else if (([event modifierFlags] & NSCommandKeyMask) == 0) {
						NSPoint delta = [mFrame cornerPoint:corner];
						delta.x = mouse.x - delta.x;
						delta.y = mouse.y - delta.y;
						int i;
						for (i = -1; i <= 1; i += 2) {
							int c = (corner + i + 4) % 4;
							NSPoint pt = [mFrame cornerPoint:c];
							NSPoint d = [mFrame cornerPoint:(c + i + 4) % 4];
							d.x -= pt.x;
							d.y -= pt.y;
							float dl = hypot(d.x, d.y);
							if (dl > 0) {
								d.x /= dl;
								d.y /= dl;
								float k = delta.x * d.x + delta.y * d.y;
								pt.x += k * d.x;
								pt.y += k * d.y;
								[mFrame setCorner:c point:pt];
							}
						}
					}
					[mFrame setCorner:corner point:mouse];
					[self setNeedsDisplay:YES];
					break;
				case NSLeftMouseUp:
					keepOn = NO;
					break;
				default:
					break;
			}
		}
		[mFrame endEditing];
	} else {
		NSPoint dir;
		int line = [self frameSideForLocation:mouse direction:&dir];
		
		if (line >= 0) {
			[mFrame beginEditing];
			BOOL keepOn = YES;
			while (keepOn) {
				NSEvent *event = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];

				switch ([event type]) {
					case NSLeftMouseDragged: {
						mouse = [self convertEventLocation:event];
						int i;
						for (i = 0; i < 2; i++) {
							NSPoint pt = [mFrame cornerPoint:(line + i) % 4];
							NSPoint origin = [mFrame cornerPoint:(line + (i == 0 ? 3 : 2)) % 4];
							NSPoint a = NSMakePoint(pt.x - origin.x, pt.y - origin.y);
							float da = hypot(a.x, a.y);
							if (da > 0) {
								a.x /= da;
								a.y /= da;
							}
							float x = (mouse.x - origin.x) * dir.y - (mouse.y - origin.y) * dir.x;
							float y = -(mouse.x - origin.x) * a.y + (mouse.y - origin.y) * a.x;
							float det = a.x * dir.y - dir.x * a.y;
							x /= det;
							y /= det;
							[mFrame setCorner:(line + i) % 4 point:NSMakePoint(origin.x + x * a.x, origin.y + x * a.y)];
						}
						[self setMagnificationLocation:mouse];
						[self setNeedsDisplay:YES];
						break;
					}
					case NSLeftMouseUp:
						keepOn = NO;
						break;
					default:
						break;
				}
			}
			[mFrame endEditing];
		} else {
			BOOL dragging = [[self framePath] containsPoint:mouse];
			if (dragging)
				[[NSCursor closedHandCursor] push];
			BOOL keepOn = YES;
			[mFrame beginEditing];
			while (keepOn) {
				NSEvent *event = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];

				switch ([event type]) {
					case NSLeftMouseDragged: {
						NSPoint point = [self convertEventLocation:event];
						if (dragging) {
							int i;
							for (i = 0; i < 4; i++) {
								NSPoint corner = [mFrame cornerPoint:i];
								corner.x += point.x - mouse.x;
								corner.y += point.y - mouse.y;
								[mFrame setCorner:i point:corner];
							}
							mouse = point;
						} else {
							[mFrame setCorner:0 point:NSMakePoint(MIN(mouse.x, point.x), MIN(mouse.y, point.y))];
							[mFrame setCorner:1 point:NSMakePoint(MAX(mouse.x, point.x), MIN(mouse.y, point.y))];
							[mFrame setCorner:2 point:NSMakePoint(MAX(mouse.x, point.x), MAX(mouse.y, point.y))];
							[mFrame setCorner:3 point:NSMakePoint(MIN(mouse.x, point.x), MAX(mouse.y, point.y))];
						}
						[self setMagnificationLocation:point];
						[self setNeedsDisplay:YES];
						break;
					}
					case NSLeftMouseUp:
						keepOn = NO;
						break;
					default:
						break;
				}
			}
			if (dragging)
				[[NSCursor closedHandCursor] pop];
			[mFrame endEditing];
		}
	}
	
	[mFrame didChange];
	mModifyingFrame = NO;
}

-(void)setFrameCursorForLocation:(NSPoint)inLocation
{
	if (mModifyingFrame)
		return;
	NSCursor *cursor = [NSCursor emptyCrosshairCursor];
	switch ([self frameCornerForLocation:inLocation]) {
		case 0:
		case 2:
			cursor = [NSCursor diagonalResizeCursor];
			break;
		case 1:
		case 3:
			cursor = [NSCursor backDiagonalResizeCursor];
			break;
		default:
			switch ([self frameSideForLocation:inLocation direction:nil]) {
				case 0:	cursor = [NSCursor resizeUpCursor]; break;
				case 1:	cursor = [NSCursor resizeLeftCursor]; break;
				case 2:	cursor = [NSCursor resizeDownCursor]; break;
				case 3:	cursor = [NSCursor resizeRightCursor]; break;
				default: {
					if ([[self framePath] containsPoint:inLocation])
						cursor = [NSCursor openHandCursor];
				}
			}
			break;
	}
	[cursor set];
}

-(void)mouseDown:(NSEvent *)inEvent
{
	NSPoint pt = [self convertEventLocation:inEvent];
	if (mScrollView) {
		GCPoint *point = [self closestPointTo:pt];
		if ([[mPointController selectedObjects] containsObject:point])
			[self moveSelectedPoints:inEvent];
		else
			[self scroll:inEvent];
	} else if ([self containsMovie] && (([inEvent modifierFlags] & NSControlKeyMask) != 0)) {
		if (([inEvent modifierFlags] & NSShiftKeyMask) != 0)
			[self stepBack:nil];
		else
			[self stepForward:nil];
	} else
		switch (mSelectedTool) {
			case GCAddPointTool:
				if (([inEvent modifierFlags] & NSShiftKeyMask) != 0 && ([inEvent modifierFlags] & NSCommandKeyMask) == 0)
					[self selectPoint:pt];
				else if (([inEvent modifierFlags] & NSCommandKeyMask) != 0)
					[self insertError:pt symmetric:([inEvent modifierFlags] & NSShiftKeyMask) != 0];
				else
					[self insertPoint:pt];
				[[self window] performSelector:@selector(invalidateCursorRectsForView:) withObject:self afterDelay:0.0];
				break;
			case GCHorizontalCurveTool:
				[self detachMagicWandThreadWithPoint:pt type:GCHorizontalCurveType];
				break;
			case GCCurveTool:
				[self detachMagicWandThreadWithPoint:pt type:GCCurveType];
				break;
			case GCAreaTool:
				[self detachMagicWandThreadWithPoint:pt type:GCAreaType];
				break;
			case GCAreasTool:
				[self detachMagicWandThreadWithPoint:pt type:GCAreasType];
				break;
			case GCMagicBarTool:
				[self detachMagicWandThreadWithPoint:pt type:GCBarType];
				break;
			case GCMagicSymbolTool:
				[self detachMagicWandThreadWithPoint:pt type:GCMagicSymbolType];
				break;
			case GCFrameTool:
				[self frameMouseDown:inEvent];
				break;
			case GCSelectTool:
				[self selectionMouseDown:inEvent];
				break;
			case GCDeformTool:
				[self deformMouseDown:inEvent];
				break;
			case GCMaskBrushTool:
				[self maskBrushMouseDown:inEvent kind:0];
				break;
			case GCMaskEraseTool:
				[self maskBrushMouseDown:inEvent kind:1];
				break;
			case GCImageEraseTool:
				[self maskBrushMouseDown:inEvent kind:2];
				break;
			case GCMaskRectangleTool:
				[self maskRectangleMouseDown:inEvent];
				break;
				
			case GCAdjustAbscissa1:
			case GCAdjustAbscissa2:
			case GCAdjustOrdinate1:
			case GCAdjustOrdinate2:
			case GCAdjustPosition1:
			case GCAdjustPosition2:
			case GCAdjustPositionB1:
			case GCAdjustPositionB2:
			case GCAdjustPositionB3:
			case GCAdjust3Points1:
			case GCAdjust3Points2:
			case GCAdjust3Points3:
			case GCAdjust4Points1:
			case GCAdjust4Points2:
			case GCAdjust4Points3:
			case GCAdjust4Points4:
			case GCAdjustAbscissaOrdinate1:
			case GCAdjustAbscissaOrdinate2:
			case GCAdjustAbscissaOrdinate3:
			case GCAdjustAbscissaOrdinate4:
			case GCAdjustOrigin:
			case GCAdjustWithWizard:
				[self promptCoordinates];
				break;
			
			case GCAdjustScale1:
			case GCAdjustScale2:
				[self promptScale];
				break;
		}
}

-(void)mouseMoved:(NSEvent *)inEvent
{
	[self setMagnificationLocation:[self convertEventLocation:nil]];
}

-(void)flagsChanged:(NSEvent *)inEvent
{
	if (mScrollView != (([inEvent modifierFlags] & NSAlternateKeyMask) != 0)) {
		mScrollView = !mScrollView;
		[self setMagnificationLocation:[self convertEventLocation:nil]];
	}
	[[self window] invalidateCursorRectsForView:self];
	if (mSelectedTool == GCFrameTool)
		[self setFrameCursorForLocation:[self convertEventLocation:nil]];
}

-(void)appearanceDidChange:(NSNotification *)inNotification
{
	if ([inNotification object] == mFrame)
		[self setNeedsDisplay:YES];
}

-(void)moveSelectedPointsBy:(NSPoint)inDelta
{
	[mFrame beginEditing];
	NSEnumerator *enumerator = [[mPointController selectedObjects] objectEnumerator];
	GCPoint *point;
	while (point = [enumerator nextObject]) {
		NSPoint pt = [point point];
		[point setPoint:NSMakePoint(pt.x + inDelta.x, pt.y + inDelta.y)];
	}
	[mFrame didChange];
	[mFrame endEditing];
	[self setNeedsDisplay:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:GCSelectedPointsDidMoveNotification object:self];
}

-(void)moveUp:(id)inSender
{
	[self moveSelectedPointsBy:NSMakePoint(0, 1)];
}

-(void)moveUpAndModifySelection:(id)inSender
{
	[self moveSelectedPointsBy:NSMakePoint(0, 0.2)];
}

-(void)moveParagraphBackwardAndModifySelection:(id)inSender
{
	[self moveSelectedPointsBy:NSMakePoint(0, 5)];
}

-(void)moveDown:(id)inSender
{
	[self moveSelectedPointsBy:NSMakePoint(0, -1)];
}

-(void)moveDownAndModifySelection:(id)inSender
{
	[self moveSelectedPointsBy:NSMakePoint(0, -0.2)];
}

-(void)moveParagraphForwardAndModifySelection:(id)inSender
{
	[self moveSelectedPointsBy:NSMakePoint(0, -5)];
}

-(void)moveLeft:(id)inSender
{
	[self moveSelectedPointsBy:NSMakePoint(-1, 0)];
}

-(void)moveLeftAndModifySelection:(id)inSender
{
	[self moveSelectedPointsBy:NSMakePoint(-0.2, 0)];
}

-(void)moveWordLeftAndModifySelection:(id)inSender
{
	[self moveSelectedPointsBy:NSMakePoint(-5, 0)];
}

-(void)moveRight:(id)inSender
{
	[self moveSelectedPointsBy:NSMakePoint(1, 0)];
}

-(void)moveRightAndModifySelection:(id)inSender
{
	[self moveSelectedPointsBy:NSMakePoint(0.2, 0)];
}

-(void)moveWordRightAndModifySelection:(id)inSender
{
	[self moveSelectedPointsBy:NSMakePoint(5, 0)];
}

-(void)deleteBackward:(id)inSender
{
	[mPointController remove:inSender];
}

-(void)delete:(id)inSender
{
	[mPointController remove:inSender];
}

-(void)keyDown:(NSEvent *)inEvent
{
    [self interpretKeyEvents:[NSArray arrayWithObject:inEvent]];
}

@end

@implementation GCView (Zoom)

-(float)zoomFactor
{
	return mZoomFactor;
}

-(void)setZoomFactor:(float)inZoomFactor
{
	id clipView = self;
	while (![clipView isKindOfClass:[NSClipView class]])
		if ((clipView = [clipView superview]) == nil)
			return;
	id scrollView = [clipView superview];
	NSRect visibleRect = [self visibleRect];
	NSPoint center = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
	if (!NSPointInRect(center, visibleRect))
		center = NSMakePoint(NSMidX(visibleRect), NSMidY(visibleRect));
	NSPoint corner = NSMakePoint(NSMinX(visibleRect), NSMinY(visibleRect));
	float k = inZoomFactor / mZoomFactor - 1.0;
	corner.x += center.x * k;
	corner.y += center.y * k;
	corner.x = round(corner.x);
	corner.y = round(corner.y);
	
	mZoomFactor = inZoomFactor;
	NSSize size = NSMakeSize(mBounds.size.width * mZoomFactor, mBounds.size.height * mZoomFactor);
	[self setFrameSize:size];
	[self resizeWithOldSuperviewSize:size];

	[clipView scrollToPoint:[clipView constrainScrollPoint:corner]];
	[scrollView reflectScrolledClipView:clipView];

	[[self superview] setNeedsDisplay:YES];
	[self setMagnificationLocation:mMagnificationLocation];

	[self updateZoomPopUp];
	[self mouseMoved:nil];
}

-(void)updateZoomPopUp
{
	int index = [mZoomPopUp indexOfItemWithTag:0];
	if (index >= 0)
		[mZoomPopUp removeItemAtIndex:index];
	
	index = [mZoomPopUp indexOfItemWithTag:mZoomFactor * 100];
	if (index >= 0)
		[mZoomPopUp selectItemAtIndex:index];
	else {
//		[mZoomPopUp selectItemWithTag:-1];
		[mZoomPopUp selectItemAtIndex:[mZoomPopUp indexOfItemWithTag:-1]];
		[mZoomPopUp setTitle:[NSString stringWithFormat:@"%i%%", (int)round(mZoomFactor * 100)]];
	}
}

-(NSArray *)preferedZoomFactors
{
	static NSArray *array = nil;
	if (!array)
		array = [[NSArray alloc] initWithObjects:[NSNumber numberWithFloat:1./10],
					[NSNumber numberWithFloat:1./5], [NSNumber numberWithFloat:1./4],
					[NSNumber numberWithFloat:1./3], [NSNumber numberWithFloat:1./2], [NSNumber numberWithFloat:3./4], 
					[NSNumber numberWithFloat:1], [NSNumber numberWithFloat:1.5], [NSNumber numberWithFloat:2],
					[NSNumber numberWithFloat:3],  [NSNumber numberWithFloat:4], 
					[NSNumber numberWithFloat:8], nil];
	return array;
}

-(IBAction)zoomIn:(id)inSender
{
	NSEnumerator *enumerator = [[self preferedZoomFactors] objectEnumerator];
	id factor;
	while (factor = [enumerator nextObject])
		if ([factor floatValue] > mZoomFactor)
			break;
	if (factor)
		[self setZoomFactor:[factor floatValue]];
}

-(IBAction)zoomOut:(id)inSender
{
	NSEnumerator *enumerator = [[self preferedZoomFactors] reverseObjectEnumerator];
	id factor;
	while (factor = [enumerator nextObject])
		if ([factor floatValue] < mZoomFactor)
			break;
	if (factor)
		[self setZoomFactor:[factor floatValue]];
}

-(IBAction)resetZoomFactor:(id)inSender
{
	[self setZoomFactor:1.0];
}

-(float)adjustedZoomFactor
{
	id clipView = self;
	while (![clipView isKindOfClass:[NSClipView class]])
		if ((clipView = [clipView superview]) == nil)
			return;
	NSSize size = [clipView visibleRect].size;
	return MIN(size.width / mBounds.size.width, size.height / mBounds.size.height);
}

-(IBAction)adjustZoomFactor:(id)inSender
{
	[self setZoomFactor:[self adjustedZoomFactor]];
}

-(IBAction)selectZoomFactor:(id)inSender
{
	int tag = [inSender selectedTag];
	if (tag > 0)
		[self setZoomFactor:(float)tag / 100];
	else if (tag == -1)
		[self adjustZoomFactor:nil];
}

-(NSPoint)convertEventLocation:(NSEvent *)inEvent
{
	NSPoint pt;
	if (inEvent)
		pt = [inEvent locationInWindow];
	else
		pt = [[self window] convertScreenToBase:[NSEvent mouseLocation]];
	pt = [self convertPoint:pt fromView:nil];
	pt.x /= mZoomFactor;
	pt.y /= mZoomFactor;
	return pt;
}

@end

@implementation GCView (Coordinates)

-(id)coordinates
{
	return [NSValue valueWithPoint:mCoordinates];
}

-(float)xCoordinate
{
	return mCoordinates.x;
}

-(float)yCoordinate
{
	return mCoordinates.y;
}

-(BOOL)validCoordinates
{
	return mValidMagnificationLocation && mSelectedTool != GCAdjustWithWizard;
}

@end

@implementation GCView (Tool)

-(int)selectedTool
{
	return mSelectedTool;
}

-(void)setSelectedTool:(int)inTool
{
	if (mSelectedTool != inTool) {
		if (mSelectedTool < GCAdjustAbscissa1)
			mPreviousSelectedTool = mSelectedTool;
		[self willChangeValueForKey:@"coordinatePrompt"];
		[self willChangeValueForKey:@"validCoordinates"];
		mSelectedTool = inTool;
		[self didChangeValueForKey:@"coordinatePrompt"];
		[self didChangeValueForKey:@"validCoordinates"];
		[[self window] invalidateCursorRectsForView:self];
		[self setMagnificationLocation:mMagnificationLocation];
	}
}

-(IBAction)selectFrameTool:(id)inSender
{
	[self setSelectedTool:GCFrameTool];
}

-(IBAction)resetDefaultFrame:(id)inSender
{
	[mFrame beginEditing];
	[mFrame setFrameRect:NSInsetRect(mBounds, 20, 20)];
	[mFrame removeDeformations];
	[mFrame endEditing];
	[self setNeedsDisplay:YES];
}

-(IBAction)adjustFrame:(id)inSender
{
	[mFrame beginEditing];
	NSSize size = [self imageBoundsSize];
	NSRect rect = NSInsetRect(mBounds, (mBounds.size.width - size.width) / 2 + 0.5, (mBounds.size.height - size.height) / 2 + 0.5);
	if ((int)(size.width) % 2 == 1)
		rect.origin.x += 0.5;
	if ((int)(size.height) % 2 == 0)
		rect.origin.y += 0.5;
	rect.origin.x -= 1;
	rect.size.width += 1;
	rect.size.height += 1;
	[mFrame setCorner:0 point:NSMakePoint(NSMinX(rect), NSMinY(rect))];
	[mFrame setCorner:1 point:NSMakePoint(NSMaxX(rect), NSMinY(rect))];
	[mFrame setCorner:2 point:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
	[mFrame setCorner:3 point:NSMakePoint(NSMinX(rect), NSMaxY(rect))];
	[mFrame removeDeformations];
	[mFrame endEditing];
	[self setNeedsDisplay:YES];
}

-(IBAction)undistortFrame:(id)inSender
{
	[mFrame beginEditing];
	NSPoint a = [mFrame cornerPoint:0];
	NSPoint b = [mFrame cornerPoint:1];
	NSPoint c = [mFrame cornerPoint:3];
	[mFrame setCorner:2	point:NSMakePoint(b.x + c.x - a.x, b.y + c.y - a.y)];
	[mFrame removeDeformations];
	[mFrame endEditing];
	[self setNeedsDisplay:YES];
}

-(IBAction)removeErrors:(id)inSender
{
	NSArray *selection = [mPointController selectedObjects];
	NSEnumerator *enumerator;
	if ([selection count] > 0)
		enumerator = [selection objectEnumerator];
	else
		enumerator = [[[[mSerieController selectedObjects] lastObject] points] objectEnumerator];
		
	[mFrame beginEditing];
	GCPoint *point;
	while (point = [enumerator nextObject]) {
		[point setXMinError:0];
		[point setXMaxError:0];
		[point setYMinError:0];
		[point setYMaxError:0];
	}
	[mFrame endEditing];
	
	[self setNeedsDisplay:YES];
}

-(BOOL)hideFrame
{
	return mHideFrame;
}

-(void)setHideFrame:(BOOL)inHide
{
	if (mHideFrame != inHide) {
		mHideFrame = inHide;
		[self setNeedsDisplay:YES];
	}
}

-(IBAction)toggleGuide:(id)inSender
{
	[self setNeedsDisplayInRect:[self guideBounds]];
	[mGuide setVisible:![mGuide visible]];
	[self setNeedsDisplayInRect:[self guideBounds]];
}

-(IBAction)editGuideSettings:(id)inSender
{
	[mGuidePreview setGuide:mGuide];
	[NSApp beginSheet:mGuideSettingsWindow modalForWindow:[self window] modalDelegate:self
				didEndSelector:@selector(guideSheetDidEnd:returnCode:contextInfo:) contextInfo:[[NSArchiver archivedDataWithRootObject:mGuide] retain]];
}

-(id)guide
{
	return mGuide;
}

-(IBAction)cancelGuideSettings:(id)inSender
{
	[NSApp endSheet:mGuideSettingsWindow returnCode:NSCancelButton];
}

-(IBAction)confirmGuideSettings:(id)inSender
{
	[NSApp endSheet:mGuideSettingsWindow returnCode:NSOKButton];
}

-(void)guideSheetDidEnd:(NSWindow *)inSheet returnCode:(int)inReturnCode contextInfo:(NSData *)inGuideData
{
	if (inReturnCode == NSCancelButton) {
		[self willChangeValueForKey:@"guide"];
		[mGuide release];
		mGuide = [[NSUnarchiver unarchiveObjectWithData:inGuideData] retain];
		[self didChangeValueForKey:@"guide"];
	}
	[inGuideData release];
	[mGuideSettingsWindow orderOut:nil];
	[mGuidePreview setGuide:nil];
	[self setNeedsDisplay:YES];
	[self flagsChanged:nil];
}

@end

@implementation GCView (URL)

-(float)imageAngleForURL:(NSURL *)inURL
{
	if ([NSApp systemVersion] < 0x01040)
		return 0.0;
		
	int orientation = 0; 
	CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)inURL, nil);
	if (CGImageSourceGetCount(source) >= 1) {
		CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil);
		if (properties) {
			orientation = [[(id)properties objectForKey:(id)kCGImagePropertyTIFFOrientation] intValue];
			CFRelease(properties);
		}
	}
	CFRelease(source);

	static float angles[4] = {0, 180, -90, 90};
	return angles[MAX(0, MIN(8, orientation) - 1) / 2];
}

-(BOOL)containsURL
{
	return mURL != nil;
}

-(NSImage *)checkedImage:(NSImage *)inImage
{
//	NSLog(@"Pasted image: %@", inImage);
//	NSLog(@"Pasted representations: %@", [inImage representations]);
	NSImageRep *representation;
	if ([[inImage representations] count] == 1 && [(representation = [[inImage representations] objectAtIndex:0]) isKindOfClass:[NSPICTImageRep class]]) {
		NSData *data = [inImage TIFFRepresentation];
		inImage = [[[NSImage alloc] initWithData:data] autorelease];
	}
	return inImage;	
}

-(BOOL)setURL:(NSURL *)inURL asUser:(BOOL)inUser
{
	BOOL ok = NO;
	
	NSImage *image = [[[NSImage alloc] initWithContentsOfURL:inURL] autorelease];
	NSMovie *movie = [[[NSMovie alloc] initWithURL:inURL byReference:YES] autorelease];
	if (image != nil && movie != nil) {
		if ([movie duration] < 0.13)
			movie = nil;
		else
			image = nil;
    }
    
	if (image) {
		image = [self checkedImage:image];
		if (inUser) {
			[self setStillImageAsUser:image];
			[self setImageAngle:[self imageAngleForURL:inURL]];
		} else
			[self setStillImage:image];
		ok = YES;
	}
	
	if (movie) {
		if (inUser)
			[self setMovieAsUser:movie];
		else
			[self setMovie:movie];
		ok = YES;
	}
	
	if (ok && mURL != inURL) {
		[self willChangeValueForKey:@"containsURL"];
		[mURL release];
		mURL = [inURL retain];
		[self didChangeValueForKey:@"containsURL"];
	}
	
	return ok;
}

-(BOOL)setURL:(NSURL *)inURL
{
	return [self setURL:inURL asUser:YES];
}

-(void)removeURL
{
	if (mURL) {
		[self willChangeValueForKey:@"containsURL"];
		[mURL autorelease];
		mURL = nil;
		[self didChangeValueForKey:@"containsURL"];
	}
}

-(void)reloadURL:(id)inSender
{
	if ([self containsMovie])
		[self setTime:[self time]];
	else
		[self setURL:mURL asUser:NO];
}

@end

@implementation GCView (Image)

-(NSImage *)image
{
	return mImage;
}

-(void)setStillImage:(NSImage *)inImage
{
	[self setMovie:nil];
	if (mImage != inImage) {
		[mFrame beginEditingImageWillChange:YES];
		[self removeURL];
		[self setImage:inImage adjustIfNeeded:YES];
		[mFrame endEditing];
	}
}

-(void)setStillImageAsUser:(NSImage *)inImage
{
	[self setStillImage:inImage];
	[self performSelector:@selector(autoAdjustCoordinates:) withObject:nil afterDelay:0.0];
}

-(void)setImage:(NSImage *)inImage
{
	[self setImage:inImage adjustIfNeeded:NO];
}

-(void)setImage:(NSImage *)inImage adjustIfNeeded:(BOOL)inAdjust
{
	if (mImage != inImage) {
		[mFrame beginEditing];
		[mImage release];
		mImage = [inImage retain];
		[mImage setCacheMode:NSImageCacheNever];
		[mImage setSize:[mImage pixelSize]];
		[mFrame setImageOrigin:[self imageOriginWithZoomFactor:1.0]];
		[mFrame endEditing];
		[self setNeedsDisplay:YES];
		
		if (inAdjust) {
			NSSize imageSize = [mImage size];
			NSSize viewSize = [self bounds].size;
			float zoomFactor = [self zoomFactor];
			viewSize.width /= zoomFactor;
			viewSize.height /= zoomFactor;
			if (imageSize.width > viewSize.width || imageSize.height > viewSize.height) {
				[self adjustSizeToImage:nil];
				[self resetDefaultFrame:nil];
			} else if (mImage != [GCDocument defaultImage] && (imageSize.width < viewSize.width - 50 || imageSize.height < viewSize.height - 50))
				[self adjustSizeToImage:nil];
			zoomFactor = [self adjustedZoomFactor];
			if (zoomFactor < 1.0)
				[self setZoomFactor:zoomFactor];
		}
	}
}

-(void)autoAdjustCoordinates:(id)inSender
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:GCAutoAdjustCoordinates])
		[self adjustCoordinates];
}

-(float)imageFraction
{
	return mImageFraction;
}

-(void)setImageFraction:(float)inFraction
{
	if (mImageFraction != inFraction) {
		mImageFraction = inFraction;
		[self setNeedsDisplay:YES];
	}
}

-(float)imageAngle
{
	return mImageAngle;
}

-(void)setImageAngle:(float)inAngle
{
	if (mImageAngle != inAngle) {
		mImageAngle = inAngle;
		[self setNeedsDisplay:YES];
	}
}

-(float)imageScale
{
	return mImageScale;
}

-(void)setImageScale:(float)inScale
{
	if (mImageScale != inScale) {
		mImageScale = inScale;
		[self setNeedsDisplay:YES];
	}
}

-(NSSize)imageBoundsSize
{
	NSRect r = NSZeroRect;
	r.size = [mImage size];
	NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRect:r];
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform rotateByDegrees:mImageAngle];
	[transform scaleBy:mImageScale];
	return [[transform transformBezierPath:bezierPath] bounds].size;
}

-(IBAction)adjustSizeToImage:(id)inSender
{
	NSSize size = [self imageBoundsSize];
	size.width += 40;
	size.height += 40;
	[self setSize:size];
	
	NSRect rect = NSZeroRect;
	rect.size = size;
	int i;
	for (i = 0; i < 4; i++)
		if (!NSPointInRect([mFrame cornerPoint:i], rect))
			break;
	if (i < 4)
		[self resetDefaultFrame:nil];
}

-(IBAction)readjustCustomProjection:(id)inSender
{
	NSEnumerator *enumerator = [[GCAdjustmentWizard availableAdjustmentWizardClassNames] objectEnumerator];
	NSString *className;
	while (className = [enumerator nextObject]) {
		Class wizardClass = NSClassFromString(className);
		if ([wizardClass customProjectionClass] == [[mFrame customProjection] class]) {
			[self setAdjustmentWizard:[wizardClass adjustmentWizard]];
			[mAdjustmentWizard performSelector:@selector(beginReadjustmentInView:) withObject:self afterDelay:0.0];
			break;
		}
	}
}

-(BOOL)canPaste
{
	if ([self canPastePoints])
		return YES;
	if ([self canPasteCoordinates])
		return YES;
	NSImage *image = [[[NSImage alloc] initWithPasteboard:[NSPasteboard generalPasteboard]] autorelease];
	return image != nil;
}

-(void)paste:(id)inSender
{
    // Weird: in theory the NSImage initWithPasteboard should handle the NSFilenamesPboardType but in reality
    // only the icon of the file is returned as the image instead of the content of it. So do it ourself.
    NSImage *image = nil;
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSArray *files = [pb propertyListForType:NSFilenamesPboardType];
    if (files.count > 0) {
        // If a file is specified, read it manually
        image = [[[NSImage alloc] initWithContentsOfFile:[files objectAtIndex:0]] autorelease];
    }
    if (nil == image) {
        // Otherwise try the default method.
        image = [[[NSImage alloc] initWithPasteboard:[NSPasteboard generalPasteboard]] autorelease];
    }
	if (image)
		[self setStillImageAsUser:[self checkedImage:image]];
	else if ([self canPastePoints])
		[self pastePoints:inSender];
	else
		[self pasteCoordinates:inSender];
}

-(NSDragOperation)draggingEntered:(id <NSDraggingInfo>)inSender
{
	return NSDragOperationCopy;
}

-(BOOL)performDragOperation:(id <NSDraggingInfo>)inSender
{
    NSPasteboard *pboard = [inSender draggingPasteboard];

	if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		if ([files count] == 1) {
			id file = [files objectAtIndex:0];
			if ([self setURL:[NSURL fileURLWithPath:file]])
				return YES;
		}
    }

	if ([[pboard types] containsObject:NSURLPboardType]) {
		if ([self setURL:[NSURL URLFromPasteboard:pboard]])
			return YES;
    }

	NSImage *image = [[[NSImage alloc] initWithPasteboard:pboard] autorelease];
	if (image) {
		[self setStillImageAsUser:image];
		return YES;
	}

    return NO;
}

-(NSData *)imageData
{
	return [NSArchiver archivedDataWithRootObject:mImage];
}

-(void)setImageData:(NSData *)inData
{
	NSImage *image = [NSUnarchiver unarchiveObjectWithData:inData];
	if (image) {
		[mImage release];
		mImage = [image retain];
		[self setNeedsDisplay:YES];
	}
}

-(void)setImageContent:(int)inContent
{
	int symbol = 1 << (1 + 1 * 3);
	switch (inContent) {
		case 1:
			symbol = 1 << (1 + 2 * 3);
			break;
		case 2:
			symbol = 1 << (2 + 1 * 3);
			break;
	}
	[self setSymbolDetect:symbol];
}

-(int)symbolDetect
{
	int x, y, s = 0;
	for (x = 0; x < 3; x++)
		for (y = 0; y < 3; y++)
			if (mSymbolDetect[x][y])
				s += 1 << (x + 3 * y);
	return s;
}

-(void)setSymbolDetect:(int)inDetect
{
	int x, y;
	for (x = 0; x < 3; x++)
		for (y = 0; y < 3; y++) {
			id key = [NSString stringWithFormat:@"symbol%i%i", x + 1, y + 1];
			[self willChangeValueForKey:key];
			mSymbolDetect[x][y] = (inDetect & (1 << (x + 3 * y))) != 0;
			[self didChangeValueForKey:key];
		}
}

-(IBAction)filterImage:(id)inSender
{
	GCFilterController *controller = [GCFilterController sharedController];
	if (!controller) {
		NSRunAlertPanel(NSLocalizedString(@"Core Image Unavailable Title", @""), NSLocalizedString(@"Core Image Unavailable Message", @""), nil, nil, nil);
		return;
	}
	NSImage *image = [controller editImage:mImage];
	if (image)
		[self setImage:image];
}

-(void)exportImage:(id)inSender
{
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setRequiredFileType:@"pdf"];
	[panel setCanSelectHiddenExtension:YES];
	[panel beginSheetForDirectory:nil file:nil
		modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(exportImagePanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(void)exportImagePanelDidEnd:(NSSavePanel *)inPanel returnCode:(int)inReturnCode contextInfo:(void *)inInfo
{
	if (inReturnCode == NSOKButton) {
		BOOL frameHidden = mHideFrame;
		mHideFrame = YES;
		NSData *data = [self dataWithPDFInsideRect:[self bounds]];
		mHideFrame = frameHidden;
		[data writeToFile:[inPanel filename] atomically:YES];
	}
}

@end

@implementation GCView (Mask)

-(NSColor *)paintClearColor
{
	return [mHistogram backgroundColorOfImage:mImage];
//	return [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
}

-(void)drawMaskWithZoomFactor:(float)inZoom
{
	float fraction = [[NSUserDefaults standardUserDefaults] floatForKey:GCMaskOpacity];
	GCMask *mask = [mFrame mask];
	NSImage *image = [mask image];
	if (image) {
		NSRect r = NSZeroRect;
		r.size = [image size];
		[image dissolveToRect:r fraction:fraction];
	}
	if (mMaskPath) {
		[[[GCMask color] colorWithAlphaComponent:fraction] set];
		[mMaskPath fill];
	}
}

-(float)brushSize
{
	return [[NSUserDefaults standardUserDefaults] floatForKey:GCMaskBrushSize];
}

-(void)maskBrushMouseDown:(NSEvent *)inEvent kind:(int)inKind
{
	[mFrame beginEditingImageWillChange:inKind == 2];
	GCMask *mask = [mFrame maskWithBounds:mBounds];
	NSPoint origin = [mask bounds].origin;
	if (inKind == 2) {
		mask = (id)self;
		[[NSNotificationCenter defaultCenter] postNotificationName:GCImageWillChangeNotification object:self];
	}
	float brushRadius = [self brushSize];
	NSSize size = NSMakeSize(2 * brushRadius, 2 * brushRadius);
	NSPoint pt = [self convertEventLocation:inEvent];
	NSRect updateRect = [mask brushAtPoint:pt size:size kind:inKind];
	[self setNeedsDisplayInRect:[self boundsForRect:updateRect]];

	BOOL keepOn = YES;
	while (keepOn) {
		NSEvent *event = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];

		switch ([event type]) {
			case NSLeftMouseDragged: {
				NSPoint mouse = [self convertEventLocation:event];
				updateRect = [mask brushFromPoint:pt toPoint:mouse size:size kind:inKind];
				pt = mouse;
				[self setMagnificationLocation:mouse];
				[self setNeedsDisplayInRect:[self boundsForRect:updateRect]];
				break;
			}
			case NSLeftMouseUp:
				keepOn = NO;
				break;
		}
	}

	if (inKind == 2)
		[[NSNotificationCenter defaultCenter] postNotificationName:GCImageDidChangeNotification object:self];
	[mFrame endEditing];
}

-(void)maskRectangleMouseDown:(NSEvent *)inEvent
{
	NSRect rect;
	rect.origin = [self convertEventLocation:inEvent];
	rect.size = NSZeroSize;
	mMaskPath = [NSBezierPath bezierPathWithRect:rect];
	
	BOOL keepOn = YES;
	while (keepOn) {
		NSEvent *event = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];

		switch ([event type]) {
			case NSLeftMouseDragged: {
				NSPoint pt = [self convertEventLocation:event];
				rect.size = NSMakeSize(pt.x - rect.origin.x, pt.y - rect.origin.y);
				[self setNeedsDisplayInRect:[self boundsForRect:[mMaskPath bounds]]];
				mMaskPath = [NSBezierPath bezierPathWithRect:rect];
				[self setNeedsDisplayInRect:[self boundsForRect:[mMaskPath bounds]]];
				break;
			}
			case NSLeftMouseUp:
				keepOn = NO;
				break;
			default:
				break;
		}
	}
	
	[mFrame beginEditing];
	[[mFrame maskWithBounds:mBounds] paintPath:mMaskPath];
	[mFrame endEditing];
	mMaskPath = nil;
	[self setNeedsDisplay:YES];
}

-(void)clearMask:(id)inSender
{
	if ([mFrame mask]) {
		[mFrame beginEditing];
		[mFrame setMask:nil];
		[mFrame endEditing];
		[self setNeedsDisplay:YES];
	}
}

@end

@implementation GCView (Size)

-(void)setSize:(NSSize)inSize
{
	if (!NSEqualSizes(mBounds.size, inSize)) {
		[self willChangeValueForKey:@"width"];
		[self willChangeValueForKey:@"height"];
		[mFrame beginEditing];
		mBounds.size = inSize;
		[self setZoomFactor:mZoomFactor];
		[mFrame endEditing];
		[self didChangeValueForKey:@"width"];
		[self didChangeValueForKey:@"height"];
	}
}

-(float)width
{
	return mBounds.size.width;
}

-(float)height
{
	return mBounds.size.height;
}

-(void)setWidth:(float)inWidth
{
	if (mBounds.size.width != inWidth) {
		[mFrame beginEditing];
		mBounds.size.width = inWidth;
		[self setZoomFactor:mZoomFactor];
		[mFrame endEditing];
	}
}

-(void)setHeight:(float)inHeight
{
	if (mBounds.size.height != inHeight) {
		[mFrame beginEditing];
		mBounds.size.height = inHeight;
		[self setZoomFactor:mZoomFactor];
		[mFrame endEditing];
	}
}

@end

@implementation GCView (Movie)

-(BOOL)containsMovie
{
	return mMovie != nil;
}

-(void)setMovie:(NSMovie *)inMovie
{
	if ([inMovie QTMovie] == nil)
		inMovie = nil;
	if (!(mMovie == nil && inMovie == nil) && ![[mMovie URL] isEqual:[inMovie URL]]) {
		[mFrame beginEditing];
		[self removeURL];
		[self willChangeValueForKey:@"containsMovie"];
		[self willChangeValueForKey:@"minTime"];
		[self willChangeValueForKey:@"maxTime"];
		[mMovie release];
		mMovie = [inMovie retain];
		[self didChangeValueForKey:@"containsMovie"];
		[self didChangeValueForKey:@"minTime"];
		[self didChangeValueForKey:@"maxTime"];
		[self setTime:0 wait:YES];
		[self setImage:[mMovie imageAtTimeFromPoster:mTime] adjustIfNeeded:YES];
		[mFrame endEditing];
	}
}

-(void)setMovieAsUser:(NSMovie *)inMovie
{
	[self setMovie:inMovie];
	[self performSelector:@selector(autoAdjustCoordinates:) withObject:nil afterDelay:0.0];
}

-(float)time
{
	return mTime;
}

-(void)setTime:(float)inTime
{
	[self setTime:inTime wait:NO];
}

-(void)setTime:(float)inTime wait:(BOOL)inWait
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self willChangeValueForKey:@"canStepBack"];
	[self willChangeValueForKey:@"canStepForward"];
	[self willChangeValueForKey:@"time"];
	mTime = MAX([self minTime], MIN([self maxTime], inTime));
	if (mMovie) {
		if (inWait)
			[self setImage:[mMovie imageAtTimeFromPoster:mTime] adjustIfNeeded:NO];
		else
			[self requestMovieImageAtTime:mTime];
    }
	[self didChangeValueForKey:@"canStepBack"];
	[self didChangeValueForKey:@"canStepForward"];
	[self didChangeValueForKey:@"time"];
	[pool release];
}

-(float)minTime
{
	if (mMovie)
		return -[mMovie posterTime];
	else
		return 0.0;
}

-(float)maxTime
{
	if (mMovie)
		return [mMovie duration] - [mMovie posterTime];
	else
		return 0.0;
}

-(float)timeStep
{
	return mTimeStep;
}

-(void)setTimeStep:(float)inTimeStep
{
	mTimeStep = inTimeStep; // MAX(0.01, inTimeStep);
}

-(BOOL)canStepBack
{
	return [self containsMovie] && mTime > [self minTime];
}

-(BOOL)canStepForward
{
	return [self containsMovie] && mTime < [self maxTime];
}

-(IBAction)gotoBegin:(id)inSender
{
	if (mMovie)
		[self setTime:[self minTime]];
}

-(IBAction)gotoEnd:(id)inSender
{
	if (mMovie)
		[self setTime:[self maxTime]];
}

-(IBAction)stepBack:(id)inSender
{
	if (mMovie)
		[self setTime:ceil(mTime / mTimeStep - 1.001) * mTimeStep];
}

-(IBAction)stepForward:(id)inSender
{
	[self stepForward:inSender wait:NO];
}

-(IBAction)stepForward:(id)inSender wait:(BOOL)inWait
{
	if (mMovie)
		[self setTime:floor(mTime / mTimeStep + 1.001) * mTimeStep wait:inWait];
}

-(BOOL)displayTimeFrameOnly
{
	return mDisplayTimeFrameOnly;
}

-(void)setDisplayTimeFrameOnly:(BOOL)inFlag
{
	if (mDisplayTimeFrameOnly != inFlag) {
		mDisplayTimeFrameOnly = inFlag;
		[self setNeedsDisplay:YES];
	}
}

-(BOOL)autoStepForward
{
	return mAutoStepForward;
}

-(void)setAutoStepForward:(BOOL)inFlag
{
	if (mAutoStepForward != inFlag)
		mAutoStepForward = inFlag;
}

-(IBAction)gotoOriginFrame:(id)inSender
{
	[self setTime:0.0];
}

-(IBAction)setOriginFrame:(id)inSender
{
	[self willChangeValueForKey:@"minTime"];
	[self willChangeValueForKey:@"maxTime"];
	[self willChangeValueForKey:@"time"];

	float delta = -[self time];
	NSEnumerator *serieEnumerator = [[mFrame series] objectEnumerator];
	GCSerie *serie;
	while (serie = [serieEnumerator nextObject]) {
		NSEnumerator *enumerator = [[serie points] objectEnumerator];
		GCPoint *point;
		while (point = [enumerator nextObject])
			[point setTime:[point time] + delta];
	}

	[mMovie setPosterTime:[self time] + [mMovie posterTime]];
	[self setTime:0.0];
	[self didChangeValueForKey:@"minTime"];
	[self didChangeValueForKey:@"maxTime"];
	[self didChangeValueForKey:@"time"];
}

-(BOOL)validateMenuItem:(NSMenuItem *)inItem
{
	SEL action = [inItem action];
	if (action == @selector(copy:))
		return [self canCopy];
	if (action == @selector(paste:))
		return [self canPaste];
	if (action == @selector(gotoBegin:) || action == @selector(gotoEnd:)
		 || action == @selector(gotoOriginFrame:) || action == @selector(setOriginFrame:))
		return [self containsMovie];
	if (action == @selector(stepBack:))
		return [self canStepBack];
	if (action == @selector(stepForward:))
		return [self canStepForward];
	if (action == @selector(reloadURL:))
		return [self containsURL];
	if (action == @selector(toggleGuide:))
		[inItem setState:[mGuide visible] ? NSOnState : NSOffState];
	if (action == @selector(editSnapGrid:))
		[inItem setState:[self snapGridActive] ? NSOnState : NSOffState];
	if (action == @selector(clearMask:))
		return [[mFrame mask] hasContent];
	if (action == @selector(resetDefaultFrame:) || action == @selector(adjustFrame:) || action == @selector(undistortFrame:))
		return [mFrame customProjection] == nil;
	return [self respondsToSelector:action];
}

@end

@implementation GCView (ThreadedMovieImage)

static NSConditionLock *sMovieImageLock = nil;
static GCView *sMovieImageTarget = nil;
static NSMovie *sMovieImageMovie = nil;
static float sMovieImageTime;

-(void)movieImageThread:(id)inSender
{
	for (;;) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[sMovieImageLock lockWhenCondition:1];
		GCView *view = sMovieImageTarget;
		sMovieImageTarget = nil;
		NSMovie *movie = sMovieImageMovie;
		sMovieImageMovie = nil;
		float time = sMovieImageTime;
		[sMovieImageLock unlockWithCondition:0];
		
		NSImage *image = [movie imageAtTimeFromPoster:time];
		[view performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
		
		[view release];
		[movie release];
		[pool release];
	}
}

-(void)requestMovieImageAtTime:(float)inTime
{
	if (!sMovieImageLock) {
		sMovieImageLock = [[NSConditionLock alloc] initWithCondition:0];
		[NSThread detachNewThreadSelector:@selector(movieImageThread:) toTarget:self withObject:nil];
	}
	[sMovieImageLock lock];
	[sMovieImageTarget release];
	sMovieImageTarget = [self retain];
	[sMovieImageMovie release];
	sMovieImageMovie = [mMovie retain];
	sMovieImageTime = inTime;
	[sMovieImageLock unlockWithCondition:1];
}

@end

@implementation GCView (Paintable)

-(id)paintTarget
{
	return mImage;
}

-(NSAffineTransform *)paintTransform
{
	NSAffineTransform *transform = [self imageTransform];
	NSPoint origin = [self imageOriginWithZoomFactor:mZoomFactor];
	[transform translateXBy:origin.x yBy:origin.y];
	[transform invert];
	return transform;
}

@end

@implementation GCView (GuideLines)

-(NSPoint)newGuideLinePosition
{
	NSRect visibleRect = [self visibleRect];
	NSPoint center = NSMakePoint(NSMidX(visibleRect) / mZoomFactor, NSMidY(visibleRect) / mZoomFactor);
	return center;
}

-(IBAction)addHorizontalGuideLine:(id)inSender
{
	GCGuideLine *guideLine = [[GCGuideLine alloc] initWithPosition:[self newGuideLinePosition].y isVertical:NO];
	[mFrame addGuideLine:guideLine];
	[guideLine release];
	[self setNeedsDisplay:YES];
}

-(IBAction)addVerticalGuideLine:(id)inSender
{
	GCGuideLine *guideLine = [[GCGuideLine alloc] initWithPosition:[self newGuideLinePosition].x isVertical:YES];
	[mFrame addGuideLine:guideLine];
	[guideLine release];
	[self setNeedsDisplay:YES];
}

-(IBAction)removeGuideLines:(id)inSender
{
	[mFrame removeGuideLines];
	[self setNeedsDisplay:YES];
}

-(void)focusGuideLine:(GCGuideLine *)inGuideLine mouseDown:(NSEvent *)inEvent
{
	sDontFocus = YES;
	BOOL keepOn = YES;
	while (keepOn) {
		NSEvent *event = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];

		switch ([event type]) {
			case NSLeftMouseDragged: {
				NSPoint pt = [self convertEventLocation:event];
				[self setMagnificationLocation:pt];
				[inGuideLine setPosition:[inGuideLine isVertical] ? pt.x : pt.y];
				[self setNeedsDisplay:YES];
				break;
			}
			case NSLeftMouseUp:
				keepOn = NO;
				break;
			default:
				break;
		}
	}
	sDontFocus = NO;
}

@end

@implementation GCView (Grid)

-(NSArray *)snapGridParameterKeys
{
	return [NSArray arrayWithObjects:@"xSnapGridSpacing", @"ySnapGridSpacing", @"xSnapGridNumber", @"ySnapGridNumber", nil];
}

-(int)xSnapGridSpacing
{
	return mSnapGridSpacing[0];
}

-(void)setXSnapGridSpacing:(int)inSpacing
{
	mSnapGridSpacing[0] = inSpacing;
}

-(int)ySnapGridSpacing
{
	return mSnapGridSpacing[1];
}

-(void)setYSnapGridSpacing:(int)inSpacing
{
	mSnapGridSpacing[1] = inSpacing;
}

-(int)xSnapGridNumber
{
	return mSnapGridNumber[0];
}

-(void)setXSnapGridNumber:(int)inNumber
{
	mSnapGridNumber[0] = inNumber;
}

-(int)ySnapGridNumber
{
	return mSnapGridNumber[1];
}

-(void)setYSnapGridNumber:(int)inNumber
{
	mSnapGridNumber[1] = inNumber;
}

-(BOOL)snapGridActive
{
	return mSnapGridSpacing[0] > 0 || mSnapGridSpacing[1] > 0;
}

-(float)snap:(float)inValue dim:(int)inDim min:(float)inMin max:(float)inMax
{
	switch (mSnapGridSpacing[inDim]) {
		case 1: {
			float delta = (inMax - inMin) / MAX(1, mSnapGridNumber[inDim]);
			if (delta == 0)
				break;
			return inMin + delta * round((inValue - inMin) / delta);
		}
		case 2:
			if (inValue > 0) {
				float basis = pow(10, floor(log10f(inValue)));
				return basis * round(inValue / basis);
			}
	}
	return inValue;
}

-(NSPoint)snapPointToGrid:(NSPoint)inPoint
{
	if (mSelectedTool != GCAddPointTool)
		return inPoint;
	
	NSPoint coords = [mFrame convertToCoordinate:inPoint];
	NSPoint unscaled = [mFrame unscale:coords];
	if (mSnapGridSpacing[0] == 1) {
		unscaled.x = [self snap:unscaled.x dim:0 min:0.0 max:1.0];
		coords.x = [mFrame scale:unscaled].x;
	} else
		coords.x = [self snap:coords.x dim:0 min:[mFrame xMin] max:[mFrame xMax]];
	if (mSnapGridSpacing[1] == 1) {
		unscaled.y = [self snap:unscaled.y dim:1 min:0.0 max:1.0];
		coords.y = [mFrame scale:unscaled].y;
	} else
		coords.y = [self snap:coords.y dim:1 min:[mFrame yMin] max:[mFrame yMax]];
	return [mFrame convertFromCoordinate:coords];
}

-(IBAction)editSnapGrid:(id)inSender
{
	if (!mSnapGridController)
		mSnapGridController = [[GCSnapGridController alloc] initWithView:self];
	[mSnapGridController startSnapGridEdition:inSender];
}

@end

@implementation GCView (Pasteboard)

#define GCPointsPboardType @"GCPointsPboardType"
#define GCCoordinatesPboardType @"GCCoordinatesPboardType"

-(BOOL)canCopy
{
	return [[mPointController selectedObjects] count] > 0;
}

-(void)copy:(id)inSender
{
	NSArray *points = [mPointController selectedObjects];
	NSMutableArray *coordinates = [NSMutableArray array];
	NSEnumerator *enumerator = [points objectEnumerator];
	GCPoint *point;
	while (point = [enumerator nextObject])
		[coordinates addObject:[NSValue valueWithPoint:[point coordinatePoint]]];
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard declareTypes:[NSArray arrayWithObjects:GCPointsPboardType, GCCoordinatesPboardType, nil] owner:self];
	[pasteboard setData:[NSArchiver archivedDataWithRootObject:points] forType:GCPointsPboardType];
	[pasteboard setData:[NSArchiver archivedDataWithRootObject:coordinates] forType:GCCoordinatesPboardType];
}

-(BOOL)canPastePoints
{
	return [[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObject:GCPointsPboardType]] != nil;
}

-(void)pastePoints:(id)inSender
{
	NSArray *points = [NSUnarchiver unarchiveObjectWithData:[[NSPasteboard generalPasteboard] dataForType:GCPointsPboardType]];
	NSArray *coordinates = [NSUnarchiver unarchiveObjectWithData:[[NSPasteboard generalPasteboard] dataForType:GCCoordinatesPboardType]];
	BOOL sameCoordinates = YES;
	[self preparePointInsertion];
	NSEnumerator *enumerator = [points objectEnumerator];
	NSEnumerator *coordinateEnumerator = [coordinates objectEnumerator];
	GCPoint *point;
	while (point = [enumerator nextObject]) {
		[mInsertionSerie insertObject:point inPointsAtIndex:mInsertionIndex];
		if (sameCoordinates) {
			NSPoint coord = [[coordinateEnumerator nextObject] pointValue];
			NSPoint actualPosition = [point point];
			NSPoint newPosition = [point convertFromCoordinate:coord];
			if (MAX(fabs(actualPosition.x - newPosition.x), fabs(actualPosition.y - newPosition.y)) > 0.5)
				sameCoordinates = NO;
		}
		[mPointsToSelect addIndex:mInsertionIndex++];
	}
	BOOL keepCoordinates = YES;
	if (!sameCoordinates) {
		switch ([[GCPointPasteDialog sharedDialog] runModal]) {
			case kGCPointPasteCancel:
				while ([mPointsToSelect count] > 0) {
					int index = [mPointsToSelect lastIndex];
					[mInsertionSerie removeObjectFromPointsAtIndex:index];
					[mPointsToSelect removeIndex:index];
				}
				keepCoordinates = NO;
				break;
			case kGCPointPasteKeepCoordinates:
				break;
			case kGCPointPasteKeepPosition:
				keepCoordinates = NO;
				break;
		}
	}
	if (keepCoordinates) {
		NSEnumerator *enumerator = [points objectEnumerator];
		NSEnumerator *coordinateEnumerator = [coordinates objectEnumerator];
		GCPoint *point;
		while (point = [enumerator nextObject]) {
			NSPoint coord = [[coordinateEnumerator nextObject] pointValue];
			[point setXCoordinate:coord.x];
			[point setYCoordinate:coord.y];
		}
	}
	[self finishPointInsertion];
}

-(BOOL)canPasteCoordinates
{
	return [[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]] != nil;
}

-(void)pasteCoordinates:(id)inSender
{
	BOOL prepared = NO;
	NSString *string = [[NSPasteboard generalPasteboard] stringForType:NSStringPboardType];
	NSEnumerator *enumerator = [[string componentsSeparatedByString:[NSString lineSeparator]] objectEnumerator];
	NSString *line;
	while (line = [enumerator nextObject]) {
		NSArray *components = [line componentsSeparatedByString:[NSString columnSeparator]];
		if ([components count] >= 2) {
			BOOL ok = YES;
			float x, y;
			NSScanner *scanner = [[NSScanner alloc] initWithString:[components objectAtIndex:0]];
			if (![scanner scanFloat:&x])
				ok = NO;
			[scanner release];
			if (ok) {
				scanner = [[NSScanner alloc] initWithString:[components objectAtIndex:1]];
				if (![scanner scanFloat:&y])
					ok = NO;
				[scanner release];
				if (ok) {
					GCPoint *point = [[GCPoint alloc] initWithPoint:NSZeroPoint];
					if (!prepared) {
						[self preparePointInsertion];
						prepared = YES;
					}
					[mInsertionSerie insertObject:point inPointsAtIndex:mInsertionIndex];
					[mPointsToSelect addIndex:mInsertionIndex++];
					[point setXCoordinate:x];
					[point setYCoordinate:y];
					[point release];
				}
			}
		}
	}
	if (prepared)
		[self finishPointInsertion];
}

@end

