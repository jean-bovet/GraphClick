//
//  main.m
//  GraphClick
//
//  Created by Simon Bovet on 02.12.04.
//  Copyright __MyCompanyName__ 2004 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GCApplicationDelegate.h"

int main(int argc, char *argv[])
{
    // Force-reference GCApplicationDelegate so modern linker dead-stripping
    // doesn't drop the nib-only-referenced NSDocumentController subclass.
    (void)[GCApplicationDelegate class];
    return NSApplicationMain(argc, (const char **) argv);
}
