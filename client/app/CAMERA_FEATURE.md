# Camera Feature Documentation

## Overview

The Camera feature is a core component of the LiftUp app that enables users to record their workout sessions and receive AI-powered feedback on their form. This feature provides real-time camera preview with overlay guides and integrates with the Language Model (LM) system for intelligent coaching.

## Architecture

The camera feature follows clean architecture principles and is organized as follows:

```
lib/features/camera/
├── presentation/
│   ├── pages/
│   │   └── camera_page.dart          # Main camera page with state management
│   └── widgets/
│       ├── camera_preview_widget.dart # Camera preview with controls
│       └── lm_comments_section.dart  # LM feedback display
├── domain/                            # Domain layer (future business logic)
└── data/                             # Data layer (future repositories)
```

## Components

### 1. CameraPage (`camera_page.dart`)

The main page component that manages camera initialization and view switching.

**Key Features:**
- Camera initialization and lifecycle management
- Error handling for camera access failures
- Toggle between camera preview and LM comments
- Automatic disposal of camera resources

**State Management:**
- `_isInitialized`: Tracks camera initialization status
- `_showComments`: Controls view switching
- `_error`: Stores error messages

**Methods:**
- `_initializeCamera()`: Initializes camera with high resolution preset
- `_toggleComments()`: Switches between camera and comments view
- `dispose()`: Properly disposes camera controller

### 2. CameraPreviewWidget (`camera_preview_widget.dart`)

Displays the live camera feed with overlay guides and control buttons.

**Features:**
- Full-screen camera preview
- Rule-of-thirds grid overlay for composition
- Center crosshair for positioning
- Bottom control panel with three actions:
  - **LM Comments**: Navigate to feedback section
  - **Capture**: Capture photo/video (placeholder)
  - **Flip**: Switch camera (placeholder)

**UI Elements:**
- Custom overlay painter for guide lines
- Gradient background for controls
- Icon-based control buttons

### 3. LMCommentsSection (`lm_comments_section.dart`)

Displays AI-generated comments and feedback on workout form.

**Features:**
- Scrollable list of comments
- Color-coded comment types:
  - 🟢 Positive (green) - Encouraging feedback
  - 🟠 Correction (orange) - Form corrections
  - 🔵 Encouragement (blue) - Motivational messages
  - 🔴 Warning (red) - Safety warnings
- Relative timestamps ("5m ago", "1h ago")
- Empty state for no comments
- "Back to Camera" navigation

**Data Models:**

```dart
class LMComment {
  final String id;
  final String text;
  final DateTime timestamp;
  final CommentType type;
}

enum CommentType {
  positive,
  correction,
  encouragement,
  warning,
}
```

## Integration with Main App

### Navigation

The camera feature is integrated into the main app through tab-based navigation in `HomePage`:

```dart
TabBar(
  tabs: [
    Tab(icon: Icon(Icons.home), text: 'Home'),
    Tab(icon: Icon(Icons.camera_alt), text: 'Camera'),
  ],
)

TabBarView(
  children: [
    _buildHomeTab(),
    const CameraPage(),
  ],
)
```

### Permissions

#### Android
Configured in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

#### iOS
Configured in `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>LiftUp needs access to your camera to provide AI-powered form analysis and coaching</string>
```

## Dependencies

The feature relies on the following packages:

```yaml
camera: ^0.10.5+5           # Camera access and control
permission_handler: ^11.0.1 # Runtime permission handling
```

## Usage Flow

1. **Open Camera Tab**: User navigates to camera tab from home screen
2. **Camera Initialization**: App requests camera permissions and initializes camera
3. **Preview Display**: Live camera feed shows with guide overlays
4. **View Toggle**: User can switch between camera and LM comments using app bar button
5. **LM Comments**: View AI feedback with color-coded comment types
6. **Return to Camera**: Back button returns to camera preview

## Future Enhancements

### Planned Features
- [ ] Photo/video capture functionality
- [ ] Front/back camera switching
- [ ] Real-time LM integration for live feedback
- [ ] Comment persistence and history
- [ ] Video recording with timestamp synchronization
- [ ] Form analysis visualization (pose overlay)
- [ ] Export workout sessions with comments

### LM Integration Points
The system is designed for easy LM integration:

1. **Replace placeholder comments** in `_comments` list with API calls
2. **Add real-time analysis** by sending camera frames to LM service
3. **Implement comment streaming** to update UI as LM generates feedback
4. **Store sessions** with associated comments for history

## Error Handling

The camera feature includes robust error handling:

- **Camera Access Denied**: Shows error message with retry option
- **No Camera Available**: Displays informative error
- **Initialization Failure**: Catches and displays error with detailed message
- **Resource Cleanup**: Ensures camera is properly disposed on navigation away

## Performance Considerations

- Camera runs at `ResolutionPreset.high` for quality analysis
- Grid overlay uses custom painter for efficient rendering
- Camera preview uses native platform views for optimal performance
- Comments list is efficiently rendered with `ListView.separated`

## Testing

See [TESTING.md](TESTING.md) for comprehensive testing documentation.

## Troubleshooting

### Camera Not Showing
1. Check device has a camera
2. Verify permissions are granted
3. Check emulator camera settings (for testing)
4. Review error message in UI

### Permission Issues
1. Uninstall and reinstall app
2. Check AndroidManifest.xml/Info.plist configuration
3. Manually grant permissions in device settings

### Build Errors
1. Run `flutter clean`
2. Run `flutter pub get`
3. Rebuild the app

## Code Quality

- ✅ All lint rules passing
- ✅ Modern Flutter patterns (super parameters, `withValues()`)
- ✅ Proper state management
- ✅ Resource disposal
- ✅ Error boundaries
- ✅ Comprehensive unit tests

## Related Documentation

- [Architecture Overview](ARCHITECTURE.md)
- [Testing Guide](TESTING.md)
- [Flutter App Setup](../../../docs/FLUTTER_APP_SETUP.md)
