//
//  GCHistogram.m
//  GraphClick
//
//  Created by Simon Bovet on 19.08.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GCHistogram.h"

#import "GCFoundation.h"
#import "GCView.h"

enum {
	kUnknownKind,
	kWhiteBackgroundKind,
	kBlackBackgroundKind
};

@implementation GCHistogram

-(unsigned long)computeHistogram:(unsigned long *)outHistogram length:(unsigned)inLength fromBitmapImageRep:(NSBitmapImageRep *)inImageRep
{
	unsigned i;
	for (i = 0; i < inLength; i++)
		outHistogram[i] = 0;

	int bpp;
	if ([inImageRep bitsPerPixel] == 32 && [inImageRep samplesPerPixel] == 4 && ![inImageRep isPlanar])
		bpp = 4;
	else if ([inImageRep bitsPerPixel] == 24 && [inImageRep samplesPerPixel] == 3 && ![inImageRep isPlanar])
		bpp = 3;
	else if ([inImageRep bitsPerPixel] == 8 && [inImageRep samplesPerPixel] == 1)
		bpp = 1;
	else
		return 0;

	int c, components = MIN(bpp, 3);
	int delta = bpp - components;
	int denom = components * 256 / inLength;
	unsigned char *data = [inImageRep bitmapData];
	int x, width = [inImageRep pixelsWide];
	int y = 0;
	for (y = 0; y < [inImageRep pixelsHigh]; y++) {
		unsigned char *src = data;
		for (x = 0; x < width; x++) {
			unsigned value = 0;
			for (c = 0; c < components; c++)
				value += *src++;
			src += delta;
			int index = value / denom;
			if (index < 0)
				index = 0;
			else if (index >= inLength)
				index = inLength - 1;
			outHistogram[index]++;
		}
		data += [inImageRep bytesPerRow];
	}
	
	return (unsigned long)[inImageRep pixelsHigh] * [inImageRep pixelsWide];
}

-(void)computeFromImage:(NSImage *)inImage
{
	if (inImage == mLastImage)
		return;
	mLastImage = inImage;
	mImageKind = kUnknownKind;

	if (inImage) {
		NSImageCacheMode cacheMode = [inImage cacheMode];
		[inImage setCacheMode:NSImageCacheNever];
		NSImage *image = [[[NSImage alloc] initWithSize:[inImage pixelSize]] autorelease];
		[image lockFocus];
		[[NSColor whiteColor] set];
		NSRect dest = NSZeroRect;
		dest.size = [image size];
		NSRectFill(dest);
		NSRect src = NSZeroRect;
		src.size = [inImage size];
		[inImage drawInRect:dest fromRect:src operation:NSCompositeSourceOver fraction:1.0];
		[image unlockFocus];
		[inImage setCacheMode:cacheMode];
		
		NSBitmapImageRep *imageRep = [[[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]] autorelease];
		
		const unsigned histogramLength = 256;
		static unsigned long *histogram = nil;
		if (!histogram)
			histogram = (unsigned long *)calloc(histogramLength, sizeof(unsigned long));

		unsigned long total = [self computeHistogram:histogram length:histogramLength fromBitmapImageRep:imageRep];
		unsigned long white = 0;
		unsigned long black = 0;
		unsigned i;
		for (i = 0; i < histogramLength / 4; i++) {
			black += histogram[i];
			white += histogram[histogramLength - 1 - i];
		}
		if (white > total / 2)
			mImageKind = kWhiteBackgroundKind;
		else if (black > total / 2)
			mImageKind = kBlackBackgroundKind;
#ifdef __DEBUG__
		NSLog(@"White: %0.1f%%\nBlack: %0.f%%", (float)white / total * 100, (float)black / total * 100);
#endif
		
		if (mImageKind != kUnknownKind) {
			unsigned long max = 0;
			unsigned long imax;
			for (i = 0; i < histogramLength; i++)
				if (histogram[i] > max) {
					max = histogram[i];
					imax = i;
				}
			mBackgroundLightness = (float)imax / (histogramLength - 1);
#ifdef __DEBUG__
			NSLog(@"Lightness: %f", mBackgroundLightness);
#endif
		}
	}
#ifdef __DEBUG__
	NSLog(@"Background: %@", mImageKind == kWhiteBackgroundKind ? @"White" : mImageKind == kBlackBackgroundKind ? @"Black" : @"?");
#endif
}

-(BOOL)isColor:(NSColor *)inColor backgroundOfImage:(NSImage *)inImage
{
	[self computeFromImage:inImage];
	if (mImageKind == kUnknownKind)
		return NO;
	float r, g, b, a;
	[inColor getRed:&r green:&g blue:&b alpha:&a];
	r = mBackgroundLightness - r, g = mBackgroundLightness - g, b = mBackgroundLightness - b;
	float distance = hypot(hypot(r, g), b) / sqrt(3.0);
	float threshold = MAX(1e-3, [[NSUserDefaults standardUserDefaults] floatForKey:GCMagicWandTolerance]);
	return distance < threshold;
}

-(NSColor *)backgroundColorOfImage:(NSImage *)inImage
{
	[self computeFromImage:inImage];
	return [NSColor colorWithCalibratedWhite:mImageKind == kUnknownKind ? 1.0 : mBackgroundLightness alpha:1.0];
}

@end
