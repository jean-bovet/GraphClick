//
//  GCPreferences.m
//  GraphClick
//
//  Created by Simon Bovet on 19.03.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GCPreferences.h"

#define GCPreferencesToolbarIdentifier @"GCPreferencesToolbarIdentifier"

@interface GCPreferences (Private)

-(void)setupToolbar;

@end

@implementation GCPreferences

-(id)init
{
	if (self = [super initWithWindowNibName:@"GCPreferences"]) {
		[self loadWindow];

		mPaneViews = [[NSArray alloc] initWithObjects:mGeneralView, mNumberView, mDetectionView, mAdvancedView, nil];
		mPaneImageNames = [[NSArray alloc] initWithObjects:@"Preferences", @"NumberPreferences", @"DetectionPreferences", @"AdvancedPreferences", nil];
		mPaneLabels = [[NSArray alloc] initWithObjects:
							NSLocalizedString(@"General Preference Pane Label", @""),
							NSLocalizedString(@"Number Format Preference Pane Label", @""),
							NSLocalizedString(@"Automatic Detection Preference Pane Label", @""),
							NSLocalizedString(@"Advanced Preference Pane Label", @""),
						nil];

		[self setupToolbar];
		[self selectPaneAtIndex:0];
	}
	return self;
}

-(void)dealloc
{
	[mPaneViews release];
	[mPaneImageNames release];
	[mPaneLabels release];
	[super dealloc];
}

-(void)selectPaneAtIndex:(unsigned)inIndex
{
	NSWindow *window = [self window];
	[[window toolbar] setSelectedItemIdentifier:[mPaneLabels objectAtIndex:inIndex]];

	NSView *paneView = [mPaneViews objectAtIndex:inIndex];
	NSView *view = [window contentView];
	float deltaHeight = [paneView frame].size.height - [view frame].size.height;
	NSRect frameRect = [window frame];
	frameRect.origin.y -= deltaHeight;
	frameRect.size.height += deltaHeight;
	frameRect.size.width = [paneView frame].size.width;

	[[view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[window setFrame:frameRect display:YES animate:YES];
	[view addSubview:paneView];
}

@end

@implementation GCPreferences (Public)

+(id)sharedWindowController
{
	static id controller = nil;
	if (!controller)
		controller = [[self alloc] init];
	return controller;
}

-(void)show
{
	[[self window] makeKeyAndOrderFront:nil];
}

-(NSView *)updateView
{
	return mUpdateView;
}

@end

@implementation GCPreferences (Toolbar)

-(void)setupToolbar
{
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:GCPreferencesToolbarIdentifier] autorelease];
    
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setDelegate:self];
    
    [[self window] setToolbar:toolbar];
}

-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)inToolbar
{
	return mPaneLabels;
}

-(NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)inToolbar
{
	return mPaneLabels;
}

-(NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)inToolbar
{
	return mPaneLabels;
}

-(NSToolbarItem *)toolbar:(NSToolbar *)inToolbar itemForItemIdentifier:(NSString *)inItemIdentifier willBeInsertedIntoToolbar:(BOOL)inWillBeInserted
{
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:inItemIdentifier] autorelease];
    
	[toolbarItem setLabel:inItemIdentifier];
	int index = [mPaneLabels indexOfObject:inItemIdentifier];
	[toolbarItem setImage:[NSImage imageNamed:[mPaneImageNames objectAtIndex:index]]];
	[toolbarItem setTarget:self];
	[toolbarItem setAction:@selector(selectPreferences:)];
	
	return toolbarItem;
}

-(void)selectPreferences:(id)inSender
{
	[self selectPaneAtIndex:[mPaneLabels indexOfObject:[inSender itemIdentifier]]];
}

@end
