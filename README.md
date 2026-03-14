# MacSqueeze

MacSqueeze is a minimal SwiftUI macOS app for batch image conversion and resizing.

## Current MVP

- Drag and drop image import
- Image grid browser
- Export to `JPEG`, `PNG`, `HEIC`, or `WebP`
- Lossy export for `JPEG`, `HEIC`, and `WebP`
- Lossless export for `PNG` and `WebP`
- Resize by width, height, longest edge, or percentage
- Custom export folder and filename suffix

## Build

This repo currently ships as a Swift Package because full Xcode app-project tooling was not available in the implementation environment.

```bash
swift build
swift run MacSqueeze
```

You can also open `Package.swift` in Xcode and run it from there.

## Test

```bash
swift test
```

## Notes

- Input support currently covers `JPEG`, `PNG`, `HEIC`, `TIFF`, and `WebP`.
- The first release intentionally skips history, before/after comparison, and advanced file-size targeting.
- `TIFF` is supported as an input format, not an export format.
