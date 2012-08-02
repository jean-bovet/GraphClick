//
//  GCWindow.m
//  GraphClick
//
//  Created by Simon Bovet on 07.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GCWindow.h"


@implementation GCWindow

-(void)mouseMoved:(NSEvent *)inEvent
{
	[mView mouseMoved:inEvent];
}

-(void)flagsChanged:(NSEvent *)inEvent
{
	[mView flagsChanged:inEvent];
}

@end
