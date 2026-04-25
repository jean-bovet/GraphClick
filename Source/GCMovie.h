//
//  GCMovie.h
//  GraphClick
//
//  AVFoundation-backed replacement for the long-deprecated NSMovie.
//

#import <Cocoa/Cocoa.h>

@class AVAsset;
@class AVAssetImageGenerator;

@interface GCMovie : NSObject <NSCoding>
{
	NSURL *mURL;
	AVAsset *mAsset;
	AVAssetImageGenerator *mImageGenerator;
	float mPosterTime;
}

-(id)initWithURL:(NSURL *)inURL;

-(NSURL *)URL;

-(float)duration;

-(NSImage *)imageAtTime:(float)inTime;
-(NSImage *)imageAtTimeFromPoster:(float)inTime;

-(float)posterTime;
-(void)setPosterTime:(float)inTime;

@end
