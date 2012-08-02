//
//  GCGeometryInspector.h
//  GraphClick
//
//  Created by Simon Bovet on 23.08.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GCDocument.h"
#import "GCSerie.h"

@interface GCGeometryInspector : NSWindowController {
	GCDocument *mDocument;
	GCSerie *mSerie;
}

-(void)awake;

-(void)pointDidChange;
-(void)serieDidChange;
-(void)documentDidChange;

-(void)displayLimitationTitle:(NSString *)inTitle message:(NSString *)inMessage;

@end

@interface GCGeometryInspector (Defaults)

+(void)loadInspector;
-(BOOL)isVisible;
-(void)setVisible:(BOOL)inVisible;
+(void)toggle;
+(BOOL)isVisible;
+(void)show;
+(void)hide;
-(void)saveInspectorState:(id)inSender;
-(id)position;
-(void)setPosition:(id)inPosition;

@end


@interface GCGeometryTableColumn : NSTableColumn {
	NSString *mBoundValue;
}

-(NSString *)boundValue;

@end
