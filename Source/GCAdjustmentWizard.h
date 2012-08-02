//
//  GCAdjustmentWizard.h
//  GraphClick
//
//  Created by Simon Bovet on 24.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GCView, GCCustomProjection;

@interface GCAdjustmentWizard : NSWindowController {
	GCView *mView;
	GCCustomProjection *mCustomProjection;
	NSString *mCoordinatePrompt;
	int mState;
	
	NSMutableArray *mPositions;
	NSMutableArray *mCoordinates;
}

+(void)registerWizardClass;

+(NSArray *)availableAdjustmentWizardClassNames;
+(id)adjustmentWizard;
+(NSDictionary *)defaults;

+(Class)customProjectionClass;
-(GCCustomProjection *)customProjection;

-(void)beginAdjustmentInView:(GCView *)inView;
-(GCView *)view;
-(void)adjustmentShouldBegin:(BOOL)inSuccess;

-(NSString *)coordinatePrompt;
-(void)setCoordinatePrompt:(NSString *)inCoordinatePrompt;

-(BOOL)shouldPromptAbscissa;
-(BOOL)shouldPromptOrdinate;
-(BOOL)shouldPromptAbscissaScale;
-(BOOL)shouldPromptOrdinateScale;

-(int)coordinatePromptKind; // 0 = none, 1 = horizontal, 2 = vertical, 3 = cross;

-(id)keyForPromptedValue;
-(float)defaultAbscissaValue;
-(float)defaultOrdinateValue;

-(BOOL)didPromptCoordinates:(NSPoint)inCoordinates atPosition:(NSPoint)inPosition isValid:(BOOL *)outValid;
-(NSPoint)coord:(int)inIndex;
-(NSPoint)position:(int)inIndex;

-(BOOL)autoAdjustParameters;
-(BOOL)validateAutoAdjustment:(BOOL *)outFatal;

-(IBAction)confirm:(id)inSender;

@end

extern float rad2deg(float x);
extern float deg2rad(float x);