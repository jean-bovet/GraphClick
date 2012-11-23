//
//  GCHoleyView.m
//  GraphClick
//
//  Created by Simon Bovet on 10.01.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GCHoleyView.h"

#import "GCView.h"

@interface GCView (Dragging)

-(NSArray *)acceptedDragTypes;
-(NSDragOperation)draggingEntered:(id <NSDraggingInfo>)inSender;
-(BOOL)performDragOperation:(id <NSDraggingInfo>)inSender;

@end

@implementation GCHoleyView

-(GCView *)graphClickView
{
	if ([mHole isKindOfClass:[GCView class]])
		return (GCView *)mHole;
	else
		return nil;
}

-(void)awakeFromNib
{
	GCView *view = [self graphClickView];
	if (view)
		[self registerForDraggedTypes:[view acceptedDragTypes]];
}

-(NSDragOperation)draggingEntered:(id <NSDraggingInfo>)inSender
{
	GCView *view = [self graphClickView];
	if (view)
		return [view draggingEntered:inSender];
	else
		return NSDragOperationNone;
}

-(BOOL)performDragOperation:(id <NSDraggingInfo>)inSender
{
	GCView *view = [self graphClickView];
	if (view)
		return [view performDragOperation:inSender];
	else
		return NO;
}

-(void)drawRect:(NSRect)inRect
{
	if ([[self window] isOpaque])
		[super drawRect:inRect];
	else {
		[[NSColor windowBackgroundColor] set];
		NSRectFill([self bounds]);
		[[NSColor colorWithCalibratedWhite:0.0 alpha:0.0625] set];
		NSRectFill([self convertRect:[mHole visibleRect] fromView:mHole]);
	}
}

-(BOOL)isOpaque
{
	return NO;
}

@end
