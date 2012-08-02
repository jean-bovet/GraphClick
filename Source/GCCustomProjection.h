//
//  GCCustomProjection.h
//  GraphClick
//
//  Created by Simon Bovet on 24.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GCAdjustmentWizard;

@interface GCCustomProjection : NSObject <NSCoding> {
	float *mParameters;
}

-(BOOL)canShowFrame;
-(NSString *)abscissaVariable;
-(NSString *)abscissaName;
-(NSString *)ordinateVariable;
-(NSString *)ordinateName;

-(NSPoint)convertToCoordinate:(NSPoint)inPoint;
-(NSPoint)convertFromCoordinate:(NSPoint)inPoint;

-(NSString *)name;
-(NSString *)infoString;
-(NSImage *)icon;
-(int)numberOfParameters;
-(float *)parameters;
-(float)param:(int)inIndex;
-(void)setParam:(int)inIndex value:(float)inValue;
-(void)initializeParameters:(GCAdjustmentWizard *)inAdjustmentWizard;

@end

