//
//  GCInspector.m
//  GraphClick
//
//  Created by Simon Bovet on 13.01.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GCInspector.h"

#import "GCFoundation.h"
#import "GCDocument.h"

#define GCInspectorStates @"GCInspectorStates"
#define GCInspectorSelectedView @"GCInspectorSelectedView"
#define GCInspectorPosition @"GCInspectorPosition"

@implementation GCInspector

+(NSMutableArray *)inspectors
{
	static NSMutableArray *array = nil;
	if (!array)
		array = [[NSMutableArray alloc] initWithCapacity:0];
	return array;
}

+(id)inspectorWithState:(id)inState
{
	return [[[self alloc] initWithState:inState] autorelease];
}

-(id)initWithState:(id)inState
{
	if (self = [super initWithWindowNibName:@"GCInspector"]) {
		mSelectedView = [inState intForKey:GCInspectorSelectedView];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentWillBecomeInactive:)
							name:GCDocumentWillBecomeInactiveNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentDidBecomeActive:)
							name:GCDocumentDidBecomeActiveNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveInspectorsState:)
							name:NSApplicationWillTerminateNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(visibleStateDidChange:)
							name:GCSerieDidChangeVisibleStateNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDocument:)
							name:GCSelectedSerieDidChangeNotification object:nil];
							
		[[self window] setDelegate:self];
		id position = [inState objectForKey:GCInspectorPosition];
		if (!position) {
			NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:GCInspectorPosition];
			if (data)
				position = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		}
		if (position)
			[[self window] setFrameTopLeftPoint:[position pointValue]];
		
		[[[self class] inspectors] addObject:self];
	}
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

-(void)documentWillBecomeInactive:(NSNotification *)inNotification
{
	[mDocumentController setContent:nil];
}

-(void)documentDidBecomeActive:(NSNotification *)inNotification
{
	[self updateDocument];
}

-(void)updateDocument
{
	GCDocument *document = [GCDocument activeDocument];
	[mDocumentController setContent:document];
}

-(void)updateDocument:(id)inSender
{
	[mDocumentController setContent:nil];
	[self updateDocument];
}

-(int)selectedView
{
	return mSelectedView;
}

-(void)setSelectedView:(int)inView
{
	if (mSelectedView != inView) {
		mSelectedView = inView;
		[self updateInspectorSize:YES];
		[self updateDocument];
	}
}

-(NSPoint)origin
{
	NSRect frame = [[self window] frame];
	return NSMakePoint(NSMinX(frame), NSMaxY(frame));
}

-(void)saveInspectorsState:(NSNotification *)inNotification
{
	NSMutableArray *states = [NSMutableArray array];
	NSEnumerator *enumerator = [[[self class] inspectors] objectEnumerator];
	GCInspector *inspector;
	while (inspector = [enumerator nextObject])
		if ([[inspector window] isVisible]) {
			NSMutableDictionary *state = [NSMutableDictionary dictionary];
			[state setInt:[inspector selectedView] forKey:GCInspectorSelectedView];
			[state setObject:[NSValue valueWithPoint:[inspector origin]] forKey:GCInspectorPosition];
			[states addObject:state];
		}
	[[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:states] forKey:GCInspectorStates];
}

-(void)windowWillClose:(NSNotification *)inNotification
{
	NSMutableArray *inspectors = [[self class] inspectors];
	if ([inspectors count] == 1)
		[[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:[NSValue valueWithPoint:[self origin]]] forKey:GCInspectorPosition];
	[inspectors removeObject:self];
}

-(void)visibleStateDidChange:(NSNotification *)inNotification
{
	[mDocumentController didChangeValueForKey:@"selection.serie.visible"];
}

-(void)updateInspectorSize:(BOOL)inAnimate
{
	float yMin = 1e10;
	NSEnumerator *enumerator = [[[[mTabView tabViewItemAtIndex:mSelectedView] view] subviews] objectEnumerator];
	NSView *subview;
	while (subview = [enumerator nextObject])
		yMin = MIN(yMin, NSMinY([subview frame]));
	float deltaHeight = 10 - yMin - [mTabView frame].origin.y;
	NSWindow *window = [self window];
	NSRect frameRect = [window frame];
	frameRect.origin.y -= deltaHeight;
	frameRect.size.height += deltaHeight;
	[window setFrame:frameRect display:YES animate:inAnimate];
}

@end

@implementation GCInspector (Public)

+(void)loadInspectors
{
	NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:GCInspectorStates];
	if (data) {
		NSArray *states = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		NSEnumerator *enumerator = [states objectEnumerator];
		id state;
		while (state = [enumerator nextObject]) {
			GCInspector *inspector = [self inspectorWithState:state];
			[inspector updateInspectorSize:NO];
			[[inspector window] orderFront:nil];
		}
	}
}

+(BOOL)isVisible
{
	NSEnumerator *enumerator = [[self inspectors] objectEnumerator];
	GCInspector *inspector;
	while (inspector = [enumerator nextObject])
		if ([[inspector window] isVisible])
			return YES;
	return NO;
}

+(void)show
{
	if ([[self inspectors] count] == 0)
		[self newInspector];

	NSEnumerator *enumerator = [[self inspectors] objectEnumerator];
	GCInspector *inspector;
	while (inspector = [enumerator nextObject])
		[[inspector window] orderFront:nil];
}

+(void)hide
{
	NSEnumerator *enumerator = [[self inspectors] objectEnumerator];
	GCInspector *inspector;
	while (inspector = [enumerator nextObject])
		[[inspector window] orderOut:nil];
}

+(void)newInspector
{
	GCInspector *inspector = [self inspectorWithState:nil];
	NSWindow *window = [inspector window];
	NSPoint origin = [inspector origin];
	int n = [[self inspectors] count] - 1;
	origin.x += n * 10;
	origin.y -= n * 10;
	[window setFrameTopLeftPoint:origin];
	[inspector updateDocument];
	[inspector updateInspectorSize:NO];
	[window orderFront:nil];
}

@end

@implementation GCInspectorTitleTransformer

+(Class)transformedValueClass
{
    return [NSString class];
}

+(BOOL)allowsReverseTransformation
{
    return NO;   
}

-(id)transformedValue:(id)inValue
{
	static NSArray *titles = nil;
	if (!titles)
		titles = [[NSArray alloc] initWithObjects:
			NSLocalizedString(@"Coordinates Inspector Title", @""),
			NSLocalizedString(@"Image Inspector Title", @""),
			NSLocalizedString(@"Appearance Inspector Title", @""),
			NSLocalizedString(@"Points Inspector Title", @""),
			NSLocalizedString(@"Deformation Inspector Title", @""),
			NSLocalizedString(@"Movie Inspector Title", @""), nil];
	return [titles objectAtIndex:[inValue intValue]];
}

@end