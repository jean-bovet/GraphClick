//
//  GCApplicationDelegate.m
//  GraphClick
//
//  Created by Simon Bovet on 17.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GCApplicationDelegate.h"

#import "GCFoundation.h"
#import "GCNumberFormatter.h"
#import "GCView.h"
#import "GCView+AdjustCoordinates.h"
#import "GCDocument.h"
#import "GCInspector.h"
#import "GCGeometryInfo.h"
#import "GCAreaInfo.h"
#import "GCPreferences.h"
#import "GCSerie.h"
#import "GCPointPasteDialog.h"
#import "GCAdjustmentWizard.h"
#import "ARAboutDialog.h"

#define GCDisplayedPaletteView @"GCDisplayedPaletteView"

@implementation GCApplicationDelegate

@synthesize updaterController = _updaterController;

+(void)initialize
{
	[NSValueTransformer setValueTransformer:[[[GCZoomFactorTransformer alloc] init] autorelease] forName:@"GCZoomFactorTransformer"];
	[NSValueTransformer setValueTransformer:[[[GCAngleTransformer alloc] init] autorelease] forName:@"GCAngleTransformer"];
	[NSValueTransformer setValueTransformer:[[[GCPercentTransformer alloc] init] autorelease] forName:@"GCPercentTransformer"];
	[NSValueTransformer setValueTransformer:[[[GCNumberTransformer alloc] init] autorelease] forName:@"GCNumberTransformer"];
	[NSValueTransformer setValueTransformer:[[[GCTimeTransformer alloc] init] autorelease] forName:@"GCTimeTransformer"];
	[NSValueTransformer setValueTransformer:[[[GCTimeTransformer alloc] init] autorelease] forName:@"GCTimeTransformer"];
	[NSValueTransformer setValueTransformer:[[[GCEqualityTransformer alloc] init] autorelease] forName:@"GCEqualityTransformer"];
	[NSValueTransformer setValueTransformer:[[[GCInspectorTitleTransformer alloc] init] autorelease] forName:@"GCInspectorTitleTransformer"];
	[NSValueTransformer setValueTransformer:[[[GCValidMarkerTransformer alloc] init] autorelease] forName:@"GCValidMarkerTransformer"];
	[NSValueTransformer setValueTransformer:[[[GCSeparatorTransformer alloc] init] autorelease] forName:@"GCSeparatorTransformer"];
	[NSValueTransformer setValueTransformer:[[[GCEnabledTextColorTransformer alloc] init] autorelease] forName:@"GCEnabledTextColorTransformer"];

	NSMutableDictionary *initialValues = [NSMutableDictionary dictionary];

	[initialValues setInt:0 forKey:GCDisplayedPaletteView];

	[initialValues setInt:3 forKey:GCNumberNumberOfDigits];
	[initialValues setInt:2 forKey:GCNumberTimeValueNumberOfDigits];
	[initialValues setInt:GCNumberScientificNotationConditional forKey:GCNumberScientificNotation];
	[initialValues setInt:5 forKey:GCNumberScientificNotationFrom];
	[initialValues setBool:NO forKey:GCNumberRemoveTrailingZeros];
	[initialValues setInt:0 forKey:GCNumberDecimalSeparator];

	[initialValues setBool:YES forKey:GCUseMagnifyingGlass];
	[initialValues setFloat:0.1 forKey:GCMagicWandTolerance];
	[initialValues setFloat:4.0 forKey:GCMagicWandSpacing];
	[initialValues setInt:50 forKey:GCMagicWandNumberOfPoints];
	[initialValues setInt:0 forKey:GCMagicWandSpacingDefinition];
	[initialValues setFloat:0.0 forKey:GCMagicWandHorizontalOffset];
	[initialValues setInt:1000 forKey:GCMagicWandMaxNumberOfPoints];
	[initialValues setBool:YES forKey:GCMagicWandDynamic];
	[initialValues setFloat:2.0 forKey:GCMagicWandLineFinderSpacing];
	[initialValues setBool:YES forKey:GCMagicWandLineFinderExtremity];
	[initialValues setBool:NO forKey:GCMagicWandLineFinderRightToLeft];

	[initialValues setObject:[NSKeyedArchiver archivedDataWithRootObject:[NSColor greenColor]] forKey:GCFrameColor];
	[initialValues setBool:YES forKey:GCFrameDotted];
	[initialValues setFloat:0.1 forKey:GCFrameBackgroundOpacity];
	[initialValues setBool:YES forKey:GCFrameLabelled];

	[initialValues setObject:[NSKeyedArchiver archivedDataWithRootObject:[NSColor blueColor]] forKey:GCMaskColor];
	[initialValues setFloat:0.3 forKey:GCMaskOpacity];
	[initialValues setFloat:10 forKey:GCMaskBrushSize];
	
	[initialValues setBool:YES forKey:GCAutoAdjustCoordinates];
	[initialValues setBool:YES forKey:GCAdjustFramePosition];
	
	[initialValues setFloat:0.5 forKey:GCGeometryMinPixelError];
	[initialValues setBool:YES forKey:GCGeometryShowError];
	[initialValues setInt:0 forKey:GCGeometryAngleMeasure];
	
	[initialValues setBool:YES forKey:GCBackgroundSelectionWarning];
	[initialValues setInt:1 forKey:GCMagnifyingGlassType];
	
	[initialValues setBool:YES forKey:@"GCAdvancedCurveParametersHidden"];
	[initialValues setBool:YES forKey:@"GCAdvancedLineParametersHidden"];
	
	[initialValues setObject:@"\t" forKey:GCColumnSeparator];
	[initialValues setObject:@"\n" forKey:GCLineSeparator];
	
	[initialValues setObject:[NSNumber numberWithInt:0] forKey:GCPointPasteItemToKeep];

	[[NSUserDefaults standardUserDefaults] registerDefaults:initialValues];
	
	NSEnumerator *enumerator = [[GCAdjustmentWizard availableAdjustmentWizardClassNames] objectEnumerator];
	NSString *className;
	while (className = [enumerator nextObject]) {
		Class wizardClass = NSClassFromString(className);
		NSDictionary *defaults = [wizardClass defaults];
		if (defaults)
			[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	}
	
	[[NSUserDefaults standardUserDefaults] setInteger:0 forKey:GCDisplayedPaletteView];
}

-(BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app
{
	return YES;
}

-(void)applicationDidFinishLaunching:(NSNotification *)inNotification
{
	[[ARAboutDialog sharedAboutDialog] show:nil];
	[[ARAboutDialog sharedAboutDialog] performSelector:@selector(hide:) withObject:nil afterDelay:2.0];

	self.updaterController = [[[SPUStandardUpdaterController alloc]
	    initWithStartingUpdater:YES
	            updaterDelegate:nil
	         userDriverDelegate:nil] autorelease];

	NSString *checkForUpdatesTitle = @"Check for Updates…";
	NSMenu *appMenu = [[[NSApp mainMenu] itemAtIndex:0] submenu];
	if (appMenu && ![appMenu itemWithTitle:checkForUpdatesTitle]) {
		NSMenuItem *checkItem = [[[NSMenuItem alloc]
		    initWithTitle:checkForUpdatesTitle
		           action:@selector(checkForUpdate:)
		    keyEquivalent:@""] autorelease];
		[checkItem setTarget:self];
		NSInteger aboutIndex = [appMenu indexOfItemWithTarget:nil andAction:@selector(orderFrontStandardAboutPanel:)];
		if (aboutIndex < 0)
			aboutIndex = [appMenu indexOfItemWithTarget:self andAction:@selector(showAboutBox:)];
		[appMenu insertItem:checkItem atIndex:(aboutIndex >= 0 ? aboutIndex + 1 : 1)];
	}
}

-(IBAction)checkForUpdate:(id)inSender
{
	[self.updaterController checkForUpdates:inSender];
}

-(void)awakeFromNib
{
	[GCInspector loadInspectors];
	[GCGeometryInfo loadInspector];
	[GCAreaInfo loadInspector];
}

-(void)dealloc
{
	[_updaterController release];
	[super dealloc];
}

-(void)showAboutBox:(id)inSender
{
	[[ARAboutDialog sharedAboutDialog] performSelector:@selector(showAboutWindow) withObject:nil afterDelay:0.0];
}

-(IBAction)visitHomepage:(id)inSender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"Homepage URL", @"")]];
}

-(void)openDocumentWithContentsOfURL:(NSURL *)inURL display:(BOOL)inDisplay
					completionHandler:(void (^)(NSDocument *, BOOL, NSError *))inCompletionHandler
{
	NSString *type = [self typeForContentsOfURL:inURL error:NULL];
	if ([type isEqual:@"GraphClick Image"] || [type isEqual:@"GraphClick Movie"]) {
		GCDocument *document = (GCDocument *)[self currentDocument];
		if (![document isKindOfClass:[GCDocument class]])
			document = (GCDocument *)[self openUntitledDocumentAndDisplay:inDisplay error:NULL];
		if (document) {
			[[document view] setURL:inURL];
			[[document mainWindow] makeKeyAndOrderFront:nil];
		}
		if (inCompletionHandler)
			inCompletionHandler(document, NO, nil);
		return;
	}
	[super openDocumentWithContentsOfURL:inURL display:inDisplay completionHandler:inCompletionHandler];
}

-(IBAction)showPreferences:(id)inSender
{
	[[GCPreferences sharedWindowController] show];
}

-(IBAction)toggleInspector:(id)inSender
{
	if ([GCInspector isVisible])
		[GCInspector hide];
	else
		[GCInspector show];
}

-(IBAction)newInspector:(id)inSender
{
	[GCInspector newInspector];
}

-(IBAction)toggleMagnifyingGlass:(id)inSender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:![defaults boolForKey:GCUseMagnifyingGlass] forKey:GCUseMagnifyingGlass];
}

-(IBAction)toggleGeometryInfo:(id)inSender
{
	[GCGeometryInfo toggle];
}

-(IBAction)toggleAreaInfo:(id)inSender
{
	[GCAreaInfo toggle];
}

-(BOOL)validateMenuItem:(NSMenuItem *)inItem
{
	SEL action = [inItem action];
	if (action == @selector(toggleMagnifyingGlass:))
		[inItem setState:[[NSUserDefaults standardUserDefaults] boolForKey:GCUseMagnifyingGlass] ? NSOnState : NSOffState];
	if (action == @selector(newInspector:))
		return [GCInspector isVisible];
	if (action == @selector(toggleInspector:))
		[inItem setTitle:[GCInspector isVisible] ? NSLocalizedString(@"Hide Inspector Menu Item Title", @"") : NSLocalizedString(@"Show Inspector Menu Item Title", @"")];
	if (action == @selector(toggleGeometryInfo:))
		[inItem setTitle:[GCGeometryInfo isVisible] ? NSLocalizedString(@"Hide Geometry Info Menu Item Title", @"") : NSLocalizedString(@"Show Geometry Info Menu Item Title", @"")];
	if (action == @selector(toggleGeometryInfo:))
		[inItem setTitle:[GCGeometryInfo isVisible] ? NSLocalizedString(@"Hide Geometry Info Menu Item Title", @"") : NSLocalizedString(@"Show Geometry Info Menu Item Title", @"")];
	if (action == @selector(toggleAreaInfo:))
		[inItem setTitle:[GCAreaInfo isVisible] ? NSLocalizedString(@"Hide Area Info Menu Item Title", @"") : NSLocalizedString(@"Show Area Info Menu Item Title", @"")];
	return [super validateMenuItem:inItem];
}

@end
