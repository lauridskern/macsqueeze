# MacSqueeze

MacSqueeze is a native macOS app for batch image compression, conversion, and resizing. Drop in a folder of images, pick one export recipe, and ship the whole batch in one pass.

![MacSqueeze preview](docs/preview.webp)

## Features

- Native SwiftUI app for macOS
- Drag-and-drop import for files and folders
- Batch export to `JPEG`, `PNG`, `HEIC`, and `WebP`
- Lossy and lossless export modes where supported
- Resize by width, height, longest edge, or percentage
- Per-image status and size reduction feedback during export
- Custom export folder and filename suffix

## Download

Prebuilt DMGs are attached to every release on [GitHub Releases](https://github.com/lauridskern/macsqueeze/releases).

## Development

```bash
swift build
swift run MacSqueeze
```

## Test

```bash
swift test
```

## Releasing

MacSqueeze ships from GitHub Actions.

1. Create a version tag like `v1.0.0`.
2. Push the tag to GitHub.
3. The `Release` workflow runs tests, builds the `.app`, packages a `.dmg`, and publishes a GitHub release with the artifacts attached.

If you only want a fresh DMG artifact without cutting a release, run the `Release` workflow manually from the Actions tab.

## Project Layout

- `Sources/` contains the SwiftUI app and image-processing code
- `Tests/` contains the package test suite
- `scripts/` contains the local packaging scripts used by CI and releases
- `.github/workflows/` contains CI and release automation

## License

MIT. See [LICENSE](LICENSE).
