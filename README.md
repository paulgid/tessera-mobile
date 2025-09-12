# Tessera Mobile

Flutter mobile application for the Tessera real-time collaborative mosaic game.

## Features

- Real-time WebSocket communication
- Battery-efficient rendering with tile virtualization
- Adaptive quality based on battery level
- Network resilience with automatic reconnection
- Cross-platform support (iOS & Android)

## Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- iOS development: Xcode and CocoaPods
- Android development: Android Studio

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run the app:
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```

## Architecture

The app follows a clean architecture pattern with:

- **Core Layer**: Models, network clients, and utilities
- **Features Layer**: UI screens and widgets
- **Providers Layer**: State management with Riverpod

### Key Components

- `WebSocketManager`: Handles real-time communication with exponential backoff
- `ApiClient`: REST API interactions using Dio
- `MosaicPainter`: Efficient tile rendering with virtualization
- `GameProvider`: Centralized game state management

## Configuration

### Server Connection

By default, the app connects to `localhost:8081`. To connect to a different server:

1. Update `_defaultHost` in `lib/core/network/websocket_manager.dart`
2. Update `_defaultBaseUrl` in `lib/core/network/api_client.dart`

### Battery Optimization

The app automatically adjusts update frequency based on battery level:
- < 20%: 5-second updates, compression enabled
- < 50%: 2-second updates, compression enabled
- > 50%: 500ms updates, normal quality

## Project Structure

```
lib/
├── core/
│   ├── models/         # Data models (Tile, Team, GameUpdate)
│   ├── network/        # API and WebSocket clients
│   ├── rendering/      # Canvas rendering utilities
│   └── utils/          # Helper functions
├── features/
│   ├── game/          # Game screen and components
│   ├── teams/         # Team selection
│   └── settings/      # App settings
├── providers/         # State management
└── main.dart         # App entry point
```

## Development

### Running Tests

```bash
flutter test
```

### Building for Release

```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release
flutter build appbundle --release
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and ensure they pass
4. Submit a pull request

## License

See LICENSE file in the root directory.