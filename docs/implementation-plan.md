# MacSqueeze MVP Plan

## Outcome

Ship a small SwiftUI macOS app that can batch-convert images, apply lossy or lossless export settings, and resize images.

## Build Order

1. app shell and file import
2. processing engine for one image
3. batch queue and export flow
4. polish and release prep

## Proposed Stack

- Swift 6
- SwiftUI
- AppKit interop
- ImageIO
- CoreGraphics
- XCTest

## Repository Shape

```text
MacSqueeze/
  App/
  Features/
    Queue/
    Processing/
    Export/
    Settings/
  Shared/
    Models/
    Services/
    UI/
  Tests/
```

## Milestones

### Milestone 1: App Shell

Deliverables:

- SwiftUI macOS app window
- drag-and-drop import
- `NSOpenPanel` import
- queue list with file metadata
- batch settings sidebar

Exit criteria:

- images can be added and inspected in the UI

### Milestone 2: Core Processing

Deliverables:

- JPEG, PNG, and HEIC export
- lossy quality controls for JPEG/HEIC
- lossless PNG path
- resize modes
- single-image processing validation

Exit criteria:

- one image can be converted and resized end to end

### Milestone 3: Batch Export

Deliverables:

- batch runner
- per-item status
- export destination picker
- naming rules and conflict handling
- completion summary

Exit criteria:

- a full batch can be processed without blocking the UI

### Milestone 4: Polish

Deliverables:

- keyboard shortcuts
- better error handling
- memory/performance tuning
- README with setup and roadmap
- app icon and release packaging

Exit criteria:

- project is usable, shareable, and easy to continue building

## Engineering Tasks

### 1. Bootstrap

- create Xcode project
- configure bundle id and sandbox
- set up folder structure

### 2. Models

- define asset and settings models
- define format support matrix
- define conflict rules

### 3. Import Flow

- drag/drop handling
- open panel integration
- metadata extraction

### 4. Processing Engine

- load source image
- optionally resize
- encode to target format
- write output file

### 5. Batch Runner

- concurrent processing with a safe worker cap
- progress updates on the main actor
- cancellation support

### 6. Export Flow

- destination folder selection
- filename generation
- overwrite policy

### 7. QA

- unsupported files
- corrupt files
- large images
- transparent PNG to JPEG conversion

## Risks

### Native Encoder Differences

- macOS image encoders do not behave identically across formats

Response:

- start with ImageIO-supported formats only

### Memory Pressure

- large images can consume a lot of memory during batch work

Response:

- downsample previews and cap concurrency

### Sandbox File Access

- export folders can be tricky across app relaunches

Response:

- keep v1 export flow simple and validate it early

## Suggested Timeline

1. Week 1: shell, import, models
2. Week 2: processing engine
3. Week 3: batch export flow
4. Week 4: polish and packaging

## First Step

Start by proving the hardest part early:

1. import one image
2. convert it to another format
3. resize it
4. save it successfully

Once that works, the batch UI is mostly orchestration.
