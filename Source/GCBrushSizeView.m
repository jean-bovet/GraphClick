//
//  GCBrushSizeView.m
//  GraphClick
//
//  Created by Simon Bovet on 17.03.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GCBrushSizeView.h"


@implementation GCBrushSizeView

-(void)drawRect:(NSRect)inRect
{
	NSRect rect = [self bounds];
	rect.size.width = rect.size.height;
	float inset = (rect.size.width - 4) / 2;
	[[NSColor grayColor] set];
	[[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(rect, inset, inset)] stroke];
	rect.origin.x = NSMaxX([self bounds]) - rect.size.width;
	inset = 1;
	[[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(rect, inset, inset)] stroke];
	
	NSImage *image = [NSImage imageNamed:@"Brush"];
	rect.size = [image size];
	rect.origin.x = NSMidX([self bounds]) - rect.size.width / 2;
	rect.origin.y = NSMidY([self bounds]) - rect.size.height / 2;
	[image dissolveToPoint:rect.origin fraction:0.5];
}

@end
