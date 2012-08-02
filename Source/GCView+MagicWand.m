//
//  GCView+MagicWand.m
//  GraphClick
//
//  Created by Simon Bovet on 21.08.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GCView+MagicWand.h"

#import "GCFoundation.h"
#import "GCNumberFormatter.h"
#import "GCGuide.h"
#import "GCDocument.h"
#import "GCOptionalAlert.h"
#import "GCFilterController.h"
#import "GCHistogram.h"
#import "GCInspector.h"
#import "GCLineFinder.h"

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

-(void)selectPointsInRect:(NSRect)inRect addToSelection:(BOOL)inAdd;
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

-(void)stepForwardIfNeeded;
-(void)displayMagicWandView:(int)inIndex;

-(void)extendLineBetween:(NSPoint)inFrom and:(NSPoint)inTo to:(NSPoint *)outFrom and:(NSPoint *)outTo;

-(BOOL)shouldDisplayGuide;

-(void)requestMovieImageAtTime:(float)inTime;

-(void)updateZoomPopUp;

@end

@interface GCSerie (Private)

-(void)setName:(NSString *)inName;
-(void)setColor:(NSColor *)inColor;
-(void)setConnected:(BOOL)inConnected;
-(void)setDefinesArea:(BOOL)inDefinesArea;

@end

@implementation GCView (MagicWand)

static bool sKeepOnMagicWand = NO;
static int sMagicWandType = 0;

static GCSerie *sInitiallySelectedSerie = nil;
static NSIndexSet *sIndexesOfInitiallySelectedPoints = nil;
static BOOL sSerieWasConnected;
static BOOL sSerieWasArea;

static NSMutableArray *sNewSeries = nil;
static NSMutableArray *sSeriesToSelect = nil;
static NSIndexSet *sIndexesOfNewPointsInInitiallySelectedSerie = nil;

-(float)insertionTime
{
	float time = [self time];
	if (time == 0) {
		GCPoint *point = [[mPointController selectedObjects] lastObject];
		if (!point)
			point = [[[[mSerieController selectedObjects] lastObject] points] lastObject];
		if (point)
			time = [point time];
	}
	return time;
}

-(void)preparePointInsertion
{
	[sSeriesToSelect release];
	sSeriesToSelect = nil;
	[GCPoint setCurrentTime:[self insertionTime]];
	[mFrame beginEditing];
	mInsertionSerie = [[mSerieController selectedObjects] lastObject];
	NSIndexSet *indexSet = [mPointController selectionIndexes];
	mInsertionIndex = [indexSet count] == 0 ? [[mInsertionSerie points] count] : [indexSet lastIndex] + 1;
	[mPointsToSelect removeAllIndexes];
}

-(void)insertSinglePoint:(NSPoint)inPoint
{
	[mInsertionSerie insertPoint:inPoint atIndex:mInsertionIndex];
	[mPointsToSelect addIndex:mInsertionIndex++];
}

-(void)selectedSerieDidChange
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GCSelectedSerieDidChangeNotification object:nil];
}

-(void)finishPointInsertion
{
	if ([mPointsToSelect count] > 0) {
		[mPointController setSelectionIndexes:mPointsToSelect];
		if ([sSeriesToSelect count] > 0) {
			[mSerieController setSelectedObjects:sSeriesToSelect];
			[self selectedSerieDidChange];
		}
		[self setNeedsDisplay:YES];
	}
	[mFrame endEditing];
	mInsertionSerie = nil;
}

-(void)stepForwardIfNeeded
{
	if ([mPointsToSelect count] > 0 && [self autoStepForward])
		[self stepForward:nil wait:YES];
}

-(void)prepareThreadedPointInsertion
{
	[GCPoint setCurrentTime:[self insertionTime]];
	[mThreadedPointsToInsert release];
	mThreadedPointsToInsert = [[NSMutableArray alloc] initWithCapacity:1000];
}

-(void)insertThreadedSeparator
{
	[mThreadedPointsToInsert addObject:[NSNull null]];
}

-(void)insertThreadedSinglePoint:(NSPoint)inPoint
{
	[mThreadedPointsToInsert addObject:[NSValue valueWithPoint:inPoint]];
}

-(void)finishThreadedPointInsertion
{
}

-(void)prepareNewElements
{
	sInitiallySelectedSerie = [self selectedSerie];
	sIndexesOfInitiallySelectedPoints = [[mPointController selectionIndexes] copy];
	sSerieWasConnected = [sInitiallySelectedSerie connected];
	sSerieWasArea = [sInitiallySelectedSerie definesArea];
}

-(void)finishNewElements
{
	[sNewSeries release];
	sNewSeries = nil;
	[sSeriesToSelect release];
	sSeriesToSelect = nil;
	[sIndexesOfNewPointsInInitiallySelectedSerie release];
	sIndexesOfNewPointsInInitiallySelectedSerie = nil;
	[sIndexesOfInitiallySelectedPoints release];
	sIndexesOfInitiallySelectedPoints = nil;
}

-(void)removeNewElements
{
	if ([sNewSeries count] > 0) {
		[mSerieController removeObjects:sNewSeries];
		[mSerieController setSelectedObjects:[NSArray arrayWithObjects:sInitiallySelectedSerie, nil]];
		[self selectedSerieDidChange];
		[mPointController removeObjectsAtArrangedObjectIndexes:sIndexesOfNewPointsInInitiallySelectedSerie];
	} else
		[mPointController remove:nil];
	[mPointController setSelectionIndexes:sIndexesOfInitiallySelectedPoints];
	[sInitiallySelectedSerie setConnected:sSerieWasConnected];
	[sInitiallySelectedSerie setDefinesArea:sSerieWasArea];	
	[self finishNewElements];
	[self prepareNewElements];
}

-(GCSerie *)addNewSerie:(BOOL)inSelectPrevious
{
	GCSerie *newSerie = [[[GCSerie alloc] init] autorelease];
	[mSerieController addObject:newSerie];
	[newSerie name];
	[mSerieController setSelectedObjects:[NSArray arrayWithObjects:newSerie, nil]];
	[self selectedSerieDidChange];
	if (!sSeriesToSelect)
		sSeriesToSelect = [[NSMutableArray alloc] initWithCapacity:0];
	if (!sNewSeries) {
		sIndexesOfNewPointsInInitiallySelectedSerie = [mPointsToSelect copy];
		sNewSeries = [[NSMutableArray alloc] initWithCapacity:0];
		if (inSelectPrevious && mInsertionSerie)
			[sSeriesToSelect addObject:mInsertionSerie];
	}
	[sNewSeries addObject:newSerie];
	[sSeriesToSelect addObject:newSerie];
	[mPointsToSelect removeAllIndexes];
	mInsertionSerie = newSerie;
	mInsertionIndex = 0;
	return newSerie;
}

-(void)insertThreadedPoints
{
	[self preparePointInsertion];
	if (sMagicWandType == GCAreaType ||sMagicWandType == GCAreasType) {
		GCSerie *serie = [self selectedSerie];
		if ([[serie points] count] > 0)
			serie = [self addNewSerie:NO];
		[serie setConnected:YES];
		[serie setDefinesArea:YES];
		[self selectedSerieDidChange];
	}
	
	NSEnumerator *enumerator = [mThreadedPointsToInsert objectEnumerator];
	id point;
	while (point = [enumerator nextObject])
		if ([point isKindOfClass:[NSValue class]])
			[self insertSinglePoint:[point pointValue]];
		else {
			GCSerie *previousSerie = mInsertionSerie;
			GCSerie *newSerie = [self addNewSerie:YES];
			[newSerie setName:[[previousSerie name] stringByIncreasingIndexBy:1]];
			[newSerie setColor:[[[previousSerie color] copy] autorelease]];
			[newSerie setConnected:YES];
			[newSerie setDefinesArea:YES];
		}
	[self finishPointInsertion];
	[mThreadedPointsToInsert release];
	mThreadedPointsToInsert = nil;
	if (mExceedingMaxNumberOfPoints) {
		GCRunOptionalAlertPanel(@"MagicWandMaxReached", NSLocalizedString(@"Max Detection Alert Title", @""), NSLocalizedString(@"Max Detection Alert Message", @""));
		mExceedingMaxNumberOfPoints = NO;
	}
}

-(BOOL)canInsertPoint
{
	if ([[mSerieController selectedObjects] count] > 1) {
		NSString *title = NSLocalizedString(@"Multiple Data Sets Selected Alert Title", @"");
		NSString *message = NSLocalizedString(@"Multiple Data Sets Selected Alert Message", @"");
		NSRunAlertPanel(title, message, nil, nil, nil);
		return NO;
	}
	GCSerie *serie = [self selectedSerie];
	if (!serie)
		[self addNewSerie:NO];
	else if (![serie visible]) {
		NSString *title = NSLocalizedString(@"Invisible Data Set Alert Title", @"");
		NSString *message = NSLocalizedString(@"Invisible Data Set Alert Message", @"");
		int choice = NSRunAlertPanel(title, message, NSLocalizedString(@"Make Visible Button", @""), NSLocalizedString(@"Cancel Insert Point Button", @""), nil);
		if (choice == NSAlertDefaultReturn)
			[serie setVisible:YES];
		else
			return NO;
	}
	return YES;
}

-(void)insertPoint:(NSPoint)inPoint
{
	if ([self canInsertPoint]) {
		NSPoint point = [self snapPointToGrid:inPoint];
		[self preparePointInsertion];
		[self insertSinglePoint:point];
		BOOL keepAdding = NO;
		[self setNeedsDisplay:YES];
		[NSEvent startPeriodicEventsAfterDelay:0.25 withPeriod:1e6];
		
		BOOL keepOn = YES;
		while (keepOn) {
			NSEvent *event = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];

			switch ([event type]) {
				case NSLeftMouseDragged: {
					if (keepAdding) {
						NSPoint pt = [self snapPointToGrid:[self convertEventLocation:event]];
						if (!NSEqualPoints(pt, point)) {
							[self insertSinglePoint:pt];
							point = pt;
						}
					}
					[self mouseMoved:event];
					break;
				}
				case NSLeftMouseUp:
					keepOn = NO;
					break;
				case NSPeriodic:
					keepAdding = YES;
					break;
				default:
					break;
			}
		}
		
	    [NSEvent stopPeriodicEvents];
		[self finishPointInsertion];
		[self stepForwardIfNeeded];
	}
}

static float *mwArray;
static int mwWidth;
static int mwHeight;
static int mwMaxIndex;
static float mwThreshold;

int mwXMin, mwXMax, mwYMin, mwYMax;
int mwTrackLimits;

int mwFill(int index)
{
	if (mwArray[index] < mwThreshold) {
#ifdef __DEBUG__
		if (index < 0 || index >= mwMaxIndex) {
			printf("*** mwFill(): index (%i) out of bounds [0,%i[", index, mwMaxIndex);
			index = 0;
		}
#endif
		mwArray[index] += 10;
		if (mwTrackLimits) {
			int x = index % mwWidth;
			int y = index / mwWidth;
			if (x < mwXMin)
				mwXMin = x;
			if (x > mwXMax)
				mwXMax = x;
			if (y < mwYMin)
				mwYMin = y;
			if (y > mwYMax)
				mwYMax = y;
		}
		return 1;
	} else
		return 0;
}

#define PIXEL(x, y) mwArray[(x) + (y) * mwWidth]

void magicWandFilter()
{
	int x, y;
	for (x = 0; x < mwWidth - 1; x++)
		for (y = 0; y < mwHeight - 1; y++) {
			if (PIXEL(x, y) >= mwThreshold && PIXEL(x + 1, y + 1) >= mwThreshold &&
						PIXEL(x + 1, y) < mwThreshold && PIXEL(x, y + 1) < mwThreshold)
				PIXEL(x, y) = PIXEL(x + 1, y + 1) = MAX(PIXEL(x + 1, y), PIXEL(x, y + 1));
			else if (PIXEL(x + 1, y) >= mwThreshold && PIXEL(x, y + 1) >= mwThreshold &&
						PIXEL(x, y) < mwThreshold && PIXEL(x + 1, y + 1) < mwThreshold)
				PIXEL(x + 1, y) = PIXEL(x, y + 1) = MAX(PIXEL(x, y), PIXEL(x + 1, y + 1));
		}
}

void magicWand(int x0, int y0, int depth)
{
	if (depth == 300)
		return;
		
	int i0 = x0 + y0 * mwWidth;
	mwFill(i0);
	
	int x = x0 - 1;
	int i = i0 - 1;
	while (x >= 0 && mwFill(i)) {
		x--;
		i--;
	}
	int xmin = x + 1;

	x = x0 + 1;
	i = i0 + 1;
	while (x < mwWidth && mwFill(i)) {
		x++;
		i++;
	}
	int xmax = x - 1;
	int y;
	for (y = y0 - 1; y <= y0 + 1 && sKeepOnMagicWand; y += 2)
		if (y >= 0 && y < mwHeight)
			for (x = xmin, i = xmin + y * mwWidth; x <= xmax && sKeepOnMagicWand; x++, i++)
				if (mwFill(i))
					magicWand(x, y, depth + 1);
}

#define VALUE(x, y) MAX(0, mwThreshold - mwArray[(x) + (y) * mwWidth])

int verticalCenter(int x, int *min, int *max, float *positions)
{
	int ymin = *min - 1, ymax = *max + 1;
	while (VALUE(x, ymin) == 0 && ymin < ymax)
		ymin++;
	while (ymin > 0 && VALUE(x, ymin - 1) > 0)
		ymin--;
		
	float sum = 0;
	int n = 0;
	ymax = ymin;
	while (ymax < mwHeight) {
		float val = VALUE(x, ymax);
		if (val == 0) {
			ymax--;
			break;
		}
		sum += ymax++;
		n++;
	}
	
	if (n == 0)
		return 0;
	
	positions[x] = sum / n;
	*min = ymin;
	*max = ymax;
	return 1;
}

void horizontalMagicWand(int x0, int y0, int *xmin, int *xmax, float *positions)
{
	int ymin0 = y0, ymax0 = y0;
	verticalCenter(x0, &ymin0, &ymax0, positions);
	int x = x0;
	int ymin = ymin0, ymax = ymax0;
	while (sKeepOnMagicWand && x > 0 && verticalCenter(x - 1, &ymin, &ymax, positions))
		x--;
	*xmin = x;
	x = x0 + 1;
	ymin = ymin0, ymax = ymax0;
	while (sKeepOnMagicWand && x < mwWidth && verticalCenter(x, &ymin, &ymax, positions))
		x++;
	*xmax = x - 1;
}

void maskedHorizontalMagicWand(int xmin, int xmax, int ymin, int ymax, float *positions)
{
	int x;
	int y;
	float value, sum, total;
	for (x = xmin; sKeepOnMagicWand & x <= xmax; x++) {
		total = 0;
		sum = 0;
		for (y = ymin; sKeepOnMagicWand & y <= ymax; y++) {
			value = VALUE(x, y);
			total += value;
			sum += value * y;
		}
		positions[x] = total > 0 ? sum / total : -1;
	}
}

static float *sDistance = nil;
static int sX0, sY0;

-(void)resetMagicWandParameters
{
	[mMagicWandImage release];
	mMagicWandImage = nil;
	[mMagicWandBitmapImageRep release];
	mMagicWandBitmapImageRep = nil;
}

-(NSImage *)magicWandImageWithBounds:(NSRect)inBounds
{
	if (!mMagicWandImage) {
		mMagicWandImage = [[NSImage alloc] initWithSize:inBounds.size];
		[mMagicWandImage lockFocus];
		[[NSColor whiteColor] set];
		NSRectFill(NSMakeRect(0, 0, inBounds.size.width, inBounds.size.height));
		[NSGraphicsContext saveGraphicsState];
		NSAffineTransform *translation = [NSAffineTransform transform];
		[translation translateXBy:-inBounds.origin.x yBy:-inBounds.origin.y + 1];
		[translation concat];
		[self drawImageWithFraction:1.0 zoomFactor:1.0];
		[NSGraphicsContext restoreGraphicsState];
		[mMagicWandImage unlockFocus];
	}
	return mMagicWandImage;
}

-(NSBitmapImageRep *)magicWandImageRepWithBounds:(NSRect)inBounds bytesPerPixel:(int *)outBPP
{
	if (!mMagicWandBitmapImageRep) {
		NSImage *image = [self magicWandImageWithBounds:inBounds];
		mMagicWandBitmapImageRep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
		mMagicWandBPP = 0;
		if ([mMagicWandBitmapImageRep bitsPerPixel] == 32 && [mMagicWandBitmapImageRep samplesPerPixel] == 4 && ![mMagicWandBitmapImageRep isPlanar])
			mMagicWandBPP = 4;
		if ([mMagicWandBitmapImageRep bitsPerPixel] == 24 && [mMagicWandBitmapImageRep samplesPerPixel] == 3 && ![mMagicWandBitmapImageRep isPlanar])
			mMagicWandBPP = 3;
	}
	if (outBPP)
		*outBPP = mMagicWandBPP;
	return mMagicWandBPP > 0 ? mMagicWandBitmapImageRep : nil;
}

-(int)findSymbolWithThreshold:(float)inThreshold width:(int)inWidth height:(int)inHeight bitmap:(float *)inBitmap mask:(BOOL *)outMask
{
	mwThreshold = inThreshold;
	int x, y;
	for (x = 0; x < inWidth; x += inWidth - 1)
		for (y = 0; y < inHeight; y++)
			magicWand(x, y, 0);
	for (x = 1; x < inWidth - 1; x++)
		for (y = 0; y < inHeight; y += inHeight - 1)
			magicWand(x, y, 0);
	int index = 0;
	for (y = 0; y < inHeight; y++)
		for (x = 0; x < inWidth; x++)
			outMask[index++] = NO;

	index = 0;
	for (y = 0; y < inHeight; y++)
		for (x = 0; x < inWidth; x++) {
			inBitmap[index] = inBitmap[index] < 10.0 ? 0.0 : 100.0;
			index++;
		}

//#define __LOG__
#ifdef __LOG__
	printf("borders:\n");
	index = 0;
	for (y = 0; y < inHeight; y++) {
		for (x = 0; x < inWidth; x++)
			printf(inBitmap[index++] > 0 ? "* " : "  ");
		printf("\n");
	}
#endif

	mwThreshold = 1.0;
	magicWand(inWidth / 2, inHeight / 2, 0);

	index = 0;
	for (y = 0; y < inHeight; y++)
		for (x = 0; x < inWidth; x++) {
			if (inBitmap[index] >= 10.0 && inBitmap[index] < 100.0) {
				outMask[index] = YES;
				if (x > 0)
					outMask[index - 1] = YES;
				if (x < inWidth - 1)
					outMask[index + 1] = YES;
				if (y > 0)
					outMask[index - inWidth] = YES;
				if (y < inHeight - 1)
					outMask[index + inWidth] = YES;
			}
			index++;
		}

#ifdef __LOG__
	printf("mask:\n");
	index = 0;
	for (y = 0; y < inHeight; y++) {
		for (x = 0; x < inWidth; x++)
			printf(outMask[index++] ? "* " : "  ");
		printf("\n");
	}
#endif

	int kernelWeight = 0;
	index = 0;
	for (y = 0; y < inHeight; y++)
		for (x = 0; x < inWidth; x++)
			if (outMask[index++])
				kernelWeight++;
	return kernelWeight;
}

float lightness(float *rgb)
{
	return (MAX(MAX(rgb[0], rgb[1]), rgb[2]) + MIN(MIN(rgb[0], rgb[1]), rgb[2])) / 2;
}

static float *sKernel = nil;
static BOOL *sKernelMask = nil;
static int sKernelWidth, sKernelHeight, sKernelWeight;

-(BOOL)prepareSymbolFromPoint:(NSPoint)inPoint withBounds:(NSRect)inBounds
{
	int bpp = 0;
	NSBitmapImageRep *imageRep = [self magicWandImageRepWithBounds:inBounds bytesPerPixel:&bpp];
	if (!imageRep) {
		NSString *message = [NSString stringWithFormat:@"%@ BitsPerPixel=%i SamplesPerPixel=%i Planar=%s", imageRep, [imageRep bitsPerPixel], [imageRep samplesPerPixel], [imageRep isPlanar] ? "YES" : "NO"];
		NSRunCriticalAlertPanel(@"Unexpected Error",
			[NSString stringWithFormat:@"Please report the following message to Arizona:\n\n%@", message], nil, nil, nil);
		return NO;
	}
	
	unsigned char *bitmap = [imageRep bitmapData];
	int kernelSemiWidth = 30, kernelSemiHeight = 30;
	int kernelWidth = 2 * kernelSemiWidth + 1, kernelHeight = 2 * kernelSemiHeight + 1;
	float kernel[kernelWidth][kernelHeight][3];
	int x, y, c;
	int ymax = (int)([imageRep size].height) - 1;
	int bytesPerRow = [imageRep bytesPerRow];
	for (x = 0; x < kernelWidth; x++)
		for (y = 0; y < kernelHeight; y++) {
			unsigned char *src = bitmap + (sX0 - kernelSemiWidth + x) * bpp + (ymax - (sY0 - kernelSemiHeight + y)) * bytesPerRow;
			for (c = 0; c < 3; c++)
				kernel[x][y][c] = (float)(*src++) / 255;
		}
		
	float border[3] = {1.0, 1.0, 1.0};
	float borderLightness = lightness(border);
	float kernelInitialBorderMask[kernelWidth * kernelHeight];
	int index = 0;
	for (y = 0; y < kernelHeight; y++)
		for (x = 0; x < kernelWidth; x++)
			kernelInitialBorderMask[index++] = fabs(lightness(kernel[x][y]) - borderLightness);
		
	float kernelBorderMask[kernelWidth * kernelHeight];
	BOOL kernelMask[kernelWidth * kernelHeight];
	mwArray = kernelBorderMask;
	mwWidth = kernelWidth;
	mwHeight = kernelHeight;
	mwMaxIndex = mwWidth * mwHeight;
	mwTrackLimits = false;
	
	int i, N = 10;
	int lastWeight = -1;
	float threshold[N];
	int delta[N];
	int weight[N];
	float meanDelta = 0;
	for (i = 0; i < N; i++) {
		threshold[i] = 0.8 * i / N;
		memcpy(kernelBorderMask, kernelInitialBorderMask, kernelWidth * kernelHeight * sizeof(float));
		weight[i] = [self findSymbolWithThreshold:threshold[i] width:kernelWidth height:kernelHeight bitmap:kernelBorderMask mask:kernelMask];
		meanDelta += delta[i] = lastWeight >= 0 ? weight[i] - lastWeight : 0;
		lastWeight = weight[i];
	}
	meanDelta /= N;
	float optimalThreshold = 0.5;
	for (i = N - 1; i >= 0; i--)
		if (delta[i] < meanDelta) {
			optimalThreshold = threshold[MAX(0, weight[i] > 0 ? i : i - 1)];
			break;
		}
	
	
	memcpy(kernelBorderMask, kernelInitialBorderMask, kernelWidth * kernelHeight * sizeof(float));
	int kernelWeight = [self findSymbolWithThreshold:optimalThreshold width:kernelWidth height:kernelHeight bitmap:kernelBorderMask mask:kernelMask];
	if (kernelWeight == 0) {
		NSRunAlertPanel(NSLocalizedString(@"No Symbol Detected Alert Title", @""),
			NSLocalizedString(@"No Symbol Detected Alert Message", @""), nil, nil, nil);
		return NO;
	}
	
#ifdef __LOG__
	printf("Kernel:\n");
	index = 0;
	for (y = 0; y < kernelHeight; y++) {
		for (x = 0; x < kernelWidth; x++)
			printf(kernelMask[index++] ? "* " : "  ");
		printf("\n");
	}
#endif
	
	int xmin, xmax, ymin/*, ymax*/;
	for (xmin = 0; xmin < kernelWidth; xmin++) {
		for (y = 0; y < kernelHeight; y++)
			if (kernelMask[xmin + y * kernelWidth])
				break;
		if (y < kernelHeight)
			break;
	}
	for (xmax = kernelWidth - 1; xmax >= xmin; xmax--) {
		for (y = 0; y < kernelHeight; y++)
			if (kernelMask[xmax + y * kernelWidth])
				break;
		if (y < kernelHeight)
			break;
	}
	for (ymin = 0; ymin < kernelHeight; ymin++) {
		for (x = 0; x < kernelWidth; x++)
			if (kernelMask[x + ymin * kernelWidth])
				break;
		if (x < kernelWidth)
			break;
	}
	for (ymax = kernelHeight - 1; ymax >= ymin; ymax--) {
		for (x = 0; x < kernelWidth; x++)
			if (kernelMask[x + ymax * kernelWidth])
				break;
		if (x < kernelWidth)
			break;
	}
	
	sKernelWidth = xmax - xmin + 1;
	sKernelHeight = ymax - ymin + 1;
	if (sKernel)
		free(sKernel);
	if (sKernelMask)
		free(sKernelMask);
	sKernel = (float *)malloc(3 * sKernelWidth * sKernelHeight * sizeof(float));
	sKernelMask = (BOOL *)malloc(sKernelWidth * sKernelHeight * sizeof(BOOL));
	sKernelWeight = kernelWeight;
	index = 0;
	for (y = ymin; y <= ymax; y++)
		for (x = xmin; x <= xmax; x++)
			for (c = 0; c < 3; c++)
				sKernel[index++] = kernel[x][y][c];
	index = 0;
	for (y = ymin; y <= ymax; y++)
		for (x = xmin; x <= xmax; x++)
			sKernelMask[index++] = kernelMask[x + y * kernelWidth];
#ifdef __LOG__
	printf("############\nKernel:\n");
	index = 0;
	for (y = ymin; y <= ymax; y++) {
		for (x = xmin; x <= xmax; x++)
			for (c = 0; c < 3; c++)
				printf("%c%0.6f ", c == 0 ? 'R' : c == 1 ? 'G' : 'B', sKernel[index++]);
		printf("\n");
	}
	printf("Mask:\n");
	index = 0;
	for (y = ymin; y <= ymax; y++) {
		for (x = xmin; x <= xmax; x++)
			printf("%s ", sKernelMask[index++] ? "*" : " ");
		printf("\n");
	}
#endif

	NSBitmapImageRep *kernelRepresentation = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
			pixelsWide:sKernelWidth pixelsHigh:sKernelHeight bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
			colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
	unsigned char *kernelBitmap = [kernelRepresentation bitmapData];
	if (kernelBitmap) {
		float *src = sKernel;
		BOOL *mask = sKernelMask;
		index = 0;
		for (y = 0; y < sKernelHeight; y++) {
			unsigned char *dst = kernelBitmap + (sKernelHeight - 1 - y) * [kernelRepresentation bytesPerRow];
			for (x = 0; x < sKernelWidth; x++) {
				BOOL opaque = *mask++;
				for (c = 0; c < 3; c++)
					*dst++ = (opaque ? 255 : 0) * (*src++);
				*dst++ = opaque ? 255 : 0;
			}
		}
	}

	NSSize size = [kernelRepresentation size];
	size.width = MAX(1, size.width);
	size.height = MAX(1, size.height);
	NSImage *kernelImage = [[[NSImage alloc] initWithSize:size] autorelease];
	[kernelImage addRepresentation:kernelRepresentation];
	[mMagicWandSymbolImageView setImage:kernelImage];

	[self displayMagicWandView:3];
	int choice = [NSApp runModalForWindow:mMagicWandSheet];
	if (choice != NSOKButton) {
		[mMagicWandSheet orderOut:nil];
		return NO;
	} else
		return YES;
}

-(IBAction)confirmSymbol:(id)inSender
{
	[NSApp stopModalWithCode:NSOKButton];
}

-(IBAction)cancelSymbol:(id)inSender
{
	[NSApp stopModalWithCode:NSCancelButton];
}

-(BOOL)preventBackgroundClickAtPoint:(NSPoint)inPoint withBounds:(NSRect)inBounds
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:GCBackgroundSelectionWarning]) {
		NSImage *image = [self magicWandImageWithBounds:inBounds];
		if (sX0 >= 0 && sX0 < [image pixelSize].width && sY0 >= 0 && sY0 < [image pixelSize].height) {
			[image lockFocus];
			NSColor *color = NSReadPixel(NSMakePoint(sX0, sY0));
			[image unlockFocus];
			if ([mHistogram isColor:color backgroundOfImage:mImage] && 
					NSRunAlertPanel(NSLocalizedString(@"Background Selected Alert Title", @""), NSLocalizedString(@"Background Selected Alert Message", @""), NSLocalizedString(@"Background Selected Continue Button", @""), NSLocalizedString(@"Background Selected Alternate Button", @""), nil) == NSAlertAlternateReturn)
				return NO;
		}
	}
	return YES;
}

-(void)prepareMagicWandAt:(NSPoint)inPoint withBounds:(NSRect)inBounds type:(int)inType
{
	int width = inBounds.size.width;
	int height = inBounds.size.height;
	if (sDistance)
		free(sDistance);
	sDistance = (float *)calloc(width * height, sizeof(float));
	
	if (sDistance) {
		NSImage *image = [self magicWandImageWithBounds:inBounds];
		
		int bpp = 0;
		NSBitmapImageRep *imageRep = [self magicWandImageRepWithBounds:inBounds bytesPerPixel:&bpp];
		if (!imageRep) {
			[image lockFocus];
			float x0 = MAX(0, MIN([image pixelSize].width - 1, sX0));
			float y0 = MAX(0, MIN([image pixelSize].height - 1, sY0));
			NSColor *magicColor = NSReadPixel(NSMakePoint(x0, y0));
			int x, y;
			NSPoint pt;
			int index = 0;
			for (y = 0; y < height && mKeepOnMagicWand; y++) {
				mMagicWandProgress = (float)y / height;
				[self performSelectorOnMainThread:@selector(updateMagicWandProgress:) withObject:nil waitUntilDone:NO];

				pt.y = y;
				for (x = 0; x < width && mKeepOnMagicWand; x++) {
					pt.x = x;

					sDistance[index++] = [magicColor distanceToColor:NSReadPixel(pt)];
				}
			}
			[image unlockFocus];
		} else if (inType != GCMagicSymbolType) {
			unsigned char *bitmap = [imageRep bitmapData];

			int x = sX0, y = sY0;
			int ymax = (int)([imageRep size].height) - 1;
			unsigned char *bit = bitmap + x * bpp + (ymax - y) * [imageRep bytesPerRow];
			float r0 = bit[0], g0 = bit[1], b0 = bit[2];
			
			const float k = 1.0 / sqrt(3 * 255 * 255);
			int index = 0;
			for (y = 0; y < height && mKeepOnMagicWand; y++) {
				if (y % 32 == 0) {
					mMagicWandProgress = (float)y / height;
					[self performSelectorOnMainThread:@selector(updateMagicWandProgress:) withObject:nil waitUntilDone:NO];
				}
				
				bit = bitmap + (ymax - y) * [imageRep bytesPerRow];
				for (x = 0; x < width && mKeepOnMagicWand; x++) {
					float r = bit[0], g = bit[1], b = bit[2];
					sDistance[index++] = hypot(hypot(r - r0, g - g0), b - b0) * k;
					bit += bpp;
				}
			}
		} else {
			unsigned char *bitmap = [imageRep bitmapData];

			int index = (height - sKernelHeight) * width;
			int x, y, c;
			for (y = 0; y < sKernelHeight; y++)
				for (x = 0; x < width; x++)
					sDistance[index++] = 10.0;
			
			index = 0;
			const float uc2f = 1.0 / 255;
			int bytesPerRow = [imageRep bytesPerRow];
			int ymax = (int)([imageRep size].height) - 1;
			for (y = 0; y < height - sKernelHeight && mKeepOnMagicWand; y++) {
				mMagicWandProgress = (float)y / (height - sKernelHeight);
				[self performSelectorOnMainThread:@selector(updateMagicWandProgress:) withObject:nil waitUntilDone:NO];
				
				int deltaSrc = - bytesPerRow - sKernelWidth * bpp;
				for (x = 0; x < width - sKernelWidth && mKeepOnMagicWand; x++) {
					int kx, ky;
					float dist = 0.0;
					unsigned char *src = bitmap + x * bpp + (ymax - y) * bytesPerRow;
					float *kernel = sKernel;
					BOOL *mask = sKernelMask;
					for (ky = 0; ky < sKernelHeight; ky++) {
						for (kx = 0; kx < sKernelWidth; kx++)
							if (!(*mask++)) {
								kernel += 3;
								src += bpp;
							} else {
								for (c = 0; c < 3; c++)
									dist += fabs((*kernel++) - uc2f * (*src++));
								src += (bpp - 3);
							}
						src += deltaSrc;
					}
					sDistance[index++] = dist / (3 * sKernelWeight);
#ifdef __LOG__
				if (sDistance[index - 1] < 0.1) {
					printf("---------- dist: %f\n", dist);
					src = bitmap + x * bpp + (ymax - y) * bytesPerRow;
					kernel = sKernel;
					mask = sKernelMask;
					for (ky = 0; ky < sKernelHeight; ky++) {
						for (kx = 0; kx < sKernelWidth; kx++)
							if (!(*mask++)) {
								printf("---\n");
								kernel += 3;
								src += bpp;
							} else {
								for (c = 0; c < 3; c++) {
									printf("k: %0.8f s: %0.8f ", *kernel, uc2f * (*src));
									printf("d: %0.8f\n", fabs((*kernel++) - uc2f * (*src++)));
								}
								src += (bpp - 3);
							}
						src += deltaSrc;
					}
				}
#endif
				}

				for (; x < width; x++)
					sDistance[index++] = 10.0;
			}
		}

		if (mKeepOnMagicWand) {
			mMagicWandProgress = 1.0;
			[self performSelectorOnMainThread:@selector(updateMagicWandProgress:) withObject:nil waitUntilDone:NO];
		}

		GCMask *mask = [mFrame mask];
		if (mKeepOnMagicWand && [mask hasContent]) {
			[mask lockFocus];
			int x, y, index = 0;
			NSPoint pt;
			float m;
			for (y = 0; y < height && mKeepOnMagicWand; y++) {
				pt.y = inBounds.origin.y + y;
				for (x = 0; x < width && mKeepOnMagicWand; x++) {
					pt.x = inBounds.origin.x + x;
					m = [mask valueAt:pt];
					sDistance[index] = 2.0 * (1.0 - m) + sDistance[index] * m;
					index++;
				}
			}
			[mask unlockFocus];
		}
	}
}

void rotateCW45(int *dx, int *dy)
{
	int x = *dx - *dy;
	int y = *dx + *dy;
	*dx = x == -2 ? -1 : x == 2 ? 1 : 0;
	*dy = y == -2 ? -1 : y == 2 ? 1 : 0;
}

void rotateCCW45(int *dx, int *dy)
{
	int x = *dx + *dy;
	int y = *dx - *dy;
	*dx = x == -2 ? -1 : x == 2 ? 1 : 0;
	*dy = y == -2 ? -1 : y == 2 ? 1 : 0;
}

-(void)magicWandAt:(NSPoint)inPoint withBounds:(NSRect)inBounds type:(int)inType
{
	int width = inBounds.size.width;
	int height = inBounds.size.height;
	float *distance = (float *)calloc(width * height, sizeof(float));
	memcpy(distance, sDistance, width * height * sizeof(float));
	
	if (distance) {
		NS_DURING
			int x0 = sX0;
			int y0 = sY0;
			int x, y;
			GCMask *mask = [mFrame mask];
			if (![mask hasContent])
				mask = nil;
			mwArray = distance;
			mwWidth = width;
			mwHeight = height;
			mwMaxIndex = mwWidth * mwHeight;
			mwThreshold = MAX(1e-3, [[NSUserDefaults standardUserDefaults] floatForKey:GCMagicWandTolerance]);
			mwTrackLimits = false;
			[self prepareThreadedPointInsertion];
			long count = [[NSUserDefaults standardUserDefaults] floatForKey:GCMagicWandMaxNumberOfPoints];
			float r = MAX(1.0, [[NSUserDefaults standardUserDefaults] floatForKey:GCMagicWandSpacing]);
			int ir = MAX(1, round(r));
/*			if (inType == GCAreaType) {
				magicWandFilter();
				magicWand(x0, y0, 0);
				for (x = 0; x < width && mKeepOnMagicWand; x++)
					for (y = 0; y < height && mKeepOnMagicWand; y++)
						if (distance[x + y * width] >= 10) {
							int xx, yy;
							for (xx = x - ir; xx <= x + ir; xx++)
								if (xx >= 0 && xx < width)
									for (yy = y - ir; yy <= y + ir; yy++)
										if (yy >= 0 && yy < height && hypot(x - xx, y - yy) <= ir)
											distance[xx + yy * width] = 0;
							[self insertThreadedSinglePoint:NSMakePoint(inBounds.origin.x + x, inBounds.origin.y + y)];
							if (--count <= 0)
								goto abort;
						}
			} */
			if (inType == GCAreasType) {
				magicWandFilter();
				
				BOOL keepOnRemovingEdges;
				int index;

				int leftMargin = 0;
				keepOnRemovingEdges = YES;
				while (mKeepOnMagicWand && keepOnRemovingEdges) {
					for (y = 0; y < height && mKeepOnMagicWand; y++) {
						index = leftMargin + y * width;
						if (distance[index] >= mwThreshold)
							keepOnRemovingEdges = NO;
						distance[index] = 2;
					}
					leftMargin++;
				}
				
				int rightMargin = 0;
				keepOnRemovingEdges = YES;
				while (mKeepOnMagicWand && keepOnRemovingEdges) {
					for (y = 0; y < height && mKeepOnMagicWand; y++) {
						index = width - 1 - rightMargin + y * width;
						if (distance[index] >= mwThreshold)
							keepOnRemovingEdges = NO;
						distance[index] = 2;
					}
					rightMargin++;
				}
				
				int bottomMargin = 0;
				keepOnRemovingEdges = YES;
				while (mKeepOnMagicWand && keepOnRemovingEdges) {
					for (x = leftMargin; x < width - rightMargin && mKeepOnMagicWand; x++) {
						index = x + bottomMargin * width;
						if (distance[index] >= mwThreshold)
							keepOnRemovingEdges = NO;
						distance[index] = 2;
					}
					bottomMargin++;
				}
				
				int topMargin = 0;
				keepOnRemovingEdges = YES;
				while (mKeepOnMagicWand && keepOnRemovingEdges) {
					for (x = leftMargin; x < width - rightMargin && mKeepOnMagicWand; x++) {
						index = x + (height - 1 - topMargin) * width;
						if (distance[index] >= mwThreshold)
							keepOnRemovingEdges = NO;
						distance[index] = 2;
					}
					topMargin++;
				}
				
				BOOL first = YES;
				int xx0, yy0;
				for (xx0 = 0; xx0 < width && mKeepOnMagicWand; xx0++)
					for (yy0 = 0; yy0 < height && mKeepOnMagicWand; yy0++)
						if (distance[xx0 + yy0 * width] < mwThreshold) {
							magicWand(x0 = xx0, y0 = yy0, 0);
									
							BOOL found = YES;
							while (distance[x0 + y0 * width] >= 10)
								x0--;
							x0++;
							if (found) {
								x = x0;
								y = y0;
								int dx = 0, dy = 1;
								int c = 0;
								do {
									if ((c++ % ir) == 0) {
										if (c == 1)
											if (first)
												first = NO;
											else
												[self insertThreadedSeparator];
										[self insertThreadedSinglePoint:NSMakePoint(inBounds.origin.x + x, inBounds.origin.y + y)];
										if (--count <= 0)
											goto abort;
									}
									int d = dx;
									dx = -dy;
									dy = d;
									int turn;
									for (turn = 0; turn < 4; turn++) {
										float d = distance[(x + dx) + (y + dy) * width];
										if (d >= 10)
											break;
										d = dx;
										dx = dy;
										dy = -d;
									}
									if (turn == 4)
										break;
									x += dx;
									y += dy;
								} while (mKeepOnMagicWand && (x != x0 || y != y0));
							}
						}
			} else if (inType == GCCurveType) {
				float *src = distance;
				float k = 1.0 / mwThreshold;
				for (y = 0; y < height && mKeepOnMagicWand; y++)
					for (x = 0; x < width && mKeepOnMagicWand; x++)
						*src++ = MAX(0.0, MIN(1.0, k * (mwThreshold - *src)));
				GCLineFinder *lineFinder = [[[GCLineFinder alloc] initWithWidth:width height:height pixels:distance] autorelease];
				NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
				[lineFinder startAroundX:x0 y:y0 spacingTolerance:[defaults floatForKey:GCMagicWandLineFinderSpacing]
							extremity:[defaults boolForKey:GCMagicWandLineFinderExtremity]
							rightToLeft:[defaults boolForKey:GCMagicWandLineFinderRightToLeft]
							keepOnFlag:&mKeepOnMagicWand];

				NSPoint last = NSMakePoint(-2 * r, -2 * r);
				NSPoint p;
				while (mKeepOnMagicWand && [lineFinder followLineAtX:&p.x y:&p.y])
					if (hypot(last.x - p.x, last.y - p.y) >= r) {
						last = p;
						[self insertThreadedSinglePoint:NSMakePoint(inBounds.origin.x + p.x, inBounds.origin.y + p.y)];
					}
			} else if (inType == GCAreaType) {
				magicWandFilter();
				for (x = 0; x < width && mKeepOnMagicWand; x++)
					distance[x] = distance[x + (height - 1) * width] = 2;
				for (y = 0; y < height && mKeepOnMagicWand; y++)
					distance[y * width] = distance[(y + 1) * width - 1] = 2;
				
				magicWand(x0, y0, 0);
						
				BOOL found = NO;
				for (x = 0; x < x0; x++)
					if (distance[x + y0 * width] >= 10) {
						x0 = x;
						found = YES;
						break;
					}
				if (found) {
					x = x0;
					y = y0;
					int dx = 0, dy = 1;
					int c = 0;
					do {
						if ((c++ % ir) == 0) {
							[self insertThreadedSinglePoint:NSMakePoint(inBounds.origin.x + x, inBounds.origin.y + y)];
							if (--count <= 0)
								goto abort;
						}
						int d = dx;
						dx = -dy;
						dy = d;
						int turn;
						for (turn = 0; turn < 4; turn++) {
							float d = distance[(x + dx) + (y + dy) * width];
							if (d < mwThreshold || d >= 10)
								break;
							d = dx;
							dx = dy;
							dy = -d;
						}
						if (turn == 4)
							break;
						x += dx;
						y += dy;
					} while (mKeepOnMagicWand && (x != x0 || y != y0));
				}
			} else if (inType == GCHorizontalCurveType) {
				float positions[width];
				int xmin, xmax;
				if (mask)
					maskedHorizontalMagicWand(xmin = 0, xmax = width - 1, 1, height - 1, positions);
				else
					horizontalMagicWand(x0, y0, &xmin, &xmax, positions);
					
				if ([[NSUserDefaults standardUserDefaults] boolForKey:GCMagicWandSpacingDefinition] == 0) {
					float xf;
					float offset = [[NSUserDefaults standardUserDefaults] floatForKey:GCMagicWandHorizontalOffset] * r;
					for (xf = (float)xmin + offset; xf <= xmax && mKeepOnMagicWand; xf += r) {
						x = round(xf);
						if (x >= xmin && x <= xmax) {
							float pos = positions[x];
							if (pos >= 0) {
								[self insertThreadedSinglePoint:NSMakePoint(inBounds.origin.x + x, inBounds.origin.y + pos)];
								if (--count <= 0)
									goto abort;
							}
						}
					}
				} else {
					int n, N = [[NSUserDefaults standardUserDefaults] integerForKey:GCMagicWandNumberOfPoints];
					float delta = (float)(xmax - xmin) / MAX(1, N - 1);
					float offset = [[NSUserDefaults standardUserDefaults] floatForKey:GCMagicWandHorizontalOffset] * delta;
					for (n = 0; n < N && mKeepOnMagicWand; n++) {
						x = (int)round((float)xmin + n * delta + offset);
						if (x >= xmin && x <= xmax) {
							float pos = positions[x];
							if (pos >= 0) {
								[self insertThreadedSinglePoint:NSMakePoint(inBounds.origin.x + x, inBounds.origin.y + pos)];
								if (--count <= 0)
									goto abort;
							}
						}
					}
				}
			} else if (inType == GCBarType || inType == GCMagicSymbolType) {
				magicWandFilter();
				mwTrackLimits = true;
				NSPoint symbolOrigin = inBounds.origin;
				symbolOrigin.x += sKernelWidth / 2;
				symbolOrigin.y += sKernelHeight / 2;
				for (x = 0; x < width && mKeepOnMagicWand; x++)
					for (y = 0; y < height && mKeepOnMagicWand; y++) {
						if (distance[x + y * width] < mwThreshold) {
							mwXMin = mwXMax = x;
							mwYMin = mwYMax = y;
							magicWand(x, y, 0);
							if (!mKeepOnMagicWand)
								break;
							int sx, sy;
							float sumX = 0, sumY = 0, total = 0;
							int xMin, xMax, yMin, yMax;
							for (sx = mwXMin; sx <= mwXMax; sx++)
								for (sy = mwYMin; sy <= mwYMax; sy++) {
									int index = sx + sy * width;
									if (distance[index] >= 10) {
										float value = 11.0 - distance[index];
										distance[index] = 9.0;
										if (total == 0) {
											xMin = xMax = sx;
											yMin = yMax = sy;
										} else {
											if (sx < xMin)
												xMin = sx;
											if (sx > xMax)
												xMax = sx;
											if (sy < yMin)
												yMin = sy;
											if (sy > yMax)
												yMax = sy;
										}
											
										total += value;
										sumX += value * sx;
										sumY += value * sy;
									}
								}
							if (total > 0) {
								float xMean = sumX / total;
								float yMean = sumY / total;
								if (inType == GCBarType) {
									int sx, sy;
									float x, y;
									for (sx = 0; sx < 3; sx++) {
										x = sx == 0 ? xMin : sx == 1 ? xMean : xMax;
										for (sy = 0; sy < 3; sy++)
											if (mSymbolDetect[sx][sy]) {
												y = sy == 0 ? yMin : sy == 1 ? yMean : yMax;
												[self insertThreadedSinglePoint:NSMakePoint(inBounds.origin.x + x, inBounds.origin.y + y)];
												if (--count <= 0)
													goto abort;
											}
									}
								} else {
									[self insertThreadedSinglePoint:NSMakePoint(symbolOrigin.x + xMean, symbolOrigin.y + yMean)];
									if (--count <= 0)
										goto abort;
								}
							}
						}
					}
			}
			goto finish;
abort:
			mExceedingMaxNumberOfPoints = YES;
finish:
			[self finishThreadedPointInsertion];
			free(distance);
		NS_HANDLER
			free(distance);
		NS_ENDHANDLER
	}
}

-(void)magicWandThread:(id)inSender
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self prepareMagicWandAt:mMagicWandPoint withBounds:mMagicWandBounds type:mMagicWandType];
	[self magicWandAt:mMagicWandPoint withBounds:mMagicWandBounds type:mMagicWandType];
	[self performSelectorOnMainThread:@selector(magicWandPreparationDidEnd:) withObject:nil waitUntilDone:NO];
	[pool release];
}

-(float)magicWandProgress
{
	return mMagicWandProgress;
}

-(BOOL)magicWandFinalProgress
{
	return mMagicWandProgress >= 1.0;
}

-(void)updateMagicWandProgress:(id)inSender
{
	[self willChangeValueForKey:@"magicWandProgress"];
	[self didChangeValueForKey:@"magicWandProgress"];
}

-(BOOL)preparingMagicWand
{
	return mPreparingMagicWand;
}

-(void)setPreparingMagicWand:(BOOL)inFlag
{
	if (mPreparingMagicWand != inFlag) {
		[self willChangeValueForKey:@"magicWandProgress"];
		mMagicWandProgress = 0.0;
		[self didChangeValueForKey:@"magicWandProgress"];
		[self willChangeValueForKey:@"preparingMagicWand"];
		mPreparingMagicWand = inFlag;
		[self didChangeValueForKey:@"preparingMagicWand"];
	}
}

-(void)setMagicWandInProgress:(BOOL)inFlag
{
	if (mMagicWandInProgress != inFlag) {
		mMagicWandInProgress = inFlag;
		if (mMagicWandInProgress)
			[mFrame beginEditing];
		else
			[mFrame endEditing];
	}
}

-(void)magicWandPreparationDidEnd:(id)inSender
{
	[self removeMagnifyingGlass];
	if (mKeepOnMagicWand) {
		[self insertThreadedPoints];
		if ([[NSUserDefaults standardUserDefaults] boolForKey:GCMagicWandDynamic]) {
			mMagicWandDynamicChangeCount = 0;
			[self displayMagicWandView:mMagicWandType == GCBarType ? 2 : mMagicWandType == GCMagicSymbolType ? 4
									: mMagicWandType == GCAreaType || mMagicWandType == GCAreasType ? 5
									: mMagicWandType == GCCurveType ? 6 : 1];
			[self setPreparingMagicWand:NO];
		} else {
			[mMagicWandSheet orderOut:nil];
			[self confirmMagicWand:nil];
		}
	} else {
		[mMagicWandSheet orderOut:nil];
		[self setPreparingMagicWand:NO];
		[self cancelMagicWand:nil];
	}
}

-(void)magicWandParameterDidChange
{
	if (mMagicWandInProgress) {
		mMagicWandDynamicChangeCount++;
		[self performSelector:@selector(redoMagicWand:) withObject:nil afterDelay:1.0 inModes:[NSArray arrayWithObject:NSModalPanelRunLoopMode]];
	}
}

-(BOOL)magicWandIndicator
{
	return mMagicWandIndicator;
}

-(void)setMagicWandIndicator:(BOOL)inIndicator
{
	if (mMagicWandIndicator != inIndicator) {
		[self willChangeValueForKey:@"magicWandIndicator"];
		mMagicWandIndicator = inIndicator;
		[self didChangeValueForKey:@"magicWandIndicator"];
	}
}

-(void)redoMagicWand:(id)inSender
{
	if (--mMagicWandDynamicChangeCount == 0) {
		[self setMagicWandIndicator:YES];
		[self removeNewElements];
		[self magicWandAt:mMagicWandPoint withBounds:mMagicWandBounds type:mMagicWandType];
		[self insertThreadedPoints];
		[self setMagicWandIndicator:NO];
	}
}

-(IBAction)confirmMagicWand:(id)inSender
{
	[self redoMagicWand:nil];
	[self stepForwardIfNeeded];
	[NSApp stopModalWithCode:NSOKButton];
}

-(IBAction)cancelMagicWand:(id)inSender
{
	[self removeNewElements];
	[NSApp stopModalWithCode:NSCancelButton];
}

-(void)displayMagicWandView:(int)inIndex
{
	NSView *view;
	switch (inIndex) {
		case 0:
			view = mMagicWandDetectionView;
			break;
		case 1:
			view = mMagicWandCurveParametersView;
			break;
		case 2:
			view = mMagicWandBarParametersView;
			break;
		case 3:
			view = mMagicWandSymbolDetectionView;
			break;
		case 4:
			view = mMagicWandSymbolParametersView;
			break;
		case 5:
			view = mMagicWandAreaParametersView;
			break;
		case 6:
			view = mMagicWandLineParametersView;
	}

	[view performSelector:@selector(updateAdvancedViewState)];
	
	NSView *contentView = [mMagicWandSheet contentView];
	float deltaHeight = [view frame].size.height - [contentView frame].size.height;
	NSRect frameRect = [mMagicWandSheet frame];
	frameRect.origin.y -= deltaHeight;
	frameRect.size.height += deltaHeight;
	frameRect.size.width = [view frame].size.width;

	[mMagicWandSheet setContentView:[[[NSView alloc] initWithFrame:NSZeroRect] autorelease]];
//	[[contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[mMagicWandSheet setFrame:frameRect display:YES animate:NO];
	[mMagicWandSheet setContentView:view];
//	[contentView addSubview:view];
}

-(void)detachMagicWandThreadWithPoint:(NSPoint)inPoint type:(int)inType
{
	sMagicWandType = inType;
	[self prepareNewElements];
	
	if ([self canInsertPoint]) {
		sKeepOnMagicWand = mKeepOnMagicWand = YES;
		mMagicWandPoint = inPoint;
		mMagicWandType = inType;
		mMagicWandBounds = mBounds;
		if (inType == GCMagicSymbolType) {
			sX0 = mMagicWandPoint.x - mMagicWandBounds.origin.x;
			sY0 = mMagicWandPoint.y - mMagicWandBounds.origin.y;
			[self resetMagicWandParameters];
			if (![self prepareSymbolFromPoint:mMagicWandPoint withBounds:mMagicWandBounds])
				return;
		}
		GCMask *mask = [mFrame mask];
		if ([mask hasContent])
			mMagicWandBounds = [mask contentBounds];
		sX0 = mMagicWandPoint.x - mMagicWandBounds.origin.x;
		sY0 = mMagicWandPoint.y - mMagicWandBounds.origin.y;

		[self resetMagicWandParameters];
		switch (inType) {
			case GCAreaType:
			case GCHorizontalCurveType:
			case GCCurveType:
				if (![self preventBackgroundClickAtPoint:mMagicWandPoint withBounds:mMagicWandBounds])
					return;
				break;
		}

		[self setMagicWandInProgress:YES];
		[self setPreparingMagicWand:YES];
		[NSThread detachNewThreadSelector:@selector(magicWandThread:) toTarget:self withObject:nil];
		[self displayMagicWandView:0];
		[NSApp runModalForWindow:mMagicWandSheet];
		[mMagicWandSheet orderOut:nil];
		[self setMagicWandInProgress:NO];
	}
	
	[self finishNewElements];
}

-(IBAction)abortMagicWand:(id)inSender
{
	sKeepOnMagicWand = mKeepOnMagicWand = NO;
}

-(id)valueForUndefinedKey:(NSString *)inKey
{
	if ([inKey hasPrefix:@"symbol"]) {
		int x = [inKey characterAtIndex:6] - '1';
		int y = [inKey characterAtIndex:7] - '1';
		return [NSNumber numberWithBool:mSymbolDetect[x][y]];
	} else
		return [super valueForUndefinedKey:inKey];
}

-(void)setValue:(id)inValue forUndefinedKey:(NSString *)inKey
{
	if ([inKey hasPrefix:@"symbol"]) {
		int x = [inKey characterAtIndex:6] - '1';
		int y = [inKey characterAtIndex:7] - '1';
		mSymbolDetect[x][y] = [inValue boolValue];
		[self magicWandParameterDidChange];
	} else
		[super setValue:inValue forUndefinedKey:inKey];
}

@end
