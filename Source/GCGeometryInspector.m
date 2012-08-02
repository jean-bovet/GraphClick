//
//  GCGeometryInspector.m
//  GraphClick
//
//  Created by Simon Bovet on 23.08.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GCGeometryInspector.h"

@implementation GCGeometryInspector

+(id)sharedInspector
{
	[NSException raise:@"Unimplemented Feature" format:@"+[%@ sharedInspector] not implemented", NSStringFromClass([self class])];
	return nil;
}

-(void)awake
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveInspectorState:)
						name:NSApplicationWillTerminateNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentWillBecomeInactive:)
						name:GCDocumentWillBecomeInactiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentDidBecomeActive:)
						name:GCDocumentDidBecomeActiveNotification object:nil];
}

-(id)init
{
	if (self = [super initWithWindowNibName:NSStringFromClass([self class])]) {
		[self loadWindow];
		[self awake];
	}
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[mDocument release];
	[mSerie release];
	[super dealloc];
}

-(void)setSerie:(GCSerie *)inSerie
{
	if (mSerie != inSerie) {
		[mSerie release];
		mSerie = [inSerie retain];
		[self serieDidChange];
	}
}

-(void)updateSerie
{
	NSArray *series = [mDocument selectedSeries];
	if ([series count] == 1)
		[self setSerie:[series objectAtIndex:0]];
	else
		[self setSerie:nil];
}

-(void)documentDidChange
{
}

-(void)setCurrentDocument:(GCDocument *)inDocument
{
	if (mDocument != inDocument) {
		[mDocument removeObserver:self forKeyPath:@"serie"];
		[mDocument removeObserver:self forKeyPath:@"point"];
		[mDocument release];
		mDocument = [inDocument retain];
		[mDocument addObserver:self forKeyPath:@"serie" options:NSKeyValueObservingOptionNew context:nil];
		[mDocument addObserver:self forKeyPath:@"point" options:NSKeyValueObservingOptionNew context:nil];
		[self documentDidChange];
		[self updateSerie];
	}
}

-(void)documentWillBecomeInactive:(NSNotification *)inNotification
{
	[self setCurrentDocument:nil];
}

-(void)documentDidBecomeActive:(NSNotification *)inNotification
{
	[self setCurrentDocument:[GCDocument activeDocument]];
}

-(void)observeValueForKeyPath:(NSString *)inKeyPath ofObject:(id)inObject
	change:(NSDictionary *)inChange context:(void *)context
{
	if ([inKeyPath isEqual:@"serie"])
		[self updateSerie];
	else if ([inKeyPath isEqual:@"point"])
		[self pointDidChange];
}

-(void)pointDidChange
{
}

-(void)serieDidChange
{
}

-(void)displayLimitationTitle:(NSString *)inTitle message:(NSString *)inMessage
{
//	int choice = NSRunAlertPanel(inTitle, inMessage, nil, NSLocalizedString(@"Register Button", @""), nil);
//	if (choice == NSAlertAlternateReturn)
//		[[ARRegisterManager sharedManager] performSelector:@selector(displayLicenseWindow:) withObject:nil afterDelay:0.0];
}

@end

@implementation GCGeometryInspector (Defaults)

+(NSString *)visibleKey
{
	return [NSString stringWithFormat:@"VisibleGeometryInspector_%@", NSStringFromClass([self class])];
}

+(NSString *)positionKey
{
	return [NSString stringWithFormat:@"PositionOfGeometryInspector_%@", NSStringFromClass([self class])];
}

+(void)loadInspector
{
	id position = [[NSUserDefaults standardUserDefaults] objectForKey:[self positionKey]];
	if (position)
		[(GCGeometryInspector *)[self sharedInspector] setPosition:[NSUnarchiver unarchiveObjectWithData:position]];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:[self visibleKey]])
		[self show];
}

-(BOOL)isVisible
{
	return [[self window] isVisible];
}

-(void)setVisible:(BOOL)inVisible
{
	if (inVisible)
		[[self window] orderFront:nil];
	else
		[[self window] orderOut:nil];
	[self serieDidChange];
	[self performSelector:@selector(documentDidBecomeActive:) withObject:nil afterDelay:0];
}

+(void)toggle
{
	if ([self isVisible])
		[self hide];
	else
		[self show];
}

+(BOOL)isVisible
{
	return [[self sharedInspector] isVisible];
}

+(void)show
{
	[[self sharedInspector] setVisible:YES];
}

+(void)hide
{
	[[self sharedInspector] setVisible:NO];
}

-(id)position
{
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithRect:[[self window] frame]], @"Frame", nil];
}

-(void)setPosition:(id)inPosition
{
	id value;
	if (value = [inPosition objectForKey:@"Frame"])
		[[self window] setFrame:[value rectValue] display:NO];
}

-(void)saveInspectorState:(id)inSender
{
	[[NSUserDefaults standardUserDefaults] setBool:[[self class] isVisible] forKey:[[self class] visibleKey]];
	[[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:[self position]] forKey:[[self class] positionKey]];
}

@end

@implementation GCGeometryTableColumn

-(void)dealloc
{
	[mBoundValue release];
	[super dealloc];
}

-(void)bind:(NSString *)inBinding toObject:(id)inObservable withKeyPath:(NSString *)inKeyPath options:(NSDictionary *)inOptions
{
	if ([inBinding isEqual:@"value"]) {
		[mBoundValue release];
		mBoundValue = [[[inKeyPath componentsSeparatedByString:@"."] objectAtIndex:1] retain];
	}
	[super bind:inBinding toObject:inObservable withKeyPath:inKeyPath options:inOptions];
}

-(NSString *)boundValue
{
	return mBoundValue;
}

@end
