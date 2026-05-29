//
//  GCDocument.h
//  GraphClick
//
//  Created by Simon Bovet on 02.12.04.
//  Copyright __MyCompanyName__ 2004 . All rights reserved.
//


#import <Cocoa/Cocoa.h>

#import "GCFrame.h"
#import "GCView.h"

#define GCDocumentWillBecomeActiveNotification @"GCDocumentWillBecomeActiveNotification"
#define GCDocumentDidBecomeActiveNotification @"CPDocumentDidBecomeActiveNotification"
#define GCDocumentWillBecomeInactiveNotification @"GCDocumentWillBecomeInactiveNotification"
#define GCDocumentDidBecomeInactiveNotification @"GCDocumentDidBecomeInactiveNotification"
#define GCDocumentDidChangeActiveStateNotification @"GCDocumentDidChangeActiveStateNotification"

@interface GCDocument : NSDocument <NSDrawerDelegate, NSTableViewDelegate, NSToolbarDelegate> {
	GCFrame *mFrame;
	NSMutableDictionary *mSettings;
	IBOutlet GCView *mView;
	IBOutlet NSArrayController *mSerieController;
	IBOutlet NSArrayController *mPointController;
	IBOutlet NSWindow *mDocumentWindow;
	IBOutlet NSView *mToolView;
	IBOutlet NSView *mZoomView;
	IBOutlet NSView *mImageFractionView;
	IBOutlet NSView *mToleranceView;
	IBOutlet NSView *mSpacingView;
	IBOutlet NSView *mMaxNumberView;
	IBOutlet NSView *mBrushSizeView;
	IBOutlet NSDrawer *mPaletteDrawer;
	IBOutlet NSDrawer *mInfoDrawer;
	IBOutlet NSTableView *mDataSetTableView;
	
	IBOutlet NSWindow *mSortSheet;
	IBOutlet id mSortCoordinate;
	IBOutlet id mSortOrder;
	
	NSDictionary *mLoadedDocumentParameters;
	NSDictionary *mLoadedViewParameters;
	BOOL mActive;
	
	IBOutlet NSWindow *mExportSettingsWindow;
	
	BOOL mIgnoreImageUndo;
	
	NSData *infoTextViewData;
	NSString *lastExportLocation;
}

+(NSImage *)defaultImage;

// Decodes the root dictionary of a GraphClick document, transparently handling
// both the current keyed-archive format and the legacy NSArchiver format used
// by GraphClick 3.0.x and earlier. Returns nil and fills outError on failure.
+(NSDictionary *)documentDictionaryFromData:(NSData *)inData error:(NSError **)outError;

-(GCView *)view;
-(NSWindow *)mainWindow;
-(NSArray *)selectedSeries;

-(IBAction)updateView:(id)inSender;
-(IBAction)renameDataSets:(id)inSender;

@end

@interface GCDocument (Sorting)

-(IBAction)sortSerie:(id)inSender;
-(IBAction)confirmSort:(id)inSender;
-(IBAction)cancelSort:(id)inSender;

@end

@interface GCDocument (Export)

-(IBAction)exportSerie:(id)inSender;
-(IBAction)cancelExport:(id)inSender;
-(IBAction)confirmExport:(id)inSender;

@end

@interface GCDocument (ActiveDocument)

+(GCDocument *)activeDocument;
-(void)becomesActive;
-(void)becomesInactive;

@end

@interface GCDocument (Undo)

-(void)prepareUndo;
-(void)finishUndo;

@end

@interface GCDocument (Transparency)

-(BOOL)transparent;
-(void)setTransparent:(BOOL)inTransparent;

@end

@interface GCImageDocument : NSDocument

@end

@interface GCMovieDocument : NSDocument

@end
