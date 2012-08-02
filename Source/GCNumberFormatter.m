//
//  GCNumberFormatter.m
//  GraphClick
//
//  Created by Simon Bovet on 19.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GCNumberFormatter.h"
#import "GCFoundation.h"

@implementation GCNumberFormatter

+(id)sharedFormatter
{
	static id formatter = nil;
	if (!formatter)
		formatter = [[self alloc] init];
	return formatter;
}

-(int)numberOfDigits
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:GCNumberNumberOfDigits];
}

-(BOOL)useScientificNotationWithExponent:(int)inExponent
{
	switch ([[NSUserDefaults standardUserDefaults] integerForKey:GCNumberScientificNotation]) {
		case GCNumberScientificNotationAlways:
			return YES;
		case GCNumberScientificNotationConditional:
			return abs(inExponent) >= [[NSUserDefaults standardUserDefaults] integerForKey:GCNumberScientificNotationFrom]
							|| inExponent < -[self numberOfDigits];
		case GCNumberScientificNotationNever:
		default:
			return NO;
	}
}

-(NSString *)undefinedString
{
    return NSLocalizedString(@"undefined number placeholder", @"");
}

-(BOOL)removeTrailingZeros
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:GCNumberRemoveTrailingZeros];
}

-(NSString *)decimalSeparator
{
	switch ([[NSUserDefaults standardUserDefaults] integerForKey:GCNumberDecimalSeparator]) {
		case 1:
			return @".";
		case 2:
			return @",";
		default:
			return [[NSUserDefaults standardUserDefaults] objectForKey:NSDecimalSeparator];
	}
}

-(NSString *)stringForObjectValue:(id)inObject
{
	if ([inObject respondsToSelector:@selector(floatValue)])
		return [self stringForFloat:[inObject floatValue]];
	else
		return nil;
}

-(NSString *)stringForFloat:(float)inValue
{
	float value = inValue;
    if (!isdefined(value))
		return [self undefinedString];
		
/*    if (fabs(value) < 1e-15)
        value = 0; */
	int digits = [self numberOfDigits];
        
    NSMutableString *string = [NSMutableString string];
    int exponent = value == 0 ? 0 : floor(log10(fabs(value)));
    BOOL scientificNotation = [self useScientificNotationWithExponent:exponent];
    float mantissa = value;
	if (scientificNotation) {
		mantissa = value * pow(10, -exponent);
		if (fabs(mantissa) >= 10.0 - 0.5 * pow(10.0, -(float)digits))
			exponent++, mantissa /= 10.0;
    }
    NSString *format = [NSString stringWithFormat:@"%%.%if", digits];
    [string setString:[NSString stringWithFormat:format, mantissa]];
    NSString *decimalSeparator = [self decimalSeparator];
    if (!decimalSeparator)
        decimalSeparator = @".";
    if (![decimalSeparator isEqual:@"."])
        [string replaceOccurrencesOfString:@"." withString:decimalSeparator options:0 range:NSMakeRange(0, [string length])];

	if ([self removeTrailingZeros]) {
		unsigned last = [string length];
		while ([string characterAtIndex:last - 1] == '0')
			last--;
		[string deleteCharactersInRange:NSMakeRange(last, [string length] - last)];
	}

	if ([string hasSuffix:decimalSeparator]) {
		NSRange range;
		range.length = [decimalSeparator length];
		range.location = [string length] - range.length;
		[string deleteCharactersInRange:range];
	}

    if (scientificNotation)
        [string appendString:[NSString stringWithFormat:@"e%i", exponent]];
	
	return string;
}

@end

@implementation GCTimeFormatter

+(id)sharedFormatter
{
	static id formatter = nil;
	if (!formatter)
		formatter = [[self alloc] init];
	return formatter;
}

-(int)numberOfDigits
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:GCNumberTimeValueNumberOfDigits];
}

-(BOOL)removeTrailingZeros
{
	return NO;
}

-(NSString *)stringForFloat:(float)inValue
{
	return [NSString stringWithFormat:@"%@ s", [super stringForFloat:inValue]];
}

@end
