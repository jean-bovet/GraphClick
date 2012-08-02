//
//  GCSnapGridController.m
//  GraphClick
//
//  Created by Simon Bovet on 02.02.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "GCSnapGridController.h"

#import "GCView.h"

@implementation GCSnapGridController

-(id)initWithView:(GCView *)inView
{
	if (self = [super initWithWindowNibName:@"GCSnapGrid"]) {
		[self loadWindow];
		mView = inView;
		mPreviousValues = [[NSMutableDictionary alloc] initWithCapacity:0];
	}
	return self;
}

-(void)dealloc
{
	[mPreviousValues release];
	[super dealloc];
}

-(void)startSnapGridEdition:(id)inSender
{
	NSEnumerator *enumerator = [[mView snapGridParameterKeys] objectEnumerator];
	NSString *key;
	while (key = [enumerator nextObject]) {
		[self willChangeValueForKey:key];
		[self didChangeValueForKey:key];
		[mPreviousValues setObject:[mView valueForKey:key] forKey:key];
	}
	
	[NSApp beginSheet:[self window] modalForWindow:[mView window] modalDelegate:self didEndSelector:@selector(editSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)finishSnapGridEdition:(id)inSender
{
	[NSApp endSheet:[self window] returnCode:[inSender tag]];
}

-(void)editSheetDidEnd:(NSWindow *)inSheet returnCode:(int)inReturnCode contextInfo:(void *)inContextInfo
{
	if (inReturnCode == NSCancelButton) {
		NSEnumerator *enumerator = [[mView snapGridParameterKeys] objectEnumerator];
		NSString *key;
		while (key = [enumerator nextObject])
			[mView setValue:[mPreviousValues objectForKey:key] forKey:key];
	}
	[inSheet orderOut:nil];
	[mView flagsChanged:nil];
}

-(id)valueForUndefinedKey:(id)inKey
{
	return [mView valueForKey:inKey];
}

-(void)setValue:(id)inValue forUndefinedKey:(id)inKey
{
	[mView setValue:inValue forKey:inKey];
}

@end
