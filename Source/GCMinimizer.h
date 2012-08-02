//
//  GCMinimizer.h
//  GraphClick
//
//  Created by Simon Bovet on 27.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GCMinimizer : NSObject {
	id mDataSource;
}

-(void)setDataSource:(id)inDataSource;
-(BOOL)minimize;

@end

@protocol GCMinimizerDataSource

-(int)numberOfParametersForMinimizer:(GCMinimizer *)inMinizer;
-(float)minimizer:(GCMinimizer *)inMinizer valueOfParameterAtIndex:(int)inIndex;
-(float)minimizer:(GCMinimizer *)inMinizer evaluationWithParameters:(float *)inParameters;

-(void)minimizer:(GCMinimizer *)inMinizer failedWithException:(NSException *)inException;
-(void)minimizer:(GCMinimizer *)inMinizer succeededWithParameters:(float *)inParameters minimum:(float)inMinimum numberOfIterations:(int)inIterations;

@end