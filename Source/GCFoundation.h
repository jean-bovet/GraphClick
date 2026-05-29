//
//  GCFoundation.h
//  GraphClick
//
//  Created by Simon Bovet on 07.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSImage (GCFoundation)

-(void)drawInRect:(NSRect)inRect;
-(void)dissolveToRect:(NSRect)inRect fraction:(float)inFraction;
-(void)dissolveToRect:(NSRect)inRect fraction:(float)inFraction clipRect:(NSRect)inClipRect;
-(void)dissolveToRect:(NSRect)inRect fraction:(float)inFraction flipped:(BOOL)inFlipped clipRect:(NSRect)inClipRect;
-(NSSize)pixelSize;

@end

@interface NSColor (GCFoundation)

-(float)distanceToColor:(NSColor *)inColor;

@end

@interface NSCursor (GCFoundation)

+(NSCursor *)emptyCrosshairCursor;
+(NSCursor *)diagonalResizeCursor;
+(NSCursor *)backDiagonalResizeCursor;
+(NSCursor *)noCursor;

@end

@interface NSCoder (GCFoundation)

// Decodes a geometry value written either as an NSValue object (current keyed
// format) or as a raw struct (legacy NSArchiver documents from GraphClick 3.0.x
// and earlier). The keyed unarchiver reports allowsKeyedCoding == YES, the
// legacy NSUnarchiver reports NO, which is how the two formats are told apart.
-(NSPoint)gcDecodePoint;
-(NSRect)gcDecodeRect;

@end

@interface NSData (GCFoundation)

// Unarchives a root object encoded with either NSKeyedArchiver (the current
// format) or the legacy NSArchiver "typedstream" format used by GraphClick
// 3.0.x and earlier. Returns nil if neither decoder can read the data.
-(id)gcUnarchivedRootObject;

@end

@interface NSDictionary (GCFoundation)

-(BOOL)boolForKey:(id)inKey;
-(int)intForKey:(id)inKey;
-(float)floatForKey:(id)inKey;

@end

@interface NSMutableDictionary (GCFoundation)

-(void)setBool:(BOOL)inValue forKey:(id)inKey;
-(void)setInt:(int)inValue forKey:(id)inKey;
-(void)setFloat:(float)inValue forKey:(id)inKey;

@end

@interface NSMutableAttributedString (GCFoundation)

-(void)appendString:(NSString *)inString attributes:(NSDictionary *)inAttributes;
-(void)insertString:(NSString *)inString attributes:(NSDictionary *)inAttributes atIndex:(unsigned)inIndex;

@end

@interface NSString (GCFoundation)

-(NSString *)stringByIncreasingIndexBy:(int)inDelta;

@end

@interface NSToolbar (GCFoundation)

-(NSToolbarItem *)itemWithIdentifier:(NSString *)inIdentifier;

@end

@interface NSAffineTransform (GCFoundation)

-(NSRect)transformRect:(NSRect)inRect;

@end

@interface GCZoomFactorTransformer : NSValueTransformer 

@end

@interface GCAngleTransformer : NSValueTransformer 

@end

@interface GCPercentTransformer : NSValueTransformer 

@end

@interface GCNumberTransformer : NSValueTransformer 

@end

@interface GCTimeTransformer : GCNumberTransformer

@end

@interface GCEqualityTransformer : NSValueTransformer

@end

@interface GCValidMarkerTransformer : NSValueTransformer

@end

@interface GCSeparatorTransformer : NSValueTransformer 

@end

@interface GCEnabledTextColorTransformer : NSValueTransformer 

@end

@interface NSBezierPath (RoundRect)

+(NSBezierPath *)bezierPathWithRoundRectInRect:(NSRect)aRect radius:(float)radius;

@end

bool isdefined(float x);

@interface NSArray (IndexSetAddition)

-(NSArray *)subarrayWithIndexes:(NSIndexSet *)inIndexes;

@end

@interface NSAttributedString (GCFoundation)

-(float)heightForWidth:(float)inWidth;

@end

@interface GCDefaultsObserver : NSObject {
	NSMutableSet *mObservedValues;
}

+(GCDefaultsObserver *)sharedObserver;
-(void)addObserver:(id)inObserver forValues:(NSString *)inFirstValue, ...;

@end

@interface NSApplication (GCFoundation)

-(unsigned long)systemVersion;

@end

@interface NSWindow (GCFoundation)

-(void)setContentSize:(NSSize)inSize animate:(BOOL)inAnimate;
-(void)setContentHeight:(float)inHeight animate:(BOOL)inAnimate;

@end
