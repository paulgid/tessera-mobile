import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../discovery_screen.dart';
import '../../mosaic/mosaic_viewer.dart';

enum CardVariant { compact, standard, featured }

class MosaicPreviewCard extends StatefulWidget {
  final MosaicPreview mosaic;
  final CardVariant variant;
  final VoidCallback? onTap;

  const MosaicPreviewCard({
    super.key,
    required this.mosaic,
    required this.variant,
    this.onTap,
  });

  @override
  State<MosaicPreviewCard> createState() => _MosaicPreviewCardState();
}

class _MosaicPreviewCardState extends State<MosaicPreviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.variant) {
      case CardVariant.compact:
        return _buildCompactCard();
      case CardVariant.standard:
        return _buildStandardCard();
      case CardVariant.featured:
        return _buildFeaturedCard();
    }
  }

  Widget _buildCompactCard() {
    return GestureDetector(
      onTap: widget.onTap ?? () => _navigateToMosaic(context),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                ),
              ),
              child: Stack(
                children: [
                  if (widget.mosaic.status == MosaicStatus.live)
                    Positioned(top: 8, right: 8, child: _buildLiveIndicator()),
                  if (widget.mosaic.isTrending)
                    const Positioned(
                      top: 8,
                      left: 8,
                      child: Text('🔥', style: TextStyle(fontSize: 20)),
                    ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.mosaic.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (widget.mosaic.status == MosaicStatus.live)
                    Row(
                      children: [
                        const Icon(Icons.people, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          _formatPlayerCount(widget.mosaic.playerCount),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  else if (widget.mosaic.status == MosaicStatus.upcoming)
                    Text(
                      widget.mosaic.startsIn != null
                          ? 'in ${_formatDuration(widget.mosaic.startsIn!)}'
                          : 'Starting soon',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardCard() {
    return GestureDetector(
      onTap: widget.onTap ?? () => _navigateToMosaic(context),
      onLongPress: () => _showQuickPreview(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Hero Image
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade400, Colors.cyan.shade400],
                ),
              ),
              child: Stack(
                children: [
                  // Title overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0),
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.mosaic.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Status indicators
                  if (widget.mosaic.status == MosaicStatus.live)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _buildLiveIndicator(),
                    ),
                  if (widget.mosaic.isTrending)
                    const Positioned(
                      top: 12,
                      left: 12,
                      child: Text('🔥', style: TextStyle(fontSize: 24)),
                    ),
                ],
              ),
            ),

            // Stats Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.grid_on,
                    _formatTileCount(widget.mosaic.tileCount),
                  ),
                  _buildStatItem(
                    Icons.people,
                    _formatPlayerCount(widget.mosaic.playerCount),
                  ),
                  _buildStatItem(
                    Icons.groups,
                    '${widget.mosaic.teamCount} teams',
                  ),
                ],
              ),
            ),

            // Progress/Status
            if (widget.mosaic.status == MosaicStatus.live)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Phase: ${widget.mosaic.phase}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Text(
                          '42% complete',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.42,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ],
                ),
              )
            else if (widget.mosaic.status == MosaicStatus.upcoming)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Starting in ${_formatDuration(widget.mosaic.startsIn!)}',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _navigateToMosaic(context),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        widget.mosaic.status == MosaicStatus.live
                            ? 'Join'
                            : 'View',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: () {
                      // Add to favorites
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // Share
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Enhanced hero with animation
          Container(
            height: 250,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade400, Colors.pink.shade400],
              ),
            ),
            child: Stack(
              children: [
                // Animated sparkles
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: SparklesPainter(
                        animation: _animationController.value,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),

                // Content overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: 0.5),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.5, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.mosaic.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Create the ultimate collaborative artwork',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Live badge
                if (widget.mosaic.status == MosaicStatus.live)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _buildEnhancedLiveIndicator(),
                  ),
              ],
            ),
          ),

          // Live statistics
          if (widget.mosaic.status == MosaicStatus.live)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.red, size: 12),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatPlayerCount(widget.mosaic.playerCount)} active players',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      const Text('142 tiles/second'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.leaderboard, size: 16),
                      const SizedBox(width: 8),
                      const Text('Team Red leading (34%)'),
                    ],
                  ),
                ],
              ),
            ),

          // Team distribution
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Team Distribution',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildTeamBar('Red', 0.34, Colors.red),
                _buildTeamBar('Blue', 0.28, Colors.blue),
                _buildTeamBar('Green', 0.22, Colors.green),
                _buildTeamBar('Yellow', 0.16, Colors.yellow),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _navigateToMosaic(context),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Join This Mosaic',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.bookmark_border),
                      label: const Text('Favorite'),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                    TextButton.icon(
                      onPressed: () => _showQuickPreview(context),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedLiveIndicator() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(
                  alpha: 0.5 + 0.2 * _animationController.value,
                ),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.7 + 0.3 * _animationController.value,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamBar(String name, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(name, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(value * 100).toInt()}%',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatPlayerCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  String _formatTileCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M tiles';
    }
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}K tiles';
    return '$count tiles';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) return '${duration.inHours}h';
    if (duration.inMinutes > 0) return '${duration.inMinutes} min';
    return '${duration.inSeconds}s';
  }

  void _navigateToMosaic(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MosaicViewer()),
    );
  }

  void _showQuickPreview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickPreviewSheet(mosaic: widget.mosaic),
    );
  }
}

class _QuickPreviewSheet extends StatelessWidget {
  final MosaicPreview mosaic;

  const _QuickPreviewSheet({required this.mosaic});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      mosaic.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Preview image
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade400,
                            Colors.purple.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick stats
                    const Text(
                      '📊 Quick Stats',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('• ${mosaic.playerCount} active players'),
                    Text('• ${mosaic.tileCount} tiles (42% claimed)'),
                    if (mosaic.phase != null)
                      Text('• Phase: ${mosaic.phase} (12:45 left)'),
                    const Text('• Leading: Team Red (34%)'),
                    const SizedBox(height: 16),

                    // Tags
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: const Text('#seasonal')),
                        Chip(label: const Text('#art')),
                        Chip(label: const Text('#community')),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Join button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MosaicViewer(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Join This Mosaic'),
                    ),
                    const SizedBox(height: 12),

                    // Secondary actions
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.bookmark_border),
                            label: const Text('Favorite'),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.open_in_full),
                            label: const Text('Full View'),
                          ),
                        ),
                      ],
                    ),
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

class SparklesPainter extends CustomPainter {
  final double animation;

  SparklesPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final x =
          (size.width * (0.2 + i * 0.15)) +
          (size.width * 0.1 * math.sin(animation * 2 * math.pi + i));
      final y =
          (size.height * 0.3) +
          (size.height * 0.2 * math.cos(animation * 2 * math.pi + i * 0.5));
      final radius = 2 + 2 * math.sin(animation * 2 * math.pi + i * 0.3);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
