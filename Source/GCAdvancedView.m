//
//  GCAdvancedView.m
//  GraphClick
//
//  Created by Simon Bovet on 29.08.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GCAdvancedView.h"

#import "GCFoundation.h"

@implementation GCAdvancedView

-(void)awakeFromNib
{
	mFullHeight = [self frame].size.height;
}

-(void)updateHeight:(BOOL)inHidden animate:(BOOL)inAnimate
{
	float previousHeight = [self frame].size.height;
	float contentHeight = [[[self window] contentView] frame].size.height;
	float height = inHidden ? 0 : mFullHeight;
	if (height != previousHeight) {
		NSWindow *window = [self window];
		if (window)
			[window setContentHeight:contentHeight + height - previousHeight animate:inAnimate];
		else if (!inAnimate) {
			NSView *ancestorView = self;
			while ([ancestorView superview])
				ancestorView = [ancestorView superview];
			NSRect frame = [ancestorView frame];
			frame.size.height += height - previousHeight;
			[ancestorView setFrame:frame];
		}
	}
}

-(void)updateAdvancedViewState
{
	[self updateHeight:[self isHidden] animate:NO];
}

-(void)setHidden:(BOOL)inHidden
{
	if (inHidden) {
		[self updateHeight:inHidden animate:YES];
		[super setHidden:inHidden];
	} else {
		[super setHidden:inHidden];
		[self updateHeight:inHidden animate:YES];
	}
}

@end

@implementation NSView (GCAdvancedView)

-(void)updateAdvancedViewState
{
	[[self subviews] makeObjectsPerformSelector:_cmd];
}

@end
