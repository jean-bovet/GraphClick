//
//  GCView.h
//  GraphClick
//
//  Created by Simon Bovet on 02.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GCSerie.h"
#import "GCFrame.h"
#import "GCMovie.h"

#define GCImageWillChangeNotification @"GCImageWillChangeNotification"
#define GCImageDidChangeNotification @"GCImageDidChangeNotification"
#define GCSelectedPointsDidMoveNotification @"GCSelectedPointsDidMoveNotification"

#define GCUseMagnifyingGlass @"GCUseMagnifyingGlass"
#define GCMagicWandTolerance @"GCMagicWandTolerance"
#define GCMagicWandSpacing @"GCMagicWandSpacing"
#define GCMagicWandNumberOfPoints @"GCMagicWandNumberOfPoints"
#define GCMagicWandSpacingDefinition @"GCMagicWandSpacingDefinition"
#define GCMagicWandHorizontalOffset @"GCMagicWandHorizontalOffset"
#define GCMagicWandMaxNumberOfPoints @"GCMagicWandMaxNumberOfPoints"
#define GCMagicWandDynamic @"GCMagicWandDynamic"
#define GCMagicWandLineFinderSpacing @"GCMagicWandLineFinderSpacing"
#define GCMagicWandLineFinderExtremity @"GCMagicWandLineFinderExtremity"
#define GCMagicWandLineFinderRightToLeft @"GCMagicWandLineFinderRightToLeft"
#define GCFrameColor @"GCFrameColor"
#define GCFrameDotted @"GCFrameDotted"
#define GCFrameBackgroundOpacity @"GCFrameBackgroundOpacity"
#define GCFrameLabelled @"GCFrameLabelled"
#define GCMaskOpacity @"GCMaskOpacity"
#define GCMaskBrushSize @"GCMaskBrushSize"
#define GCAutoAdjustCoordinates @"GCAutoAdjustCoordinates"
#define GCBackgroundSelectionWarning @"GCBackgroundSelectionWarning"
#define GCMagnifyingGlassType @"GCMagnifyingGlassType"

@class GCGuide;
@class GCHistogram;
@class GCSnapGridController;
@class GCAdjustmentWizard;
@class GCCustomProjection;

typedef enum _GCTool {
	GCFrameTool = 0,
	GCAddPointTool = 1,
	GCHorizontalCurveTool = 2,
	GCAreaTool = 3,
	GCSelectTool = 4,
	GCDeformTool = 5,
	GCMaskBrushTool = 6,
	GCMaskRectangleTool = 7,
	GCMagicBarTool = 8,
	GCMaskEraseTool = 9,
	GCImageEraseTool = 10,
	GCMagicSymbolTool = 11,
	GCAreasTool = 12,
	GCCurveTool = 13,
	
	GCAdjustAbscissa1 = 100,
	GCAdjustAbscissa2,
	GCAdjustOrdinate1 = 110,
	GCAdjustOrdinate2,
	GCAdjustPosition1 = 120,
	GCAdjustPosition2,
	GCAdjustPositionB1 = 130,
	GCAdjustPositionB2,
	GCAdjustPositionB3,
	GCAdjust3Points1 = 200,
	GCAdjust3Points2,
	GCAdjust3Points3,
	GCAdjustAbscissaOrdinate1 = 210,
	GCAdjustAbscissaOrdinate2,
	GCAdjustAbscissaOrdinate3,
	GCAdjustAbscissaOrdinate4,
	GCAdjustOrigin = 220,
	GCAdjust4Points1 = 230,
	GCAdjust4Points2,
	GCAdjust4Points3,
	GCAdjust4Points4,
	GCAdjustScale1 = 300,
	GCAdjustScale2,
	GCAdjustWithWizard = 1000
} GCTool;

enum {
	GCImageDefaultType = 0,
	GCImageVerticalBarChartType = 1,
	GCImageHorizontalBarChartType = 2
};

enum {
	GCAreaType = 0,
	GCHorizontalCurveType = 1,
	GCBarType = 2,
	GCMagicSymbolType = 3,
	GCAreasType = 4,
	GCCurveType = 5
};

@interface GCView : NSView {
	IBOutlet NSArrayController *mSerieController;
	IBOutlet NSArrayController *mPointController;
	IBOutlet NSWindow *mMagicWandSheet;
	IBOutlet NSView *mMagicWandDetectionView;
	IBOutlet NSView *mMagicWandCurveParametersView;
	IBOutlet NSView *mMagicWandLineParametersView;
	IBOutlet NSView *mMagicWandBarParametersView;
	IBOutlet NSView *mMagicWandSymbolDetectionView;
	IBOutlet NSView *mMagicWandSymbolParametersView;
	IBOutlet NSView *mMagicWandAreaParametersView;
	IBOutlet NSImageView *mMagicWandSymbolImageView;
	IBOutlet NSWindow *mGuideSettingsWindow;
	IBOutlet id mGuidePreview;
	IBOutlet NSWindow *mAdjustCoordinateWindow;
	IBOutlet NSWindow *mCoordinatePromptWindow;
	IBOutlet NSTextField *mAbscissaPromptField;
	IBOutlet NSWindow *mScalePromptWindow;
	IBOutlet NSPopUpButton *mZoomPopUp;
	
	GCFrame *mFrame;
	BOOL mHideFrame;
	NSPoint mMagnificationLocation;
	BOOL mValidMagnificationLocation;
	BOOL mHideMagnifyingGlass;
	float mZoomFactor;
	NSRect mBounds;
	
	NSURL *mURL;
	
	NSImage *mImage;
	float mImageFraction;
	float mImageAngle;
	float mImageScale;
	NSColor *mFrameColor;
	
	GCHistogram *mHistogram;
	
	GCMovie *mMovie;
	float mTime;
	float mTimeStep;
	BOOL mDisplayTimeFrameOnly;
	BOOL mAutoStepForward;
	
	GCTool mSelectedTool;
	BOOL mScrollView;
	BOOL mModifyingFrame;
	BOOL mSymbolDetect[3][3];
	
	NSPoint mCoordinates;
	GCSerie *mInsertionSerie;
	unsigned mInsertionIndex;
	NSMutableIndexSet *mPointsToSelect;
	
	NSBezierPath *mSelectionPath;
	NSBezierPath *mMaskPath;
	NSBezierPath *mCoordinatePath;
	float mSelectionPathPhase;
	NSMutableArray *mFocusedPoints;
	
	BOOL mPreparingMagicWand;
	BOOL mMagicWandInProgress;
	int mMagicWandDynamicChangeCount;
	NSPoint mMagicWandPoint;
	NSRect mMagicWandBounds;
	float mMagicWandProgress;
	int mMagicWandType;
	BOOL mKeepOnMagicWand;
	NSMutableArray *mThreadedPointsToInsert;
	BOOL mMagicWandIndicator;
	BOOL mExceedingMaxNumberOfPoints;
	
	GCGuide *mGuide;
	
	GCTool mPreviousSelectedTool;
	NSPoint mPromptCoordinates;
	float mPromptLength;
	NSMutableDictionary *mPromptedPositions;
	NSMutableDictionary *mPromptedCoordinates;
	NSMutableDictionary *mPromptedOriginalCoordinates;
	BOOL mAdjustFramePosition;
	
	NSRect mRectBeingDrawn;
	
	float mLastFrameLimit[4];
	NSAttributedString *mFrameLabelString[4];
	NSSize mFrameLabelSize[4];
	
	NSMutableDictionary *mSpriteRects;
	
	NSImage *mMagicWandImage;
	NSBitmapImageRep *mMagicWandBitmapImageRep;
	int mMagicWandBPP;
	
	GCSnapGridController *mSnapGridController;
	int mSnapGridSpacing[2];
	int mSnapGridNumber[2];
	
	GCAdjustmentWizard *mAdjustmentWizard;
	GCCustomProjection *mPreviousCustomProjection;
}

-(GCFrame *)frameObject;
-(void)setFrameObject:(GCFrame *)inFrame;

-(GCSerie *)selectedSerie;
-(NSArray *)selectedSeries;

-(id)parameters;
-(void)setParameters:(id)inParameters afterLoading:(BOOL)inLoading;

@end

@interface GCView (MagnifyingGlass)

-(void)setMagnificationLocation:(NSPoint)inLocation;
-(void)removeMagnifyingGlass;

@end

@interface GCView (Focus)

-(void)focusElementsAtLocation:(NSPoint)inLocation;
-(NSRect)focusBounds;
-(void)drawFocusInRect:(NSRect)inRect withZoomFactor:(float)inZoom;
-(void)focusMouseDown:(NSEvent *)inEvent;

@end

@interface GCView (Zoom)

-(NSPoint)convertEventLocation:(NSEvent *)inEvent;
-(void)setZoomFactor:(float)inZoomFactor;
-(IBAction)resetZoomFactor:(id)inSender;
-(IBAction)selectZoomFactor:(id)inSender;

@end

@interface GCView (Tool)

-(int)selectedTool;
-(void)setSelectedTool:(int)inTool;

-(BOOL)hideFrame;
-(void)setHideFrame:(BOOL)inHide;

-(IBAction)selectFrameTool:(id)inSender;
-(IBAction)resetDefaultFrame:(id)inSender;
-(IBAction)adjustFrame:(id)inSender;

-(IBAction)toggleGuide:(id)inSender;
-(IBAction)editGuideSettings:(id)inSender;
-(IBAction)cancelGuideSettings:(id)inSender;
-(IBAction)confirmGuideSettings:(id)inSender;

@end

@interface GCView (URL)

-(BOOL)containsURL;
-(BOOL)setURL:(NSURL *)inURL;
-(void)removeURL;
-(void)reloadURL:(id)inSender;

@end

@interface GCView (Image)

-(BOOL)canPaste;
-(NSImage *)image;
-(void)setStillImage:(NSImage *)inImage;
-(void)setStillImageAsUser:(NSImage *)inImage;
-(void)setImage:(NSImage *)inImage;
-(void)setImage:(NSImage *)inImage adjustIfNeeded:(BOOL)inAdjust;
-(IBAction)adjustSizeToImage:(id)inSender;
-(IBAction)readjustCustomProjection:(id)inSender;

-(NSData *)imageData;
-(void)setImageData:(NSData *)inData;

-(IBAction)filterImage:(id)inSender;

@end

@interface GCView (Mask)

-(float)brushSize;

-(void)drawMaskWithZoomFactor:(float)inZoom;
-(void)maskBrushMouseDown:(NSEvent *)inEvent kind:(int)inKind;
-(void)maskRectangleMouseDown:(NSEvent *)inEvent;

@end

@interface GCView (Size)

-(void)setSize:(NSSize)inSize;

@end

@interface GCView (Movie)

-(BOOL)containsMovie;
-(void)setMovie:(GCMovie *)inMovie;
-(void)setMovieAsUser:(GCMovie *)inMovie;
-(float)time;
-(void)setTime:(float)inTime;
-(void)setTime:(float)inTime wait:(BOOL)inWait;
-(float)minTime;
-(float)maxTime;
-(float)timeStep;
-(void)setTimeStep:(float)inTimeStep;
-(BOOL)displayTimeFrameOnly;
-(void)setDisplayTimeFrameOnly:(BOOL)inFlag;
-(BOOL)autoStepForward;
-(void)setAutoStepForward:(BOOL)inFlag;

-(IBAction)stepBack:(id)inSender;
-(IBAction)stepForward:(id)inSender;
-(IBAction)stepForward:(id)inSender wait:(BOOL)inWait;

-(IBAction)gotoOriginFrame:(id)inSender;
-(IBAction)setOriginFrame:(id)inSender;

@end

@interface GCView (AdjustCoordinates)

-(void)adjustCoordinates;
-(IBAction)startCoordinateAdjustment:(id)inSender;

-(IBAction)confirmCoordinatePrompt:(id)inSender;
-(IBAction)cancelCoordinatePrompt:(id)inSender;

@end

@interface GCView (GuideLines)

-(IBAction)addHorizontalGuideLine:(id)inSender;
-(IBAction)addVerticalGuideLine:(id)inSender;
-(IBAction)removeGuideLines:(id)inSender;

-(void)focusGuideLine:(GCGuideLine *)inGuideLine mouseDown:(NSEvent *)inEvent;

@end

@interface GCView (Grid)

-(NSArray *)snapGridParameterKeys;
-(NSPoint)snapPointToGrid:(NSPoint)inPoint;

-(IBAction)editSnapGrid:(id)inSender;

@end

@interface GCView (Pasteboard)

-(BOOL)canCopy;
-(void)copy:(id)inSender;
-(BOOL)canPastePoints;
-(void)pastePoints:(id)inSender;
-(BOOL)canPasteCoordinates;
-(void)pasteCoordinates:(id)inSender;

@end

