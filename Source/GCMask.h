//
//  GCMask.h
//  GraphClick
//
//  Created by Simon Bovet on 06.01.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define GCMaskColor @"GCMaskColor"

@interface GCMask : NSObject {
	NSRect mBounds;
	NSRect mContentBounds;
	NSImage *mImage;
	
	int mCurrentPaintKind;
}

-(id)initWithBounds:(NSRect)inBounds;

-(NSRect)bounds;
-(NSRect)contentBounds;
-(BOOL)hasContent;
-(NSImage *)image;

-(void)lockFocus;
-(float)valueAt:(NSPoint)inPoint;
-(void)unlockFocus;

+(NSColor *)color;
-(NSColor *)color;

@end

@interface NSObject (Paintable)

-(id)paintTarget;
-(NSAffineTransform *)paintTransform;

-(NSRect)brushAtPoint:(NSPoint)inPoint size:(NSSize)inSize kind:(int)inKind;
-(NSRect)brushFromPoint:(NSPoint)inSource toPoint:(NSPoint)inDestination size:(NSSize)inSize kind:(int)inKind;
-(void)paintPath:(NSBezierPath *)inBezierPath;

@end
