//
//  GCNumberFormatter.h
//  GraphClick
//
//  Created by Simon Bovet on 19.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define GCNumberNumberOfDigits @"GCNumberNumberOfDigits"
#define GCNumberTimeValueNumberOfDigits @"GCNumberTimeValueNumberOfDigits"
#define GCNumberScientificNotation @"GCNumberScientificNotation"
#define GCNumberScientificNotationFrom @"GCNumberScientificNotationFrom"
#define GCNumberRemoveTrailingZeros @"GCNumberRemoveTrailingZeros"
#define GCNumberDecimalSeparator @"GCNumberDecimalSeparator"

enum {
	GCNumberScientificNotationNever = -1,
	GCNumberScientificNotationConditional = 0,
	GCNumberScientificNotationAlways = 1
};

@interface GCNumberFormatter : NSFormatter {

}

+(id)sharedFormatter;
-(NSString *)stringForFloat:(float)inValue;

@end

@interface GCTimeFormatter : GCNumberFormatter {
}

+(id)sharedFormatter;
-(NSString *)stringForFloat:(float)inValue;

@end
