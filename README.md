# ReplayIt 🎬

A Flutter app that continuously records camera video and lets you save the last 60 seconds on demand — like an instant replay for real life.

## How It Works

ReplayIt keeps a rolling buffer of the most recent camera frames in memory and on disk. When you tap **Save**, it converts the buffered frames into an MP4 video and saves it to your gallery. No footage is lost — if something cool just happened, you can always go back and grab it.

## Tech Stack

- **Flutter** (Dart SDK `^3.8.1`)
- **camera** — live camera preview & image stream capture
- **ffmpeg_kit_flutter_new** — frame-to-video conversion
- **path_provider** — temp file management
- **image_gallery_saver_plus** — saving videos to the device gallery

## Project Structure

```
lib/
├── main.dart                               # App entry point
├── domain/
│   └── use_cases/
│       └── convertFrameToVideo.dart        # Frame → MP4 conversion logic
└── presentation/
    ├── controllers/
    │   └── camera_recorder_controller.dart # Camera + buffer orchestration
    ├── pages/
    │   └── home_page.dart                  # Main screen
    └── widgets/
        ├── camera_preview_widget.dart      # Live camera preview
        └── camera_recorder_widget.dart     # Recording controls UI
```

## Getting Started

### Prerequisites

- Flutter SDK `^3.8.1`
- A physical device (camera is not available on simulators/emulators)

### Run

```bash
flutter pub get
flutter run
```

## Known Problems

This pure-Flutter/Dart implementation has several fundamental limitations:

- **Main-thread blocking** — YUV frame conversion and disk I/O run on the main isolate, causing UI stuttering and dropped frames.
- **Race conditions** — the image stream callback and recording state aren't properly synchronised, leading to lost frames at start/stop boundaries.
- **Memory pressure** — no backpressure handling; if disk writes lag behind, frames pile up in RAM with no cap.

## What's Next

Because many of these issues stem from Dart's single-threaded model and lack of low-level camera control, a **custom Flutter plugin** that handles the recording buffer natively (Swift / Kotlin) is currently in active development. This approach gives us:

- Direct access to platform camera APIs and hardware-accelerated encoding
- True background threading for frame capture and disk I/O
- Better memory management and backpressure control

The plugin is planned to be published on [pub.dev](https://pub.dev) once it's ready.
