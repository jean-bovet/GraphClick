//
//  GCView+AdjustCoordinates.m
//  GraphClick
//
//  Created by Simon Bovet on 12.09.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GCView+AdjustCoordinates.h"

#import "GCFoundation.h"
#import "GCNumberFormatter.h"
#import "GCGuide.h"
#import "GCDocument.h"
#import "GCOptionalAlert.h"
#import "GCFilterController.h"
#import "GCHistogram.h"
#import "GCInspector.h"
#import "GCMapAdjustmentWizard.h"

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

-(void)restoreCurrentFrame;
-(void)discardSavedFrame;

@end

@interface GCFrame (Private)

-(NSPoint)convert:(NSPoint)inPoint;
-(NSPoint)unconvert:(NSPoint)inPoint;

@end

@implementation GCView (AdjustCoordinates)

-(NSString *)coordinatePrompt
{
	if (mSelectedTool == GCAdjustWithWizard)
		return [mAdjustmentWizard coordinatePrompt];
	if (mSelectedTool >= GCAddPointTool) {
		NSString *message = [NSString stringWithFormat:@"Adjust Coordinates %i Message", mSelectedTool];
		return NSLocalizedString(message, @"");
	} else
		return @"";
}

-(void)adjustCoordinates
{
	[self willChangeValueForKey:@"adjustFramePosition"];
	mAdjustFramePosition = [[NSUserDefaults standardUserDefaults] boolForKey:GCAdjustFramePosition];
	[self didChangeValueForKey:@"adjustFramePosition"];
	[NSApp beginSheet:mAdjustCoordinateWindow modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(adjustCoordinatesSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(BOOL)adjustFramePosition
{
	return mAdjustFramePosition;
}

-(void)setAdjustFramePosition:(BOOL)inAdjust
{
	mAdjustFramePosition = inAdjust;
}

-(IBAction)startCoordinateAdjustment:(id)inSender
{
	[[NSUserDefaults standardUserDefaults] setBool:mAdjustFramePosition forKey:GCAdjustFramePosition];
	[NSApp endSheet:mAdjustCoordinateWindow returnCode:[inSender tag]];
}

-(GCAdjustmentWizard *)adjustmentWizard
{
	return mAdjustmentWizard;
}

-(void)setAdjustmentWizard:(GCAdjustmentWizard *)inAdjustmentWizard
{
	if (mAdjustmentWizard != inAdjustmentWizard) {
		[self willChangeValueForKey:@"adjustmentWizard"];
		[mAdjustmentWizard autorelease];
		mAdjustmentWizard = [inAdjustmentWizard retain];
		[self setNeedsDisplay:YES];
		[self didChangeValueForKey:@"adjustmentWizard"];
	}
}

-(void)adjustmentDidEnd:(BOOL)inSuccess
{
	[self setAdjustmentWizard:nil];
	if (inSuccess) {
		[mFrame beginEditing];
		[mFrame didChange];
		[mFrame endEditing];
		[self discardSavedFrame];
	} else
		[self restoreCurrentFrame];
	[self setNeedsDisplay:YES];
}

-(void)adjustmentShouldBegin:(BOOL)inSuccess
{
	if (inSuccess)
		[self setSelectedTool:GCAdjustWithWizard];
	else
		[self adjustmentDidEnd:NO];
}

-(void)saveCurrentFrame
{
	[mPreviousCustomProjection release];
	mPreviousCustomProjection = [[mFrame customProjection] retain];
}

-(void)discardSavedFrame
{
	[mPreviousCustomProjection release];
	mPreviousCustomProjection = nil;
}

-(void)restoreCurrentFrame
{
	[mFrame setCustomProjection:mPreviousCustomProjection];
	[mPreviousCustomProjection release];
	mPreviousCustomProjection = nil;
}

-(void)adjustCoordinatesSheetDidEnd:(NSWindow *)inSheet returnCode:(int)inReturnCode contextInfo:(void *)inContextInfo
{
	[mAdjustCoordinateWindow orderOut:nil];
	[self setAdjustmentWizard:nil];
	
	switch (inReturnCode) {
		case 1:
			[self setSelectedTool:GCAdjustAbscissa1];
			break;
		case 2:
			[self setSelectedTool:GCAdjustOrdinate1];
			break;
		case 3:
			[self setSelectedTool:GCAdjustPosition1];
			break;
		case 4:
			[self setSelectedTool:GCAdjustPositionB1];
			break;
		case 5:
			[self setSelectedTool:GCAdjust3Points1];
			break;
		case 6:
			[self setSelectedTool:GCAdjustAbscissaOrdinate1];
			break;
		case 7:
			[self setSelectedTool:GCAdjustScale1];
			break;
		case 8:
			[self setSelectedTool:GCAdjustOrigin];
			break;
		case 9:
			[self setSelectedTool:GCAdjust4Points1];
			break;
		case 100:
			[self setAdjustmentWizard:[GCMercatorProjectionWizard adjustmentWizard]];
			break;
		case 101:
			[self setAdjustmentWizard:[GCObliqueMercatorProjectionWizard adjustmentWizard]];
			break;
		case 102:
			[self setAdjustmentWizard:[GCTransverseMercatorProjectionWizard adjustmentWizard]];
			break;
		case 103:
			[self setAdjustmentWizard:[GCGnomonicProjectionWizard adjustmentWizard]];
			break;
	}
	if (mAdjustmentWizard)
		[mAdjustmentWizard performSelector:@selector(beginAdjustmentInView:) withObject:self afterDelay:0.0];
	else
		[[self frameObject] setCustomProjection:nil];
	[self setNeedsDisplay:YES];
	
	[self performSelector:@selector(flagsChanged:) withObject:nil afterDelay:0.0];
}

-(NSBezierPath *)abscissaCoordinatePathAt:(float)inOrdinate
{
    if (!isdefined(inOrdinate))
		return nil;
	NSBezierPath *path = [NSBezierPath bezierPath];
	NSPoint A, B, C, D;
	B = [mFrame convertFromCoordinate:NSMakePoint([mFrame xMin], inOrdinate)];
	C = [mFrame convertFromCoordinate:NSMakePoint([mFrame xMax], inOrdinate)];
	[self extendLineBetween:B and:C to:&A and:&D];
	[path moveToPoint:A];
	[path lineToPoint:B];
	[path lineToPoint:C];
	[path lineToPoint:D];
	return path;
}

-(NSBezierPath *)ordinateCoordinatePathAt:(float)inAbscissa
{
    if (!isdefined(inAbscissa))
		return nil;
	NSBezierPath *path = [NSBezierPath bezierPath];
	NSPoint A, B, C, D;
	B = [mFrame convertFromCoordinate:NSMakePoint(inAbscissa, [mFrame yMin])];
	C = [mFrame convertFromCoordinate:NSMakePoint(inAbscissa, [mFrame yMax])];
	[self extendLineBetween:B and:C to:&A and:&D];
	[path moveToPoint:A];
	[path lineToPoint:B];
	[path lineToPoint:C];
	[path lineToPoint:D];
	return path;
}

-(NSBezierPath *)crossCoordinatePathAt:(NSPoint)inPoint
{
	NSBezierPath *path = [self abscissaCoordinatePathAt:inPoint.y];
	[path appendBezierPath:[self ordinateCoordinatePathAt:inPoint.y]];
	return path;
}

-(float)promptAbscissa
{
	return mPromptCoordinates.x;
}

-(void)setPromptAbscissa:(float)inAbscissa
{
	mPromptCoordinates.x = inAbscissa;
}

-(float)promptOrdinate
{
	return mPromptCoordinates.y;
}

-(void)setPromptOrdinate:(float)inOrdinate
{
	mPromptCoordinates.y = inOrdinate;
}

-(BOOL)shouldPromptAbscissa
{
	return isdefined([self promptAbscissa]);
}

-(BOOL)shouldPromptOrdinate
{
	return isdefined([self promptOrdinate]);
}

-(BOOL)shouldPromptAbscissaScale
{
	return mAdjustmentWizard ? [mAdjustmentWizard shouldPromptAbscissaScale] : YES;
}

-(BOOL)shouldPromptOrdinateScale
{
	return mAdjustmentWizard ? [mAdjustmentWizard shouldPromptOrdinateScale] : YES;
}

-(void)setNilValueForKey:(NSString *)inKey
{
	[self setValue:[NSNumber numberWithFloat:0.0] forKey:inKey];
}

-(BOOL)adjustFrameFromLeft:(float)inLeft right:(float)inRight bottom:(float)inBottom top:(float)inTop
	xMin:(float)inXMin xMax:(float)inXMax yMin:(float)inYMin yMax:(float)inYMax
{
	if (inLeft == inRight || inBottom == inTop)
		return NO;
		
	NSPoint corner[4];
	corner[0] = [mFrame unconvert:NSMakePoint(inLeft, inBottom)];
	corner[3] = [mFrame unconvert:NSMakePoint(inLeft, inTop)];
	corner[1] = [mFrame unconvert:NSMakePoint(inRight, inBottom)];
	corner[2] = [mFrame unconvert:NSMakePoint(inRight, inTop)];
	[mFrame beginEditing];
	int i;
	for (i = 0; i < 4; i++)
		[mFrame setCorner:i point:corner[i]];
	[mFrame setXMin:inXMin];
	[mFrame setXMax:inXMax];
	[mFrame setYMin:inYMin];
	[mFrame setYMax:inYMax];
	[mFrame endEditing];
	return YES;
}

-(BOOL)adjustAbscissa:(int)inKind
{
	int key1 = inKind == 0 ? GCAdjustAbscissa1 : GCAdjustAbscissaOrdinate1;
	int key2 = inKind == 0 ? GCAdjustAbscissa2 : GCAdjustAbscissaOrdinate2;

	if (mAdjustFramePosition)
		return [self adjustFrameFromLeft:[[mPromptedPositions objectForKey:[NSNumber numberWithInt:key1]] pointValue].x
			right:[[mPromptedPositions objectForKey:[NSNumber numberWithInt:key2]] pointValue].x
			bottom:0 top:1
			xMin:[[mPromptedOriginalCoordinates objectForKey:[NSNumber numberWithInt:key1]] pointValue].x
			xMax:[[mPromptedOriginalCoordinates objectForKey:[NSNumber numberWithInt:key2]] pointValue].x
			yMin:[mFrame yMin] yMax:[mFrame yMax]];	
	
	float p1 = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:key1]] pointValue].x;
	float p2 = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:key2]] pointValue].x;
	float x1 = [[mPromptedCoordinates objectForKey:[NSNumber numberWithInt:key1]] pointValue].x;
	float x2 = [[mPromptedCoordinates objectForKey:[NSNumber numberWithInt:key2]] pointValue].x;
	float dx = (x2 - x1) / (p2 - p1);
	float x0 = x1 - dx * p1;
	float min = [mFrame scale:NSMakePoint(x0, 0)].x;
	float max = [mFrame scale:NSMakePoint(x0 + dx, 0)].x;
	if (isdefined(min) && isdefined(max) && min != max) {
		[mFrame beginEditing];
		[mFrame setXMin:min];
		[mFrame setXMax:max];
		[mFrame endEditing];
		return YES;
	} else
		return NO;
}

-(BOOL)adjustOrdinate:(int)inKind
{
	int key1 = inKind == 0 ? GCAdjustOrdinate1 : GCAdjustAbscissaOrdinate3;
	int key2 = inKind == 0 ? GCAdjustOrdinate2 : GCAdjustAbscissaOrdinate4;

	if (mAdjustFramePosition)
		return [self adjustFrameFromLeft:0 right:1
			bottom:[[mPromptedPositions objectForKey:[NSNumber numberWithInt:key1]] pointValue].y
			top:[[mPromptedPositions objectForKey:[NSNumber numberWithInt:key2]] pointValue].y
			xMin:[mFrame xMin] xMax:[mFrame xMax]
			yMin:[[mPromptedOriginalCoordinates objectForKey:[NSNumber numberWithInt:key1]] pointValue].y
			yMax:[[mPromptedOriginalCoordinates objectForKey:[NSNumber numberWithInt:key2]] pointValue].y];
	
	float p1 = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:key1]] pointValue].y;
	float p2 = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:key2]] pointValue].y;
	float y1 = [[mPromptedCoordinates objectForKey:[NSNumber numberWithInt:key1]] pointValue].y;
	float y2 = [[mPromptedCoordinates objectForKey:[NSNumber numberWithInt:key2]] pointValue].y;
	float dy = (y2 - y1) / (p2 - p1);
	float y0 = y1 - dy * p1;
	float min = [mFrame scale:NSMakePoint(0, y0)].y;
	float max = [mFrame scale:NSMakePoint(0, y0 + dy)].y;
	if (isdefined(min) && isdefined(max) && min != max) {
		[mFrame beginEditing];
		[mFrame setYMin:min];
		[mFrame setYMax:max];
		[mFrame endEditing];
		return YES;
	} else
		return NO;
}

-(BOOL)adjustAbscissaAndOrdinate:(int)inKind
{
	NSPoint p1, p2, a1, a2;
	id coords = mAdjustFramePosition ? mPromptedOriginalCoordinates : mPromptedCoordinates;
	if (inKind == 0) {
		p1 = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:GCAdjustPosition1]] pointValue];
		p2 = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:GCAdjustPosition2]] pointValue];
		a1 = [[coords objectForKey:[NSNumber numberWithInt:GCAdjustPosition1]] pointValue];
		a2 = [[coords objectForKey:[NSNumber numberWithInt:GCAdjustPosition2]] pointValue];
	} else {
		p1 = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:GCAdjustPositionB1]] pointValue];
		p2.x = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:GCAdjustPositionB2]] pointValue].x;
		p2.y = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:GCAdjustPositionB3]] pointValue].y;
		a1 = [[coords objectForKey:[NSNumber numberWithInt:GCAdjustPositionB1]] pointValue];
		a2.x = [[coords objectForKey:[NSNumber numberWithInt:GCAdjustPositionB2]] pointValue].x;
		a2.y = [[coords objectForKey:[NSNumber numberWithInt:GCAdjustPositionB3]] pointValue].y;
	}

	if (mAdjustFramePosition)
		return [self adjustFrameFromLeft:p1.x right:p2.x bottom:p1.y top:p2.y
			xMin:a1.x xMax:a2.x yMin:a1.y yMax:a2.y];
	
	NSPoint d = NSMakePoint((a2.x - a1.x) / (p2.x - p1.x), (a2.y - a1.y) / (p2.y - p1.y));
	NSPoint a0 = NSMakePoint(a1.x - d.x * p1.x, a1.y - d.y * p1.y);
	NSPoint min = [mFrame scale:a0];
	NSPoint max = [mFrame scale:NSMakePoint(a0.x + d.x, a0.y + d.y)];
	if (isdefined(min.x) && isdefined(max.x) && isdefined(min.y) && isdefined(max.y) && min.x != max.x && min.y != max.y) {
		[mFrame beginEditing];
		[mFrame setXMin:min.x];
		[mFrame setXMax:max.x];
		[mFrame setYMin:min.y];
		[mFrame setYMax:max.y];
		[mFrame endEditing];
		return YES;
	} else
		return NO;
}

float unscaleValue(float *x, GCScale scale)
{
	switch (scale) {
		case GCLinearScale:
			break;
		case GCLogScale:
			*x = log10(*x);
			break;
		case GCInverseScale:
			*x = 1. / *x;
			break;
	}
	return *x;
}

float scaleValue(float *x, GCScale sc)
{
	switch (sc) {
		case GCLinearScale:
			break;
		case GCLogScale:
			*x = pow(10, *x);
			break;
		case GCInverseScale:
			*x = 1. / *x;
			break;
	}
	return *x;
}

float unscaledValue(float x, GCScale sc)
{
	return unscaleValue(&x, sc);
}

float scaledValue(float x, GCScale sc)
{
	return scaleValue(&x, sc);
}

-(BOOL)adjustOrigin
{
	NSPoint o = [[mPromptedOriginalCoordinates objectForKey:[NSNumber numberWithInt:GCAdjustOrigin]] pointValue];
	GCScale xScale = [mFrame xScale];
	GCScale yScale = [mFrame yScale];
	unscaleValue(&o.x, xScale);
	unscaleValue(&o.y, yScale);
	[mFrame beginEditing];
	[mFrame setXMin:scaledValue(unscaledValue([mFrame xMin], xScale) - o.x, xScale)];
	[mFrame setXMax:scaledValue(unscaledValue([mFrame xMax], xScale) - o.x, xScale)];
	[mFrame setYMin:scaledValue(unscaledValue([mFrame yMin], yScale) - o.y, yScale)];
	[mFrame setYMax:scaledValue(unscaledValue([mFrame yMax], yScale) - o.y, yScale)];
	[mFrame endEditing];
	return YES;
}

-(BOOL)adjust3Points
{
	NSPoint p1 = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:GCAdjust3Points1]] pointValue];
	NSPoint p2 = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:GCAdjust3Points2]] pointValue];
	NSPoint p3 = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:GCAdjust3Points3]] pointValue];
	NSPoint x1 = [[mPromptedCoordinates objectForKey:[NSNumber numberWithInt:GCAdjust3Points1]] pointValue];
	NSPoint x2 = [[mPromptedCoordinates objectForKey:[NSNumber numberWithInt:GCAdjust3Points2]] pointValue];
	NSPoint x3 = [[mPromptedCoordinates objectForKey:[NSNumber numberWithInt:GCAdjust3Points3]] pointValue];
	
	GCScale xScale = [mFrame xScale];
	GCScale yScale = [mFrame yScale];
	unscaleValue(&x1.x, xScale);
	unscaleValue(&x2.x, xScale);
	unscaleValue(&x3.x, xScale);
	unscaleValue(&x1.y, yScale);
	unscaleValue(&x2.y, yScale);
	unscaleValue(&x3.y, yScale);
	
	float k2 = (x2.y - x1.y) / (x3.y - x1.y);
	x2.x -= k2 * (x3.x - x1.x);
	x2.y -= k2 * (x3.y - x1.y);
	p2.x -= k2 * (p3.x - p1.x);
	p2.y -= k2 * (p3.y - p1.y);
	
	float k3 = (x3.x - x1.x) / (x2.x - x1.x);
	x3.x -= k3 * (x2.x - x1.x);
	x3.y -= k3 * (x2.y - x1.y);
	p3.x -= k3 * (p2.x - p1.x);
	p3.y -= k3 * (p2.y - p1.y);
	
	if (isdefined(k2) && isdefined(k3)) {
		[mFrame beginEditing];
		[mFrame setCorner:0 point:p1];
		[mFrame setCorner:1 point:p2];
		[mFrame setCorner:2 point:NSMakePoint(p2.x + p3.x - p1.x, p2.y + p3.y - p1.y)];
		[mFrame setCorner:3 point:p3];
		[mFrame setXMin:scaleValue(&x1.x, xScale)];
		[mFrame setXMax:scaleValue(&x2.x, xScale)];
		[mFrame setYMin:scaleValue(&x1.y, yScale)];
		[mFrame setYMax:scaleValue(&x3.y, yScale)];
		[mFrame endEditing];
		return YES;
	} else
		return NO;
}

-(BOOL)adjust4Points
{
	NSPoint p1 = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:GCAdjust4Points1]] pointValue];
	NSPoint p2 = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:GCAdjust4Points2]] pointValue];
	NSPoint p3 = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:GCAdjust4Points3]] pointValue];
	NSPoint p4 = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:GCAdjust4Points4]] pointValue];
	NSPoint x1 = [[mPromptedCoordinates objectForKey:[NSNumber numberWithInt:GCAdjust4Points1]] pointValue];
	NSPoint x2 = [[mPromptedCoordinates objectForKey:[NSNumber numberWithInt:GCAdjust4Points2]] pointValue];
	NSPoint x3 = [[mPromptedCoordinates objectForKey:[NSNumber numberWithInt:GCAdjust4Points3]] pointValue];
	NSPoint x4 = [[mPromptedCoordinates objectForKey:[NSNumber numberWithInt:GCAdjust4Points4]] pointValue];
	
	GCScale xScale = [mFrame xScale];
	GCScale yScale = [mFrame yScale];
	unscaleValue(&x1.x, xScale);
	unscaleValue(&x2.x, xScale);
	unscaleValue(&x3.x, xScale);
	unscaleValue(&x4.x, xScale);
	unscaleValue(&x1.y, yScale);
	unscaleValue(&x2.y, yScale);
	unscaleValue(&x3.y, yScale);
	unscaleValue(&x4.y, yScale);
	
	float k2 = (x2.y - x1.y) / (x3.y - x1.y);
	x2.x -= k2 * (x3.x - x1.x);
	x2.y -= k2 * (x3.y - x1.y);
	p2.x -= k2 * (p3.x - p1.x);
	p2.y -= k2 * (p3.y - p1.y);
	
	float k3 = (x3.x - x1.x) / (x2.x - x1.x);
	x3.x -= k3 * (x2.x - x1.x);
	x3.y -= k3 * (x2.y - x1.y);
	p3.x -= k3 * (p2.x - p1.x);
	p3.y -= k3 * (p2.y - p1.y);
	
	float k4 = (x4.y - x3.y) / (x3.y - x1.y);
	x4.x -= k4 * (x3.x - x1.x);
	x4.y -= k4 * (x3.y - x1.y);
	p4.x -= k4 * (p3.x - p1.x);
	p4.y -= k4 * (p3.y - p1.y);
	
	float k5 = (x4.x - x2.x) / (x2.x - x1.x);
	x4.x -= k5 * (x2.x - x1.x);
	x4.y -= k5 * (x2.y - x1.y);
	p4.x -= k5 * (p2.x - p1.x);
	p4.y -= k5 * (p2.y - p1.y);
	
	if (isdefined(k2) && isdefined(k3) && isdefined(k4) && isdefined(k5)) {
		[mFrame beginEditing];
		[mFrame setCorner:0 point:p1];
		[mFrame setCorner:1 point:p2];
		[mFrame setCorner:2 point:p4];
		[mFrame setCorner:3 point:p3];
		[mFrame setXMin:scaleValue(&x1.x, xScale)];
		[mFrame setXMax:scaleValue(&x2.x, xScale)];
		[mFrame setYMin:scaleValue(&x1.y, yScale)];
		[mFrame setYMax:scaleValue(&x3.y, yScale)];
		[mFrame endEditing];
		return YES;
	} else
		return NO;
}

-(GCTool)nextTool
{
	return mPreviousSelectedTool == GCSelectTool ? GCAddPointTool : mPreviousSelectedTool;
}

-(void)runInvalidAdjustErrorAlert
{
	NSString *title = NSLocalizedString(@"Invalid Coordinates To Adjust Alert Title", @"");
	NSString *message = NSLocalizedString(@"Invalid Coordinates To Adjust Alert Message", @"");
	NSRunAlertPanel(title, message, nil, nil, nil);
}

-(void)promptCoordinates
{
	mPromptCoordinates = mCoordinates;
	NSPoint position;
	switch (mSelectedTool) {
		case GCAdjust3Points1:
		case GCAdjust3Points2:
		case GCAdjust3Points3:
		case GCAdjust4Points1:
		case GCAdjust4Points2:
		case GCAdjust4Points3:
		case GCAdjust4Points4:
		case GCAdjustWithWizard:
			position = mMagnificationLocation;
			break;
		default:
			position = [mFrame unscale:mCoordinates];
			break;
	}
	
	if (isnan(mPromptCoordinates.x))
		mPromptCoordinates.x = 0.0;
	if (isnan(mPromptCoordinates.y))
		mPromptCoordinates.y = 0.0;
	float nan = sqrt(-1.0);
	switch (mSelectedTool) {
		case GCAdjustAbscissa1:
		case GCAdjustAbscissa2:
		case GCAdjustPositionB2:
		case GCAdjustAbscissaOrdinate1:
		case GCAdjustAbscissaOrdinate2:
			mPromptCoordinates.y = nan;
			break;
		case GCAdjustOrdinate1:
		case GCAdjustOrdinate2:
		case GCAdjustPositionB3:
		case GCAdjustAbscissaOrdinate3:
		case GCAdjustAbscissaOrdinate4:
			mPromptCoordinates.x = nan;
			break;
		case GCAdjustWithWizard:
			if (![mAdjustmentWizard shouldPromptAbscissa])
				mPromptCoordinates.x = nan;
			if (![mAdjustmentWizard shouldPromptOrdinate])
				mPromptCoordinates.y = nan;
		default:
			break;
	}

	id key = [NSNumber numberWithInt:mSelectedTool];
	if (mSelectedTool == GCAdjustWithWizard)
		key = [mAdjustmentWizard keyForPromptedValue];
	if (mSelectedTool != GCAdjustOrigin) {
		static NSMutableDictionary *previousValues = nil;
		if (key) {
			if (!previousValues)
				previousValues = [[NSMutableDictionary alloc] initWithCapacity:0];
			id previousCoords = [previousValues objectForKey:key];
			if (previousCoords) {
				NSPoint coords = [previousCoords pointValue];
				if (isdefined(mPromptCoordinates.x))
					mPromptCoordinates.x = coords.x;
				if (isdefined(mPromptCoordinates.y))
					mPromptCoordinates.y = coords.y;
			} else if (mSelectedTool == GCAdjustWithWizard) {
				if (isdefined(mPromptCoordinates.x))
					mPromptCoordinates.x = [mAdjustmentWizard defaultAbscissaValue];
				if (isdefined(mPromptCoordinates.y))
					mPromptCoordinates.y = [mAdjustmentWizard defaultOrdinateValue];
			}
		}
		
		[self willChangeValueForKey:@"promptAbscissa"];
		[self didChangeValueForKey:@"promptAbscissa"];
		[self willChangeValueForKey:@"promptOrdinate"];
		[self didChangeValueForKey:@"promptOrdinate"];
		[self willChangeValueForKey:@"shouldPromptAbscissa"];
		[self didChangeValueForKey:@"shouldPromptAbscissa"];
		[self willChangeValueForKey:@"shouldPromptOrdinate"];
		[self didChangeValueForKey:@"shouldPromptOrdinate"];
		[self willChangeValueForKey:@"shouldPromptAbscissaScale"];
		[self didChangeValueForKey:@"shouldPromptAbscissaScale"];
		[self willChangeValueForKey:@"shouldPromptOrdinateScale"];
		[self didChangeValueForKey:@"shouldPromptOrdinateScale"];
		[self removeMagnifyingGlass];
		
		[mCoordinatePromptWindow makeFirstResponder:mAbscissaPromptField];
		int result = [NSApp runModalForWindow:mCoordinatePromptWindow];
		[mCoordinatePromptWindow orderOut:nil];
		if (result == NSCancelButton) {
			[self adjustmentDidEnd:NO];
			[self setSelectedTool:mPreviousSelectedTool];
			return;
		}
		
		if (key)
			[previousValues setObject:[NSValue valueWithPoint:mPromptCoordinates] forKey:key];
	}
	
	NSPoint coordinates;
	switch (mSelectedTool) {
		case GCAdjust3Points1:
		case GCAdjust3Points2:
		case GCAdjust3Points3:
		case GCAdjust4Points1:
		case GCAdjust4Points2:
		case GCAdjust4Points3:
		case GCAdjust4Points4:
			coordinates = mPromptCoordinates;
			break;
		default:
			coordinates = [mFrame unscale:mPromptCoordinates];
			break;
	}
	if (key) {
		[mPromptedCoordinates setObject:[NSValue valueWithPoint:coordinates] forKey:key];
		[mPromptedPositions setObject:[NSValue valueWithPoint:position] forKey:key];
		[mPromptedOriginalCoordinates setObject:[NSValue valueWithPoint:mPromptCoordinates] forKey:key];
	}
	
	BOOL valid = YES;
	switch (mSelectedTool) {
		case GCAdjustAbscissa1:
			[self setSelectedTool:GCAdjustAbscissa2];
			break;
		case GCAdjustAbscissa2:
			if (valid = [self adjustAbscissa:0])
				[self setSelectedTool:[self nextTool]];
			break;
			
		case GCAdjustOrdinate1:
			[self setSelectedTool:GCAdjustOrdinate2];
			break;
		case GCAdjustOrdinate2:
			if (valid = [self adjustOrdinate:0])
				[self setSelectedTool:[self nextTool]];
			break;
			
		case GCAdjustPosition1:
			[self setSelectedTool:GCAdjustPosition2];
			break;
		case GCAdjustPosition2:
			if (valid = [self adjustAbscissaAndOrdinate:0])
				[self setSelectedTool:[self nextTool]];
			break;
			
		case GCAdjustOrigin:
			if (valid = [self adjustOrigin])
				[self setSelectedTool:[self nextTool]];
			break;
			
		case GCAdjustPositionB1:
			[self setSelectedTool:GCAdjustPositionB2];
			break;
		case GCAdjustPositionB2:
			[self setSelectedTool:GCAdjustPositionB3];
			break;
		case GCAdjustPositionB3:
			if (valid = [self adjustAbscissaAndOrdinate:1])
				[self setSelectedTool:[self nextTool]];
			break;

		case GCAdjust3Points1:
			[self setSelectedTool:GCAdjust3Points2];
			break;
		case GCAdjust3Points2:
			[self setSelectedTool:GCAdjust3Points3];
			break;
		case GCAdjust3Points3:
			if (valid = [self adjust3Points])
				[self setSelectedTool:[self nextTool]];
			break;

		case GCAdjust4Points1:
			[self setSelectedTool:GCAdjust4Points2];
			break;
		case GCAdjust4Points2:
			[self setSelectedTool:GCAdjust4Points3];
			break;
		case GCAdjust4Points3:
			[self setSelectedTool:GCAdjust4Points4];
			break;
		case GCAdjust4Points4:
			if (valid = [self adjust4Points])
				[self setSelectedTool:[self nextTool]];
			break;

		case GCAdjustAbscissaOrdinate1:
			[self setSelectedTool:GCAdjustAbscissaOrdinate2];
			break;
		case GCAdjustAbscissaOrdinate2:
			valid = [self adjustAbscissa:1];
			[self setSelectedTool:GCAdjustAbscissaOrdinate3];
			break;
		case GCAdjustAbscissaOrdinate3:
			[self setSelectedTool:GCAdjustAbscissaOrdinate4];
			break;
		case GCAdjustAbscissaOrdinate4:
			if (valid = [self adjustOrdinate:1])
				[self setSelectedTool:[self nextTool]];
			break;

		case GCAdjustWithWizard:
			valid = YES;
			if ([mAdjustmentWizard didPromptCoordinates:mPromptCoordinates atPosition:position isValid:&valid] && valid) {
				[self adjustmentDidEnd:YES];
				[self setSelectedTool:[self nextTool]];
			}
			break;
	}
	
	if (!valid) {
		if (mSelectedTool != GCAdjustWithWizard)
			[self runInvalidAdjustErrorAlert];
		[self adjustmentDidEnd:NO];
		[self setSelectedTool:mPreviousSelectedTool];
	}
}

-(BOOL)adjustScale
{
	NSPoint a = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:GCAdjustScale1]] pointValue];
	NSPoint b = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:GCAdjustScale2]] pointValue];
	float scale = mPromptLength / hypot(a.x - b.x, a.y - b.y);
	if (!isdefined(scale))
		return NO;
	
	[mFrame beginEditing];
	[self adjustFrame:nil];
	a = [mFrame cornerPoint:0];
	b = [mFrame cornerPoint:2];
	[mFrame setXMin:0.0];
	[mFrame setYMin:0.0];
	[mFrame setXMax:(b.x - a.x) * scale];
	[mFrame setYMax:(b.y - a.y) * scale];
	[mFrame endEditing];
	return YES;
}

-(float)promptLength
{
	return mPromptLength;
}

-(void)setPromptLength:(float)inLength
{
	mPromptLength = inLength;
}

-(void)promptScale
{
	[mPromptedPositions setObject:[NSValue valueWithPoint:mMagnificationLocation] forKey:[NSNumber numberWithInt:mSelectedTool]];

	BOOL valid = YES;
	switch (mSelectedTool) {
		case GCAdjustScale1:
			[self setSelectedTool:GCAdjustScale2];
			break;
		case GCAdjustScale2: {
			NSPoint a = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:GCAdjustScale1]] pointValue];
			NSPoint b = [[mPromptedPositions objectForKey:[NSNumber numberWithInt:GCAdjustScale2]] pointValue];
			[self willChangeValueForKey:@"promptLength"];
			mPromptLength = hypot(a.x - b.x, a.y - b.y);
			[self didChangeValueForKey:@"promptLength"];
			[self removeMagnifyingGlass];
			if ([NSApp runModalForWindow:mScalePromptWindow] == NSCancelButton) {
				[self setSelectedTool:mPreviousSelectedTool];
				return;
			}
			if (valid = [self adjustScale])
				[self setSelectedTool:[self nextTool]];
			[mScalePromptWindow orderOut:nil];
			break;
		}
		default:
			break;
	}
	if (!valid)
		[self runInvalidAdjustErrorAlert];
}

-(IBAction)confirmCoordinatePrompt:(id)inSender
{
	[NSApp stopModalWithCode:NSOKButton];
}

-(IBAction)cancelCoordinatePrompt:(id)inSender
{
	[NSApp stopModalWithCode:NSCancelButton];
}

@end
