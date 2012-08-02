//
//  GCFrame.h
//  GraphClick
//
//  Created by Simon Bovet on 03.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GCSerie.h"
#import "GCGuideLine.h"
#import "GCDeformation.h"
#import "GCMask.h"

#define GCFrameAppearanceDidChangeNotification @"GCFrameAppearanceDidChangeNotification"
#define GCFrameWillChangeNotification @"GCFrameWillChangeNotification"
#define GCFrameDidChangeNotification @"GCFrameDidChangeNotification"

@class GCCustomProjection;

typedef enum _GCScale {
	GCLinearScale,
	GCLogScale,
	GCInverseScale
} GCScale;

@interface GCFrame : NSObject {
	NSMutableArray *mSeries;
	NSMutableArray *mGuideLines;
	NSMutableArray *mCorners;
	NSMutableArray *mDeformations;
	NSIndexSet *mSelectedDeformations;
	GCMask *mMask;
	NSPoint mMin;
	NSPoint mMax;
	GCScale mXScale;
	GCScale mYScale;
	NSPoint mImageOrigin;
	BOOL mUsePixelCoordinates;
	
	NSMutableArray *mFrameLimits;
	int mCurrentFrameLimitIndex;
	
	int mEditCount;
	
	bool mFrozen;
	NSArray *mFrozenCorners;
	NSPoint mFrozenMin;
	NSPoint mFrozenMax;
	
	GCCustomProjection *mCustomProjection;
}

-(void)didChange;
-(void)appearanceDidChange;

-(NSPoint)scale:(NSPoint)inPoint;
-(NSPoint)unscale:(NSPoint)inPoint;

-(NSPoint)convertToCoordinate:(NSPoint)inPoint;
-(NSPoint)convertFromCoordinate:(NSPoint)inPoint;

-(BOOL)canShowFrame;
-(GCCustomProjection *)customProjection;
-(void)setCustomProjection:(GCCustomProjection *)inCustomProjection;

@end

@interface GCFrame (Corners)

-(void)setFrameRect:(NSRect)inRect;

-(NSPoint)cornerPoint:(int)inIndex;
-(void)setCorner:(int)inIndex point:(NSPoint)inPoint;

-(float)xMin;
-(float)xMax;
-(float)yMin;
-(float)yMax;
-(void)setXMin:(float)inValue;
-(void)setXMax:(float)inValue;
-(void)setYMin:(float)inValue;
-(void)setYMax:(float)inValue;

-(GCScale)xScale;
-(GCScale)yScale;

-(BOOL)usePixelCoordinates;
-(void)setUsePixelCoordinates:(BOOL)inFlag;

@end

@interface GCFrame (Series)

-(NSArray *)series;

@end

@interface GCFrame (Editing)

-(void)beginEditing;
-(void)beginEditingImageWillChange:(BOOL)inImageWillChange;
-(void)endEditing;

@end

@interface GCFrame (Deformation)

-(unsigned)addDeformationAtPoint:(NSPoint)inPoint withOffset:(float)inOffset;
-(void)removeDeformation:(unsigned)inIndex;
-(void)removeDeformations;
-(void)removeSelectedDeformations;

-(unsigned)numberOfDeformations;
-(float)offsetOfDeformationAtIndex:(unsigned)inIndex;
-(NSPoint)positionOfDeformationAtIndex:(unsigned)inIndex leftSide:(BOOL)inLeft;
-(NSPoint)positionOfDeformation:(id)inDeformation leftSide:(BOOL)inLeft;

-(NSPoint)deform:(NSPoint)inPoint;
-(NSPoint)undeform:(NSPoint)inPoint;

-(void)selectDeformationAtIndex:(unsigned)inIndex;
-(BOOL)isDeformationSelectedAtIndex:(unsigned)inIndex;

@end

@interface GCFrame (Mask)

-(GCMask *)mask;
-(GCMask *)maskWithBounds:(NSRect)inBounds;
-(void)setMask:(GCMask *)inMask;

@end

@interface GCFrame (Image)

-(void)setImageOrigin:(NSPoint)inOrigin;

@end

@interface GCFrame (GuideLines)

-(NSArray *)guideLines;
-(void)addGuideLine:(GCGuideLine *)inGuideLine;
-(void)removeGuideLine:(GCGuideLine *)inGuideLine;
-(void)removeGuideLines;

@end

@interface GCFrame (FrameLimits)

-(void)saveCurrentFrameLimits;
-(void)setCurrentFrameLimitIndex:(int)inIndex;

@end

@interface GCFrame (Variables)

-(NSString *)abscissaVariable;
-(NSString *)abscissaName;
-(NSString *)ordinateVariable;
-(NSString *)ordinateName;

@end
