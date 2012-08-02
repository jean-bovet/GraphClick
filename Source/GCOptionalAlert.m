//
//  GCOptionalAlert.m
//  GraphClick
//
//  Created by Simon Bovet on 06.04.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GCOptionalAlert.h"

#import "GCFoundation.h"

@interface GCOptionalAlert (Private)

+(id)sharedController;
-(void)setTitle:(NSString *)inTitle;
-(void)setMessage:(NSString *)inMessage;
-(void)run:(id)inIdentifier;
-(BOOL)shouldDisplay:(id)inIdentifier;

@end


@implementation GCOptionalAlert

+(id)sharedController
{
	static id sharedController = nil;
	if (!sharedController)
		sharedController = [[self alloc] init];
	return sharedController;
}

-(id)init
{
	if (self = [super initWithWindowNibName:@"GCOptionalAlert"]) {
		[self loadWindow];
		mHiddenSet = [[NSMutableSet alloc] initWithCapacity:0];
	}
	return self;
}

-(void)dealloc
{
	[mTitle release];
	[mMessage release];
	[mHiddenSet release];
	[super dealloc];
}

-(NSString *)title
{
	return mTitle;
}

-(void)setTitle:(NSString *)inTitle
{
	if (mTitle != inTitle) {
		[mTitle release];
		mTitle = [inTitle retain];
		
		NSAttributedString *string = [[[NSAttributedString alloc] initWithString:mTitle
				attributes:[NSDictionary dictionaryWithObjectsAndKeys:[mTitleTextField font], NSFontAttributeName, nil]] autorelease];
		NSWindow *window = [self window];
		NSSize size = [[window contentView] bounds].size;
		size.width += 4 + [string size].width - [mTitleTextField bounds].size.width;
		size.width = MAX([window minSize].width, size.width);
		[[self window] setContentSize:size];
	}
}

-(NSString *)message
{
	return mMessage;
}

-(void)setMessage:(NSString *)inMessage
{
	if (mMessage != inMessage) {
		[mMessage release];
		mMessage = [inMessage retain];

		
		NSAttributedString *string = [[[NSAttributedString alloc] initWithString:mMessage
				attributes:[NSDictionary dictionaryWithObjectsAndKeys:[mMessageTextField font], NSFontAttributeName, nil]] autorelease];
		NSWindow *window = [self window];
		NSSize size = [[window contentView] frame].size;
		size.height += 8 + [string heightForWidth:[mMessageTextField frame].size.width - 4] - [mMessageTextField frame].size.height;
		[[self window] setContentSize:size];
	}
}

-(BOOL)dontShowAnymore
{
	return mDontShowAnymore;
}

-(void)setDontShowAnymore:(BOOL)inFlag
{
	mDontShowAnymore = inFlag;
}

-(void)run:(id)inIdentifier
{
	[self setDontShowAnymore:NO];
	NSWindow *window = [self window];
	[NSApp runModalForWindow:window];
	[window orderOut:nil];
	if ([self dontShowAnymore])
		[mHiddenSet addObject:inIdentifier];
}

-(BOOL)shouldDisplay:(id)inIdentifier
{
	return ![mHiddenSet containsObject:inIdentifier];
}

-(IBAction)confirm:(id)inSender
{
	[NSApp stopModal];
}

@end

void GCRunOptionalAlertPanel(id inIdentifier, NSString *inTitle, NSString *inMessage)
{
	GCOptionalAlert *alert = [GCOptionalAlert sharedController];
	if ([alert shouldDisplay:inIdentifier]) {
		[alert setTitle:inTitle];
		[alert setMessage:inMessage];
		[alert performSelectorOnMainThread:@selector(run:) withObject:inIdentifier waitUntilDone:YES];
	}
}
