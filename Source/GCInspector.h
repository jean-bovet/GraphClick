//
//  GCInspector.h
//  GraphClick
//
//  Created by Simon Bovet on 13.01.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define GCSelectedSerieDidChangeNotification @"GCSelectedSerieDidChangeNotification"

@class GCDocument;

@interface GCInspector : NSWindowController <NSWindowDelegate> {
	IBOutlet NSObjectController *mDocumentController;
	IBOutlet NSTabView *mTabView;
	
	int mSelectedView;
}

+(NSMutableArray *)inspectors;

+(id)inspectorWithState:(id)inState;
-(id)initWithState:(id)inState;

-(NSPoint)origin;
-(void)updateDocument;
-(void)updateInspectorSize:(BOOL)inAnimate;

@end

@interface GCInspector (Public)

+(void)loadInspectors;

+(BOOL)isVisible;
+(void)show;
+(void)hide;

+(void)newInspector;

@end

@interface GCInspectorTitleTransformer : NSValueTransformer

@end