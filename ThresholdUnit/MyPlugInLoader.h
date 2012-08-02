//
//  MyPlugInLoader.h
//  GraphClick
//
//  Created by Simon Bovet on 21.08.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/CoreImage.h>


@interface MyPlugInLoader : NSObject <CIPlugInRegistration> {

}

-(BOOL)load:(void *)inHost;

@end
