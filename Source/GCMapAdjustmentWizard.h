//
//  GCMapAdjustmentWizard.h
//  GraphClick
//
//  Created by Simon Bovet on 25.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GCAdjustmentWizard.h"
#import "GCCustomProjection.h"

@interface GCMapAdjustmentWizard : GCAdjustmentWizard {
}

@end

@interface GCMapProjection : GCCustomProjection {
	NSSize mViewSize;
}

@end


@interface GCGenericMapProjectionWizard : GCMapAdjustmentWizard {

}

@end

@interface GCGenericMapProjection : GCMapProjection

@end


@interface GCMercatorProjectionWizard : GCMapAdjustmentWizard {
	BOOL mCollapsedCoordinates;
}

@end

@interface GCMercatorProjection : GCMapProjection

@end

@interface GCObliqueMercatorProjectionWizard : GCGenericMapProjectionWizard {
}

@end

@interface GCObliqueMercatorProjection : GCGenericMapProjection

@end

@interface GCTransverseMercatorProjectionWizard : GCGenericMapProjectionWizard {
}

@end

@interface GCTransverseMercatorProjection : GCGenericMapProjection {
	float x0, lambda0, y0, phi0;
}

@end

@interface GCGnomonicProjectionWizard : GCGenericMapProjectionWizard {
}

@end

@interface GCGnomonicProjection : GCGenericMapProjection {
	float x0, lambda0, y0, phi1;
}

@end

