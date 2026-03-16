# Video Feature Documentation

**Module:** `features/video`  
**Version:** 1.0.0  
**Last Updated:** March 9, 2026

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Features](#features)
4. [File Structure](#file-structure)
5. [Components](#components)
6. [Usage Guide](#usage-guide)
7. [Dependencies](#dependencies)
8. [Permissions](#permissions)
9. [Future Enhancements](#future-enhancements)

---

## Overview

The Video Feature module provides comprehensive functionality for recording, importing, previewing, and uploading videos within the LiftUp application. This module follows the Clean Architecture pattern and is designed to integrate seamlessly with the movement analysis functionality.

### Key Capabilities

- 📹 **Video Recording**: Record videos directly using the device camera
- 📂 **Video Import**: Import existing videos from gallery or file system
- 👁️ **Video Preview**: Preview videos before uploading with playback controls
- ☁️ **Video Upload**: Upload videos with progress tracking and status management
- 🎯 **Exercise Type Selection**: Categorize videos by movement type

---

## Architecture

The video feature follows **Clean Architecture** principles with three distinct layers:

```
features/video/
│
├── domain/           # Business logic layer
│   ├── entities/     # Core business objects
│   └── repositories/ # Repository interfaces
│
├── data/             # Data layer
│   └── models/       # Data models with JSON serialization
│
└── presentation/     # UI layer
    ├── pages/        # Full-screen UI components
    └── widgets/      # Reusable UI components
```

### Layer Responsibilities

| Layer | Responsibility |
|-------|---------------|
| **Domain** | Business entities, repository contracts, use cases |
| **Data** | Data models, API integration, local storage |
| **Presentation** | UI pages, widgets, state management |

---

## Features

### 1. Video Recording (`VideoRecordingPage`)

Full-screen camera interface for recording videos.

**Capabilities:**
- Camera initialization with permission handling
- Front/back camera switching
- Flash mode control (off, auto, on, torch)
- Recording timer display
- Recording start/stop controls

**States:**
- Permission denied state with settings navigation
- Camera initialization loading state
- Active recording state with duration indicator
- Error handling with user-friendly messages

### 2. Video Selection (`VideoSelectionPage`)

Entry point for adding videos through multiple methods.

**Options:**
- **Record Video**: Opens camera for live recording
- **Import from Gallery**: Uses system image picker
- **Import from Files**: Uses file picker for broader format support

**Supported Formats:** MP4, MOV, AVI, MKV (max 10 minutes)

### 3. Video Preview (`VideoPreviewPage`)

Video player interface for reviewing selected/recorded videos.

**Controls:**
- Play/Pause toggle
- Progress scrubbing
- 10-second skip forward/backward
- Duration display
- Confirm or cancel selection

### 4. Video Upload (`VideoUploadPage`)

Form and progress interface for uploading videos.

**Features:**
- Video metadata input (title, description)
- Exercise type selection
- Upload progress indicator (circular)
- Upload state management (idle, uploading, success, failed, cancelled)
- Cancel upload confirmation dialog
- Retry functionality on failure

---

## File Structure

```
lib/features/video/
│
├── video.dart                          # Barrel exports
│
├── domain/
│   ├── entities/
│   │   └── video_entity.dart           # VideoEntity class
│   └── repositories/
│       └── video_repository.dart       # VideoRepository interface
│
├── data/
│   └── models/
│       └── video_model.dart            # VideoModel with JSON support
│
└── presentation/
    ├── pages/
    │   ├── video_recording_page.dart   # Camera recording UI
    │   ├── video_selection_page.dart   # Video source selection UI
    │   ├── video_preview_page.dart     # Video playback preview UI
    │   └── video_upload_page.dart      # Upload form and progress UI
    └── widgets/
        ├── video_card.dart             # Video list item card
        └── video_list.dart             # Video list with empty state
```

---

## Components

### VideoEntity

Core business entity representing a video.

```dart
class VideoEntity {
  final String id;
  final String localPath;
  final String title;
  final String? description;
  final int durationInSeconds;
  final int sizeInBytes;
  final String? thumbnailPath;
  final VideoUploadStatus uploadStatus;
  final double uploadProgress;
  final String? remoteUrl;
  final DateTime createdAt;
  
  // Helper getters
  String get formattedDuration;  // "MM:SS"
  String get formattedSize;      // "X.X MB"
}
```

### VideoUploadStatus

Enum representing upload states:

| Status | Description |
|--------|-------------|
| `pending` | Video awaiting upload |
| `uploading` | Upload in progress |
| `uploaded` | Successfully uploaded |
| `failed` | Upload failed |
| `cancelled` | Upload cancelled by user |

### VideoCard Widget

Reusable card component for displaying video information.

**Props:**
- `video`: VideoEntity to display
- `onTap`: Callback for card tap
- `onDelete`: Callback for delete action
- `onUpload`: Callback for upload action

### VideoList Widget

List component with loading and empty states.

**Props:**
- `videos`: List of VideoEntity
- `isLoading`: Loading state flag
- `onVideoTap`: Video tap callback
- `onVideoDelete`: Delete callback
- `onVideoUpload`: Upload callback
- `onAddVideo`: Add video callback

---

## Usage Guide

### Basic Integration

```dart
import 'package:app/features/video/video.dart';

// Open video selection page
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => VideoSelectionPage(
      onVideoSelected: (videoPath) {
        // Handle selected video
        print('Video selected: $videoPath');
      },
    ),
  ),
);
```

### Opening Camera Directly

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => VideoRecordingPage(
      onVideoRecorded: (videoPath) {
        // Handle recorded video
      },
    ),
  ),
);
```

### Displaying Video List

```dart
VideoList(
  videos: myVideoList,
  isLoading: isLoading,
  onVideoTap: (video) => navigateToDetail(video),
  onVideoDelete: (video) => deleteVideo(video),
  onAddVideo: () => openVideoSelection(),
)
```

### Creating VideoEntity

```dart
final video = VideoEntity(
  id: UniqueKey().toString(),
  localPath: '/path/to/video.mp4',
  title: 'Mon Squat',
  description: 'Squat avec 100kg',
  durationInSeconds: 45,
  sizeInBytes: 15 * 1024 * 1024, // 15 MB
  uploadStatus: VideoUploadStatus.pending,
  createdAt: DateTime.now(),
);
```

---

## Dependencies

Add these dependencies to `pubspec.yaml`:

```yaml
dependencies:
  # Video & Camera
  camera: ^0.11.0
  video_player: ^2.9.0
  image_picker: ^1.0.7
  permission_handler: ^11.3.0
  path_provider: ^2.1.2
  
  # File handling
  file_picker: ^8.0.0
  mime: ^1.0.5
```

---

## Permissions

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Camera and microphone for recording -->
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>

<!-- Storage for video files -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

<!-- Internet for uploads -->
<uses-permission android:name="android.permission.INTERNET"/>
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Cette application nécessite l'accès à la caméra pour enregistrer vos mouvements.</string>

<key>NSMicrophoneUsageDescription</key>
<string>Cette application nécessite l'accès au microphone pour l'enregistrement vidéo.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Cette application nécessite l'accès à la galerie pour importer des vidéos.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>Cette application nécessite l'accès à la galerie pour sauvegarder des vidéos.</string>
```

---

## Future Enhancements

### Planned Features

- [ ] **Backend Integration**: Connect to LiftUp API for actual uploads
- [ ] **Thumbnail Generation**: Generate video thumbnails for previews
- [ ] **Video Compression**: Compress videos before upload
- [ ] **Offline Queue**: Queue uploads for later when offline
- [ ] **Video Trimming**: Allow users to trim videos before upload
- [ ] **Multiple Video Upload**: Support batch video uploads
- [ ] **Analysis Results**: Display AI analysis results
- [ ] **Video Annotations**: Add annotations to highlight technique issues

### State Management Integration

Consider integrating with Riverpod for:
- Video list state management
- Upload queue management  
- Analysis results caching

```dart
// Example: Video list provider
@riverpod
class VideoListNotifier extends _$VideoListNotifier {
  @override
  Future<List<VideoEntity>> build() async {
    return await ref.read(videoRepositoryProvider).getLocalVideos();
  }
  
  Future<void> addVideo(VideoEntity video) async {
    state = AsyncData([...state.value!, video]);
    await ref.read(videoRepositoryProvider).saveVideo(video);
  }
}
```

---

## Localization

All UI strings are in French (default app language):

| Key | French | English Translation |
|-----|--------|---------------------|
| Add video | Ajouter une vidéo | Add a video |
| Recording | Enregistrement | Recording |
| Upload | Téléverser | Upload |
| Cancel | Annuler | Cancel |
| Success | Réussi | Success |
| Failed | Échec | Failed |

---

## Testing

### Unit Tests

```dart
// Test VideoEntity formatting
test('formattedDuration returns correct format', () {
  final video = VideoEntity(
    id: '1',
    localPath: '/test.mp4',
    title: 'Test',
    durationInSeconds: 125,
    sizeInBytes: 1024,
    createdAt: DateTime.now(),
  );
  
  expect(video.formattedDuration, equals('02:05'));
});
```

### Widget Tests

```dart
// Test VideoCard rendering
testWidgets('VideoCard displays video info', (tester) async {
  final video = VideoEntity(/*...*/);
  
  await tester.pumpWidget(MaterialApp(
    home: VideoCard(video: video),
  ));
  
  expect(find.text(video.title), findsOneWidget);
  expect(find.text(video.formattedSize), findsOneWidget);
});
```

---

## Contributing

When contributing to this module:

1. Follow the existing architecture patterns
2. Add documentation for new components
3. Include comments in French where user-facing
4. Test on both iOS and Android
5. Update this documentation for significant changes

---

**Author:** LiftUp Development Team  
**License:** Proprietary
