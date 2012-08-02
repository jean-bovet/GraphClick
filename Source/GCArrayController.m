//
//  GCArrayController.m
//  GraphClick
//
//  Created by Simon Bovet on 22.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GCArrayController.h"


@implementation GCArrayController

-(void)remove:(id)inSender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GCArrayControllerWillRemove object:[self content]];
	[super remove:inSender];
	[[NSNotificationCenter defaultCenter] postNotificationName:GCArrayControllerDidRemove object:[self content]];
}

@end

@implementation GCArrayController (DragNDrop)

NSString *GCMovedRowsType = @"GCMovedRowsType";

-(void)awakeFromNib
{
    [mTableView registerForDraggedTypes:[NSArray arrayWithObject:GCMovedRowsType]];
	[mTableView setDataSource:self];
	[mTableView setDelegate:self];
}

-(BOOL)tableView:(NSTableView *)inTableView
		writeRows:(NSArray*)inRows
	 toPasteboard:(NSPasteboard*)inPboard
{
	[inPboard declareTypes:[NSArray arrayWithObject:GCMovedRowsType] owner:self];
    [inPboard setPropertyList:inRows forType:GCMovedRowsType];
	return YES;
}

-(NSDragOperation)tableView:(NSTableView*)inTableView
				validateDrop:(id <NSDraggingInfo>)inInfo
				 proposedRow:(int)inRow
	   proposedDropOperation:(NSTableViewDropOperation)inOperation
{
    [inTableView setDropRow:inRow dropOperation:NSTableViewDropAbove];
    return [inInfo draggingSource] == mTableView ? NSDragOperationMove : NSDragOperationNone;
}



- (BOOL)tableView:(NSTableView*)inTableView
	   acceptDrop:(id <NSDraggingInfo>)inInfo
			  row:(int)inRow
	dropOperation:(NSTableViewDropOperation)inOperation
{
	int row = MAX(0, inRow);
    
    if ([inInfo draggingSource] == mTableView) {
		NSArray *rows = [[inInfo draggingPasteboard] propertyListForType:GCMovedRowsType];
		NSIndexSet  *indexSet = [self indexSetFromRows:rows];
		
		[self moveObjectsInArrangedObjectsFromIndexes:indexSet toIndex:row];
		
		// set selected rows to those that were just moved
		// Need to work out what moved where to determine proper selection...
		int rowsAbove = [self rowsAboveRow:row inIndexSet:indexSet];
		
		NSRange range = NSMakeRange(row - rowsAbove, [indexSet count]);
		indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
		[self setSelectionIndexes:indexSet];
		
		return YES;
    }
	
    return NO;
}


-(void)moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)inIndexSet
										toIndex:(unsigned int)inInsertIndex
{
    NSArray *objects = [self arrangedObjects];
	
    int aboveInsertIndexCount = 0;
    int removeIndex;
	int insertIndex = inInsertIndex;
	
	int index = [inIndexSet lastIndex];
    while (index != NSNotFound) {
		if (index >= insertIndex) {
			removeIndex = index + aboveInsertIndexCount;
			aboveInsertIndexCount++;
		} else {
			removeIndex = index;
			insertIndex--;
		}
		[self insertObject:[objects objectAtIndex:removeIndex] atArrangedObjectIndex:insertIndex + (removeIndex < insertIndex ? 1 : 0)];
		[self removeObjectAtArrangedObjectIndex:removeIndex + (removeIndex >= insertIndex ? 1 : 0)];
		
		index = [inIndexSet indexLessThanIndex:index];
    }
}

-(NSIndexSet *)indexSetFromRows:(NSArray *)inRows
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    NSEnumerator *rowEnumerator = [inRows objectEnumerator];
    NSNumber *idx;
    while (idx = [rowEnumerator nextObject])
		[indexSet addIndex:[idx intValue]];
    return indexSet;
}


-(int)rowsAboveRow:(int)inRow inIndexSet:(NSIndexSet *)inIndexSet
{
    unsigned currentIndex = [inIndexSet firstIndex];
    int i = 0;
    while (currentIndex != NSNotFound) {
		if (currentIndex < inRow)
			i++;
		currentIndex = [inIndexSet indexGreaterThanIndex:currentIndex];
    }
    return i;
}

-(void)setSortDescriptors:(NSArray *)inSortDescriptors
{
}

@end