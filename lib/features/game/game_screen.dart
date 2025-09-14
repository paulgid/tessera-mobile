import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/game_update.dart';
import '../../core/models/tile.dart';
import '../../core/models/team.dart';
import '../../core/network/websocket_manager.dart';
import '../../providers/game_provider.dart';
import 'mosaic_painter.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String mosaicId;
  
  const GameScreen({Key? key, required this.mosaicId}) : super(key: key);
  
  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final TransformationController _transformationController = TransformationController();
  
  @override
  void initState() {
    super.initState();
    // Connect to the game when screen loads
    Future.microtask(() {
      ref.read(gameProvider.notifier).connectToMosaic(widget.mosaicId);
    });
  }
  
  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Mosaic: ${widget.mosaicId.substring(0, 8)}'),
        backgroundColor: Colors.grey.shade900,
        actions: [
          _buildConnectionIndicator(gameState.connectionStatus),
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            onPressed: _resetZoom,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPhaseIndicator(gameState.phase),
          _buildMetricsBar(gameState),
          Expanded(
            child: _buildMosaicView(gameState),
          ),
          _buildTeamsBar(gameState.teams),
        ],
      ),
    );
  }
  
  Widget _buildConnectionIndicator(ConnectionStatus status) {
    Color color;
    String tooltip;
    
    switch (status) {
      case ConnectionStatus.connected:
        color = Colors.green;
        tooltip = 'Connected';
        break;
      case ConnectionStatus.connecting:
        color = Colors.orange;
        tooltip = 'Connecting...';
        break;
      case ConnectionStatus.disconnected:
        color = Colors.red;
        tooltip = 'Disconnected';
        break;
      case ConnectionStatus.error:
        color = Colors.red;
        tooltip = 'Connection Error';
        break;
    }
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
  
  Widget _buildPhaseIndicator(GamePhase phase) {
    final phaseColors = {
      GamePhase.idle: Colors.grey,
      GamePhase.claim: Colors.blue,
      GamePhase.formation: Colors.orange,
      GamePhase.assembly: Colors.purple,
      GamePhase.complete: Colors.green,
    };
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      color: phaseColors[phase]?.withOpacity(0.2),
      child: Text(
        'Phase: ${phase.name.toUpperCase()}',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: phaseColors[phase],
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
  
  Widget _buildMetricsBar(GameState gameState) {
    final metrics = gameState.metrics;
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey.shade900,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMetric('Claimed', metrics?.claimedTiles ?? 0),
          _buildMetric('Placements', metrics?.totalPlacements ?? 0),
          _buildMetric('Bots', metrics?.activeBots ?? 0),
          _buildMetric(
            'Rate',
            '${metrics?.placementsPerSec.toStringAsFixed(1) ?? '0.0'}/s',
          ),
          if (metrics?.convergence != null)
            _buildMetric(
              'Convergence',
              '${(metrics!.convergence! * 100).toStringAsFixed(1)}%',
            ),
        ],
      ),
    );
  }
  
  Widget _buildMetric(String label, dynamic value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMosaicView(GameState gameState) {
    if (gameState.tiles.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.1,
      maxScale: 10.0,
      boundaryMargin: const EdgeInsets.all(80),
      child: Center(
        child: CustomPaint(
          size: Size(
            gameState.mosaicWidth * 10.0,
            gameState.mosaicHeight * 10.0,
          ),
          painter: MosaicPainter(
            tiles: gameState.tiles,
            width: gameState.mosaicWidth,
            height: gameState.mosaicHeight,
          ),
        ),
      ),
    );
  }
  
  Widget _buildTeamsBar(List<Team> teams) {
    if (teams.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 60,
      color: Colors.grey.shade900,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: teams.length,
        itemBuilder: (context, index) {
          final team = teams[index];
          return _buildTeamCard(team);
        },
      ),
    );
  }
  
  Widget _buildTeamCard(Team team) {
    return Container(
      width: 120,
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: team.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: team.color, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            team.name,
            style: TextStyle(
              color: team.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${team.tileCount} tiles',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          if (team.percentage > 0)
            Text(
              '${team.percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
  
  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }
}