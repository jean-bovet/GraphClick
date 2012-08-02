//
//  GCPaletteView.m
//  GraphClick
//
//  Created by Simon Bovet on 17.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GCPaletteView.h"


@implementation GCPaletteView

-(void)mouseMoved:(NSEvent *)inEvent
{
	[mView mouseMoved:inEvent];
}

-(void)flagsChanged:(NSEvent *)inEvent
{
	[mView flagsChanged:inEvent];
}

@end
