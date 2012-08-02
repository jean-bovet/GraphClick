//
//  GCHistogram.h
//  GraphClick
//
//  Created by Simon Bovet on 19.08.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GCHistogram : NSObject {
	unsigned mImageKind;
	float mBackgroundLightness;
	NSImage *mLastImage;
}

-(BOOL)isColor:(NSColor *)inColor backgroundOfImage:(NSImage *)inImage;
-(NSColor *)backgroundColorOfImage:(NSImage *)inImage;

@end
