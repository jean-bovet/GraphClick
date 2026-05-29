# Test fixtures

Drop a GraphClick document (`*.gc`) here to exercise
`GCDocumentLegacyFormatTests testOpensLegacyFixtureDocument`, which opens every
bundled `.gc` and asserts it decodes. A legacy (GraphClick 3.0.x) document is the
most useful, since it covers the old-format reading path.

`*.gc` files are gitignored (they may be personal documents), so this test skips
when the folder has none. This README keeps the folder present in a fresh
checkout so the test bundle's folder reference resolves.
