//
//  ThresholdFilter.m
//  GraphClick
//
//  Created by Simon Bovet on 21.08.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ThresholdFilter.h"


@implementation ThresholdFilter

static CIKernel *_thresholdKernel = nil;

-(id)init
{
    if (!_thresholdKernel) {
        NSBundle *bundle = [NSBundle bundleForClass:NSClassFromString(@"ThresholdFilter")];
        NSString *code = [NSString stringWithContentsOfFile:[bundle pathForResource:@"threshold" ofType:@"cikernel"]];
        NSArray *kernels = [CIKernel kernelsWithString:code];
        _thresholdKernel = [[kernels objectAtIndex:0] retain];
    }
    return [super init];
}


-(NSDictionary *)customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:

        [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithDouble:0.00], kCIAttributeMin,
            [NSNumber numberWithDouble:1.00], kCIAttributeMax,
            [NSNumber numberWithDouble:0.00], kCIAttributeSliderMin,
            [NSNumber numberWithDouble:1.00], kCIAttributeSliderMax,
            [NSNumber numberWithDouble:0.50], kCIAttributeDefault,
            [NSNumber numberWithDouble:1.00], kCIAttributeIdentity,
            kCIAttributeTypeScalar, kCIAttributeType,
            nil],                               @"inputThreshold",

        nil];
}

-(CGRect)thresholdROI:(int)inSampler forRect:(CGRect)inRect userInfo:(void *)inUserInfo
{
	return inRect;
}

-(CIImage *)outputImage
{
    CISampler *src = [CISampler samplerWithImage:inputImage];
    float threshold = [inputThreshold floatValue];
    [_thresholdKernel setROISelector:@selector(thresholdROI:forRect:userInfo:)];
    CIImage *thresholdedImage = [self apply:_thresholdKernel, src, [NSNumber numberWithFloat:threshold], nil];
	return thresholdedImage;
}

@end
