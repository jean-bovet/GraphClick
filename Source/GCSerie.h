//
//  GCSerie.h
//  GraphClick
//
//  Created by Simon Bovet on 02.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GCPoint.h"

#define GCSerieDidChangeVisibleStateNotification @"GCSerieDidChangeVisibleStateNotification"
#define GCSerieDidChangeFrameLimitIndexNotification @"GCSerieDidChangeFrameLimitIndexNotification"

#define GCColumnSeparator @"columnSeparator"
#define GCLineSeparator @"lineSeparator"

@class GCFrame;

@interface GCSerie : NSObject {
	GCFrame *mFrame;
	NSMutableArray *mPoints;
	NSString *mName;
	BOOL mVisible;
	NSColor *mColor;
	int mMarker;
	float mMarkerSize;
	BOOL mConnected;
	BOOL mDefinesArea;
	float mAreaFill;

	BOOL mValidAreaParameters;	
	float mPerimeter;
	float mArea;
	
	int mFrameLimitIndex;
}

-(GCFrame *)frame;
-(void)setFrame:(GCFrame *)inFrame;

@end

@interface GCSerie (Points)

-(NSArray *)points;
-(void)insertPoint:(NSPoint)inPoint atIndex:(unsigned)inIndex;
-(void)sortCoordinate:(int)inCoordinate order:(int)inOrder;

@end

@interface GCSerie (Interface)

-(NSString *)name;
-(BOOL)visible;
-(void)setVisible:(BOOL)inVisible;
-(NSColor *)color;
-(int)marker;
-(float)markerSize;
-(BOOL)connected;
-(BOOL)definesArea;
-(float)areaFill;

-(NSString *)stringForValuesWithSettings:(id)inSettings;

@end

@interface GCSerie (Area)

-(float)perimeter;
-(void)setPerimeter:(float)inPerimeter;
-(float)area;
-(void)setArea:(float)inArea;

-(void)invalidateAreaParameters;
-(void)computeAreaParameters;

@end

@interface GCSerie (FrameLimits)

-(int)frameLimitIndex;
-(void)setFrameLimitIndex:(int)inIndex;
-(void)useFrameLimits;

@end

@interface NSArray (GCSerie)

-(NSString *)stringForValuesWithSettings:(id)inSettings;

@end

@interface NSString (GCSerie)

+(NSString *)columnSeparator;
+(NSString *)lineSeparator;

@end
