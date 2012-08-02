//
//  GCMapAdjustmentWizard.m
//  GraphClick
//
//  Created by Simon Bovet on 25.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GCMapAdjustmentWizard.h"

#import "mrqmin.h"

@implementation GCMapAdjustmentWizard

-(NSString *)windowNibName
{
	return NSStringFromClass([self class]);
}

-(id)init
{
	if (self = [super initWithWindowNibName:[self windowNibName]]) {
	}
	return self;
}

-(void)displayInfo
{
	[NSApp beginSheet:[self window] modalForWindow:[mView window] modalDelegate:self didEndSelector:@selector(infoSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(int)minNumberOfStatesBeforeAdjustment
{
	return 2;
}

-(NSString *)prompt
{
	return mState == 1 ? NSLocalizedString(@"Default Map Adjustment Initial Prompt", @"") : NSLocalizedString(@"Default Map Adjustment Prompt", @"");
}

-(BOOL)performAdjustment:(BOOL *)outValid
{
	if (mState < [self minNumberOfStatesBeforeAdjustment])
		return NO;
	
	if (![self autoAdjustParameters]) {
		if (outValid)
			*outValid = NO;
		return YES;
	}
	
	BOOL fatal = NO;
	if (![self validateAutoAdjustment:&fatal])
		if (fatal) {
			NSRunAlertPanel(NSLocalizedString(@"Auto Adjustment Failed Title", @""), NSLocalizedString(@"Auto Adjustment Failed Message", @""), nil, nil, nil);
			if (outValid)
				*outValid = NO;
			return YES;
		} else  {
			int response = NSRunAlertPanel(NSLocalizedString(@"Poor Adjustment Found Title", @""),
											NSLocalizedString(@"Poor Adjustment Found Message", @""),
											NSLocalizedString(@"Add Point", @""),
											NSLocalizedString(@"Cancel", @""),
											NSLocalizedString(@"Ignore", @""));
			[[mView window] makeKeyAndOrderFront:nil];
			switch (response) {
				case NSAlertDefaultReturn:
					return NO;
				case NSAlertAlternateReturn:
					if (outValid)
						*outValid = NO;
					return YES;
				case NSAlertOtherReturn: 
					return YES;
			}
		}
	
	return YES;
}

@end

@implementation GCMapProjection

-(id)initWithCoder:(NSCoder *)inCoder
{
	if (self = [super initWithCoder:inCoder]) {
		[inCoder decodeValueOfObjCType:@encode(float) at:&mViewSize.width];
		[inCoder decodeValueOfObjCType:@encode(float) at:&mViewSize.height];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)inCoder
{
	[super encodeWithCoder:inCoder];
	[inCoder encodeValueOfObjCType:@encode(float) at:&mViewSize.width];
	[inCoder encodeValueOfObjCType:@encode(float) at:&mViewSize.height];
}

-(NSString *)abscissaVariable
{
	return [NSString stringWithFormat:@"%C", 0x03BB]; // lambda
}

-(NSString *)abscissaName
{
	return @"Longitude";
}

-(NSString *)ordinateVariable
{
	return [NSString stringWithFormat:@"%C", 0x03D5]; // phi
}

-(NSString *)ordinateName
{
	return @"Latitude";
}

-(int)numberOfParameters
{
	return 4;
}

-(void)initializeParameters:(GCAdjustmentWizard *)inAdjustmentWizard
{
	[super initializeParameters:inAdjustmentWizard];
	mViewSize = [[inAdjustmentWizard view] bounds].size;
	[self setParam:0 value:0.5];
	[self setParam:1 value:2.0];
	[self setParam:2 value:0.5];
	[self setParam:3 value:2.0];
}

-(NSPoint)convertToCoordinate:(NSPoint)inPoint
{
	float x = (inPoint.x / mViewSize.width - [self param:0]) * [self param:1];
	float y = (inPoint.y / mViewSize.height - [self param:2]) * [self param:3];
	return NSMakePoint(x, y);
}

-(NSPoint)convertFromCoordinate:(NSPoint)inPoint
{
	float x = (inPoint.x / [self param:1] + [self param:0]) * mViewSize.width;
	float y = (inPoint.y / [self param:3] + [self param:2]) * mViewSize.height;
	return NSMakePoint(x, y);
}

@end

@implementation GCGenericMapProjectionWizard

+(void)load
{
	[self registerWizardClass];
}

+(Class)customProjectionClass
{
	return [GCGenericMapProjection class];
}

-(NSString *)projectionName
{
	return [[self customProjection] name];
}

-(NSString *)projectionInfoString
{
	return [[self customProjection] infoString];
}

-(NSData *)projectionIcon
{
	return [[[self customProjection] icon] TIFFRepresentation];
}

-(NSString *)windowNibName
{
	return @"GCGenericMapProjectionWizard";
}

-(int)minNumberOfStatesBeforeAdjustment
{
	return 2;
}

@end

@implementation GCGenericMapProjection

-(NSString *)name
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

-(NSImage *)icon
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

-(void)initializeParameters:(GCAdjustmentWizard *)inAdjustmentWizard
{
	[super initializeParameters:inAdjustmentWizard];
	[self setParam:1 value:pi];
	[self setParam:3 value:pi];
}

-(NSPoint)convertToCoordinate:(NSPoint)inPoint
{
	return [super convertToCoordinate:inPoint];
}

-(NSPoint)convertFromCoordinate:(NSPoint)inPoint
{
	return [super convertFromCoordinate:inPoint];
}

@end

@implementation GCMercatorProjectionWizard

#define GCMercatorAdjustmentKind @"GCMercatorAdjustmentKind"
#define GCMercatorAdjustmentNumberOfPoints @"GCMercatorAdjustmentNumberOfPoints"

+(NSDictionary *)defaults
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithInt:2], GCMercatorAdjustmentNumberOfPoints,
										[NSNumber numberWithInt:0], GCMercatorAdjustmentKind,
										nil];
}

+(void)load
{
	[self registerWizardClass];
}

+(Class)customProjectionClass
{
	return [GCMercatorProjection class];
}

-(int)adjustmentKind
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:GCMercatorAdjustmentKind];
}

-(int)adjustmentNumberOfPoints
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:GCMercatorAdjustmentNumberOfPoints];
}

-(int)minNumberOfStatesBeforeAdjustment
{
	return ([self adjustmentKind] == 0 ? 2 : 1) * [self adjustmentNumberOfPoints];
}

-(BOOL)shouldPromptAbscissa
{
	return [self adjustmentKind] == 0 ? mState <= 2 || mState > 4: YES;
}

-(BOOL)shouldPromptOrdinate
{
	return [self adjustmentKind] == 0 ? mState > 2 || mState > 4 : YES;
}

-(int)coordinatePromptKind
{
	if ([self adjustmentKind] == 0)
		if (mState <= 2)
			return 1;
		else if (mState <= 4)
			return 2;
	return 0;
}

-(NSString *)prompt
{
	if ([self adjustmentKind] == 0)
		switch (mState) {
			case 1:
				return NSLocalizedString(@"Default Map Adjustment Initial Prompt (Abscissa)", @"");
			case 2:
				return NSLocalizedString(@"Default Map Adjustment Prompt (Abscissa)", @"");
			case 3:
				return NSLocalizedString(@"Default Map Adjustment Initial Prompt (Ordinate)", @"");
			case 4:
				return NSLocalizedString(@"Default Map Adjustment Prompt (Ordinate)", @"");
		}
	return [super prompt];
}

-(int)numberOfAutoAdjustmentPasses
{
	return 2;
}

static int sMercatorApproximation = 0;

-(void)setAutoAdjustmentPass:(int)inPass
{
	sMercatorApproximation = [self numberOfAutoAdjustmentPasses] - 1 - inPass;
}

-(BOOL)performAdjustment:(BOOL *)outValid
{
	if (mState < [self minNumberOfStatesBeforeAdjustment])
		return NO;
		
	if ([self adjustmentKind] == 0 && !mCollapsedCoordinates) {
		NSPoint coord[2], pos[2];
		pos[0].x = [self position:0].x;
		pos[1].x = [self position:1].x;
		pos[0].y = [self position:2].y;
		pos[1].y = [self position:3].y;
		coord[0].x = [self coord:0].x;
		coord[1].x = [self coord:1].x;
		coord[0].y = [self coord:2].y;
		coord[1].y = [self coord:3].y;
		[mPositions setArray:[NSArray arrayWithObjects:[NSValue valueWithPoint:pos[0]], [NSValue valueWithPoint:pos[1]], nil]];
		[mCoordinates setArray:[NSArray arrayWithObjects:[NSValue valueWithPoint:coord[0]], [NSValue valueWithPoint:coord[1]], nil]];
		mCollapsedCoordinates = YES;
	}
	return [super performAdjustment:outValid];
}

@end

@implementation GCMercatorProjection

-(NSString *)name
{
	return NSLocalizedString(@"Mercator Projection Name", @"");
}

-(NSImage *)icon
{
	return [NSImage imageNamed:@"Mercator"];
}

-(void)initializeParameters:(GCAdjustmentWizard *)inAdjustmentWizard
{
	[super initializeParameters:inAdjustmentWizard];
	NSRect bounds = [[inAdjustmentWizard view] bounds];
	[self setParam:1 value:pi];
	[self setParam:3 value:4.8];
}

-(NSPoint)convertToCoordinate:(NSPoint)inPoint
{
	inPoint = [super convertToCoordinate:inPoint];
	float x = inPoint.x;
	float y = inPoint.y;
	float lambda = x;
	float phi; // = atan(sinh(y))
	switch (sMercatorApproximation) {
		case 0:
			phi = atan(sinh(y));
			break;
		case 1:
			phi = asinh(y);
			break;
	}
	return NSMakePoint(rad2deg(lambda), rad2deg(phi));
}

-(NSPoint)convertFromCoordinate:(NSPoint)inPoint
{
	float lambda = deg2rad(inPoint.x);
	float phi = deg2rad(inPoint.y);
	float x = lambda;
	float y = atanh(sin(phi));
	return [super convertFromCoordinate:NSMakePoint(x, y)];
}

@end

@implementation GCObliqueMercatorProjectionWizard

+(void)load
{
	[self registerWizardClass];
}

+(Class)customProjectionClass
{
	return [GCObliqueMercatorProjection class];
}

-(int)minNumberOfStatesBeforeAdjustment
{
	return 4;
}

@end

@implementation GCObliqueMercatorProjection

-(int)numberOfParameters
{
	return 8;
}

-(NSString *)name
{
	return NSLocalizedString(@"Oblique Mercator Projection Name", @"");
}

-(NSImage *)icon
{
	return [NSImage imageNamed:@"ObliqueMercator"];
}

-(void)initializeParameters:(GCAdjustmentWizard *)inAdjustmentWizard
{
	[super initializeParameters:inAdjustmentWizard];
	[self setParam:1 value:pi];
	[self setParam:3 value:pi];
	[self setParam:4 value:0.5 * pi];
	[self setParam:5 value:0.5 * pi];
	[self setParam:6 value:0.5 * pi];
	[self setParam:7 value:0.5 * pi];
}

-(NSPoint)convertToCoordinate:(NSPoint)inPoint
{
	inPoint = [super convertToCoordinate:inPoint];
	float x = inPoint.x;
	float y = inPoint.y;
	float lambda_1 = [self param:4];
	float lambda_2 = [self param:5];
	float phi_1 = [self param:6];
	float phi_2 = [self param:7];
	float lambda_p = atan2((cos(phi_1) * sin(phi_2) * cos(lambda_1) - sin(phi_1) * cos(phi_2) * cos(lambda_2)),
							(sin(phi_1) * cos(phi_2) * sin(lambda_2) - cos(phi_1) * sin(phi_2) * sin(lambda_1)));
	float phi_p = -atan2(cos(lambda_p - lambda_1), tan(phi_1));
	lambda_p = phi_p = 0.1;
	float lambda = atan2((sin(phi_p) * sin(x) - cos(phi_p) * sinh(y)), cos(x));
	float phi = asin(sin(phi_p) * tanh(y) + (cos(phi_p) * sin(x) / cosh(y)));
	return NSMakePoint(rad2deg(lambda), rad2deg(phi));
}

-(NSPoint)convertFromCoordinate:(NSPoint)inPoint
{
	float lambda = deg2rad(inPoint.x);
	float phi = deg2rad(inPoint.y);
	float lambda_1 = [self param:4];
	float lambda_2 = [self param:5];
	float phi_1 = [self param:6];
	float phi_2 = [self param:7];
	float lambda_p = atan2((cos(phi_1) * sin(phi_2) * cos(lambda_1) - sin(phi_1) * cos(phi_2) * cos(lambda_2)),
							(sin(phi_1) * cos(phi_2) * sin(lambda_2) - cos(phi_1) * sin(phi_2) * sin(lambda_1)));
	float phi_p = -atan2(cos(lambda_p - lambda_1), tan(phi_1));
	lambda_p = phi_p = 0.1;
	float A = sin(phi_p) * sin(phi) - cos(phi_p) * cos(phi) * sin(lambda);
	float x = atan2((tan(phi) * cos(phi_p) + sin(phi_p) * sin(lambda)), cos(lambda));
	float y = atanh(A);
	return [super convertFromCoordinate:NSMakePoint(x, y)];
}

@end

@implementation GCTransverseMercatorProjectionWizard

+(void)load
{
	[self registerWizardClass];
}

+(Class)customProjectionClass
{
	return [GCTransverseMercatorProjection class];
}

-(int)minNumberOfStatesBeforeAdjustment
{
	return 3;
}

-(BOOL)shouldPromptAbscissa
{
	return mState != 2;
}

-(BOOL)shouldPromptOrdinate
{
	return mState != 1;
}

-(int)coordinatePromptKind
{
	if (mState == 1)
		return 1;
	else if (mState == 2)
		return 2;
	else
		return 0;
}

-(NSString *)prompt
{
	switch (mState) {
		case 1:
			return NSLocalizedString(@"Select the tangent meridian", @"");
		case 2:
			return NSLocalizedString(@"Select the 'equator'", @"");
	}
	return [super prompt];
}

@end

@implementation GCTransverseMercatorProjection

-(id)initWithCoder:(NSCoder *)inCoder
{
	if (self = [super initWithCoder:inCoder]) {
		[inCoder decodeValueOfObjCType:@encode(float) at:&x0];
		[inCoder decodeValueOfObjCType:@encode(float) at:&lambda0];
		[inCoder decodeValueOfObjCType:@encode(float) at:&y0];
		[inCoder decodeValueOfObjCType:@encode(float) at:&phi0];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)inCoder
{
	[super encodeWithCoder:inCoder];
	[inCoder encodeValueOfObjCType:@encode(float) at:&x0];
	[inCoder encodeValueOfObjCType:@encode(float) at:&lambda0];
	[inCoder encodeValueOfObjCType:@encode(float) at:&y0];
	[inCoder encodeValueOfObjCType:@encode(float) at:&phi0];
}

-(int)numberOfParameters
{
	return 2;
}

-(NSString *)name
{
	return NSLocalizedString(@"Transverse Mercator Projection Name", @"");
}

-(NSImage *)icon
{
	return [NSImage imageNamed:@"TransverseMercator"];
}

-(void)initializeParameters:(GCAdjustmentWizard *)inAdjustmentWizard
{
	mViewSize = [[inAdjustmentWizard view] bounds].size;
	x0 = [inAdjustmentWizard position:0].x;
	lambda0 = deg2rad([inAdjustmentWizard coord:0].x);
	y0 = [inAdjustmentWizard position:1].y;
	phi0 = deg2rad([inAdjustmentWizard coord:1].y);
	[self setParam:0 value:deg2rad(30.0)];
	[self setParam:1 value:deg2rad(90.0)];
}

-(NSPoint)convertToCoordinate:(NSPoint)inPoint
{
	float x = (inPoint.x - x0) / mViewSize.width * [self param:0];
	float y = (inPoint.y - y0) / mViewSize.height * [self param:1];
	float D = y + phi0;
	float lambda = lambda0 + atan2(sinh(x), cos(D));
	float phi = asin(sin(D) / cosh(x));
	return NSMakePoint(rad2deg(lambda), rad2deg(phi));
}

-(NSPoint)convertFromCoordinate:(NSPoint)inPoint
{
	float lambda = deg2rad(inPoint.x);
	float phi = deg2rad(inPoint.y);
	float x = atanh(cos(phi) * sin(lambda - lambda0)) - phi0;
	float y = atan2(tan(phi), cos(lambda - lambda0));
	x = x / [self param:0] * mViewSize.width + x0;
	y = y / [self param:1] * mViewSize.height + y0;
	return NSMakePoint(x, y);
}

@end

@implementation GCGnomonicProjectionWizard

+(void)load
{
	[self registerWizardClass];
}

+(Class)customProjectionClass
{
	return [GCGnomonicProjection class];
}

-(int)minNumberOfStatesBeforeAdjustment
{
	return 3;
}

-(NSString *)prompt
{
	switch (mState) {
		case 1:
			return NSLocalizedString(@"Select the projection center (can be approx.)", @"");
		case 2:
			return NSLocalizedString(@"Default Map Adjustment Initial Prompt", @"");
	}
	return NSLocalizedString(@"Default Map Adjustment Prompt", @"");
}

-(BOOL)usePositionForAutoAdjustment:(int)inIndex
{
	return inIndex >= 1;
}

-(int)numberOfAutoAdjustmentPasses
{
	return 2;
}

static int sGnomonicApproximation = 0;

-(void)setAutoAdjustmentPass:(int)inPass
{
	sGnomonicApproximation = [self numberOfAutoAdjustmentPasses] - 1 - inPass;
}

@end

@implementation GCGnomonicProjection

-(id)initWithCoder:(NSCoder *)inCoder
{
	if (self = [super initWithCoder:inCoder]) {
		[inCoder decodeValueOfObjCType:@encode(float) at:&x0];
		[inCoder decodeValueOfObjCType:@encode(float) at:&y0];
		[inCoder decodeValueOfObjCType:@encode(float) at:&lambda0];
		[inCoder decodeValueOfObjCType:@encode(float) at:&phi1];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)inCoder
{
	[super encodeWithCoder:inCoder];
	[inCoder encodeValueOfObjCType:@encode(float) at:&x0];
	[inCoder encodeValueOfObjCType:@encode(float) at:&y0];
	[inCoder encodeValueOfObjCType:@encode(float) at:&lambda0];
	[inCoder encodeValueOfObjCType:@encode(float) at:&phi1];
}

-(int)numberOfParameters
{
	return 3;
}

-(NSString *)name
{
	return NSLocalizedString(@"Gnomonic Projection Name", @"");
}

-(NSString *)infoString
{
	return NSLocalizedString(@"Gnomonic Projection Info String", @"");
}

-(NSImage *)icon
{
	return [NSImage imageNamed:@"GnomonicProjection"];
}

-(void)initializeParameters:(GCAdjustmentWizard *)inAdjustmentWizard
{
	mViewSize = [[inAdjustmentWizard view] bounds].size;
	x0 = [inAdjustmentWizard position:0].x;
	y0 = [inAdjustmentWizard position:0].y;
	lambda0 = deg2rad([inAdjustmentWizard coord:0].x);
	phi1 = deg2rad([inAdjustmentWizard coord:0].y);
	[self setParam:0 value:1.0 / MAX(mViewSize.width, mViewSize.height)];
	[self setParam:1 value:0.0];
	[self setParam:2 value:0.0];
}

-(NSPoint)convertToCoordinate:(NSPoint)inPoint
{
	float x = inPoint.x;
	float y = inPoint.y;
	if (sGnomonicApproximation == 0) {
		x -= [self param:1];
		y -= [self param:2];
	}
	x = (x - x0) * [self param:0];
	y = (y - y0) * [self param:0];
	float rho = hypot(x, y);
	if (rho == 0)
		return NSMakePoint(rad2deg(lambda0), rad2deg(phi1));
	float c = atan(rho);
	float phi = asin(cos(c) * sin(phi1) + (y * sin(c) * cos(phi1)) / rho);
	float lambda = lambda0 + atan2(x * sin(c), rho * cos(phi1) * cos(c) - y * sin(phi1) * sin(c));
	return NSMakePoint(rad2deg(lambda), rad2deg(phi));
}

-(NSPoint)convertFromCoordinate:(NSPoint)inPoint
{
	float lambda = deg2rad(inPoint.x);
	float phi = deg2rad(inPoint.y);
	float cosc = sin(phi1) * sin(phi) + cos(phi1) * cos(phi) * cos(lambda - lambda0);
	float x = cos(phi) * sin(lambda - lambda0) / cosc;
	float y = (cos(phi1) * sin(phi) - sin(phi1) * cos(phi) * cos(lambda - lambda0)) / cosc;
	return NSMakePoint(x / [self param:0] + x0 + [self param:1], y / [self param:0] + y0 + [self param:2]);
}

@end
