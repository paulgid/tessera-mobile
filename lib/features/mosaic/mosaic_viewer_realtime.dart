import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/websocket_provider.dart';
import '../../providers/mosaic_provider.dart';
import '../../providers/game_provider.dart';
import '../../core/services/websocket_service.dart' as ws;

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

// Tile state for real-time updates
class TileState {
  final int x;
  final int y;
  final int? teamId;
  final bool isClaimed;
  final double claimIntensity;
  final DateTime lastUpdate;
  final Map<String, int>? color; // RGB color values

  TileState({
    required this.x,
    required this.y,
    this.teamId,
    required this.isClaimed,
    required this.claimIntensity,
    required this.lastUpdate,
    this.color,
  });
}

class MosaicViewerRealtime extends ConsumerStatefulWidget {
  final String mosaicId;
  final int gridSize;

  const MosaicViewerRealtime({
    super.key,
    required this.mosaicId,
    this.gridSize = 100,
  });

  @override
  ConsumerState<MosaicViewerRealtime> createState() =>
      _MosaicViewerRealtimeState();
}

class _MosaicViewerRealtimeState extends ConsumerState<MosaicViewerRealtime>
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

  // Tile selection and state
  Offset? _selectedTile;
  final Map<String, TileState> _tileStates = {};

  // Update batching for performance
  final List<ws.TileUpdate> _pendingUpdates = [];
  Timer? _updateBatchTimer;

  // Phase tracking
  int _currentPhase = 0;
  bool _gameEnded = false;
  int? _winningTeam;
  bool _overlayDismissed = false; // Track if user dismissed the overlay

  // Minimap
  final bool _showMinimap = true;
  Offset _minimapOffset = const Offset(20, 100);

  // Performance
  int _frameCount = 0;
  DateTime _lastFpsUpdate = DateTime.now();
  double _fps = 60.0;

  // Base size for calculations
  static const double baseImageSize = 1000.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Connect to WebSocket for this mosaic
    _connectToMosaic();

    // FPS counter
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFps());
  }

  void _connectToMosaic() {
    // Delay provider modification to avoid modifying during build
    Future.microtask(() {
      // Subscribe to this specific mosaic
      ref.read(webSocketNotifierProvider.notifier).subscribeTo(widget.mosaicId);
      // Load initial mosaic state
      _loadInitialMosaicState();
    });
  }

  Future<void> _loadInitialMosaicState() async {
    try {
      // Fetch initial mosaic state from REST API
      final apiClient = ref.read(apiClientProvider);

      // First get the mosaic status to know the phase
      try {
        final statusResponse = await apiClient.getMosaicStatus(widget.mosaicId);
        debugPrint('Mosaic status response: $statusResponse');
        if (statusResponse['phase'] != null) {
          setState(() {
            _currentPhase = statusResponse['phase'] as int;
            // Phase 4 is Complete phase
            if (_currentPhase == 4) {
              _gameEnded = true;
              // Backend returns 'dominance_leader' as the winning team in phase 4
              if (statusResponse['dominance_leader'] != null) {
                _winningTeam = statusResponse['dominance_leader'] as int;
                debugPrint('Set winning team from dominance_leader: $_winningTeam');
              } else if (statusResponse['winning_team'] != null) {
                _winningTeam = statusResponse['winning_team'] as int;
                debugPrint('Set winning team from winning_team: $_winningTeam');
              }
            }
          });
          debugPrint('Initial state set - Phase: $_currentPhase, GameEnded: $_gameEnded, WinningTeam: $_winningTeam');
        }
      } catch (e) {
        print('Could not fetch mosaic status: $e');
      }

      // Fetch the actual mosaic data with tiles
      final response = await apiClient.getMosaicData(widget.mosaicId);

      debugPrint('=== Loading Mosaic Data ===');
      debugPrint('Mosaic ID: ${widget.mosaicId}');
      debugPrint('Current Phase: $_currentPhase');

      if (response['tiles'] != null) {
        final tiles = response['tiles'] as List;
        debugPrint('Total tiles received: ${tiles.length}');

        int tilesWithColor = 0;
        int tilesWithoutColor = 0;

        if (!mounted) return;
        setState(() {
          for (final tile in tiles) {
            final position = tile['position'] ?? {};
            final x = position['x'] ?? 0;
            final y = position['y'] ?? 0;
            final key = '$x,$y';

            Map<String, int>? color;
            if (tile['color'] != null) {
              color = {
                'r': tile['color']['r'] ?? 0,
                'g': tile['color']['g'] ?? 0,
                'b': tile['color']['b'] ?? 0,
              };
              tilesWithColor++;
            } else {
              tilesWithoutColor++;
              // Log some tiles without color for debugging
              if (tilesWithoutColor <= 5) {
                debugPrint('Tile at ($x,$y) has no color data. Raw tile: $tile');
              }
            }

            _tileStates[key] = TileState(
              x: x,
              y: y,
              teamId: tile['owner'],
              isClaimed: tile['is_claimed'] ?? false,
              claimIntensity: (tile['claim_intensity'] ?? 0.0).toDouble(),
              lastUpdate: DateTime.now(),
              color: color,
            );
          }
        });

        debugPrint('Tiles with color: $tilesWithColor');
        debugPrint('Tiles without color: $tilesWithoutColor');
        debugPrint('=== End Loading Mosaic Data ===');
      }
    } catch (e) {
      print('Error loading initial mosaic state: $e');
    }
  }

  void _updateFps() {
    if (!mounted) return;

    _frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(_lastFpsUpdate).inMilliseconds;

    if (elapsed > 1000) {
      if (mounted) {
        setState(() {
          _fps = (_frameCount * 1000 / elapsed).clamp(0, 120);
          _frameCount = 0;
          _lastFpsUpdate = now;
        });
      }
    }

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateFps());
    }
  }

  void _handleTileUpdate(ws.TileUpdate update) {
    // Batch updates for performance
    _pendingUpdates.add(update);

    // Debounce updates to prevent excessive redraws
    _updateBatchTimer?.cancel();
    _updateBatchTimer = Timer(const Duration(milliseconds: 16), () {
      _processPendingUpdates();
    });
  }

  void _processPendingUpdates() {
    if (!mounted || _pendingUpdates.isEmpty) return;

    setState(() {
      for (final update in _pendingUpdates) {
        final key = '${update.x},${update.y}';

        // Extract color if present
        Map<String, int>? color;
        if (update.color != null) {
          color = {
            'r': update.color!.r,
            'g': update.color!.g,
            'b': update.color!.b,
          };
        }

        _tileStates[key] = TileState(
          x: update.x,
          y: update.y,
          teamId: update.teamId,
          isClaimed: update.isClaimed,
          claimIntensity: update.claimIntensity,
          lastUpdate: DateTime.now(),
          color: color,
        );
      }
      _pendingUpdates.clear();
    });
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
    final tileX = (transformedPosition.dx / (baseImageSize / widget.gridSize))
        .floor();
    final tileY = (transformedPosition.dy / (baseImageSize / widget.gridSize))
        .floor();

    if (tileX >= 0 &&
        tileX < widget.gridSize &&
        tileY >= 0 &&
        tileY < widget.gridSize) {
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
    final tileKey = '$x,$y';
    final tileState = _tileStates[tileKey];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 260,
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
              'Tile Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text('Position: ($x, $y)'),
            if (_currentPhase == 0) ...[
              Text(
                tileState?.isClaimed == true
                    ? 'Status: Claimed'
                    : 'Status: Unclaimed',
                style: TextStyle(
                  color: tileState?.isClaimed == true
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
              if (tileState?.isClaimed == true)
                Text(
                  'Intensity: ${((tileState?.claimIntensity ?? 0) * 100).toStringAsFixed(0)}%',
                ),
            ] else ...[
              Text(
                'Team: ${tileState?.teamId ?? "None"}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            const Spacer(),
            if (_currentPhase == 0)
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
                        onPressed: tileState?.isClaimed == true
                            ? null
                            : () => _claimTile(x, y),
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

  Future<void> _claimTile(int x, int y) async {
    Navigator.pop(context);

    try {
      // Call backend API to claim tile
      await ref
          .read(mosaicActionsProvider.notifier)
          .claimTile(mosaicId: widget.mosaicId, x: x, y: y);

      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tile ($x, $y) claimed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim tile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _animateToScale(double targetScale, Offset focalPoint) {
    final Matrix4 start = _transformController.value;
    // ignore: deprecated_member_use
    final Matrix4 end = Matrix4.identity()
      // ignore: deprecated_member_use
      ..translate(focalPoint.dx, focalPoint.dy, 0.0)
      // ignore: deprecated_member_use
      ..scale(targetScale, targetScale, 1.0)
      // ignore: deprecated_member_use
      ..translate(-focalPoint.dx, -focalPoint.dy, 0.0);

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
    // Watch for WebSocket updates
    final wsState = ref.watch(webSocketNotifierProvider);

    // Handle tile updates
    if (wsState.lastTileUpdate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handleTileUpdate(wsState.lastTileUpdate!);
        }
      });
    }

    // Update phase only if WebSocket provides a new value (don't overwrite with 0)
    if (wsState.currentPhase != null) {
      _currentPhase = wsState.currentPhase!;
    }
    // Update game ended state if provided
    if (wsState.gameEnded == true && !_gameEnded) {
      _gameEnded = true;
      _winningTeam = wsState.winningTeam;
      debugPrint('Game ended via WebSocket - WinningTeam: $_winningTeam');
    }

    // Also check if we're in phase 4 but haven't set game ended yet
    if (_currentPhase == 4 && !_gameEnded) {
      debugPrint('Detected phase 4 but gameEnded is false - fixing state');
      _gameEnded = true;
      // If we don't have a winning team yet, try to get it from status
      if (_winningTeam == null) {
        _loadInitialMosaicState();
      }
    }

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

          // Game end overlay (only show if not dismissed)
          if (_gameEnded && !_overlayDismissed) _buildGameEndOverlay(),
        ],
      ),
    );
  }

  Widget _buildMosaicViewer() {
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
          painter: RealtimeMosaicPainter(
            tileStates: _tileStates,
            scale: _currentScale,
            zoomLevel: _currentZoomLevel,
            selectedTile: _selectedTile,
            gridSize: widget.gridSize,
            currentPhase: _currentPhase,
            winningTeam: _winningTeam,
            gameEnded: _gameEnded,
          ),
        ),
      ),
    );
  }

  Widget _buildTopHud() {
    final connectionState = ref.watch(webSocketConnectionProvider);

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
                  Text(
                    'Mosaic ${widget.mosaicId}',
                    style: const TextStyle(
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

            // Connection indicator
            connectionState.when(
              data: (state) => Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: state == ws.ConnectionState.connected
                      ? Colors.green
                      : state == ws.ConnectionState.connecting
                      ? Colors.orange
                      : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              loading: () => Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              error: (_, __) => Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getPhaseColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Phase: ${_getPhaseText()}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPhaseText() {
    switch (_currentPhase) {
      case 0:
        return 'Claim';
      case 1:
        return 'Formation';
      case 2:
      case 3:
        return 'Assembly';
      case 4:
        return 'Complete';
      default:
        return 'Unknown';
    }
  }

  Color _getPhaseColor() {
    switch (_currentPhase) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.purple;
      case 2:
      case 3:
        return Colors.orange;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
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
          child: CustomPaint(
            size: const Size(120, 120),
            painter: MinimapPainter(
              tileStates: _tileStates,
              gridSize: widget.gridSize,
              viewportTransform: _transformController.value,
              mosaicSize: baseImageSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    final claimedCount = _tileStates.values
        .where((tile) => tile.isClaimed)
        .length;
    final totalTiles = widget.gridSize * widget.gridSize;
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
                const Icon(Icons.grid_on, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Claimed tiles: $claimedCount / $totalTiles',
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
            if (_selectedTile != null && _currentPhase == 0)
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
                child: const Text('View Tile Details'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameEndOverlay() {
    // Show a dismissible notification at the top instead of blocking the whole view
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          // Dismiss the overlay notification
          setState(() {
            _overlayDismissed = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade800.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, size: 32, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Game Complete!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Team $_winningTeam Victory! Tap to dismiss.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () {
                  setState(() {
                    _overlayDismissed = true;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Cancel timers first
    _tapTimer?.cancel();
    _updateBatchTimer?.cancel();

    // Dispose animation controllers
    _animationController.dispose();
    _transformController.dispose();

    // Note: WebSocket cleanup is handled by autoDispose providers
    // Don't access ref during disposal to avoid lifecycle issues

    super.dispose();
  }
}

class RealtimeMosaicPainter extends CustomPainter {
  final Map<String, TileState> tileStates;
  final double scale;
  final ZoomLevel zoomLevel;
  final Offset? selectedTile;
  final int gridSize;
  final int currentPhase;
  final int? winningTeam;
  final bool gameEnded;

  RealtimeMosaicPainter({
    required this.tileStates,
    required this.scale,
    required this.zoomLevel,
    required this.selectedTile,
    required this.gridSize,
    required this.currentPhase,
    this.winningTeam,
    this.gameEnded = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tileSize = size.width / gridSize;

    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.grey[800]!,
    );

    // Always draw tiles based on zoom level - this shows the actual mosaic state
    if (zoomLevel == ZoomLevel.interaction || zoomLevel == ZoomLevel.detail) {
      _drawInteractionLevel(canvas, size, tileSize);
    } else if (zoomLevel == ZoomLevel.navigation) {
      _drawNavigationLevel(canvas, size);
    } else {
      _drawOverviewLevel(canvas, size);
    }

    // When game is complete, optionally add a subtle overlay effect
    if (currentPhase == 4 && gameEnded) {
      // Add a very subtle vignette effect to indicate completion
      final gradient = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.1),
        ],
      );
      final paint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }
  }

  void _drawInteractionLevel(Canvas canvas, Size size, double tileSize) {
    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= gridSize; i++) {
      final x = i * tileSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, x), Offset(size.width, x), gridPaint);
    }

    // Draw tiles
    for (final entry in tileStates.entries) {
      final tile = entry.value;
      final rect = Rect.fromLTWH(
        tile.x * tileSize,
        tile.y * tileSize,
        tileSize,
        tileSize,
      );

      // First priority: If we have actual color data, always use it
      if (tile.color != null) {
        // Use the actual color from the tile
        final tilePaint = Paint()
          ..color = Color.fromARGB(
            255,
            tile.color!['r'] ?? 0,
            tile.color!['g'] ?? 0,
            tile.color!['b'] ?? 0,
          )
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, tilePaint);
      }
      // Second priority: If it's claim phase and tile is claimed, show claim visualization
      else if (currentPhase == 0 && tile.isClaimed) {
        final claimPaint = Paint()
          ..color = Colors.blue.withValues(alpha: tile.claimIntensity * 0.5)
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, claimPaint);

        // Draw claim pattern
        final patternPaint = Paint()
          ..color = Colors.blue.withValues(alpha: tile.claimIntensity)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        // Draw diagonal lines for claimed tiles
        for (int i = 0; i < 3; i++) {
          final offset = (i + 1) * tileSize / 4;
          canvas.drawLine(
            rect.topLeft + Offset(offset, 0),
            rect.topLeft + Offset(0, offset),
            patternPaint,
          );
          canvas.drawLine(
            rect.bottomRight - Offset(offset, 0),
            rect.bottomRight - Offset(0, offset),
            patternPaint,
          );
        }
      }
      // Third priority: If tile is claimed but no color, only show blue in claim phase
      else if (tile.isClaimed && currentPhase == 0) {
        final claimPaint = Paint()
          ..color = Colors.blue.withValues(alpha: tile.claimIntensity * 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, claimPaint);
      }
      // Fallback: Show grey for tiles with team but no color
      else if (tile.teamId != null) {
        final teamPaint = Paint()
          ..color = Colors.grey.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, teamPaint);
      }

      // Animate recently updated tiles
      final timeSinceUpdate = DateTime.now().difference(tile.lastUpdate);
      if (timeSinceUpdate.inMilliseconds < 500) {
        final animationProgress =
            1.0 - (timeSinceUpdate.inMilliseconds / 500.0);
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: animationProgress * 0.5)
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, glowPaint);
      }
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
    // Draw chunked view (5x5 tiles per chunk)
    const chunkSize = 5;
    final chunkPixelSize = size.width / (gridSize / chunkSize);

    final chunkPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= gridSize / chunkSize; i++) {
      final x = i * chunkPixelSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), chunkPaint);
      canvas.drawLine(Offset(0, x), Offset(size.width, x), chunkPaint);
    }

    // Draw each chunk with averaged colors
    for (int chunkX = 0; chunkX < gridSize / chunkSize; chunkX++) {
      for (int chunkY = 0; chunkY < gridSize / chunkSize; chunkY++) {
        int totalR = 0, totalG = 0, totalB = 0;
        int validTileCount = 0;

        // Average the colors in this chunk using the SAME logic as interaction level
        for (int x = chunkX * chunkSize; x < (chunkX + 1) * chunkSize && x < gridSize; x++) {
          for (int y = chunkY * chunkSize; y < (chunkY + 1) * chunkSize && y < gridSize; y++) {
            final tileKey = '$x,$y';
            final tile = tileStates[tileKey];

            if (tile != null) {
              // ONLY average actual color data from tiles, not claim visualizations
              // This ensures navigation view shows the actual image colors only
              if (tile.color != null) {
                totalR += tile.color!['r'] ?? 0;
                totalG += tile.color!['g'] ?? 0;
                totalB += tile.color!['b'] ?? 0;
                validTileCount++;
              }
            }
          }
        }

        // Draw the averaged color
        if (validTileCount > 0) {
          final avgR = (totalR / validTileCount).round().clamp(0, 255);
          final avgG = (totalG / validTileCount).round().clamp(0, 255);
          final avgB = (totalB / validTileCount).round().clamp(0, 255);

          final paint = Paint()
            ..color = Color.fromARGB(255, avgR, avgG, avgB)
            ..style = PaintingStyle.fill;

          canvas.drawRect(
            Rect.fromLTWH(
              chunkX * chunkPixelSize,
              chunkY * chunkPixelSize,
              chunkPixelSize,
              chunkPixelSize,
            ),
            paint,
          );
        }
      }
    }
  }

  void _drawOverviewLevel(Canvas canvas, Size size) {
    // Show heat map of activity
    const blockSize = 10;
    final blockPixelSize = size.width / (gridSize / blockSize);

    for (int blockX = 0; blockX < gridSize / blockSize; blockX++) {
      for (int blockY = 0; blockY < gridSize / blockSize; blockY++) {
        // For completed mosaics, just copy what the interaction level does
        // Iterate through all tiles in this block and average their displayed colors
        int totalR = 0, totalG = 0, totalB = 0;
        int validTileCount = 0;

        for (int x = blockX * blockSize; x < (blockX + 1) * blockSize && x < gridSize; x++) {
          for (int y = blockY * blockSize; y < (blockY + 1) * blockSize && y < gridSize; y++) {
            final tileKey = '$x,$y';
            final tile = tileStates[tileKey];

            if (tile != null) {
              // ONLY average actual color data from tiles, not claim visualizations
              // This ensures zoom-out shows the actual image, not mixed with blue claims
              if (tile.color != null) {
                // Only count tiles with actual color data
                totalR += tile.color!['r'] ?? 0;
                totalG += tile.color!['g'] ?? 0;
                totalB += tile.color!['b'] ?? 0;
                validTileCount++;
              }
            }
          }
        }

        // Draw the averaged color for this block
        if (validTileCount > 0) {
          final avgR = (totalR / validTileCount).round().clamp(0, 255);
          final avgG = (totalG / validTileCount).round().clamp(0, 255);
          final avgB = (totalB / validTileCount).round().clamp(0, 255);

          final paint = Paint()
            ..color = Color.fromARGB(255, avgR, avgG, avgB)
            ..style = PaintingStyle.fill;

          canvas.drawRect(
            Rect.fromLTWH(
              blockX * blockPixelSize,
              blockY * blockPixelSize,
              blockPixelSize,
              blockPixelSize,
            ),
            paint,
          );
        }
      }
    }
  }


  @override
  bool shouldRepaint(RealtimeMosaicPainter oldDelegate) {
    return oldDelegate.tileStates != tileStates ||
        oldDelegate.scale != scale ||
        oldDelegate.selectedTile != selectedTile ||
        oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.currentPhase != currentPhase;
  }
}

class MinimapPainter extends CustomPainter {
  final Map<String, TileState> tileStates;
  final int gridSize;
  final Matrix4 viewportTransform;
  final double mosaicSize;

  MinimapPainter({
    required this.tileStates,
    required this.gridSize,
    required this.viewportTransform,
    required this.mosaicSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw minimap background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black,
    );

    // Draw tile states as pixels
    final pixelSize = size.width / gridSize;

    for (final entry in tileStates.entries) {
      final tile = entry.value;

      // Show actual tile colors in minimap, same as main view
      Color? tileColor;
      if (tile.color != null) {
        // Show actual color if available
        tileColor = Color.fromARGB(
          255,
          tile.color!['r'] ?? 0,
          tile.color!['g'] ?? 0,
          tile.color!['b'] ?? 0,
        );
      } else if (tile.isClaimed) {
        // Only show blue for claimed tiles without color data
        tileColor = Colors.blue.withValues(alpha: tile.claimIntensity * 0.8);
      } else if (tile.teamId != null) {
        // Grey for tiles with team but no color
        tileColor = Colors.grey.withValues(alpha: 0.5);
      }

      if (tileColor != null) {
        final paint = Paint()
          ..color = tileColor
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromLTWH(
            tile.x * pixelSize,
            tile.y * pixelSize,
            pixelSize,
            pixelSize,
          ),
          paint,
        );
      }
    }

    // Draw viewport indicator
    final scale = viewportTransform.getMaxScaleOnAxis();
    final translation = viewportTransform.getTranslation();

    final viewportWidth = size.width / scale;
    final viewportHeight = size.height / scale;
    final viewportX = -translation.x / scale;
    final viewportY = -translation.y / scale;

    final minimapScale = size.width / mosaicSize;

    final rect = Rect.fromLTWH(
      viewportX * minimapScale,
      viewportY * minimapScale,
      viewportWidth * minimapScale,
      viewportHeight * minimapScale,
    );

    final viewportPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, viewportPaint);
  }


  @override
  bool shouldRepaint(MinimapPainter oldDelegate) {
    return oldDelegate.tileStates != tileStates ||
        oldDelegate.viewportTransform != viewportTransform;
  }
}
