# Modernization Log

GraphClick 3.0.2 was last released in 2012. This file tracks the changes
made to get the source tree building, running, and feature-complete again
on modern macOS (26 / Apple Silicon / Xcode 26), and what is still
outstanding.

## Done

### Build & link (`8343508`, `1fea4f2`)
- Dropped the bundled Numerical Recipes sources (`matmath`, `mrqmin`,
  `nrutil`, `powell`) and the deprecated framework references that came
  with them.
- Dropped the hard-coded `QuickTime.framework` link; the framework no
  longer ships on Apple Silicon.
- Bumped the deployment target to macOS 10.13.
- Cleared the hard-coded code-sign identities in the project so the
  project builds for whoever checks it out.
- Fixed a handful of type-mismatch errors the modern clang front-end
  rejects (comparator return types in `GCSerie`/`GCFrame`, `NSPoint`
  casts to disambiguate the `-offset` selector, etc.).

### Archiving (`1fea4f2`)
- Replaced every `NSArchiver` / `NSUnarchiver` call site with
  `NSKeyedArchiver` / `NSKeyedUnarchiver`. The non-keyed coders were
  removed in macOS 10.14.
- Switched `NSPoint`/`NSRect` struct encoding to `NSValue +
  encodeObject:` so the keyed archiver accepts it.
- **Note:** this is not backwards-compatible with documents saved by
  previous GraphClick releases. A legacy unarchive will now throw an
  `NSInvalidArgumentException` during `GCFrame -initWithCoder:`; the
  read path (see below) catches it and reports
  `NSFileReadCorruptFileError` instead of crashing.

### `NSDocument` / `NSDocumentController` modernization (`dbee937`, `d5d607b`)
- Opted `GCDocument` into `+autosavesInPlace` returning `YES`.
- Renamed the `GCApplicationDelegate` override from the long-deprecated
  `-openUntitledDocumentOfType:display:` to
  `-openUntitledDocumentAndDisplay:error:`.
- Replaced the deprecated `-openDocumentWithContentsOfFile:display:` /
  `-makeDocumentWithContentsOfFile:ofType:` overrides with an override
  of `-openDocumentWithContentsOfURL:display:completionHandler:`. The
  old file-based path is no longer dispatched to by modern
  `NSDocumentController`, so File → Open never reached the custom
  movie/image import path until this was switched.
- Migrated `GCDocument` from the 10.4-era
  `-dataRepresentationOfType:` / `-loadDataRepresentation:ofType:` to
  `-dataOfType:error:` / `-readFromData:ofType:error:`. The read path
  wraps the unarchive in `@try` so a legacy-format document (left over
  from before the keyed-archive switch) fails cleanly instead of
  crashing the state-restoration path at launch.
- Opted the app delegate into secure restorable state.
- Broke a responder-chain recursion in `GCDocument`'s forwarding
  category by refusing to forward `validRequestorForSendType:returnType:`
  to `mView`.

### Movie digitization (`d5d607b`)
- `NSMovie` was deprecated in macOS 10.5 and its backing QuickTime C
  API is gone on modern macOS. The entire `-[GCView setURL:asUser:]`
  movie path had been stubbed to `NSMovie *movie = nil` to avoid a
  crash on every file open; the documented frame-by-frame
  digitization feature was therefore non-functional.
- Introduced `GCMovie`, an `AVAsset` + `AVAssetImageGenerator`
  wrapper that exposes the same
  `duration` / `imageAtTimeFromPoster:` / `posterTime` interface the
  view already expected. `GCMovie` conforms to `NSSecureCoding` and
  archives only the URL + poster time; the asset is reloaded on
  demand.
- Switched `mMovie` and the worker-thread cache in
  `GCView (ThreadedMovieImage)` to `GCMovie`, deleted the
  `NSMovie (GCFoundation)` category, and dropped the `[inMovie QTMovie]`
  guard in `-setMovie:`.
- Linked `AVFoundation.framework` and `CoreMedia.framework`.

### Linker / dead-stripping (`d5d607b`)
- `GCApplicationDelegate` is only referenced by name from the nib.
  The modern linker dead-strips nib-only-referenced Objective-C
  classes, which caused `NSDocumentController` to silently use a
  default instance and none of our overrides to fire. Added a
  `(void)[GCApplicationDelegate class];` in `main()` to force a
  hard reference.

### Sandboxing & code signing (`e3760b9`, `8bf672c`, `928c983`)
- App sandboxing turned on with a minimal entitlements set.
- Code signing corrected so the sandboxed build launches cleanly.

## TODO

### Deprecated AppKit API (functional, but warned)
The current `xcodebuild` produces a large number of
`-Wdeprecated-declarations` warnings. None block building; Apple has
kept the legacy symbols around but will remove them eventually.

- `NSDrawer` (40 occurrences) — `GCDocument`'s palette and info
  panels are `NSDrawer`s. Apple recommends `NSSplitViewController`.
  Will require nib surgery.
- `NSRunAlertPanel` / `NSRunCriticalAlertPanel`, plus
  `NSAlertDefaultReturn` / `NSAlertAlternateReturn` /
  `NSAlertOtherReturn` / `NSOKButton` / `NSCancelButton`
  (~100 occurrences combined, mostly in `GCView+MagicWand.m`,
  `GCView.m`, `GCSerieRenamer.m`, `GCSnapGridController.m`) — rewrite
  to `NSAlert` with modern response codes.
- Pre-10.12 event-type constants: `NSLeftMouseDown`,
  `NSLeftMouseDragged`, `NSLeftMouseUp`, `NSKeyDown`,
  `NSFlagsChanged`, their `Mask` counterparts, and the modifier
  constants `NSShiftKeyMask` / `NSCommandKeyMask` /
  `NSControlKeyMask` / `NSAlternateKeyMask` (~100 occurrences,
  concentrated in `GCView.m` and `GCView+MagicWand.m`) — mechanical
  replace with `NSEventType…` / `NSEventModifierFlag…`.
- `NSCompositeSourceOver` → `NSCompositingOperationSourceOver`.
- `NSCenterTextAlignment` → `NSTextAlignmentCenter`.
- `-[NSWindow beginSheet:modalForWindow:modalDelegate:didEndSelector:contextInfo:]`
  in `GCSerieRenamer.m` and `GCSnapGridController.m` — rewrite to
  block-based `-beginSheet:completionHandler:`.
- `-[NSSavePanel beginSheetForDirectory:file:modalForWindow:...]`
  in `GCDocument.m` export paths — rewrite to
  `-beginSheetModalForWindow:completionHandler:` with `directoryURL` /
  `nameFieldStringValue`.
- `-[NSSavePanel setRequiredFileType:]` → `allowedContentTypes`.
- `-[NSString writeToFile:atomically:]` in two export paths (`GCDocument.m`)
  → `-writeToFile:atomically:encoding:error:`.
- `-[NSPropertyListSerialization propertyListFromData:mutabilityOption:format:errorDescription:]`
  in `GCDocument -readFromData:` →
  `propertyListWithData:options:format:error:`.
- `NSImage -dissolveToPoint:fraction:` → `-drawAtPoint:…` variants.
- `-[NSWindow convertScreenToBase:]` → `-convertPointFromScreen:`.
- `-[NSClipView constrainScrollPoint:]` → `-constrainBoundsRect:`.
- `-[NSOpenPanel filename]` → `-URL`.
- `gestaltSystemVersion` in `GCFoundation.m` → `NSProcessInfo
  operatingSystemVersion`.
- `'pi'` from `CarbonCore/fp.h` (66 occurrences, all in
  `GCAdjustmentWizard.m` / `GCMinimizer.m`) → `M_PI`.

### Toolbar / nib
- Runtime warning: `NSToolbarItem.minSize` / `maxSize` are deprecated;
  Apple wants auto-layout constraints. The current toolbar items are
  sized explicitly in the nib. Requires a nib edit.

### Build settings
- `xcodebuild` emits three project-level warnings that should be
  cleaned up:
  - `ONLY_ACTIVE_ARCH=YES` requested with multiple ARCHS (benign but
    noisy).
  - "Traditional headermap style is no longer supported" — Apple wants
    `ALWAYS_SEARCH_USER_PATHS=NO`.
  - The "Run Script" build phase has no declared outputs, so it runs
    unconditionally every build.

### Other
- The pre-9 `.graphclick` document format is no longer readable (see
  the Archiving note above). A one-shot legacy-reader (read the old
  `NSArchiver` stream and translate to the keyed format) would let
  users recover historical documents, but is not in scope for a
  retired app.
