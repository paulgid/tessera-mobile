import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Zoom level definitions based on UX design specs
enum ZoomLevel {
  overview(0.01, 0.05), // Aggregate view
  navigation(0.06, 0.25), // Pattern view
  interaction(0.26, 1.0), // Individual tiles
  detail(1.1, 4.0); // Inspection

  final double min;
  final double max;
  const ZoomLevel(this.min, this.max);

  static ZoomLevel fromScale(double scale) {
    if (scale <= 0.05) return overview;
    if (scale <= 0.25) return navigation;
    if (scale <= 1.0) return interaction;
    return detail;
  }
}

class MosaicViewer extends StatefulWidget {
  const MosaicViewer({super.key});

  @override
  State<MosaicViewer> createState() => _MosaicViewerState();
}

class _MosaicViewerState extends State<MosaicViewer>
    with TickerProviderStateMixin {
  // Transformation controls
  final TransformationController _transformController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  // Gesture detection
  TapDownDetails? _tapDownDetails;
  Timer? _tapTimer;
  bool _isPanning = false;

  // Tile selection
  Offset? _selectedTile;
  final Set<Offset> _claimedTiles = {};

  // Image data
  ui.Image? _image;
  bool _imageLoading = true;

  // Minimap
  final bool _showMinimap = true;
  Offset _minimapOffset = const Offset(20, 100);

  // Performance
  int _frameCount = 0;
  DateTime _lastFpsUpdate = DateTime.now();
  double _fps = 60.0;

  // Grid settings (100x100 mosaic)
  static const int gridSize = 100;
  static const double baseImageSize = 1000.0; // Base size for calculations

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadImage();

    // FPS counter
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFps());
  }

  Future<void> _loadImage() async {
    try {
      final ByteData data = await rootBundle.load(
        'assets/images/sample_mosaic.jpg',
      );
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 1200,
        targetHeight: 1200,
      );
      final frame = await codec.getNextFrame();

      if (mounted) {
        setState(() {
          _image = frame.image;
          _imageLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    }
  }

  void _updateFps() {
    if (!mounted) return;

    _frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(_lastFpsUpdate).inMilliseconds;

    if (elapsed > 1000) {
      setState(() {
        _fps = (_frameCount * 1000 / elapsed).clamp(0, 120);
        _frameCount = 0;
        _lastFpsUpdate = now;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFps());
  }

  double get _currentScale {
    return _transformController.value.getMaxScaleOnAxis();
  }

  ZoomLevel get _currentZoomLevel {
    return ZoomLevel.fromScale(_currentScale);
  }

  void _handleTapDown(TapDownDetails details) {
    _tapDownDetails = details;

    // Start disambiguation timer (50ms as per UX spec)
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 50), () {
      if (!_isPanning && _tapDownDetails != null) {
        _handleTileSelection(_tapDownDetails!);
      }
    });
  }

  void _handleTileSelection(TapDownDetails details) {
    if (_currentZoomLevel != ZoomLevel.interaction &&
        _currentZoomLevel != ZoomLevel.detail) {
      return;
    }

    // Convert tap position to tile coordinates
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // Get the transform matrix
    final Matrix4 transform = _transformController.value;
    final Matrix4 inverse = Matrix4.inverted(transform);

    // Transform the tap position to the mosaic coordinate space
    final transformedPosition = MatrixUtils.transformPoint(
      inverse,
      localPosition,
    );

    // Calculate tile position
    final tileX = (transformedPosition.dx / (baseImageSize / gridSize)).floor();
    final tileY = (transformedPosition.dy / (baseImageSize / gridSize)).floor();

    if (tileX >= 0 && tileX < gridSize && tileY >= 0 && tileY < gridSize) {
      setState(() {
        _selectedTile = Offset(tileX.toDouble(), tileY.toDouble());
      });

      // Haptic feedback
      HapticFeedback.lightImpact();

      // Show claim dialog
      _showClaimDialog(tileX, tileY);
    }
  }

  void _showClaimDialog(int x, int y) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 220,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Claim This Tile?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Position: ($x, $y)'),
            Text(
              _claimedTiles.contains(Offset(x.toDouble(), y.toDouble()))
                  ? 'Status: Already Claimed'
                  : 'Status: Unclaimed',
              style: TextStyle(
                color:
                    _claimedTiles.contains(Offset(x.toDouble(), y.toDouble()))
                    ? Colors.orange
                    : Colors.green,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _claimedTiles.contains(
                            Offset(x.toDouble(), y.toDouble()),
                          )
                          ? null
                          : () {
                              setState(() {
                                _claimedTiles.add(
                                  Offset(x.toDouble(), y.toDouble()),
                                );
                              });
                              HapticFeedback.mediumImpact();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Tile ($x, $y) claimed!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Claim Tile'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _animateToScale(double targetScale, Offset focalPoint) {
    final Matrix4 start = _transformController.value;
    final Matrix4 end = Matrix4.identity()
      ..translate(focalPoint.dx, focalPoint.dy)
      ..scale(targetScale)
      ..translate(-focalPoint.dx, -focalPoint.dy);

    _animation = Matrix4Tween(begin: start, end: end).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animation!.addListener(() {
      _transformController.value = _animation!.value;
    });

    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Stack(
        children: [
          // Main mosaic viewer
          _buildMosaicViewer(),

          // Top HUD
          _buildTopHud(),

          // Minimap
          if (_showMinimap) _buildMinimap(),

          // Bottom info panel
          _buildBottomPanel(),

          // FPS counter (debug)
          if (const bool.fromEnvironment('dart.vm.product') == false)
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'FPS: ${_fps.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.green, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMosaicViewer() {
    if (_imageLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapCancel: () {
        _tapTimer?.cancel();
        _tapDownDetails = null;
      },
      onDoubleTap: () {
        // Zoom in on double tap
        final center = Offset(
          MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height / 2,
        );
        final newScale = (_currentScale * 2).clamp(0.01, 4.0);
        _animateToScale(newScale, center);
      },
      child: InteractiveViewer(
        transformationController: _transformController,
        minScale: 0.01,
        maxScale: 4.0,
        constrained: false,
        onInteractionStart: (_) {
          _isPanning = true;
          _tapTimer?.cancel();
        },
        onInteractionEnd: (_) {
          _isPanning = false;
        },
        child: CustomPaint(
          size: const Size(baseImageSize, baseImageSize),
          painter: MosaicPainter(
            image: _image,
            scale: _currentScale,
            zoomLevel: _currentZoomLevel,
            selectedTile: _selectedTile,
            claimedTiles: _claimedTiles,
            gridSize: gridSize,
          ),
        ),
      ),
    );
  }

  Widget _buildTopHud() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          left: 16,
          right: 16,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.black54, Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sample Mosaic',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Zoom: ${_currentZoomLevel.name} (${(_currentScale * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Phase: Claim',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimap() {
    return Positioned(
      left: _minimapOffset.dx,
      top: _minimapOffset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _minimapOffset += details.delta;
          });
        },
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: Stack(
            children: [
              // Mini image
              if (_image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: RawImage(image: _image, fit: BoxFit.cover),
                ),

              // Viewport indicator
              CustomPaint(
                size: const Size(120, 120),
                painter: MinimapViewportPainter(
                  viewportTransform: _transformController.value,
                  mosaicSize: baseImageSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    final claimedCount = _claimedTiles.length;
    final totalTiles = gridSize * gridSize;
    final claimedPercent = (claimedCount / totalTiles * 100);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.black54, Colors.transparent],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Your tiles: $claimedCount',
                  style: const TextStyle(color: Colors.white),
                ),
                const Spacer(),
                Text(
                  '${claimedPercent.toStringAsFixed(1)}% claimed',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedTile != null)
              ElevatedButton(
                onPressed: () {
                  _showClaimDialog(
                    _selectedTile!.dx.toInt(),
                    _selectedTile!.dy.toInt(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text('Claim Selected Tile'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _transformController.dispose();
    _animationController.dispose();
    _tapTimer?.cancel();
    super.dispose();
  }
}

class MosaicPainter extends CustomPainter {
  final ui.Image? image;
  final double scale;
  final ZoomLevel zoomLevel;
  final Offset? selectedTile;
  final Set<Offset> claimedTiles;
  final int gridSize;

  MosaicPainter({
    required this.image,
    required this.scale,
    required this.zoomLevel,
    required this.selectedTile,
    required this.claimedTiles,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;

    final tileSize = size.width / gridSize;

    // Draw base image
    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(
      image!,
      Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    // Draw grid and tiles based on zoom level
    if (zoomLevel == ZoomLevel.interaction || zoomLevel == ZoomLevel.detail) {
      _drawInteractionLevel(canvas, size, tileSize);
    } else if (zoomLevel == ZoomLevel.navigation) {
      _drawNavigationLevel(canvas, size);
    } else {
      _drawOverviewLevel(canvas, size);
    }
  }

  void _drawInteractionLevel(Canvas canvas, Size size, double tileSize) {
    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= gridSize; i++) {
      final x = i * tileSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, x), Offset(size.width, x), gridPaint);
    }

    // Draw claimed tiles
    final claimPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (final tile in claimedTiles) {
      final rect = Rect.fromLTWH(
        tile.dx * tileSize,
        tile.dy * tileSize,
        tileSize,
        tileSize,
      );
      canvas.drawRect(rect, claimPaint);

      // Draw claim pattern
      final patternPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        rect.topLeft + Offset(tileSize * 0.2, tileSize * 0.2),
        rect.bottomRight - Offset(tileSize * 0.2, tileSize * 0.2),
        patternPaint,
      );
    }

    // Draw selected tile
    if (selectedTile != null) {
      final rect = Rect.fromLTWH(
        selectedTile!.dx * tileSize,
        selectedTile!.dy * tileSize,
        tileSize,
        tileSize,
      );

      final selectPaint = Paint()
        ..color = Colors.yellow
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawRect(rect, selectPaint);
    }
  }

  void _drawNavigationLevel(Canvas canvas, Size size) {
    // Draw chunked view (20x20 chunks)
    const chunkSize = 5; // 5x5 tiles per chunk
    final chunkPixelSize = size.width / (gridSize / chunkSize);

    final chunkPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= gridSize / chunkSize; i++) {
      final x = i * chunkPixelSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), chunkPaint);
      canvas.drawLine(Offset(0, x), Offset(size.width, x), chunkPaint);
    }

    // Draw claimed chunks
    final claimPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    for (final tile in claimedTiles) {
      final chunkX = (tile.dx / chunkSize).floor();
      final chunkY = (tile.dy / chunkSize).floor();

      final rect = Rect.fromLTWH(
        chunkX * chunkPixelSize,
        chunkY * chunkPixelSize,
        chunkPixelSize,
        chunkPixelSize,
      );
      canvas.drawRect(rect, claimPaint);
    }
  }

  void _drawOverviewLevel(Canvas canvas, Size size) {
    // Show heat map of claims
    final heatmapPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Aggregate tiles into larger blocks (10x10)
    const blockSize = 10;
    final blockPixelSize = size.width / (gridSize / blockSize);

    for (int blockX = 0; blockX < gridSize / blockSize; blockX++) {
      for (int blockY = 0; blockY < gridSize / blockSize; blockY++) {
        int claimCount = 0;

        // Count claimed tiles in this block
        for (int x = blockX * blockSize; x < (blockX + 1) * blockSize; x++) {
          for (int y = blockY * blockSize; y < (blockY + 1) * blockSize; y++) {
            if (claimedTiles.contains(Offset(x.toDouble(), y.toDouble()))) {
              claimCount++;
            }
          }
        }

        if (claimCount > 0) {
          final intensity = claimCount / (blockSize * blockSize);
          heatmapPaint.color = Colors.blue.withValues(alpha: intensity * 0.7);

          canvas.drawRect(
            Rect.fromLTWH(
              blockX * blockPixelSize,
              blockY * blockPixelSize,
              blockPixelSize,
              blockPixelSize,
            ),
            heatmapPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(MosaicPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.selectedTile != selectedTile ||
        oldDelegate.claimedTiles != claimedTiles ||
        oldDelegate.zoomLevel != zoomLevel;
  }
}

class MinimapViewportPainter extends CustomPainter {
  final Matrix4 viewportTransform;
  final double mosaicSize;

  MinimapViewportPainter({
    required this.viewportTransform,
    required this.mosaicSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate viewport rectangle in minimap space
    final scale = viewportTransform.getMaxScaleOnAxis();
    final translation = viewportTransform.getTranslation();

    // Viewport size in mosaic coordinates
    final viewportWidth = size.width / scale;
    final viewportHeight = size.height / scale;

    // Viewport position in mosaic coordinates
    final viewportX = -translation.x / scale;
    final viewportY = -translation.y / scale;

    // Convert to minimap coordinates
    final minimapScale = size.width / mosaicSize;

    final rect = Rect.fromLTWH(
      viewportX * minimapScale,
      viewportY * minimapScale,
      viewportWidth * minimapScale,
      viewportHeight * minimapScale,
    );

    // Draw viewport indicator
    final paint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, paint);

    // Draw center dot
    final centerPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    canvas.drawCircle(rect.center, 2, centerPaint);
  }

  @override
  bool shouldRepaint(MinimapViewportPainter oldDelegate) {
    return oldDelegate.viewportTransform != viewportTransform;
  }
}
