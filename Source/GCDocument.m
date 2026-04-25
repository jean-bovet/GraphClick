//
//  GCDocument.m
//  GraphClick
//
//  Created by Simon Bovet on 02.12.04.
//  Copyright __MyCompanyName__ 2004 . All rights reserved.
//

#import "GCDocument.h"
#import "GCFoundation.h"
#import "GCSerieRenamer.h"

@interface GCDocument (Private)

-(void)setupToolbar;
-(BOOL)paletteDrawerIsOpen;
-(BOOL)infoDrawerIsOpen;

@end

#define GCDocumentToolbarIdentifier @"GCDocumentToolbarIdentifierV3"
#define GCToolToolbarItemIdentifier @"GCToolToolbarItemIdentifierV3"
#define GCZoomToolbarItemIdentifier @"GCZoomToolbarItemIdentifierV3"
#define GCImageFractionToolbarItemIdentifier @"GCImageFractionToolbarItemIdentifierV3"
#define GCToleranceToolbarItemIdentifier @"GCToleranceToolbarItemIdentifierV3"
#define GCSpacingToolbarItemIdentifier @"GCSpacingToolbarItemIdentifierV3"
#define GCMaxNumberToolbarItemIdentifier @"GCMaxNumberToolbarItemIdentifierV3"
#define GCBrushSizeToolbarItemIdentifier @"GCBrushSizeToolbarItemIdentifierV3"
#define GCPaletteDrawerToolbarItemIdentifier @"GCPaletteDrawerToolbarItemIdentifierV3"
#define GCInspectorToolbarItemIdentifier @"GCInspectorToolbarItemIdentifierV3"
#define GCGeometryInfoToolbarItemIdentifier @"GCGeometryInfoToolbarItemIdentifierV3"
#define GCAreaInfoToolbarItemIdentifier @"GCAreaInfoToolbarItemIdentifierV3"

@implementation GCDocument

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"mergeDataSets"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"dataSetsAsColumns"]];
    }
    if ([key isEqualToString:@"canMergeIntoSingleFile"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"multipleDataSets"]];
    }
    return keyPaths;
}

-(id)init
{
    if (self = [super init]) {
		mFrame = [[GCFrame alloc] init];
	}
    return self;
}

-(void)dealloc
{
    [mSerieController removeObserver:self forKeyPath:@"selection"];
	[mSerieController release];
    [mPointController removeObserver:self forKeyPath:@"selection"];
	[mPointController release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[mFrame release];
	[mSettings release];
	[mLoadedDocumentParameters release];
	[mLoadedViewParameters release];
	[super dealloc];
}

-(GCView *)view
{
	return mView;
}

-(NSWindow *)mainWindow
{
	return [mView window];
}

-(GCFrame *)frame
{
	return mFrame;
}

-(GCSerie *)serie
{
	return [mSerieController selection];
}

-(NSArray *)selectedSeries
{
	return [mSerieController selectedObjects];
}

-(GCPoint *)point
{
	return [mPointController selection];
}

-(NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"GCDocument";
}

-(void)setNilValueForKey:(id)inKey
{
	[self setValue:[NSNumber numberWithFloat:0.0] forKey:inKey];
}

-(float)magicWandTolerance
{
	return [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"GCMagicWandTolerance"] floatValue];
}

-(void)setMagicWandTolerance:(float)inTolerance
{
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[NSNumber numberWithFloat:inTolerance] forKey:@"GCMagicWandTolerance"];
}

-(int)magicWandNumberOfPoints
{
	return [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"GCMagicWandNumberOfPoints"] intValue];
}

-(void)setMagicWandNumberOfPoints:(int)inNumber
{
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[NSNumber numberWithInt:inNumber] forKey:@"GCMagicWandNumberOfPoints"];
}

-(int)magicWandSpacingDefinition
{
	return [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"GCMagicWandSpacingDefinition"] intValue];
}

-(void)setMagicWandSpacingDefinition:(int)inDefinition
{
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[NSNumber numberWithInt:inDefinition] forKey:@"GCMagicWandSpacingDefinition"];
}

-(float)magicWandSpacing
{
	return [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"GCMagicWandSpacing"] floatValue];
}

-(void)setMagicWandSpacing:(float)inSpacing
{
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[NSNumber numberWithFloat:inSpacing] forKey:@"GCMagicWandSpacing"];
}

-(float)magicWandHorizontalOffset
{
	return [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"GCMagicWandHorizontalOffset"] floatValue];
}

-(void)setMagicWandHorizontalOffset:(float)inOffset
{
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[NSNumber numberWithFloat:inOffset] forKey:@"GCMagicWandHorizontalOffset"];
}

-(int)magicWandMaxNumberOfPoints
{
	return [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"GCMagicWandMaxNumberOfPoints"] intValue];
}

-(void)setMagicWandMaxNumberOfPoints:(int)inNumber
{
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[NSNumber numberWithInt:inNumber] forKey:@"GCMagicWandMaxNumberOfPoints"];
}

-(float)lineFinderSpacing
{
	return [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"GCMagicWandLineFinderSpacing"] floatValue];
}

-(void)setLineFinderSpacing:(float)inSpacing
{
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[NSNumber numberWithFloat:inSpacing] forKey:@"GCMagicWandLineFinderSpacing"];
}

-(BOOL)lineFinderExtremity
{
	return [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"GCMagicWandLineFinderExtremity"] floatValue];
}

-(void)setLineFinderExtremity:(BOOL)inFlag
{
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[NSNumber numberWithBool:inFlag] forKey:@"GCMagicWandLineFinderExtremity"];
}

-(BOOL)lineFinderRightToLeft
{
	return [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"GCMagicWandLineFinderRightToLeft"] floatValue];
}

-(void)setLineFinderRightToLeft:(BOOL)inFlag
{
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[NSNumber numberWithBool:inFlag] forKey:@"GCMagicWandLineFinderRightToLeft"];
}

-(float)brushSize
{
	return [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"GCMaskBrushSize"] floatValue];
}

-(void)setBrushSize:(float)inSize
{
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[NSNumber numberWithFloat:inSize] forKey:@"GCMaskBrushSize"];
}

-(void)serieFrameLimitsDidChange:(id)inSender
{
	GCSerie *serie = [[self selectedSeries] lastObject];
	[serie useFrameLimits];
}

-(void)observeValueForKeyPath:(NSString *)inKeyPath ofObject:(id)inObject
	change:(NSDictionary *)inChange context:(void *)context
{
	if ([inKeyPath isEqual:@"values.GCMagicWandTolerance"]) {
		[self willChangeValueForKey:@"magicWandTolerance"];
		[self didChangeValueForKey:@"magicWandTolerance"];
	}
	if ([inKeyPath isEqual:@"values.GCMagicWandSpacing"]) {
		[self willChangeValueForKey:@"magicWandSpacing"];
		[self didChangeValueForKey:@"magicWandSpacing"];
	}
	if ([inKeyPath isEqual:@"values.GCMagicWandNumberOfPoints"]) {
		[self willChangeValueForKey:@"magicWandNumberOfPoints"];
		[self didChangeValueForKey:@"magicWandNumberOfPoints"];
	}
	if ([inKeyPath isEqual:@"values.GCMagicWandSpacingDefinition"]) {
		[self willChangeValueForKey:@"magicWandSpacingDefinition"];
		[self didChangeValueForKey:@"magicWandSpacingDefinition"];
	}
	if ([inKeyPath isEqual:@"values.GCMagicWandHorizontalOffset"]) {
		[self willChangeValueForKey:@"magicWandHorizontalOffset"];
		[self didChangeValueForKey:@"magicWandHorizontalOffset"];
	}
	if ([inKeyPath isEqual:@"values.GCMagicWandMaxNumberOfPoints"]) {
		[self willChangeValueForKey:@"magicWandMaxNumberOfPoints"];
		[self didChangeValueForKey:@"magicWandMaxNumberOfPoints"];
	}
	if ([inKeyPath isEqual:@"values.GCMagicWandMaxNumberOfPoints"]) {
		[self willChangeValueForKey:@"magicWandMaxNumberOfPoints"];
		[self didChangeValueForKey:@"magicWandMaxNumberOfPoints"];
	}
	if ([inKeyPath isEqual:@"values.GCMagicWandLineFinderSpacing"]) {
		[self willChangeValueForKey:@"lineFinderSpacing"];
		[self didChangeValueForKey:@"lineFinderSpacing"];
	}
	if ([inKeyPath isEqual:@"values.GCMagicWandLineFinderExtremity"]) {
		[self willChangeValueForKey:@"lineFinderExtremity"];
		[self didChangeValueForKey:@"lineFinderExtremity"];
	}
	if ([inKeyPath isEqual:@"values.GCMagicWandLineFinderRightToLeft"]) {
		[self willChangeValueForKey:@"lineFinderRightToLeft"];
		[self didChangeValueForKey:@"lineFinderRightToLeft"];
	}
	if ([inKeyPath isEqual:@"values.GCMaskBrushSize"]) {
		[self willChangeValueForKey:@"brushSize"];
		[self didChangeValueForKey:@"brushSize"];
	}
	if (inObject == mSerieController) {
		[self willChangeValueForKey:@"serie"];
		[self didChangeValueForKey:@"serie"];
		[self serieFrameLimitsDidChange:nil];
	}
	if (inObject == mPointController) {
		[self willChangeValueForKey:@"point"];
		[self didChangeValueForKey:@"point"];
	}
}

-(void)setupSettings
{
	if (!mSettings)
		mSettings = [[NSMutableDictionary dictionary] retain];
}

+(NSImage *)defaultImage
{
	static NSImage *image = nil;
	if (!image) {
		NSString *text = NSLocalizedString(@"Graph Placeholder", @"");
		NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		[paragraphStyle setAlignment:NSCenterTextAlignment];
		NSFont *font = [NSFont fontWithName:@"Lucida Grande" size:24];
		font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, 
										paragraphStyle, NSParagraphStyleAttributeName,
										[NSColor whiteColor], NSForegroundColorAttributeName, nil];
		NSAttributedString *string = [[[NSAttributedString alloc] initWithString:text attributes:attributes] autorelease];
		NSRect r = NSZeroRect;
		r.size = [string size];
		r.size.width = round(r.size.width + 40);
		r.size.height = round(r.size.height + 4);
		image = [[NSImage alloc] initWithSize:r.size];
		[image lockFocus];
		[[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] set];
		NSRect rr = r;
		rr.size.height -= 2;
		rr.origin.y += 2;
		[[NSBezierPath bezierPathWithRoundRectInRect:rr radius:5] fill];
		[string drawInRect:r];
		[image unlockFocus];
	}
	return image;
}

-(void)windowControllerDidLoadNib:(NSWindowController *)inController
{
    [super windowControllerDidLoadNib:inController];
	
	[[GCDefaultsObserver sharedObserver] addObserver:self forValues:GCMagicWandTolerance, GCMagicWandSpacing, GCMagicWandNumberOfPoints, GCMagicWandSpacingDefinition, GCMagicWandHorizontalOffset,
											GCMagicWandMaxNumberOfPoints, GCMagicWandLineFinderSpacing, GCMagicWandLineFinderExtremity, GCMagicWandLineFinderRightToLeft, GCMaskBrushSize, nil];
	[self setupSettings];

	NSWindow *window = [inController window];
	[window setAcceptsMouseMovedEvents:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKey:)
                    name:NSWindowDidBecomeKeyNotification object:window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:)
                    name:NSWindowWillCloseNotification object:window];

	if (!mLoadedViewParameters) {
		[mFrame setFrameRect:NSInsetRect([mView bounds], 20, 20)];
		[mView setStillImage:[[self class] defaultImage]];
	} else
		[mView setParameters:mLoadedViewParameters afterLoading:YES];
	
	id value;
	if ((value = [mLoadedDocumentParameters objectForKey:@"ContentSize"]))
		[mDocumentWindow setContentSize:[value sizeValue]];
	if ((value = [mLoadedDocumentParameters objectForKey:@"Transparent"]))
		[self setTransparent:[value boolValue]];
	[mView setFrameObject:mFrame];
    [self setupToolbar];
	[mPaletteDrawer setDelegate:self];
	[mInfoDrawer setDelegate:self];
	[mPaletteDrawer performSelector:@selector(open:) withObject:nil afterDelay:0.0];
	[mDataSetTableView setDelegate:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameWillChange:)
											name:GCFrameWillChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChange:)
											name:GCFrameDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageWillChange:)
											name:GCImageWillChangeNotification object:mView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDidChange:)
											name:GCImageDidChangeNotification object:mView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serieFrameLimitsDidChange:)
											name:GCSerieDidChangeFrameLimitIndexNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pointsDidChange:)
                    name:GCSelectedPointsDidMoveNotification object:mView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pointsDidChange:)
                    name:GCFrameAppearanceDidChangeNotification object:nil];

    [[mSerieController retain] addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionNew context:nil];
    [[mPointController retain] addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionNew context:nil];
	
	[self performSelector:@selector(initialSetNeedsDisplay:) withObject:nil afterDelay:0.0];
}

-(void)initialSetNeedsDisplay:(id)inSender
{
	[[mDocumentWindow contentView] setNeedsDisplay:YES];
}

-(NSArray *)keysOfValuesToSaveWithFile
{
	return [NSArray arrayWithObjects:@"infoTextViewData", @"lastExportLocation", nil];
}

-(NSData *)dataRepresentationOfType:(NSString *)inType
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	[dictionary setObject:mFrame forKey:@"Frame"];
	[dictionary setObject:[mView parameters] forKey:@"ViewParameters"];
	[dictionary setObject:[NSPropertyListSerialization dataFromPropertyList:mSettings format:NSPropertyListBinaryFormat_v1_0 errorDescription:nil] forKey:@"SettingsData"];
	
	NSMutableDictionary *docParameters = [NSMutableDictionary dictionary];
	[docParameters setObject:[NSValue valueWithSize:[(NSView *)[mDocumentWindow contentView] frame].size] forKey:@"ContentSize"];
	[docParameters setBool:[self transparent] forKey:@"Transparent"];
	[dictionary setObject:docParameters forKey:@"DocumentParameters"];
	
	id value;
	NSEnumerator *enumerator = [[self keysOfValuesToSaveWithFile] objectEnumerator];
	NSString *key;
	while (key = [enumerator nextObject])
		if ((value = [self valueForKey:key]))
			[dictionary setObject:value forKey:key];

	return [NSKeyedArchiver archivedDataWithRootObject:dictionary];
}

-(BOOL)loadDataRepresentation:(NSData *)inData ofType:(NSString *)inType
{
	NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:inData];
	[self willChangeValueForKey:@"frame"];
	[mFrame release];
	mFrame = [[dictionary objectForKey:@"Frame"] retain];
	[self didChangeValueForKey:@"frame"];
	mLoadedDocumentParameters = [[dictionary objectForKey:@"DocumentParameters"] retain];
	mLoadedViewParameters = [[dictionary objectForKey:@"ViewParameters"] retain];
	mSettings = [[NSPropertyListSerialization propertyListFromData:[dictionary objectForKey:@"SettingsData"] mutabilityOption:NSPropertyListMutableContainersAndLeaves format:nil errorDescription:nil] retain];

	id value;
	NSEnumerator *enumerator = [[self keysOfValuesToSaveWithFile] objectEnumerator];
	NSString *key;
	while (key = [enumerator nextObject])
		if ((value = [dictionary valueForKey:key]))
			[self setValue:value forKey:key];

	return YES;
}

-(void)setupToolbar
{
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:GCDocumentToolbarIdentifier] autorelease];
    
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setDelegate:self];
    
    [mDocumentWindow setToolbar:toolbar];
}

-(BOOL)paletteDrawerIsOpen
{
	return [mPaletteDrawer state] == NSDrawerOpeningState || [mPaletteDrawer state] == NSDrawerOpenState;
}

-(BOOL)infoDrawerIsOpen
{
	return [mInfoDrawer state] == NSDrawerOpeningState || [mInfoDrawer state] == NSDrawerOpenState;
}

-(NSImage *)paletteDrawerToolbarItemImage
{
	return [NSImage imageNamed:[self paletteDrawerIsOpen] ? @"CloseHorizontalDrawer" : @"OpenHorizontalDrawer"];
}

-(NSToolbarItem *)toolbar:(NSToolbar *)inToolbar itemForItemIdentifier:(NSString *)inItemIdentifier willBeInsertedIntoToolbar:(BOOL)inWillBeInserted
{
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:inItemIdentifier] autorelease];
    
    if ([inItemIdentifier isEqual:GCToolToolbarItemIdentifier]) {
		[toolbarItem setLabel:NSLocalizedString(@"Selected Tool Toolbar Item Label", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Selected Tool Toolbar Item Palette Label", @"")];
		[toolbarItem setView:mToolView];
		NSSize size = [mToolView bounds].size;
		[toolbarItem setMinSize:size];
		[toolbarItem setMaxSize:size];
    } else if ([inItemIdentifier isEqual:GCZoomToolbarItemIdentifier]) {
		[toolbarItem setLabel:NSLocalizedString(@"Zoom Toolbar Item Label", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Zoom Toolbar Item Palette Label", @"")];
		[toolbarItem setToolTip:NSLocalizedString(@"Zoom Toolbar Item Tool Tip", @"")];
		[toolbarItem setView:mZoomView];
		NSSize size = [mZoomView bounds].size;
		[toolbarItem setMinSize:NSMakeSize(150, size.height)];
		[toolbarItem setMaxSize:NSMakeSize(150, size.height)];
    } else if ([inItemIdentifier isEqual:GCImageFractionToolbarItemIdentifier]) {
		[toolbarItem setLabel:NSLocalizedString(@"Image Faction Toolbar Item Label", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Image Faction Toolbar Item Palette Label", @"")];
		[toolbarItem setToolTip:NSLocalizedString(@"Image Faction Toolbar Item Tool Tip", @"")];
		[toolbarItem setView:mImageFractionView];
		NSSize size = [mImageFractionView bounds].size;
		[toolbarItem setMinSize:NSMakeSize(100, size.height)];
		[toolbarItem setMaxSize:NSMakeSize(100, size.height)];
    } else if ([inItemIdentifier isEqual:GCToleranceToolbarItemIdentifier]) {
		[toolbarItem setLabel:NSLocalizedString(@"Tolerance Toolbar Item Label", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Tolerance Toolbar Item Palette Label", @"")];
		[toolbarItem setToolTip:NSLocalizedString(@"Tolerance Toolbar Item Tool Tip", @"")];
		[toolbarItem setView:mToleranceView];
		NSSize size = [mToleranceView bounds].size;
		[toolbarItem setMinSize:NSMakeSize(100, size.height)];
		[toolbarItem setMaxSize:NSMakeSize(100, size.height)];
    } else if ([inItemIdentifier isEqual:GCSpacingToolbarItemIdentifier]) {
		[toolbarItem setLabel:NSLocalizedString(@"Spacing Toolbar Item Label", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Spacing Toolbar Item Palette Label", @"")];
		[toolbarItem setToolTip:NSLocalizedString(@"Spacing Toolbar Item Tool Tip", @"")];
		[toolbarItem setView:mSpacingView];
		NSSize size = [mSpacingView bounds].size;
		[toolbarItem setMinSize:size];
		[toolbarItem setMaxSize:size];
    } else if ([inItemIdentifier isEqual:GCMaxNumberToolbarItemIdentifier]) {
		[toolbarItem setLabel:NSLocalizedString(@"Max Number Toolbar Item Label", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Max Number Toolbar Item Palette Label", @"")];
		[toolbarItem setToolTip:NSLocalizedString(@"Max Number Toolbar Item Tool Tip", @"")];
		[toolbarItem setView:mMaxNumberView];
		NSSize size = [mMaxNumberView bounds].size;
		[toolbarItem setMinSize:size];
		[toolbarItem setMaxSize:size];
    } else if ([inItemIdentifier isEqual:GCBrushSizeToolbarItemIdentifier]) {
		[toolbarItem setLabel:NSLocalizedString(@"Brush Size Toolbar Item Label", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Brush Size Toolbar Item Palette Label", @"")];
		[toolbarItem setToolTip:NSLocalizedString(@"Brush Size Toolbar Item Tool Tip", @"")];
		[toolbarItem setView:mBrushSizeView];
		NSSize size = [mBrushSizeView bounds].size;
		[toolbarItem setMinSize:size];
		[toolbarItem setMaxSize:size];
	} else if ([inItemIdentifier isEqual:GCPaletteDrawerToolbarItemIdentifier]) {
		[toolbarItem setLabel:NSLocalizedString(@"Palette Toolbar Item Label", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Palette Toolbar Item Palette Label", @"")];
		[toolbarItem setToolTip:NSLocalizedString(@"Palette Toolbar Item Tool Tip", @"")];
		[toolbarItem setImage:[self paletteDrawerToolbarItemImage]];
		[toolbarItem setTarget:mPaletteDrawer];
		[toolbarItem setAction:@selector(toggle:)];
	} else if ([inItemIdentifier isEqual:GCInspectorToolbarItemIdentifier]) {
		[toolbarItem setLabel:NSLocalizedString(@"Inspector Toolbar Item Label", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Inspector Toolbar Item Palette Label", @"")];
		[toolbarItem setToolTip:NSLocalizedString(@"Inspector Toolbar Item Tool Tip", @"")];
		[toolbarItem setImage:[NSImage imageNamed:@"InspectorToolbarImage"]];
		[toolbarItem setTarget:nil];
		[toolbarItem setAction:@selector(toggleInspector:)];
	} else if ([inItemIdentifier isEqual:GCGeometryInfoToolbarItemIdentifier]) {
		[toolbarItem setLabel:NSLocalizedString(@"Geometry Info Toolbar Item Label", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Geometry Info Toolbar Item Palette Label", @"")];
		[toolbarItem setToolTip:NSLocalizedString(@"Geometry Info Toolbar Item Tool Tip", @"")];
		[toolbarItem setImage:[NSImage imageNamed:@"GeometryInfoToolbarImage"]];
		[toolbarItem setTarget:nil];
		[toolbarItem setAction:@selector(toggleGeometryInfo:)];
	} else if ([inItemIdentifier isEqual:GCAreaInfoToolbarItemIdentifier]) {
		[toolbarItem setLabel:NSLocalizedString(@"Area Info Toolbar Item Label", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Area Info Toolbar Item Palette Label", @"")];
		[toolbarItem setToolTip:NSLocalizedString(@"Area Info Toolbar Item Tool Tip", @"")];
		[toolbarItem setImage:[NSImage imageNamed:@"AreaInfoToolbarImage"]];
		[toolbarItem setTarget:nil];
		[toolbarItem setAction:@selector(toggleAreaInfo:)];
    } else
		toolbarItem = nil;
		
    return toolbarItem;
}

-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)inToolbar
{
    return [NSArray arrayWithObjects:GCToolToolbarItemIdentifier, NSToolbarSeparatorItemIdentifier,
				GCBrushSizeToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier,
				GCInspectorToolbarItemIdentifier, GCGeometryInfoToolbarItemIdentifier, nil];
}

-(NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)inToolbar
{
    return [NSArray arrayWithObjects:GCToolToolbarItemIdentifier, GCZoomToolbarItemIdentifier, GCImageFractionToolbarItemIdentifier,
				GCBrushSizeToolbarItemIdentifier, 
				GCInspectorToolbarItemIdentifier, GCGeometryInfoToolbarItemIdentifier, GCAreaInfoToolbarItemIdentifier, GCPaletteDrawerToolbarItemIdentifier,
				GCToleranceToolbarItemIdentifier, GCSpacingToolbarItemIdentifier, GCMaxNumberToolbarItemIdentifier,
				NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier, nil];
}

-(void)toolbarWillAddItem:(NSNotification *)inNotification
{
    NSToolbarItem *toolbarItem = [[inNotification userInfo] objectForKey:@"item"];
    if	([[toolbarItem itemIdentifier] isEqual:GCPaletteDrawerToolbarItemIdentifier])
		[toolbarItem setImage:[self paletteDrawerToolbarItemImage]];
}

-(NSToolbarItem *)toolbarItemWithIdentifier:(NSString *)inIdentifier
{
	return [[mDocumentWindow toolbar] itemWithIdentifier:inIdentifier];
}

-(void)drawerDidClose:(NSNotification *)inNotification
{
	[[self toolbarItemWithIdentifier:GCPaletteDrawerToolbarItemIdentifier] setImage:[self paletteDrawerToolbarItemImage]];
}

-(void)drawerDidOpen:(NSNotification *)inNotification
{
	[[self toolbarItemWithIdentifier:GCPaletteDrawerToolbarItemIdentifier] setImage:[self paletteDrawerToolbarItemImage]];
}

-(IBAction)exportValues:(id)inSender
{
	if (![mView selectedSerie])
		NSRunAlertPanel(NSLocalizedString(@"No serie to export alert title", @""), NSLocalizedString(@"No serie to export alert message", @""), nil, nil, nil);
	else
		[self exportSerie:inSender];
}

-(IBAction)updateView:(id)inSender
{
	[mView setNeedsDisplay:YES];
}

-(IBAction)renameDataSets:(id)inSender
{
	[[GCSerieRenamer renamer] renameSeries:[mSerieController selectedObjects] modalForWindow:[self mainWindow]];
}

-(void)printDocument:(id)inSender
{
	NSPrintInfo *info = [self printInfo];
	[info setHorizontalPagination:NSFitPagination];
	[info setVerticalPagination:NSFitPagination];
	[info setHorizontallyCentered:YES];
	[info setVerticallyCentered:YES];
    NSPrintOperation *op = [NSPrintOperation printOperationWithView:mView printInfo:info];
    [op runOperationModalForWindow:mDocumentWindow delegate:self didRunSelector:nil contextInfo:nil];
}

@end

@implementation GCDocument (ActiveDocument)

static GCDocument *sActiveDocument = nil;

+(GCDocument *)activeDocument
{
	return sActiveDocument;
}

-(void)becomesActive
{
    if (!mActive)
        [[NSNotificationCenter defaultCenter] postNotificationName:GCDocumentWillBecomeActiveNotification object:self];
    NSEnumerator *enumerator = [[NSApp orderedDocuments] objectEnumerator];
    GCDocument *document;
    
    while (document = [enumerator nextObject])
        if (document != self)
            [document becomesInactive];
    if (sActiveDocument != self)
        [sActiveDocument becomesInactive];
        
    sActiveDocument = self;
    
    if (!mActive) {
        mActive = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:GCDocumentDidBecomeActiveNotification object:self];
        [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:GCDocumentDidChangeActiveStateNotification object:self]
					postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName forModes:nil];
    }
}

-(void)becomesInactive
{
    if (mActive) {
        [[NSNotificationCenter defaultCenter] postNotificationName:GCDocumentWillBecomeInactiveNotification object:self];
        mActive = NO;
        sActiveDocument = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:GCDocumentDidBecomeInactiveNotification object:self];
        [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:GCDocumentDidChangeActiveStateNotification object:self]
					postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName forModes:nil];
    }
}

-(void)windowDidBecomeKey:(NSNotification *)inNotification
{
    [self becomesActive];
}

-(void)windowWillClose:(NSNotification *)inNotification
{
    [self becomesInactive];
}

-(void)pointsDidChange:(NSNotification *)inNotification
{
	[self willChangeValueForKey:@"point"];
	[self didChangeValueForKey:@"point"];
}

-(BOOL)selectionShouldChangeInTableView:(NSTableView *)inTableView
{
	if (inTableView == mDataSetTableView)
		[self performSelector:@selector(selectAllPoints:) withObject:nil afterDelay:0.0];
	return YES;
}

-(void)selectAllPoints:(id)inSender
{
	[mPointController setSelectedObjects:[mPointController arrangedObjects]];
}

@end

@implementation GCDocument (Menu)

-(void)selectTool:(id)inSender
{
	[mView setSelectedTool:[inSender tag]];
}

-(void)togglePaletteDrawer:(id)inSender
{
	[mPaletteDrawer toggle:inSender];
}

-(void)toggleInfoDrawer:(id)inSender
{
	[mInfoDrawer toggle:inSender];
}

-(void)showHideFrame:(id)inSender
{
	[mView setHideFrame:![mView hideFrame]];
}

-(void)adjustCoordinates:(id)inSender
{
	if ([mFrame usePixelCoordinates])
		[mFrame setUsePixelCoordinates:NO];
	[mView adjustCoordinates];
}

-(BOOL)validateMenuItem:(NSMenuItem *)inItem
{
	SEL action = [inItem action];
	if (action == @selector(resetDefaultFrame:) || action == @selector(adjustFrame:) || action == @selector(undistortFrame:))
		return [mView validateMenuItem:inItem];
	if (action == @selector(selectTool:))
		[inItem setState:[inItem tag] == [mView selectedTool] ? NSOnState : NSOffState];
	if (action == @selector(adjustCoordinates:))
		[inItem setState:[mView selectedTool] >= GCAdjustAbscissa1 ? NSOnState : NSOffState];
	if (action == @selector(togglePaletteDrawer:))
		[inItem setTitle:[self paletteDrawerIsOpen] ? NSLocalizedString(@"Hide Palette Menu Item Title", @"") : NSLocalizedString(@"Show Palette Menu Item Title", @"")];
	if (action == @selector(toggleInfoDrawer:))
		[inItem setTitle:[self infoDrawerIsOpen] ? NSLocalizedString(@"Hide Info Menu Item Title", @"") : NSLocalizedString(@"Show Info Menu Item Title", @"")];
	if (action == @selector(showHideFrame:)) {
		[inItem setTitle:![mFrame canShowFrame] || [mView hideFrame] ? NSLocalizedString(@"Show Frame Menu Item Title", @"") : NSLocalizedString(@"Hide Frame Menu Item Title", @"")];
		return [mFrame canShowFrame];
	}
	if (action == @selector(renameDataSets:)) {
		int n = [[mSerieController selectedObjects] count];
		[inItem setTitle:n > 1 ? NSLocalizedString(@"Rename Selected Series Menu Item Title", @"") : NSLocalizedString(@"Rename Selected Serie Menu Item Title", @"")];
		return n > 0;
	}
	return [super validateMenuItem:inItem];
}

@end

@implementation GCDocument (Sorting)

-(IBAction)sortSerie:(id)inSender
{
	[NSApp beginSheet:mSortSheet modalForWindow:mDocumentWindow modalDelegate:self didEndSelector:@selector(sortSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)confirmSort:(id)inSender
{
	[NSApp endSheet:mSortSheet returnCode:NSOKButton];
}

-(IBAction)cancelSort:(id)inSender
{
	[NSApp endSheet:mSortSheet returnCode:NSCancelButton];
}

-(void)sortSheetDidEnd:(NSWindow *)inSheet returnCode:(int)inReturnCode contextInfo:(void *)inContextInfo
{
	if (inReturnCode == NSOKButton)
		[[mView selectedSerie] sortCoordinate:[mSortCoordinate selectedTag] order:[mSortOrder selectedTag]];
	[mSortSheet orderOut:nil];
}

@end

@implementation GCDocument (Forwarding)

-(BOOL)respondsToSelector:(SEL)inSelector
{
	if ([super respondsToSelector:inSelector])
		return YES;
	if (inSelector == @selector(validRequestorForSendType:returnType:))
		return NO;
	return [mView respondsToSelector:inSelector];
}

-(NSMethodSignature *)methodSignatureForSelector:(SEL)inSelector
{
	if ([super respondsToSelector:inSelector])
		return [super methodSignatureForSelector:inSelector];
	if (inSelector == @selector(validRequestorForSendType:returnType:))
		return nil;
	return [mView methodSignatureForSelector:inSelector];
}

-(void)forwardInvocation:(NSInvocation *)inInvocation
{
    SEL selector = [inInvocation selector];
    if ([mView respondsToSelector:selector])
        [inInvocation invokeWithTarget:mView];
    else
        [self doesNotRecognizeSelector:selector];
}

-(IBAction)deleteSelectedDeformations:(id)inSender
{
	[mFrame removeSelectedDeformations];
}

@end

@implementation GCDocument (Export)

-(int)coordinatesToExport
{
	return [mSettings intForKey:@"CoordinatesToExport"];
}

-(void)setCoordinatesToExport:(int)inCoordinates
{
	[mSettings setInt:inCoordinates forKey:@"CoordinatesToExport"];
}

-(BOOL)stackedValues
{
	return [mSettings boolForKey:@"StackedValues"];
}

-(void)setStackedValues:(BOOL)inStacked
{
	[mSettings setBool:inStacked forKey:@"StackedValues"];
}

-(BOOL)includeTimeValues
{
	return ![mSettings boolForKey:@"IgnoreTimeValues"];
}

-(void)setIncludeTimeValues:(BOOL)inIncludeTime
{
	[mSettings setBool:!inIncludeTime forKey:@"IgnoreTimeValues"];
}

-(BOOL)includeHeaders
{
	return ![mSettings boolForKey:@"IgnoreHeaders"];
}

-(void)setIncludeHeaders:(BOOL)inIncludeHeaders
{
	[mSettings setBool:!inIncludeHeaders forKey:@"IgnoreHeaders"];
}

-(BOOL)includeGeometryInfo
{
	return [mSettings boolForKey:@"IncludeGeometryInfo"];
}

-(void)setIncludeGeometryInfo:(BOOL)inIncludeGeometryInfo
{
	[mSettings setBool:inIncludeGeometryInfo forKey:@"IncludeGeometryInfo"];
}

-(BOOL)includeIndexes
{
	return [mSettings boolForKey:@"IncludeIndexes"];
}

-(void)setIncludeIndexes:(BOOL)inIncludeIndexes
{
	[mSettings setBool:inIncludeIndexes forKey:@"IncludeIndexes"];
}

-(BOOL)multipleDataSets
{
	return [[mView selectedSeries] count] > 1;
}

static BOOL sExportingToFile = NO;

-(BOOL)canMergeIntoSingleFile
{
	return sExportingToFile && [self multipleDataSets];
}

-(BOOL)dataSetsAsColumns
{
	return [mSettings boolForKey:@"DataSetsAsColumns"];
}

-(void)setDataSetsAsColumns:(BOOL)inFlag
{
	[mSettings setBool:inFlag forKey:@"DataSetsAsColumns"];
}

-(BOOL)mergeDataSets
{
	return [mSettings boolForKey:@"MergeDataSets"] || [mSettings boolForKey:@"DataSetsAsColumns"];
}

-(void)setMergeDataSets:(BOOL)inMerge
{
	[mSettings setBool:inMerge forKey:@"MergeDataSets"];
}

-(IBAction)exportSerie:(id)inSender
{
	[mSettings setBool:[mView containsMovie] forKey:@"ContainsMovie"];
	[self willChangeValueForKey:@"multipleDataSets"];
	sExportingToFile = YES;
	[self didChangeValueForKey:@"multipleDataSets"];
	[NSApp beginSheet:mExportSettingsWindow modalForWindow:mDocumentWindow modalDelegate:self didEndSelector:@selector(exportSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

-(IBAction)confirmExport:(id)inSender
{
	[NSApp endSheet:mExportSettingsWindow returnCode:NSOKButton];
}

-(IBAction)cancelExport:(id)inSender
{
	[NSApp endSheet:mExportSettingsWindow returnCode:NSCancelButton];
}

-(void)exportSheetDidEnd:(NSWindow *)inSheet returnCode:(int)inReturnCode contextInfo:(void *)inInfo
{
	[inSheet orderOut:nil];
	if (inReturnCode == NSOKButton)
		if ([self multipleDataSets] && ![self mergeDataSets]) {
			NSOpenPanel *panel = [NSOpenPanel openPanel];
			[panel setPrompt:NSLocalizedString(@"Export Data Sets Panel Prompt", @"")];
			[panel setMessage:NSLocalizedString(@"Export Data Sets Panel Message", @"")];
			[panel setCanChooseFiles:NO];
			[panel setCanChooseDirectories:YES];
			[panel setCanCreateDirectories:YES];
			[panel beginSheetForDirectory:lastExportLocation file:nil
				modalForWindow:mDocumentWindow modalDelegate:self didEndSelector:@selector(multipleExportPanelDidEnd:returnCode:contextInfo:) contextInfo:[mView selectedSeries]];
		} else {
			NSSavePanel *panel = [NSSavePanel savePanel];
			[panel setAllowedFileTypes:[NSArray arrayWithObject:@"txt"]];
			[panel setAllowsOtherFileTypes:YES];
			[panel setCanSelectHiddenExtension:YES];
			[panel beginSheetForDirectory:lastExportLocation file:[self multipleDataSets] ? nil : [NSString stringWithFormat:@"%@.txt", [[mView selectedSerie] name]]
				modalForWindow:mDocumentWindow modalDelegate:self didEndSelector:@selector(exportPanelDidEnd:returnCode:contextInfo:) contextInfo:[mView selectedSeries]];
		}
}

-(void)exportPanelDidEnd:(NSSavePanel *)inPanel returnCode:(int)inReturnCode contextInfo:(id)inSource
{
	if (inReturnCode == NSOKButton) {
		[self setValue:[inPanel directory] forKey:@"lastExportLocation"];
		[self updateChangeCount:NSChangeDone];
		[[inSource stringForValuesWithSettings:mSettings] writeToFile:[inPanel filename] atomically:YES];
	}
}

-(void)multipleExportPanelDidEnd:(NSOpenPanel *)inPanel returnCode:(int)inReturnCode contextInfo:(NSArray *)inSeries
{
	if (inReturnCode == NSOKButton) {
		[self setValue:[inPanel directory] forKey:@"lastExportLocation"];
		NSEnumerator *enumerator = [inSeries objectEnumerator];
		GCSerie *serie;
		NSFileManager *fileManager = [NSFileManager defaultManager];
		BOOL overwriteAll = NO;
		while (serie = [enumerator nextObject]) {
			NSString *file = [[[inPanel directory] stringByAppendingPathComponent:[serie name]] stringByAppendingPathExtension:@"txt"];
			if (!overwriteAll && [fileManager fileExistsAtPath:file]) {
				NSString *fileName = [file lastPathComponent];
				NSString *folderName = [[[file stringByAbbreviatingWithTildeInPath] stringByDeletingLastPathComponent] lastPathComponent];
				NSString *title = [NSString stringWithFormat:NSLocalizedString(@"File Overwrite Alert Title (File: %@)", @""), fileName];
				NSString *message = [NSString stringWithFormat:NSLocalizedString(@"File Overwrite Alert Message (Folder: %@, File: %@)", @""), folderName, fileName];
				int choice = NSRunAlertPanel(title, message, NSLocalizedString(@"Overwrite Button", @""), NSLocalizedString(@"Overwrite All Button", @""), NSLocalizedString(@"Cancel Export Data Sets Button", @""));
				switch (choice) {
					case NSAlertDefaultReturn:
						break;
					case NSAlertOtherReturn:
						return;
					case NSAlertAlternateReturn:
						overwriteAll = YES;
						break;
				}
			}
			[[serie stringForValuesWithSettings:mSettings] writeToFile:file atomically:YES];
		}
	}
}

-(IBAction)copySerieWithSettings:(id)inSender
{
	[self willChangeValueForKey:@"multipleDataSets"];
	sExportingToFile = NO;
	[self didChangeValueForKey:@"multipleDataSets"];
	[NSApp beginSheet:mExportSettingsWindow modalForWindow:mDocumentWindow modalDelegate:self didEndSelector:@selector(copyExportSheetDidEnd:returnCode:contextInfo:) contextInfo:[mView selectedSerie]];
}

-(IBAction)copySerie:(id)inSender
{
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[mSettings setBool:[mView containsMovie] forKey:@"ContainsMovie"];
	[pasteboard setString:[[mView selectedSeries] stringForValuesWithSettings:mSettings] forType:NSStringPboardType];
}

-(void)copyExportSheetDidEnd:(NSWindow *)inSheet returnCode:(int)inReturnCode contextInfo:(GCSerie *)inSerie
{
	[inSheet orderOut:nil];
	if (inReturnCode == NSOKButton)
		[self copySerie:nil];
}

-(void)resetDefaultFrame:(id)inSender
{
	[mView resetDefaultFrame:inSender];
}

-(void)adjustSizeToImage:(id)inSender
{
	[mView adjustSizeToImage:inSender];
}

-(void)readjustCustomProjection:(id)inSender
{
	[mView readjustCustomProjection:inSender];
}

@end

@implementation GCDocument (Undo)

-(NSData *)undoData
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	[dictionary setObject:mFrame forKey:@"Frame"];
	NSMutableDictionary *parameters = [mView parameters];
	if (mIgnoreImageUndo)
		[parameters removeObjectForKey:@"Image"];
	[dictionary setObject:parameters forKey:@"ViewParameters"];
	[dictionary setObject:[mSerieController selectionIndexes] forKey:@"SelectedSeries"];
	[dictionary setObject:[mPointController selectionIndexes] forKey:@"SelectedPoints"];
	return [NSKeyedArchiver archivedDataWithRootObject:dictionary];
}

-(void)setUndoData:(NSData *)inData
{
	[self prepareUndo];
	NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:inData];
	[self willChangeValueForKey:@"frame"];
	[mFrame release];
	mFrame = [[dictionary objectForKey:@"Frame"] retain];
	[self didChangeValueForKey:@"frame"];
	[mView setFrameObject:mFrame];
	[mView setParameters:[dictionary objectForKey:@"ViewParameters"] afterLoading:NO];
	[mSerieController setSelectedObjects:[NSArray array]];
	[mPointController setSelectedObjects:[NSArray array]];
	[mSerieController setSelectionIndexes:[dictionary objectForKey:@"SelectedSeries"]];
	[mPointController setSelectionIndexes:[dictionary objectForKey:@"SelectedPoints"]];
	[self finishUndo];
}

-(void)prepareUndo
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUndoData:[self undoData]];
}

-(void)finishUndo
{
}

-(void)frameWillChange:(NSNotification *)inNotification
{
	if ([inNotification object] == mFrame) {
		[mView setNeedsDisplay:YES];
		mIgnoreImageUndo = ![[inNotification userInfo] boolForKey:@"ImageWillChange"];
		[self prepareUndo];
		mIgnoreImageUndo = NO;
	}
}

-(void)frameDidChange:(NSNotification *)inNotification
{
	if ([inNotification object] == mFrame)
		[self finishUndo];
}

-(void)imageWillChange:(NSNotification *)inNotification
{
	NSImage *image = [mView image];
	NSRect bounds = NSZeroRect;
	bounds.size = [image pixelSize];
	NSImage *newImage = [[[NSImage alloc] initWithSize:bounds.size] autorelease];
	[newImage lockFocus];
	[image drawInRect:bounds];
	[newImage unlockFocus];
	[mView setImage:newImage];
}

-(void)imageDidChange:(NSNotification *)inNotification
{
}

@end

@implementation GCDocument (Transparency)

-(BOOL)transparent
{
	return ![mDocumentWindow isOpaque];
}

-(void)setTransparent:(BOOL)inTransparent
{
	[mDocumentWindow setOpaque:!inTransparent];
	[mDocumentWindow setHasShadow:!inTransparent];
	[mDocumentWindow invalidateShadow];
	[mView setNeedsDisplay:YES];
}

@end

@implementation GCImageDocument

@end

@implementation GCMovieDocument

@end
