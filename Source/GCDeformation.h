//
//  GCDeformation.h
//  GraphClick
//
//  Created by Simon Bovet on 06.01.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GCFrame;

@interface GCDeformation : NSObject {
	GCFrame *mFrame;
	NSPoint mPosition;
	float mOffset;
}

+(id)deformationWithFrame:(GCFrame *)inFrame position:(NSPoint)inPosition offset:(float)inOffset;
-(id)initWithFrame:(GCFrame *)inFrame position:(NSPoint)inPosition offset:(float)inOffset;

-(NSPoint)position;
-(float)offset;

@end
