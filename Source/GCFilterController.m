//
//  GCFilterController.m
//  GraphClick
//
//  Created by Simon Bovet on 17.07.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GCFilterController.h"

#import "GCFoundation.h"

@interface GCFilterController (Private)

-(void)setFilterName:(NSString *)inName;
-(void)updateOutputImage;

@end

@implementation GCFilterController

+(void)initialize
{
	[self setKeys:[NSArray arrayWithObject:@"filterName"] triggerChangeNotificationsForDependentKey:@"filterNameIndex"];
}

+(void)loadImageUnits
{
    [CIPlugIn loadAllPlugIns];
    NSArray *filterList = [CIFilter filterNamesInCategories:nil];
    if (![filterList containsObject:@"ThresholdFilter"]) {
		NSString *path = [[NSBundle mainBundle] pathForResource:@"ThresholdUnit" ofType:@"plugin"];
		if (path)
			[CIPlugIn loadPlugIn:[NSURL fileURLWithPath:path] allowNonExecutable:NO];
    }
    
    filterList = [CIFilter filterNamesInCategories:nil];
    if (![filterList containsObject:@"ThresholdFilter"]) {
		NSLog(@"*** Threshold Unit not installed! ***");
		[NSApp terminate:self];
    }
}

+(id)sharedController
{
	if ([NSApp systemVersion] >= 0x01040) {
		static id controller = nil;
		if (!controller) {
			[self loadImageUnits];
			controller = [[self alloc] init];
		}
		return controller;
	} else
		return nil;
}

-(id)init
{
	if (self = [super initWithWindowNibName:@"GCFilterController"]) {
		[self loadWindow];
		mFilters = [[NSMutableDictionary alloc] initWithCapacity:0];
		[self setFilterName:@"ThresholdFilter"];
	}
	return self;
}

-(void)dealloc
{
	[mFilters release];
	[mCropFilter release];
	[super dealloc];
}

-(void)updateFilterImages
{
	if (mInputImage) {
		[mFilter setValue:mInputImage forKey:@"inputImage"];
		[mCropFilter release];
		mCropFilter = [[CIFilter filterWithName:@"CICrop"] retain];
		CGRect r = [mInputImage extent];
		[mCropFilter setValue:[CIVector vectorWithX:r.origin.x Y:r.origin.y Z:r.size.width W:r.size.height] forKey:@"inputRectangle"];
		[mCropFilter setValue:[mFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
		[mView setCIImage:[mCropFilter valueForKey:@"outputImage"]];
	}
}

-(NSImage *)editImage:(NSImage *)inImage
{
	mInputImage = [CIImage imageWithData:[inImage TIFFRepresentation]];
	[self updateFilterImages];
	
	NSWindow *window = [self window];
	int returnCode = [NSApp runModalForWindow:window];
	[window orderOut:nil];
	[mView setCIImage:nil];
	
	NSImage *resultingImage = nil;
	if (returnCode == NSOKButton) {
		NSSize size = [inImage pixelSize];
		NSBitmapImageRep *bitmapImageRep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil pixelsWide:size.width pixelsHigh:size.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
		NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmapImageRep];
		[NSGraphicsContext saveGraphicsState];
		[NSGraphicsContext setCurrentContext:context];
		CIImage *outputCIImage = [mCropFilter valueForKey:@"outputImage"];
		[[context CIContext] drawImage:outputCIImage atPoint:CGPointZero fromRect:[outputCIImage extent]];
		[NSGraphicsContext restoreGraphicsState];
		
		NSImage *outputImage = [[[NSImage alloc] initWithSize:size] autorelease];
		[outputImage addRepresentation:bitmapImageRep];
		resultingImage = outputImage;
	}
	[mCropFilter release];
	mCropFilter = nil;
	return resultingImage;
}

-(NSArray *)availableFilterNames
{
	static NSArray *names = nil;
	if (!names)
		names = [[NSArray alloc] initWithObjects:@"ThresholdFilter", @"CIColorControls", @"CIEdges", @"CIGaussianBlur", @"CISharpenLuminance", @"CIExposureAdjust", @"CINoiseReduction", nil];
	return names;
}

-(NSString *)filterName
{
	return [[mFilter attributes] objectForKey:kCIAttributeFilterName];
}

-(int)filterNameIndex
{
	return [[self availableFilterNames] indexOfObject:[self filterName]];
}

-(void)setFilterName:(NSString *)inName
{
	mFilter = [mFilters objectForKey:inName];
	if (!mFilter) {
		mFilter = [CIFilter filterWithName:inName];
		[mFilter setDefaults];
		[mFilters setObject:mFilter forKey:inName];
		
		NSEnumerator *enumerator = [[mFilter inputKeys] objectEnumerator];
		id input;
		while (input = [enumerator nextObject])
			if (![input isEqual:@"inputImage"]) {
				[self willChangeValueForKey:input];
				[self didChangeValueForKey:input];
			}
	}
	[self updateFilterImages];
}

-(void)setFilterNameIndex:(int)inNameIndex
{
	[self setFilterName:[[self availableFilterNames] objectAtIndex:inNameIndex]];
}

-(id)valueForUndefinedKey:(NSString *)inKey
{
	return [mFilter valueForKey:inKey];
}

-(id)setValue:(id)inValue forUndefinedKey:(NSString *)inKey
{
	[mFilter setValue:inValue forKey:inKey];
	[self updateOutputImage];
}

-(void)updateOutputImage
{
	[mCropFilter setValue:[mFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
	[mView setCIImage:[mCropFilter valueForKey:@"outputImage"]];
}

@end

@implementation GCFilterController (Interface)

-(IBAction)cancel:(id)inSender
{
	[NSApp stopModalWithCode:NSCancelButton];
}

-(IBAction)ok:(id)inSender
{
	[NSApp stopModalWithCode:NSOKButton];
}

@end

@implementation GCCIImageView

-(void)dealloc
{
	[mImage release];
	[super dealloc];
}

-(void)setCIImage:(CIImage *)inImage
{
	if (mImage != inImage) {
		[mImage release];
		mImage = [inImage retain];
		[self setNeedsDisplay:YES];
	}
}

-(void)drawRect:(NSRect)inRect
{
	if (mImage) {
		NSSize boundsSize = [self bounds].size;
		CGSize imageSize = [mImage extent].size;
		float k = MIN(boundsSize.width / imageSize.width, boundsSize.height / imageSize.height);
		imageSize.width *= k;
		imageSize.height *= k;
		CGRect cg = CGRectMake((boundsSize.width - imageSize.width) / 2, (boundsSize.height - imageSize.height) / 2, imageSize.width, imageSize.height);
		CIContext *context = [[NSGraphicsContext currentContext] CIContext];
		[context drawImage:mImage inRect:cg fromRect:[mImage extent]];
	}
}

@end
