//
//  GCFilterController.h
//  GraphClick
//
//  Created by Simon Bovet on 17.07.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <Quartz/Quartz.h>

@class GCCIImageView;

@interface GCFilterController : NSWindowController {
	IBOutlet GCCIImageView *mView;
	NSMutableDictionary *mFilters;
	CIFilter *mFilter;
	CIImage *mInputImage;
	CIFilter *mCropFilter;
}

+(id)sharedController;

-(NSImage *)editImage:(NSImage *)inImage;

@end

@interface GCFilterController (Interface)

-(IBAction)cancel:(id)inSender;
-(IBAction)ok:(id)inSender;

@end

@interface GCCIImageView : NSView {
	CIImage *mImage;
}

-(void)setCIImage:(CIImage *)inImage;

@end
