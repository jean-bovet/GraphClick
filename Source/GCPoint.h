//
//  GCPoint.h
//  GraphClick
//
//  Created by Simon Bovet on 02.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GCSerie;

@interface GCPoint : NSObject {
	GCSerie *mSerie;
	NSPoint mPoint;
	float mXMinError;
	float mXMaxError;
	float mYMinError;
	float mYMaxError;
	float mTime;
	
	float mDistance;
	float mMinDistance;
	float mMaxDistance;
	float mAngle;
	float mMinAngle;
	float mMaxAngle;
	float mSpeed;
	float mMinSpeed;
	float mMaxSpeed;
	float mXSpeed;
	float mMinXSpeed;
	float mMaxXSpeed;
	float mYSpeed;
	float mMinYSpeed;
	float mMaxYSpeed;
	
	NSString *mLabel;
}

-(id)initWithPoint:(NSPoint)inPoint;

-(GCSerie *)serie;
-(void)setSerie:(GCSerie *)inSerie;

-(NSPoint)point;
-(void)setPoint:(NSPoint)inPoint;

@end

@interface GCPoint (Coordinates)

-(NSPoint)pointWithError:(NSPoint)inDelta;

-(float)xCoordinate;
-(float)yCoordinate;

-(NSPoint)coordinatePoint;

-(float)xMinError;
-(void)setXMinError:(float)inError;
-(float)xMaxError;
-(void)setXMaxError:(float)inError;
-(float)yMinError;
-(void)setYMinError:(float)inError;
-(float)yMaxError;
-(void)setYMaxError:(float)inError;

-(float)distance;
-(void)setDistance:(float)inDistance;
-(float)minDistance;
-(void)setMinDistance:(float)inMinDistance;
-(float)maxDistance;
-(void)setMaxDistance:(float)inMaxDistance;
-(float)angle;
-(void)setAngle:(float)inAngle;
-(float)minAngle;
-(void)setMinAngle:(float)inMinAngle;
-(float)maxAngle;
-(void)setMaxAngle:(float)inMaxAngle;
-(float)speed;
-(void)setSpeed:(float)inSpeed;
-(float)minSpeed;
-(void)setMinSpeed:(float)inMinSpeed;
-(float)maxSpeed;
-(void)setMaxSpeed:(float)inMaxSpeed;
-(float)xSpeed;
-(void)setXSpeed:(float)inSpeed;
-(float)minXSpeed;
-(void)setMinXSpeed:(float)inMinSpeed;
-(float)maxXSpeed;
-(void)setMaxXSpeed:(float)inMaxSpeed;
-(float)ySpeed;
-(void)setYSpeed:(float)inSpeed;
-(float)minYSpeed;
-(void)setMinYSpeed:(float)inMinSpeed;
-(float)maxYSpeed;
-(void)setMaxYSpeed:(float)inMaxSpeed;

-(float)distanceError;
-(float)angleError;
-(float)speedError;
-(float)xSpeedError;
-(float)ySpeedError;

@end

@interface GCPoint (Time)

+(void)setCurrentTime:(float)inTime;
-(float)time;
-(void)setTime:(float)inTime;

@end
