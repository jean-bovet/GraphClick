//
//  GCDocumentLegacyFormatTests.m
//  GraphClick
//
//  Verifies that GraphClick can still open documents saved in the legacy
//  NSArchiver "typedstream" format (GraphClick 3.0.x and earlier), in addition
//  to the current NSKeyedArchiver format. Regression coverage for the modern
//  build switching to NSKeyedUnarchiver, which cannot read the old format.
//

#import <XCTest/XCTest.h>
#import "GCDocument.h"
#import "GCFrame.h"
#import "GCGuide.h"
#import "GCFoundation.h"

@interface GCDocumentLegacyFormatTests : XCTestCase
@end

@implementation GCDocumentLegacyFormatTests

// A keyed archive (current format) must decode back to the same dictionary.
- (void)testReadsCurrentKeyedArchiveFormat
{
	NSDictionary *original = @{ @"Frame": @"placeholder", @"ViewParameters": @{ @"ZoomFactor": @2 } };
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:original];

	NSError *error = nil;
	NSDictionary *decoded = [GCDocument documentDictionaryFromData:data error:&error];

	XCTAssertNotNil(decoded, @"keyed archive should decode, error: %@", error);
	XCTAssertEqualObjects(decoded, original);
}

// A legacy NSArchiver typedstream must decode via the NSUnarchiver fallback.
// This is the exact format of files like map9.gc that the keyed unarchiver rejects.
- (void)testReadsLegacyNSArchiverFormat
{
	NSDictionary *original = @{ @"Frame": @"placeholder", @"ViewParameters": @{ @"ZoomFactor": @2 } };
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	NSData *data = [NSArchiver archivedDataWithRootObject:original];
#pragma clang diagnostic pop

	// Sanity: the keyed unarchiver alone cannot read this — that is the bug we
	// work around. Depending on the input it either throws or returns nil; in
	// neither case does it reconstruct the original dictionary.
	id keyedOnly = nil;
	@try {
		keyedOnly = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	} @catch (NSException *expected) {
		keyedOnly = nil;
	}
	XCTAssertNotEqualObjects(keyedOnly, original,
							 @"legacy typedstream should not be readable by NSKeyedUnarchiver alone");

	NSError *error = nil;
	NSDictionary *decoded = [GCDocument documentDictionaryFromData:data error:&error];

	XCTAssertNotNil(decoded, @"legacy archive should decode via fallback, error: %@", error);
	XCTAssertEqualObjects(decoded, original);
}

// Truly unreadable data must fail cleanly (nil + error), not crash.
- (void)testRejectsCorruptData
{
	NSData *garbage = [@"this is not an archive" dataUsingEncoding:NSUTF8StringEncoding];
	NSError *error = nil;
	NSDictionary *decoded = [GCDocument documentDictionaryFromData:garbage error:&error];

	XCTAssertNil(decoded);
	XCTAssertNotNil(error);
}

// Opens the real legacy document fixture end-to-end through the document's own
// read path, exercising decoding of the actual GCFrame/GCSerie/GCPoint/GCGuide
// objects. Skips if no fixture is present (the fixture is gitignored — drop a
// .gc file into Tests/Fixtures/ to enable this).
- (void)testOpensLegacyFixtureDocument
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	// Fixtures are bundled as a folder reference, so they live under Fixtures/.
	NSArray *fixtures = [bundle pathsForResourcesOfType:@"gc" inDirectory:@"Fixtures"];
	if (fixtures.count == 0)
		fixtures = [bundle pathsForResourcesOfType:@"gc" inDirectory:nil];
	if (fixtures.count == 0) {
		XCTSkip(@"No .gc fixture bundled; add one to Tests/Fixtures/ to run this test.");
		return;
	}

	for (NSString *path in fixtures) {
		NSData *data = [NSData dataWithContentsOfFile:path];
		XCTAssertNotNil(data, @"could not read fixture %@", path);

		// Decode the root dictionary directly.
		NSError *error = nil;
		NSDictionary *dictionary = [GCDocument documentDictionaryFromData:data error:&error];
		XCTAssertNotNil(dictionary, @"fixture %@ failed to decode: %@", path.lastPathComponent, error);
		XCTAssertTrue([dictionary[@"Frame"] isKindOfClass:[GCFrame class]],
					  @"fixture %@ should contain a GCFrame", path.lastPathComponent);

		// The view parameters embed the guide as a nested archive blob, which is
		// also legacy-encoded in old documents and must decode via the fallback.
		NSData *guideData = dictionary[@"ViewParameters"][@"Guide"];
		if ([guideData isKindOfClass:[NSData class]])
			XCTAssertTrue([[guideData gcUnarchivedRootObject] isKindOfClass:[GCGuide class]],
						  @"nested Guide blob in %@ should decode to a GCGuide", path.lastPathComponent);

		// And drive the full document read path the app actually uses.
		GCDocument *document = [[GCDocument alloc] init];
		error = nil;
		BOOL ok = [document readFromData:data ofType:@"GraphClick Document" error:&error];
		XCTAssertTrue(ok, @"readFromData failed for %@: %@", path.lastPathComponent, error);
		// -frame is declared only in GCDocument.m, so reach it via KVC to avoid
		// the compiler resolving to AppKit's NSRect-returning -frame.
		XCTAssertTrue([[document valueForKey:@"frame"] isKindOfClass:[GCFrame class]],
					  @"document.frame should be a GCFrame after opening %@", path.lastPathComponent);
		[document release];
	}
}

@end
