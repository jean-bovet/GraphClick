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

BOOL sDisplayLicenseAgreement = NO;

-(BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app
{
	return YES;
}

-(NSDocument *)openUntitledDocumentAndDisplay:(BOOL)displayDocument error:(NSError **)outError
{
	if (sDisplayLicenseAgreement)
		return nil;
	return [super openUntitledDocumentAndDisplay:displayDocument error:outError];
}

-(void)applicationDidFinishLaunching:(NSNotification *)inNotification
{
//	if (sDisplayLicenseAgreement) {
//		ARLicenseAgreementManager *manager = [ARLicenseAgreementManager sharedManager];
//		if (![manager userAcceptsLicenseAgreement])
//			exit(0);
//		sDisplayLicenseAgreement = NO;
//	    [[ARAboutDialog sharedAboutDialog] show:nil];
//		[self openUntitledDocumentOfType:@"GraphClick Document" display:YES];
//	    [[ARAboutDialog sharedAboutDialog] performSelector:@selector(hide:) withObject:nil afterDelay:2.0];
//	}
	    [[ARAboutDialog sharedAboutDialog] show:nil];
//		[self openUntitledDocumentOfType:@"GraphClick Document" display:YES];
	    [[ARAboutDialog sharedAboutDialog] performSelector:@selector(hide:) withObject:nil afterDelay:2.0];
}

-(void)awakeFromNib
{
//	ARLicenseAgreementManager *manager = [ARLicenseAgreementManager sharedManager];
	sDisplayLicenseAgreement = NO; //![manager userHasAcceptedLicenseAgreement];

//	ARRegisterManager* registerManager = [ARRegisterManager sharedManager];
/*	[registerManager addVersionWithID:@"GC"
			name:@"GraphClick"
			price:@"US$8"
			comment:nil
			latest:YES
			equivalentToID:nil
			eSellerID:@"ES9638921356"
			previewID:nil //@"PC2287029595-4975"
			eSelleratePrefix:@"GCN0200"
			expirable:NO
			arizonaPrefix:@"AGC0200"
			previousVersionIDs:nil];*/
//	[registerManager addVersionWithID:@"GC"
//			name:@"GraphClick"
//			price:@"US$8"
//			comment:nil
//			latest:YES
//			equivalentToID:nil
//			eSellerID:@"STR6516190330"
//			SKUID:@"SKU81770258615"
//			previewID:nil //@"hewC5jVH"
//			eSelleratePrefix:@"GCN0200"
//			expirable:NO
//			arizonaPrefix:@"AGC0200"
//			previousVersionIDs:nil];
//
//	[registerManager addInvalidBlacklist:@""];
//	[registerManager addHackedBlacklist:@"FWW4/189J/NX92Z3N.27RY18978.1/-C.Wz MVP.03/36236P5D6PLL0.Z6M77M88K4-BW63Mi XUD/041.98.AZG553.PJ/2H45/1-4874953/Ki ZOR/04171595.-.8HTSS3J1JG96KD30224A/Li FWW4/189-WQ125X.E86E-934.4O5FK3D7Kz UHJ0606487K..57-4./9R-ZU-/DLB.-6A52Qv YPZ413/4W3OU35SAH5.L3-5H6G4./DCN7Iz MGU.03/7166FQFS0ZKJL7Q.749MHSX3SSUB9Ji"];
//	
//	if (!sDisplayLicenseAgreement)
//	    [[ARAboutDialog sharedAboutDialog] show:nil];

//    ARUpdateManager *updater = [ARUpdateManager sharedManager];
//	[updater setServerName:@"localhost"];
//	[updater setServerPath:@"/~bovet/updates/"];
//	[updater setServerName:@"www.arizona-software.ch"];
//	[updater setServerPath:@"/updates/"];
//    [updater setLocalPath:[[[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist" inDirectory:@"Updates"] stringByDeletingLastPathComponent]];
//    [updater setName:@"graphclick"];
//	[updater setUpdateBlacklist:YES];
//	[updater insertPreferencesIntoView:[[GCPreferences sharedWindowController] updateView]];
	
	[GCInspector loadInspectors];
	[GCGeometryInfo loadInspector];
	[GCAreaInfo loadInspector];
	
//	if (!sDisplayLicenseAgreement)
//	    [[ARAboutDialog sharedAboutDialog] performSelector:@selector(hide:) withObject:nil afterDelay:2.0];
}

-(void)dealloc
{
	[super dealloc];
}

-(void)showAboutBox:(id)inSender
{
	[[ARAboutDialog sharedAboutDialog] performSelector:@selector(showAboutWindow) withObject:nil afterDelay:0.0];
}

-(void)checkForUpdates:(id)inSender
{
//    [[ARUpdateManager sharedManager] checkForUpdates:inSender];
}

-(void)showLicenseWindow:(id)inSender
{
//	[[ARRegisterManager sharedManager] performSelector:@selector(displayLicenseWindow:) withObject:nil afterDelay:0];
}

-(void)reportBug:(id)inSender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"Bug Report URL", @"")]];
}

-(void)onlineTour:(id)inSender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"Online Tour URL", @"")]];
}

-(IBAction)lostSerial:(id)inSender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"Lost Serial URL", @"")]];
}

-(IBAction)visitHomepage:(id)inSender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"Homepage URL", @"")]];
}

-(id)openDocumentWithContentsOfFile:(NSString *)inFileName display:(BOOL)inFlag
{
//	if (sDisplayLicenseAgreement)
//		return [NSNull null];

//	if ([[inFileName pathExtension] isEqual:@"graphclicklicense"]) {
//		NSError *error = nil;
//		NSStringEncoding encoding = NSUTF8StringEncoding;
//		NSString *string = [NSString stringWithContentsOfFile:inFileName encoding:encoding error:&error];
//		if (string)
//			[[ARRegisterManager sharedManager] registerDirectlyWithString:string];
//	}
	
	id document = [super openDocumentWithContentsOfFile:inFileName display:inFlag];
	if (!document) {
		document = [self currentDocument];
		if ([document isKindOfClass:[GCDocument class]])
			[[document mainWindow] makeKeyAndOrderFront:nil];
	}
	return document;
}

-(id)makeDocumentWithContentsOfFile:(NSString *)inFileName ofType:(NSString *)inDocType
{
	if ([inDocType isEqual:@"GraphClick Image"] || [inDocType isEqual:@"GraphClick Movie"]) {
		GCDocument *document = [self currentDocument];
		if (![document isKindOfClass:[GCDocument class]])
			document = 	[self openUntitledDocumentOfType:@"GraphClick Document" display:YES];
		if (document)
			[[document view] setURL:[NSURL fileURLWithPath:inFileName]];
		return nil;
	} else
		return [super makeDocumentWithContentsOfFile:inFileName ofType:inDocType];
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
