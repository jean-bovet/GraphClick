# GraphClick

GraphClick is a macOS application that extracts numerical data from the image of a graph. Given a scanned figure, a screenshot, a PDF, or even a QuickTime movie, it lets you recover the underlying coordinates of curves, symbols, bar charts, and areas — the kind of task that otherwise requires a ruler, a magnifier, and a lot of patience.

It was developed by [Arizona Software](http://www.arizona-software.ch/graphclick) (Jean Bovet) as a commercial product from 2004 through 2012 and is now retired. This repository is the final open-source release of the source code.

## What it does

Given an image of a plot, GraphClick helps you:

- **Calibrate** the graph by clicking on known reference points (two corners, the origin, the four sides, an arbitrary 3- or 4-point basis, a distance scale, etc.).
- **Detect points automatically** on:
  - continuous curves (including dotted or dashed lines, via a brush mask)
  - scattered symbols (pattern matching)
  - vertical or horizontal bar charts
  - the perimeter of filled areas
- **Add points manually** with a magnifier for pixel-precision clicks.
- **Digitize movies** frame by frame — useful for extracting the trajectory of a moving object from a QuickTime clip.
- **Export** the resulting data sets as CSV/TSV (to file or clipboard), optionally with column headers, stacked differences, error bars, or geometric information.

## Features

- Linear, logarithmic, and inverse axis scales; support for two ordinate axes and pixel coordinates.
- Arbitrary coordinate frames, including non-perpendicular axes and non-linear deformations (the frame can be warped to match skewed or distorted plots).
- **Map projections**: Mercator, oblique Mercator, transverse Mercator, and gnomonic — for digitizing geographic data from maps.
- **Image filters** powered by Core Image: threshold, color controls, edge detection, blur, sharpen, exposure adjustment, noise reduction.
- **Multiple data sets** per document with customizable appearance (color, line style, markers), error bars, and point labels.
- Horizontal and vertical **guide lines**, snap-to-grid, and a customizable reticle.
- **Geometry inspector** for measuring distances, angles, areas, perimeters, and speeds along digitized paths.
- Wide image format support: PDF, TIFF, PNG, JPEG, GIF, BMP, PSD, PICT, and anything else the system can decode.
- **Localizations**: English, French, German, and Italian.

## Repository layout

```
Source/              Objective-C source (Cocoa / AppKit)
Images/              Application icons and image assets
Resources/           Info.plist, version.plist
English.lproj/       English UI nibs, Localizable.strings, and bundled Help Book
French.lproj/        French localization
German.lproj/        German localization
Italian.lproj/       Italian localization
ThresholdUnit/       Core Image threshold filter plug-in
GraphClick.xcodeproj Xcode project
GraphClick.entitlements App sandbox entitlements
```

The bundled help book under `English.lproj/GraphClick Help/` is the primary user-facing documentation and covers every feature in detail.

## Status

GraphClick is retired. The source is published here for historical interest and as a reference for anyone digitizing plots or building similar tools. It is no longer actively developed, and there is no official support channel — issues and pull requests may or may not receive a response.

The last released version was 3.0.2; the `master` branch currently carries the unreleased 3.0.3 work (code signing and warning fixes, Numerical Recipes dependency removed). The `3.0.2` branch preserves the final shipping source.

## Building

The project is a standard Xcode project targeting macOS. Open `GraphClick.xcodeproj` in a recent Xcode and build the `GraphClick` target. The code is Objective-C against the Cocoa frameworks; no external package manager is involved. Some formerly-bundled numerical routines (Numerical Recipes) were removed in the final commit for licensing reasons, so paths that depended on them may need replacement before certain auto-detection features compile and run cleanly.

## License & copyright

Copyright © 2004–2012 Arizona Software. All rights reserved. See the `English.lproj/Credits.rtf` and any `LICENSE` file in this repository for the terms under which this source is released.
