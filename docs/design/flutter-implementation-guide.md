# Tessera Mobile Flutter Implementation Guide

Version: 1.0.0
Date: 2025-01-16
Designer: UX Design Authority
Technical Specification for: Frontend Engineers

## Executive Summary

This guide provides Flutter-specific implementation details for the Tessera mobile app, translating design specifications into concrete technical requirements. All implementations must follow these specifications to ensure consistency and performance.

## Critical Performance Requirements

### Target Metrics

```yaml
performance_targets:
  frame_rate:
    overview_zoom: 60fps  # Non-negotiable
    interaction_zoom: 30fps_minimum
    detail_zoom: 60fps
    
  memory:
    baseline: 50MB
    active_game: 150MB_max
    peak_allowed: 200MB
    
  network:
    initial_load: 3s_on_4G
    tile_updates: 100ms_latency
    batch_size: 64KB_max
    
  battery:
    active_play: <10%_per_hour
    background: <1%_per_hour
```

## 1. Mosaic Viewport Implementation

### 1.1 Custom Tile Renderer

```dart
// Required CustomPainter implementation
class MosaicTileRenderer extends CustomPainter {
  // Required properties from design spec
  final QuadTree visibleTiles;
  final double zoomLevel;
  final Offset panOffset;
  final int renderQuality; // 1=low, 2=medium, 3=high
  
  // Performance-critical paint objects (cache these!)
  static final Paint tilePaint = Paint()
    ..isAntiAlias = false  // Disable for performance
    ..filterQuality = FilterQuality.low;
    
  @override
  void paint(Canvas canvas, Size size) {
    // REQUIRED: Implement frustum culling
    final viewport = Rect.fromLTWH(
      -panOffset.dx,
      -panOffset.dy,
      size.width / zoomLevel,
      size.height / zoomLevel,
    );
    
    // REQUIRED: Use layer painting for performance
    canvas.saveLayer(viewport, Paint());
    
    // Draw based on zoom level (from design spec)
    if (zoomLevel < 0.05) {
      _drawAggregatedBlocks(canvas, viewport);
    } else if (zoomLevel < 0.25) {
      _drawChunkedRegions(canvas, viewport);
    } else {
      _drawIndividualTiles(canvas, viewport);
    }
    
    canvas.restore();
  }
  
  // CRITICAL: Implement intelligent repaint detection
  @override
  bool shouldRepaint(MosaicTileRenderer oldDelegate) {
    // Only repaint if viewport or data changed
    return oldDelegate.zoomLevel != zoomLevel ||
           oldDelegate.panOffset != panOffset ||
           oldDelegate.visibleTiles.version != visibleTiles.version;
  }
}
```

### 1.2 Gesture Detection System

```dart
// Required gesture handler with disambiguation
class MosaicGestureDetector extends StatefulWidget {
  // Gesture callbacks matching design spec
  final Function(TilePosition) onTileSelected;
  final Function(TilePosition) onTileLongPressed;
  final Function(Offset) onPan;
  final Function(double) onZoom;
  
  @override
  _MosaicGestureDetectorState createState() => _MosaicGestureDetectorState();
}

class _MosaicGestureDetectorState extends State<MosaicGestureDetector> {
  // Gesture detection timers from spec
  static const int tapMaxDuration = 300; // ms
  static const int longPressMinDuration = 500; // ms
  static const double panThreshold = 10.0; // pixels
  static const double pinchThreshold = 0.05; // 5% scale change
  
  // Track gesture state
  Timer? _gestureTimer;
  Offset? _initialTouchPosition;
  int _pointerCount = 0;
  
  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        // Custom gesture recognizer for disambiguation
        MosaicGestureRecognizer: GestureRecognizerFactoryWithHandlers<
          MosaicGestureRecognizer>(
          () => MosaicGestureRecognizer(),
          (instance) {
            instance
              ..onTap = _handleTap
              ..onLongPress = _handleLongPress
              ..onPanUpdate = _handlePan
              ..onScaleUpdate = _handleScale;
          },
        ),
      },
      child: widget.child,
    );
  }
  
  // Implement 50ms wait period for gesture disambiguation
  void _startGestureDetection(PointerDownEvent event) {
    _initialTouchPosition = event.position;
    _gestureTimer = Timer(Duration(milliseconds: 50), () {
      // Check movement after 50ms to determine gesture type
      // This matches the design specification
    });
  }
}
```

### 1.3 Zoom Level Management

```dart
// Zoom controller matching design specifications
class ZoomController extends ChangeNotifier {
  // Snap points from design spec
  static const List<double> snapPoints = [
    0.03,  // Overview min
    0.1,   // Overview mid
    0.25,  // Navigation
    0.5,   // Interaction low
    1.0,   // Interaction full
    2.0,   // Detail low
    4.0,   // Detail max
  ];
  
  double _currentZoom = 1.0;
  
  // Animated zoom with specified duration and curve
  Future<void> animateZoom(double targetZoom) async {
    // Find nearest snap point
    final snappedZoom = _findNearestSnapPoint(targetZoom);
    
    // Animate with specified curve
    await _animationController.animateTo(
      snappedZoom,
      duration: Duration(milliseconds: 250),
      curve: Cubic(0.25, 0.46, 0.45, 0.94), // From spec
    );
  }
  
  // Double-tap zoom behavior from spec
  void handleDoubleTap(Offset tapPosition) {
    // Zoom to next level or specific tile
    if (_currentZoom < 0.25) {
      animateZoom(0.25); // Jump to navigation level
    } else if (_currentZoom < 1.0) {
      animateZoom(1.0); // Jump to interaction level
    } else {
      // Zoom to specific tile with centering
      _zoomToTile(tapPosition);
    }
  }
}
```

## 2. Progressive Loading Implementation

### 2.1 Tile Data Manager

```dart
// Manages progressive loading as specified
class TileDataManager {
  // Data structures from spec
  static const int overviewDataSize = 2;     // bytes per tile
  static const int navigationDataSize = 8;   // bytes per tile
  static const int interactionDataSize = 32; // bytes per tile
  
  // Cache limits from spec
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  
  // Loading priority queue
  final PriorityQueue<TileChunk> _loadQueue = PriorityQueue();
  
  // Required loading strategy implementation
  Future<void> loadTilesProgressive(Rect viewport, double zoom) async {
    // Phase 1: Critical (immediate)
    final criticalTiles = _calculateViewportTiles(viewport);
    await _loadTiles(criticalTiles, priority: LoadPriority.immediate);
    
    // Phase 2: Prefetch (background)
    if (await _isConnectionFast()) {
      final prefetchArea = viewport.inflate(viewport.width);
      final prefetchTiles = _calculateViewportTiles(prefetchArea);
      _loadTiles(prefetchTiles, priority: LoadPriority.background);
    }
    
    // Phase 3: Cache (idle)
    if (await _isWifiConnected()) {
      _cacheFrequentAreas();
    }
  }
  
  // Compression from spec
  Uint8List _compressTileData(List<TileData> tiles) {
    // Delta encoding + zlib as specified
    final delta = _deltaEncode(tiles);
    return zlib.encode(delta);
  }
}
```

### 2.2 Network Optimization

```dart
// Network handling matching specifications
class NetworkOptimizer {
  // Adaptive quality from spec
  enum ConnectionQuality { wifi, fast4G, slow4G, slow3G, offline }
  
  ConnectionQuality _currentQuality = ConnectionQuality.wifi;
  
  // Batch settings from spec
  static const Map<ConnectionQuality, int> batchIntervals = {
    ConnectionQuality.wifi: 0,        // Real-time
    ConnectionQuality.fast4G: 100,    // 100ms batching
    ConnectionQuality.slow4G: 500,    // 500ms batching
    ConnectionQuality.slow3G: 1000,   // 1s batching
    ConnectionQuality.offline: -1,    // No updates
  };
  
  // Required network adaptation
  void adaptToNetwork() {
    _currentQuality = _detectConnectionQuality();
    
    switch (_currentQuality) {
      case ConnectionQuality.wifi:
        _setHighQualityMode();
        break;
      case ConnectionQuality.slow3G:
      case ConnectionQuality.offline:
        _setLowQualityMode();
        break;
      default:
        _setMediumQualityMode();
    }
  }
}
```

## 3. Touch Interaction Implementation

### 3.1 Touch Target Expansion

```dart
// Implements 44px minimum touch targets from spec
class ExpandedTouchTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Size visualSize;
  
  // Minimum touch target from spec
  static const double minTouchSize = 44.0;
  
  @override
  Widget build(BuildContext context) {
    // Calculate expanded hit box
    final expandedSize = Size(
      max(visualSize.width, minTouchSize),
      max(visualSize.height, minTouchSize),
    );
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: expandedSize.width,
        height: expandedSize.height,
        alignment: Alignment.center,
        child: SizedBox(
          width: visualSize.width,
          height: visualSize.height,
          child: child,
        ),
      ),
    );
  }
}
```

### 3.2 Haptic Feedback Patterns

```dart
// Haptic patterns from design specification
class HapticManager {
  // Feedback intensities from spec
  static Future<void> lightTap() async {
    if (Platform.isIOS) {
      await HapticFeedback.lightImpact();
    } else {
      await HapticFeedback.vibrate();
    }
  }
  
  static Future<void> successPattern() async {
    // Success pattern: double tap with pause
    await HapticFeedback.mediumImpact();
    await Future.delayed(Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }
  
  static Future<void> errorPattern() async {
    // Error pattern: rapid triple vibration
    for (int i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      if (i < 2) await Future.delayed(Duration(milliseconds: 50));
    }
  }
}
```

## 4. UI Component Specifications

### 4.1 Bottom Sheet Implementation

```dart
// Claim confirmation sheet from spec
class ClaimConfirmationSheet extends StatelessWidget {
  final TilePosition tilePosition;
  
  // Sheet height from spec
  static const double sheetHeight = 220.0;
  
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: sheetHeight / MediaQuery.of(context).size.height,
      minChildSize: 0.0,
      maxChildSize: sheetHeight / MediaQuery.of(context).size.height,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [designLanguage.shadowLg], // From design system
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content matching spec
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Claim This Tile?',
                      style: designLanguage.headingMedium),
                    SizedBox(height: 16),
                    _buildTileInfo(),
                    SizedBox(height: 24),
                    _buildClaimButton(),
                    SizedBox(height: 12),
                    _buildCancelButton(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### 4.2 Minimap Widget

```dart
// Minimap implementation from spec
class Minimap extends StatefulWidget {
  // Sizes from spec
  static const Size defaultSize = Size(120, 120);
  static const Size expandedSize = Size(200, 200);
  
  final MosaicData mosaicData;
  final Rect currentViewport;
  final Function(Offset) onViewportChange;
  
  @override
  _MinimapState createState() => _MinimapState();
}

class _MinimapState extends State<Minimap> 
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      right: 16,
      child: GestureDetector(
        onTap: _toggleSize,
        onPanUpdate: _handleViewportDrag,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOutBack, // Spring curve
          width: _isExpanded ? 200 : 120,
          height: _isExpanded ? 200 : 120,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [designLanguage.shadowMd],
          ),
          child: CustomPaint(
            painter: MinimapPainter(
              mosaicData: widget.mosaicData,
              viewport: widget.currentViewport,
              updateFrequency: Duration(seconds: 1), // From spec
            ),
          ),
        ),
      ),
    );
  }
}
```

## 5. Animation Specifications

### 5.1 Tile Claim Animation

```dart
// Claim effect from specification
class ClaimAnimation extends StatefulWidget {
  final Offset center;
  final Color teamColor;
  
  @override
  _ClaimAnimationState createState() => _ClaimAnimationState();
}

class _ClaimAnimationState extends State<ClaimAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Duration from spec
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Radial expansion effect
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 3.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    // Fade out
    _opacityAnimation = Tween<double>(
      begin: 0.8,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.5, 1.0),
    ));
    
    _controller.forward();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.center.dx - 50 * _scaleAnimation.value,
          top: widget.center.dy - 50 * _scaleAnimation.value,
          child: Container(
            width: 100 * _scaleAnimation.value,
            height: 100 * _scaleAnimation.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.teamColor.withOpacity(_opacityAnimation.value),
            ),
          ),
        );
      },
    );
  }
}
```

## 6. State Management Architecture

### 6.1 Riverpod Providers Structure

```dart
// State management from spec
// game_state_provider.dart
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier();
});

class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier() : super(GameState.initial());
  
  // Required state updates
  void updatePhase(GamePhase phase) {
    state = state.copyWith(currentPhase: phase);
  }
  
  void updateTile(TilePosition pos, TileData data) {
    // Optimistic update
    state = state.copyWith(
      tiles: state.tiles.update(pos, data),
      lastUpdate: DateTime.now(),
    );
  }
}

// mosaic_data_provider.dart
final mosaicDataProvider = FutureProvider.family
  .autoDispose<MosaicData, String>((ref, mosaicId) async {
  // Auto-dispose after 5 minutes as specified
  ref.keepAlive();
  Timer(Duration(minutes: 5), () => ref.invalidateSelf());
  
  return await MosaicRepository.fetch(mosaicId);
});

// websocket_provider.dart
final websocketProvider = StreamProvider<WebSocketMessage>((ref) {
  final ws = WebSocketConnection();
  
  // Automatic reconnection from spec
  ws.enableAutoReconnect(
    strategy: ExponentialBackoff(
      intervals: [1, 2, 4, 8, 16, 32], // seconds
    ),
  );
  
  return ws.messages;
});
```

## 7. Platform-Specific Implementations

### 7.1 iOS-Specific Code

```dart
// iOS adaptations from spec
class IOSAdaptations {
  static Widget buildScrollView({required Widget child}) {
    return ScrollConfiguration(
      behavior: IOSScrollBehavior(),
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(), // iOS bounce
        child: child,
      ),
    );
  }
  
  static Route buildPageRoute(Widget page) {
    return CupertinoPageRoute(
      builder: (_) => page,
      fullscreenDialog: false,
    );
  }
}
```

### 7.2 Android-Specific Code

```dart
// Android adaptations from spec
class AndroidAdaptations {
  static Widget buildScrollView({required Widget child}) {
    return ScrollConfiguration(
      behavior: AndroidScrollBehavior(),
      child: SingleChildScrollView(
        physics: ClampingScrollPhysics(), // Android clamping
        child: child,
      ),
    );
  }
  
  static Route buildPageRoute(Widget page) {
    return MaterialPageRoute(
      builder: (_) => page,
    );
  }
}
```

## 8. Performance Monitoring

### 8.1 Frame Rate Monitor

```dart
// Debug mode performance overlay from spec
class PerformanceMonitor extends StatefulWidget {
  @override
  _PerformanceMonitorState createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  double _currentFPS = 60.0;
  int _tileCount = 0;
  int _memoryUsage = 0;
  
  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return SizedBox.shrink();
    
    return Positioned(
      top: 50,
      left: 10,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FPS: ${_currentFPS.toStringAsFixed(1)}',
              style: TextStyle(color: _getFPSColor(), fontSize: 12)),
            Text('Frame: ${(1000 / _currentFPS).toStringAsFixed(0)}ms',
              style: TextStyle(color: Colors.white, fontSize: 12)),
            Text('Tiles: $_tileCount',
              style: TextStyle(color: Colors.white, fontSize: 12)),
            Text('Memory: ${_memoryUsage}MB',
              style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
  
  Color _getFPSColor() {
    if (_currentFPS >= 55) return Colors.green;
    if (_currentFPS >= 30) return Colors.yellow;
    return Colors.red;
  }
}
```

## 9. Critical Implementation Checklist

### Must-Have Features (MVP)
- [ ] Tile rendering with 3 zoom levels
- [ ] Touch targets minimum 44px
- [ ] Progressive loading (critical tiles first)
- [ ] Pan and pinch zoom with momentum
- [ ] Tile selection with haptic feedback
- [ ] Network status indicator
- [ ] Basic offline mode
- [ ] Claim action with confirmation

### Performance Requirements
- [ ] 60fps at overview zoom
- [ ] 30fps minimum at interaction zoom
- [ ] <3s initial load on 4G
- [ ] <200MB memory usage
- [ ] Smooth animations (no jank)

### Platform Compliance
- [ ] iOS bounce scrolling
- [ ] Android material transitions
- [ ] Proper safe area handling
- [ ] Platform-specific haptics
- [ ] Adaptive text scaling

## 10. Code Quality Standards

### Required Patterns
```dart
// ALWAYS use const constructors where possible
const MyWidget({Key? key}) : super(key: key);

// ALWAYS dispose controllers
@override
void dispose() {
  _animationController.dispose();
  _scrollController.dispose();
  super.dispose();
}

// ALWAYS use RepaintBoundary for complex widgets
RepaintBoundary(
  child: ExpensiveWidget(),
)

// NEVER rebuild entire tree for small changes
// Use selective Consumer widgets with Riverpod
```

### Performance Anti-Patterns to Avoid
```dart
// DON'T: Rebuild on every frame
setState(() {
  // Frequent updates
});

// DO: Use ValueListenableBuilder or Riverpod
ValueListenableBuilder<double>(
  valueListenable: zoomLevel,
  builder: (context, zoom, child) {
    // Only this rebuilds
  },
)

// DON'T: Create objects in build method
@override
Widget build(BuildContext context) {
  final paint = Paint(); // Bad! Creates every rebuild
}

// DO: Create once and reuse
static final _paint = Paint(); // Good! Single instance
```

## Version History

- 1.0.0 (2025-01-16): Complete Flutter implementation guide
  - Tile renderer specifications
  - Gesture handling requirements
  - Progressive loading implementation
  - Component specifications
  - Performance requirements
  - Platform adaptations

---

*This implementation guide provides mandatory technical requirements. All code must follow these specifications exactly. Deviations require explicit approval from the Design Authority.*