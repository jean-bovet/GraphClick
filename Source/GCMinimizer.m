//
//  GCMinimizer.m
//  GraphClick
//
//  Created by Simon Bovet on 27.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GCMinimizer.h"

#include "powell.h"

@implementation GCMinimizer

-(void)dealloc
{
	[mDataSource release];
	[super dealloc];
}

-(id)dataSource
{
	return mDataSource;
}

-(void)setDataSource:(id)inDataSource
{
	if (mDataSource != inDataSource) {
		[mDataSource release];
		mDataSource = [inDataSource retain];
	}
}

-(float)tolerance
{
	return 1e-8;
}

-(float)evaluate:(float *)inParameters
{
	return [[self dataSource] minimizer:self evaluationWithParameters:inParameters];
}

static GCMinimizer *sMinimizer = nil;

float minimizerEvaluation(float p[])
{
	return [sMinimizer evaluate:p + 1];
}

-(BOOL)minimize
{
	int n = [[self dataSource] numberOfParametersForMinimizer:self];
	float *p = vector(1, n);
	float **xi = matrix(1, n, 1, n);
	int i, j;
	for (i = 1; i <= n; i++) {
		p[i] = [[self dataSource] minimizer:self valueOfParameterAtIndex:i - 1];
		for (j = 1; j <= n; j++)
			xi[i][j] = i == j ? 1.0 : 0.0;
	}
	float ftol = [self tolerance];
	int iter;
	float min;
	
	BOOL ok = NO;
	sMinimizer = self;
	NS_DURING
		powell(p, xi, n, ftol, &iter, &min, minimizerEvaluation);
		ok = YES;
	NS_HANDLER
		if ([[self dataSource] respondsToSelector:@selector(minimizer:failedWithException:)])
			[[self dataSource] minimizer:self failedWithException:localException];
		else
			NSLog(@"*** Minimizer failed with exception: %@", localException);
	NS_ENDHANDLER

	for (i = 1; i <= n; i++)
		NSLog(@"p[%i] = %f", i, p[i]);
	if (ok && [[self dataSource] respondsToSelector:@selector(minimizer:succeededWithParameters:minimum:numberOfIterations:)])
		[[self dataSource] minimizer:self succeededWithParameters:p + 1 minimum:min numberOfIterations:iter];
	
	free_vector(p, 1, n);
	free_matrix(xi, 1, n, 1, n);
	
	return ok;
}

@end
