//
//  GCSerieRenamer.m
//  GraphClick
//
//  Created by Simon Bovet on 23.08.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GCSerieRenamer.h"

#import "GCSerie.h"

@interface GCSerie (Private)

-(void)setName:(NSString *)inName;

@end

@implementation GCSerieRenamer

+(GCSerieRenamer *)renamer
{
	return [[[self alloc] init] autorelease];
}

-(id)init
{
	if (self = [self initWithWindowNibName:@"GCSerieRenamer"]) {
		[self loadWindow];
	}
	return self;
}

-(void)renameSeries:(NSArray *)inSeries modalForWindow:(NSWindow *)inWindow
{
	[self retain];
	BOOL multiple = [inSeries count] > 1;
	[mAddIndex setState:multiple ? NSOnState : NSOffState];
	[mAddIndex setEnabled:multiple];
	[NSApp beginSheet:[self window] modalForWindow:inWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:userInfo:) contextInfo:inSeries];
}

-(IBAction)confirmName:(id)inSender
{
	[NSApp endSheet:[self window] returnCode:NSOKButton];
}

-(IBAction)cancelName:(id)inSender
{
	[NSApp endSheet:[self window] returnCode:NSCancelButton];
}

-(void)sheetDidEnd:(NSWindow *)inWindow returnCode:(int)inReturnCode userInfo:(NSArray *)inSeries
{
	[inWindow orderOut:nil];
	if (inReturnCode == NSOKButton) {
		NSString *name = [mNewName stringValue];
		BOOL addIndex = [mAddIndex intValue];
		
		NSEnumerator *enumerator = [inSeries objectEnumerator];
		GCSerie *serie;
		int index = 1;
		while (serie = [enumerator nextObject]) {
            if (addIndex) {
                [serie setName:[NSString stringWithFormat:@"%@ %i", name, index]];
            } else {
                [serie setName:[NSString stringWithFormat:@"%@", name]];
            }
            index++;            
        }
	}
	[self release];
}

@end
