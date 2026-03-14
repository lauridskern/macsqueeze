# MacSqueeze MVP Spec

## Objective

Build a small native macOS app in SwiftUI for three things:

- convert images to a different format
- export with lossy or lossless settings
- resize one or many images in a batch

This is no longer a one-to-one Squeeze clone spec. It is a minimal first release inspired by that workflow.

## Product Goals

- Fast drag-and-drop batch processing
- Local-only image handling
- Simple settings with very little UI clutter
- Reliable export for common formats

## Non-Goals

- No history in v1
- No before/after comparison UI in v1
- No premium features or billing
- No advanced file-size targeting
- No image editing beyond format conversion and resize

## Platform

- macOS 14+
- SwiftUI app lifecycle
- App Sandbox enabled

## Core User Stories

- As a user, I can drag images into the app and process them in one batch.
- As a user, I can choose an output format such as JPEG, PNG, or HEIC.
- As a user, I can choose lossy or lossless output where that makes sense.
- As a user, I can resize images by width, height, longest edge, or percentage.
- As a user, I can export the results to a folder I choose.

## Functional Scope

### 1. Import

- Drag and drop files into the main window
- Import files through `NSOpenPanel`
- Optional folder import if it is easy to support during implementation

### 2. Input Formats

Support for reading:

- JPEG/JPG
- PNG
- HEIC
- TIFF

Optional later:

- GIF
- WebP
- AVIF

### 3. Output Formats

Required for MVP:

- JPEG
- PNG
- HEIC

### 4. Processing Options

#### Format Conversion

- Convert all selected images to one chosen output format

#### Compression

- Lossy quality slider for JPEG and HEIC
- Lossless output path for PNG
- Preserve metadata only if easy; otherwise strip metadata in v1

#### Resize

- Resize by width
- Resize by height
- Resize by longest edge
- Resize by percentage
- Preserve aspect ratio by default

### 5. Batch Processing

- Queue of imported files
- Per-item status: pending, processing, done, failed
- Start batch
- Cancel batch
- Remove selected items
- Clear queue

### 6. Export

- Save to a custom destination folder
- Keep original filename and swap extension by default
- Optional filename suffix such as `-optimized`
- Conflict handling:
  - keep both
  - overwrite
  - ask

## UX Requirements

### Layout

- Single main window
- Left: queue list
- Right: settings panel
- Center: simple selected-image preview or placeholder

### Empty State

- Large drop target
- `Add Images` button
- Short helper text explaining supported actions

### Active State

- Queue remains visible
- One shared settings panel applies to the whole batch
- Header shows file count and total original size

## Technical Requirements

- SwiftUI for the app UI
- AppKit interop for `NSOpenPanel` and export folder picking
- `ImageIO`, `CoreGraphics`, and `UniformTypeIdentifiers` for image processing
- Swift Concurrency for batch work

## Suggested Architecture

- `AppShell`
  - window and menu commands
- `QueueDomain`
  - import, selection, item status
- `ProcessingDomain`
  - conversion, compression, resize
- `ExportDomain`
  - output folder, filename rules, conflict policy
- `SettingsDomain`
  - current batch settings

## Core Data Models

### InputAsset

- id
- fileURL
- filename
- format
- fileSize
- dimensions

### ProcessingSettings

- outputFormat
- compressionMode
- quality
- resizeMode
- resizeValue
- preserveAspectRatio
- outputDirectory
- filenameSuffix
- conflictPolicy

### JobResult

- inputAssetID
- status
- outputURL
- outputFileSize
- outputDimensions
- errorDescription

## Edge Cases

- corrupt images
- transparent PNG converted to JPEG
- duplicate filenames
- unsupported formats
- very large images causing memory pressure

## Success Criteria

- A user can import a mixed batch and export converted/resized results without help.
- The app stays responsive during batch work.
- Output files match the chosen format and resize settings reliably.
