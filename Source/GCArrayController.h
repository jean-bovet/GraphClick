//
//  GCArrayController.h
//  GraphClick
//
//  Created by Simon Bovet on 22.12.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#define GCArrayControllerWillRemove @"GCArrayControllerWillRemove"
#define GCArrayControllerDidRemove @"GCArrayControllerDidRemove"

@interface GCArrayController : NSArrayController <NSTableViewDataSource, NSTableViewDelegate> {
    IBOutlet NSTableView *mTableView;
}

@end

@interface GCArrayController (DragNDrop)

-(void)moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)inIndexSet
										toIndex:(unsigned int)inInsertIndex;
-(NSIndexSet *)indexSetFromRows:(NSArray *)inRows;
-(int)rowsAboveRow:(int)inRow inIndexSet:(NSIndexSet *)inIndexSet;
										
@end