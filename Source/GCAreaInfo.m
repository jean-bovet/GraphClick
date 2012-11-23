//
//  GCAreaInfo.m
//  GraphClick
//
//  Created by Simon Bovet on 23.08.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "GCAreaInfo.h"

#import "GCFoundation.h"
#import "GCNumberFormatter.h"

@interface GCDocument (Private)

-(GCFrame *)frame;

@end

@implementation GCAreaInfo

+(id)sharedInspector
{
	static id sharedInspector = nil;
	if (!sharedInspector)
		sharedInspector = [[self alloc] init];
	return sharedInspector;
}

-(void)updateSeries
{
	[self willChangeValueForKey:@"series"];
	[self didChangeValueForKey:@"series"];
}

-(void)documentDidChange
{
	[super documentDidChange];
	[self updateSeries];
}

-(void)invalidateCurrentSerie
{
	NSArray *series = [mDocument selectedSeries];
	[series makeObjectsPerformSelector:@selector(invalidateAreaParameters)];
}

-(void)serieDidChange
{
	[super serieDidChange];
	[self invalidateCurrentSerie];
	[self updateSeries];
}

-(void)pointDidChange
{
	[super pointDidChange];
	[self invalidateCurrentSerie];
	[self updateSeries];
}

-(NSArray *)series
{
	NSMutableArray *array = [NSMutableArray array];
	NSEnumerator *enumerator = [[[mDocument frame] series] objectEnumerator];
	GCSerie *serie;
	while (serie = [enumerator nextObject])
		if ([serie definesArea])
			[array addObject:serie];
	return array;
}

-(IBAction)copy:(id)inSender
{
	NSArray *columns = [mTableView tableColumns];
	if ([mTableView numberOfSelectedColumns] > 0)
		columns = [columns subarrayWithIndexes:[mTableView selectedColumnIndexes]];
	
	NSArray *rows = [mArrayController selectedObjects];
	if ([rows count] == 0)
		rows = [mArrayController arrangedObjects];
	
	NSMutableString *string = [NSMutableString string];
	GCNumberFormatter *formatter = [GCNumberFormatter sharedFormatter];

	NSEnumerator *columnEnumerator = [columns objectEnumerator];
	GCGeometryTableColumn *column;
	BOOL hasContent = NO;
	while (column = [columnEnumerator nextObject]) {
		hasContent = YES;
		[string appendString:[[column headerCell] stringValue]];
		[string appendString:[NSString columnSeparator]];
	}
	if (hasContent) {
		int l = [[NSString columnSeparator] length];
		[string replaceCharactersInRange:NSMakeRange([string length] - l, l) withString:[NSString lineSeparator]];

		BOOL unregistered = NO; //![[ARRegisterManager sharedManager] hasRegisteredApplication];
		int count = 0;
		NSEnumerator *rowEnumerator = [rows objectEnumerator];
		id row;
		while (row = [rowEnumerator nextObject]) {
			NSEnumerator *columnEnumerator = [columns objectEnumerator];
			GCGeometryTableColumn *column;
			while (column = [columnEnumerator nextObject]) {
				id value = [row valueForKey:[column boundValue]];
				if (![value isKindOfClass:[NSString class]]) {
					if ([[column identifier] isEqual:@"Number"])
						value = [NSString stringWithFormat:@"%i", [value intValue]];
					else {
						value = [formatter stringForFloat:[value floatValue]];                        
                    }
                }
				[string appendFormat:@"%@%@", value, [NSString columnSeparator]];
			}
			int l = [[NSString columnSeparator] length];
			[string replaceCharactersInRange:NSMakeRange([string length] - l, l) withString:[NSString lineSeparator]];

			if (unregistered && ++count == 2) {
				[self displayLimitationTitle:NSLocalizedString(@"Unregistered Area Alert Title", @"")
					message:NSLocalizedString(@"Unregistered Area Alert Message", @"")];
				break;
			}
		}
	}
	
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[pasteboard setString:string forType:NSStringPboardType];
}

@end
