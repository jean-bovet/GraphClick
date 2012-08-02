//
//  GCAdjustmentWizard.m
//  GraphClick
//
//  Created by Simon Bovet on 24.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GCAdjustmentWizard.h"

#import "GCView.h"
#import "GCFrame.h"
#import "GCCustomProjection.h"
#import "GCMinimizer.h"

@interface GCView (GCAdjustmentWizard)

-(void)adjustmentShouldBegin:(BOOL)inSuccess;
-(void)saveCurrentFrame;

@end

@interface GCAdjustmentWizard (Private)

-(void)gotoNextState;
-(void)infoSheetDidEnd:(NSWindow *)inSheet returnCode:(int)inReturnCode contextInfo:(void *)inContextInfo;

@end

@implementation GCAdjustmentWizard

static NSMutableArray *sAdjustmentWizardClassNames = nil;

+(NSArray *)availableAdjustmentWizardClassNames
{
	return sAdjustmentWizardClassNames;
}

+(void)registerWizardClass
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (!sAdjustmentWizardClassNames)
		sAdjustmentWizardClassNames = [[NSMutableArray alloc] initWithCapacity:0];
	[sAdjustmentWizardClassNames addObject:NSStringFromClass([self class])];
	[pool release];
}

+(id)adjustmentWizard
{
	return [[[self alloc] init] autorelease];
}

+(NSDictionary *)defaults
{
	return nil;
}

-(void)dealloc
{
	[mView release];
	[mCustomProjection release];
	[mCoordinatePrompt release];
	[mPositions release];
	[mCoordinates release];
	[super dealloc];
}

+(Class)customProjectionClass
{
	return Nil;
}

-(GCCustomProjection *)customProjection
{
	if (!mCustomProjection)
		mCustomProjection = [[[[self class] customProjectionClass] alloc] init];
	return mCustomProjection;
}

-(void)displayInfo
{
	[self infoSheetDidEnd:nil returnCode:NSOKButton contextInfo:nil];
}

-(void)beginAdjustmentInView:(GCView *)inView displayInfo:(BOOL)inDisplayInfo
{
	[mView release];
	mView = [inView retain];
	mState = 1;
	[mView saveCurrentFrame];
	[[mView frameObject] setCustomProjection:[self customProjection]];
	[mView setNeedsDisplay:YES];
	if (inDisplayInfo)
		[self displayInfo];
	else
		[self infoSheetDidEnd:nil returnCode:NSOKButton contextInfo:nil];
}

-(void)beginAdjustmentInView:(GCView *)inView
{
	[self beginAdjustmentInView:inView displayInfo:YES];
}

-(void)beginReadjustmentInView:(GCView *)inView
{
	[self beginAdjustmentInView:inView displayInfo:NO];
}

-(GCView *)view
{
	return mView;
}

-(NSString *)prompt
{
	return @"?";
}

-(void)gotoNextState
{
	mState++;
	[self setCoordinatePrompt:[self prompt]];
}

-(void)infoSheetDidEnd:(NSWindow *)inSheet returnCode:(int)inReturnCode contextInfo:(void *)inContextInfo
{
	BOOL ok = inReturnCode == NSOKButton;
	if (ok)
		[self setCoordinatePrompt:[self prompt]];
	[self adjustmentShouldBegin:ok];
	[[mView window] makeKeyAndOrderFront:nil];
}

-(void)adjustmentShouldBegin:(BOOL)inSuccess
{
	[mView adjustmentShouldBegin:inSuccess];
}

-(NSString *)coordinatePrompt
{
	return mCoordinatePrompt;
}

-(void)setCoordinatePrompt:(NSString *)inCoordinatePrompt
{
	if (![mCoordinatePrompt isEqual:inCoordinatePrompt]) {
		[mView willChangeValueForKey:@"coordinatePrompt"];
		[mCoordinatePrompt release];
		mCoordinatePrompt = [inCoordinatePrompt retain];
		[mView didChangeValueForKey:@"coordinatePrompt"];
	}
}

-(BOOL)shouldPromptAbscissa
{
	return YES;
}

-(BOOL)shouldPromptOrdinate
{
	return YES;
}

-(BOOL)shouldPromptAbscissaScale
{
	return NO;
}

-(BOOL)shouldPromptOrdinateScale
{
	return NO;
}

-(int)coordinatePromptKind
{
	return 0;
}

-(int)adjustmentKind
{
	return -1;
}

-(id)keyForPromptedValue
{
	return [NSString stringWithFormat:@"%@ #%i (%i)", NSStringFromClass([self class]), mState, [self adjustmentKind]];
}

-(float)defaultAbscissaValue
{
	return 0.0;
}

-(float)defaultOrdinateValue
{
	return 0.0;
}

-(BOOL)checkAdjustment
{
	return YES;
}

-(BOOL)performAdjustment:(BOOL *)outValid
{
	return NO;
}

-(BOOL)didPromptCoordinates:(NSPoint)inCoordinates atPosition:(NSPoint)inPosition isValid:(BOOL *)outValid
{
	if (!mPositions) {
		mPositions = [[NSMutableArray alloc] initWithCapacity:0];
		mCoordinates = [[NSMutableArray alloc] initWithCapacity:0];
	}
	[mPositions addObject:[NSValue valueWithPoint:inPosition]];
	[mCoordinates addObject:[NSValue valueWithPoint:inCoordinates]];
	
	if (![self checkAdjustment]) {
		if (outValid)
			*outValid = NO;
		return NO;
	} else if ([self performAdjustment:outValid])
		return YES;
	else {
		[self gotoNextState];
		return NO;
	}
}

-(NSPoint)coord:(int)inIndex
{
	return [[mCoordinates objectAtIndex:inIndex] pointValue];
}

-(NSPoint)position:(int)inIndex
{
	return [[mPositions objectAtIndex:inIndex] pointValue];
}

-(BOOL)usePositionForAutoAdjustment:(int)inIndex
{
	return YES;
}

-(int)numberOfParametersForMinimizer:(GCMinimizer *)inMinizer
{
	return [[self customProjection] numberOfParameters];
}

-(float)minimizer:(GCMinimizer *)inMinizer valueOfParameterAtIndex:(int)inIndex
{
	return [[self customProjection] param:inIndex];
}

-(float)minimizer:(GCMinimizer *)inMinizer evaluationWithParameters:(float *)inParameters
{
	float dist = 0.0;
	int i, n;
	
	GCCustomProjection *projection = [self customProjection];
	n = [projection numberOfParameters];
	for (i = 0; i < n; i++)
		[projection setParam:i value:inParameters[i]];
	
	n = [mCoordinates count];
	for (i = 0; i < n; i++)
		if ([self usePositionForAutoAdjustment:i]) {
			NSPoint estimatedCoord = [projection convertToCoordinate:[self position:i]];
			NSPoint actualCoord = [self coord:i];
			float d = 0.0;
			if (!isnan(actualCoord.x))
				d = hypotf(d, estimatedCoord.x - actualCoord.x);
			if (!isnan(actualCoord.y))
				d = hypotf(d, estimatedCoord.y - actualCoord.y);
			dist += d;
		}
	
	return dist;
}

-(void)minimizer:(GCMinimizer *)inMinizer failedWithException:(NSException *)inException
{
	NSRunAlertPanel(NSLocalizedString(@"Auto Adjustment Failed Title", @""), NSLocalizedString(@"Auto Adjustment Failed Message", @""), nil, nil, nil);
	NSLog(@"autoAdjustError: %@", inException);
}

-(void)minimizer:(GCMinimizer *)inMinizer succeededWithParameters:(float *)inParameters minimum:(float)inMinimum numberOfIterations:(int)inIterations
{
	GCCustomProjection *projection = [self customProjection];
	int i, n = [projection numberOfParameters];
	for (i = 0; i < n; i++)
		[projection setParam:i value:inParameters[i]];
}

-(int)numberOfAutoAdjustmentPasses
{
	return 1;
}

-(void)setAutoAdjustmentPass:(int)inPass
{
}

-(BOOL)autoAdjustParameters
{
	[[self customProjection] initializeParameters:self];
	
	int p, pmax = [self numberOfAutoAdjustmentPasses];
	for (p = 0; p < pmax; p++) {
		[self setAutoAdjustmentPass:p];
		GCMinimizer *minimizer = [[[GCMinimizer alloc] init] autorelease];
		[minimizer setDataSource:self];
		if (![minimizer minimize])
			return NO;
	}
	
	return YES;
}
			
-(BOOL)validateAutoAdjustment:(BOOL *)outFatal
{
	GCCustomProjection *projection = [self customProjection];
	int i, n = [projection numberOfParameters];
	for (i = 0; i < n; i++)
		if (isnan([projection param:i]))
			goto fatal;
	
	float maxDist = 0.0;
	n = [mCoordinates count];
	for (i = 0; i < n; i++) {
		NSPoint coord = [self coord:i];
		if (!isnan(coord.x) && !isnan(coord.y)) {
			NSPoint position = [projection convertFromCoordinate:coord];
			if (isnan(position.x) || isnan(position.y))
				goto fatal;
			
			NSPoint actualPosition = [self position:i];
			float d = hypot(position.x - actualPosition.x, position.y - actualPosition.y);
			NSLog(@"d = %f (%@ vs. actual %@)", d, NSStringFromPoint(position), NSStringFromPoint(actualPosition));
			NSLog(@"in coord: (%@ vs. actual %@)", NSStringFromPoint([self coord:i]), NSStringFromPoint([projection convertToCoordinate:[self position:i]]));
			if (isnan(d))
				goto fatal;
			maxDist = MAX(d, maxDist);
		}
	}

	NSLog(@"maxDist = %f", maxDist);
	if (maxDist > 2.0)
		return NO;
	return YES;

fatal:
	if (outFatal)
		*outFatal = YES;
	return NO;
}

-(IBAction)confirm:(id)inSender
{
	[[self window] orderOut:nil];
	[NSApp endSheet:[self window] returnCode:[inSender tag]];
}

@end

float rad2deg(float x)
{
	const float k = 180.0 / pi;
	return x * k;
}

float deg2rad(float x)
{
	const float k = pi / 180.0;
	return x * k;
}