//
//  GCGuideLine.h
//  GraphClick
//
//  Created by Simon Bovet on 16.11.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GCGuideLine : NSObject {
	float mPosition;
	BOOL mIsVertical;
}

-(id)initWithPosition:(float)inPosition isVertical:(BOOL)inIsVertical;
-(float)position;
-(void)setPosition:(float)inPosition;
-(BOOL)isVertical;

@end
