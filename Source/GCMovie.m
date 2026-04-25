//
//  GCMovie.m
//  GraphClick
//

#import "GCMovie.h"

#import <AVFoundation/AVFoundation.h>

@implementation GCMovie

-(id)initWithURL:(NSURL *)inURL
{
	self = [super init];
	if (!self)
		return nil;
	if (!inURL)
		goto fail;

	AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inURL options:nil];
	if (!asset || ![[asset tracksWithMediaType:AVMediaTypeVideo] count])
		goto fail;

	mURL = [inURL retain];
	mAsset = [asset retain];
	mImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:mAsset];
	mImageGenerator.appliesPreferredTrackTransform = YES;
	mImageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
	mImageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
	mPosterTime = 0.0;
	return self;

fail:
	[self release];
	return nil;
}

-(void)dealloc
{
	[mImageGenerator release];
	[mAsset release];
	[mURL release];
	[super dealloc];
}

-(NSURL *)URL
{
	return mURL;
}

-(float)duration
{
	return (float)CMTimeGetSeconds([mAsset duration]);
}

-(NSImage *)imageAtTime:(float)inTime
{
	if (!mImageGenerator)
		return nil;
	CMTime time = CMTimeMakeWithSeconds(inTime, 600);
	CGImageRef cgImage = [mImageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
	if (!cgImage)
		return nil;
	NSSize size = NSMakeSize(CGImageGetWidth(cgImage), CGImageGetHeight(cgImage));
	NSImage *image = [[[NSImage alloc] initWithCGImage:cgImage size:size] autorelease];
	CGImageRelease(cgImage);
	return image;
}

-(NSImage *)imageAtTimeFromPoster:(float)inTime
{
	return [self imageAtTime:inTime + mPosterTime];
}

-(float)posterTime
{
	return mPosterTime;
}

-(void)setPosterTime:(float)inTime
{
	mPosterTime = inTime;
}

#pragma mark NSCoding

-(id)initWithCoder:(NSCoder *)coder
{
	NSURL *url = [coder decodeObjectOfClass:[NSURL class] forKey:@"URL"];
	float posterTime = [coder decodeFloatForKey:@"PosterTime"];
	self = [self initWithURL:url];
	if (self)
		mPosterTime = posterTime;
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:mURL forKey:@"URL"];
	[coder encodeFloat:mPosterTime forKey:@"PosterTime"];
}

+(BOOL)supportsSecureCoding
{
	return YES;
}

@end
