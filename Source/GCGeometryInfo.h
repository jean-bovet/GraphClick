//
//  GCGeometryInfo.h
//  GraphClick
//
//  Created by Simon Bovet on 09.03.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GCGeometryInspector.h"

#define GCGeometryMinPixelError @"GCGeometryMinPixelError"
#define GCGeometryShowError @"GCGeometryShowError"
#define GCGeometryAngleMeasure @"angleMeasure"

@interface GCGeometryInfo : GCGeometryInspector {
	BOOL mAbortComputationThread;
	NSMutableDictionary *mDataToCompute;
	NSConditionLock *mPointsLock;
	float mMinPixelError;
	GCFrame *mFrame;
	
	NSDictionary *mComputedValues;
	BOOL mComputing;
	
	IBOutlet NSTableView *mTableView;
	IBOutlet NSArrayController *mArrayController;
}

+(id)sharedInspector;

@end

@interface GCGeometryInfo (Public)

-(IBAction)copy:(id)inSender;

@end

@interface GCGeometryInfo (Computation)

-(void)startComputationThread;
-(void)stopComputationThread;

-(void)recompute;

-(NSDictionary *)compute:(NSDictionary *)inData;

@end

@interface GCGeometryInfo (Measures)

-(BOOL)definesArea;
-(NSString *)lengthTitle;
-(id)length;
-(id)area;

@end

@interface GCGeometryPoint : NSObject {
	GCPoint *mPoint;
	float mDistance;
	float mShortestDistance;
	float mLongestDistance;
	float mAngle;
	float mMinAngle;
	float mMaxAngle;
}

-(GCPoint *)point;
-(void)setPoint:(GCPoint *)inPoint;
-(id)distance;
-(void)setDistance:(float)inDistance;
-(void)setMinDistance:(float)inDistance;
-(void)setMaxDistance:(float)inDistance;
-(void)setAngle:(float)inAngle;
-(void)setMinAngle:(float)inAngle;
-(void)setMaxAngle:(float)inAngle;
-(void)setSpeed:(float)inSpeed x:(float)inSpeedX y:(float)inSpeedY;
-(void)setMinSpeed:(float)inSpeed x:(float)inSpeedX y:(float)inSpeedY;
-(void)setMaxSpeed:(float)inSpeed x:(float)inSpeedX y:(float)inSpeedY;

@end
