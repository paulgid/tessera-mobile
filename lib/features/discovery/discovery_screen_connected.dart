import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/mosaic_provider.dart';
import '../../providers/websocket_provider.dart';
import '../../core/models/mosaic.dart';
import 'widgets/featured_banner.dart';
import 'widgets/mosaic_section.dart';
import '../search/search_screen.dart';
import '../search/id_entry_screen.dart';
import '../common/widgets/connection_indicator.dart';
import 'discovery_screen.dart' show MosaicPreview;
import 'discovery_screen.dart' as discovery;

class ConnectedDiscoveryScreen extends ConsumerStatefulWidget {
  const ConnectedDiscoveryScreen({super.key});

  @override
  ConsumerState<ConnectedDiscoveryScreen> createState() =>
      _ConnectedDiscoveryScreenState();
}

class _ConnectedDiscoveryScreenState
    extends ConsumerState<ConnectedDiscoveryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Auto-connect to WebSocket when screen initializes
    Future.microtask(() {
      ref.read(webSocketNotifierProvider.notifier).connectToMosaic('');
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Watch the auto-refresh to get real-time updates
    ref.watch(mosaicRefreshProvider);

    // Watch WebSocket state for real-time updates
    ref.watch(webSocketNotifierProvider);

    // Get mosaics from backend
    final mosaicsAsync = ref.watch(mosaicsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎨 Tessera'),
            const SizedBox(width: 12),
            const ConnectionDot(size: 10),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IdEntryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(mosaicsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(mosaicsProvider);
          await ref.read(mosaicsProvider.future);
        },
        child: mosaicsAsync.when(
          data: (mosaics) => _buildContent(mosaics),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error.toString()),
        ),
      ),
    );
  }

  Widget _buildContent(List<Mosaic> mosaics) {
    final liveMosaics = _convertToMosaicPreviews(
      mosaics.where((m) => m.isLive).toList(),
    );
    final upcomingMosaics = _convertToMosaicPreviews(
      mosaics.where((m) => m.isUpcoming).toList(),
    );
    final trendingMosaics = _convertToMosaicPreviews(
      mosaics.where((m) => m.isLive && m.status.activeBots > 100).toList(),
    );

    if (mosaics.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Featured Banner
        const SliverToBoxAdapter(child: FeaturedBanner()),

        // Live Now Section
        if (liveMosaics.isNotEmpty)
          SliverToBoxAdapter(
            child: MosaicSection(
              title: 'Live Now',
              icon: '🔴',
              mosaics: liveMosaics,
              onSeeAll: () => _navigateToFiltered('live'),
            ),
          ),

        // Starting Soon Section
        if (upcomingMosaics.isNotEmpty)
          SliverToBoxAdapter(
            child: MosaicSection(
              title: 'Starting Soon',
              icon: '⏰',
              mosaics: upcomingMosaics,
              onSeeAll: () => _navigateToFiltered('upcoming'),
            ),
          ),

        // Trending Section
        if (trendingMosaics.isNotEmpty)
          SliverToBoxAdapter(
            child: MosaicSection(
              title: 'Trending',
              icon: '🔥',
              mosaics: trendingMosaics,
              onSeeAll: () => _navigateToFiltered('trending'),
            ),
          ),

        // All Mosaics Section
        SliverToBoxAdapter(
          child: MosaicSection(
            title: 'All Mosaics',
            icon: '🎯',
            mosaics: _convertToMosaicPreviews(mosaics),
            onSeeAll: () => _navigateToBrowseAll(),
          ),
        ),

        // Bottom padding
        const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.grid_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No mosaics available',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later or create one!',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewMosaic,
            icon: const Icon(Icons.add),
            label: const Text('Create Mosaic'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Failed to load mosaics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(mosaicsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  List<MosaicPreview> _convertToMosaicPreviews(List<Mosaic> mosaics) {
    return mosaics.map((mosaic) {
      // Calculate grid dimensions (assuming square grid)

      return MosaicPreview(
        id: mosaic.mosaicId,
        name: mosaic.displayName,
        playerCount: mosaic.status.activeBots,
        tileCount: mosaic.status.totalTiles,
        status: mosaic.isLive
            ? discovery.MosaicStatus.live
            : mosaic.isUpcoming
            ? discovery.MosaicStatus.upcoming
            : discovery.MosaicStatus.completed,
        phase: mosaic.phaseText,
        startsIn: mosaic.isUpcoming
            ? const Duration(minutes: 5)
            : null, // Add startsIn for upcoming
        teamCount: 4, // Default team count
        isTrending: mosaic.status.activeBots > 100,
        imageUrl: '/assets/images/sample_mosaic.jpg',
      );
    }).toList();
  }

  void _navigateToFiltered(String filter) {
    // Navigate to browse with filter
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Filtering by: $filter')));
  }

  void _navigateToBrowseAll() {
    // Navigate to browse all
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Browse all mosaics')));
  }

  void _createNewMosaic() async {
    final actions = ref.read(mosaicActionsProvider.notifier);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    try {
      await actions.createMosaic(
        name: 'Test Mosaic ${DateTime.now().millisecondsSinceEpoch}',
        description: 'Created from mobile app',
        gridSize: 50,
      );
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mosaic created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
