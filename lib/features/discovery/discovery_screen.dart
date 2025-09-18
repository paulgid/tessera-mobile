import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/featured_banner.dart';
import 'widgets/mosaic_section.dart';
import '../search/search_screen.dart';
import '../search/id_entry_screen.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎨 Tessera'),
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh data
          await Future.delayed(const Duration(seconds: 1));
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Featured Banner
            const SliverToBoxAdapter(child: FeaturedBanner()),

            // Live Now Section
            SliverToBoxAdapter(
              child: MosaicSection(
                title: 'Live Now',
                icon: '🔴',
                mosaics: _getLiveMosaics(),
                onSeeAll: () => _navigateToFiltered('live'),
              ),
            ),

            // Starting Soon Section
            SliverToBoxAdapter(
              child: MosaicSection(
                title: 'Starting Soon',
                icon: '⏰',
                mosaics: _getUpcomingMosaics(),
                onSeeAll: () => _navigateToFiltered('upcoming'),
              ),
            ),

            // Trending Section
            SliverToBoxAdapter(
              child: MosaicSection(
                title: 'Trending',
                icon: '🔥',
                mosaics: _getTrendingMosaics(),
                onSeeAll: () => _navigateToFiltered('trending'),
              ),
            ),

            // Browse All Button
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverToBoxAdapter(
                child: OutlinedButton(
                  onPressed: _navigateToBrowseAll,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Browse All Mosaics'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<MosaicPreview> _getLiveMosaics() {
    // Mock data - replace with API call
    return [
      MosaicPreview(
        id: 'MOS-123456',
        name: 'Summer Festival',
        playerCount: 2341,
        tileCount: 100000,
        status: MosaicStatus.live,
        phase: 'Assembly',
        teamCount: 8,
        imageUrl: '/assets/images/sample_mosaic.jpg',
      ),
      MosaicPreview(
        id: 'MOS-789012',
        name: 'City Skyline',
        playerCount: 1856,
        tileCount: 250000,
        status: MosaicStatus.live,
        phase: 'Claim',
        teamCount: 4,
        imageUrl: '/assets/images/sample_mosaic.jpg',
      ),
    ];
  }

  List<MosaicPreview> _getUpcomingMosaics() {
    return [
      MosaicPreview(
        id: 'MOS-345678',
        name: 'Abstract Pattern',
        playerCount: 0,
        tileCount: 50000,
        status: MosaicStatus.upcoming,
        startsIn: const Duration(minutes: 5),
        teamCount: 16,
        imageUrl: '/assets/images/sample_mosaic.jpg',
      ),
      MosaicPreview(
        id: 'MOS-901234',
        name: 'Nature Scene',
        playerCount: 0,
        tileCount: 150000,
        status: MosaicStatus.upcoming,
        startsIn: const Duration(minutes: 20),
        teamCount: 6,
        imageUrl: '/assets/images/sample_mosaic.jpg',
      ),
    ];
  }

  List<MosaicPreview> _getTrendingMosaics() {
    return [
      MosaicPreview(
        id: 'MOS-567890',
        name: 'Weekly Challenge',
        playerCount: 15234,
        tileCount: 1000000,
        status: MosaicStatus.live,
        phase: 'Assembly',
        teamCount: 12,
        isTrending: true,
        imageUrl: '/assets/images/sample_mosaic.jpg',
      ),
    ];
  }

  void _navigateToFiltered(String filter) {
    // Navigate to browse with filter
  }

  void _navigateToBrowseAll() {
    // Navigate to browse all
  }
}

class MosaicPreview {
  final String id;
  final String name;
  final int playerCount;
  final int tileCount;
  final MosaicStatus status;
  final String? phase;
  final Duration? startsIn;
  final int teamCount;
  final bool isTrending;
  final String imageUrl;

  MosaicPreview({
    required this.id,
    required this.name,
    required this.playerCount,
    required this.tileCount,
    required this.status,
    this.phase,
    this.startsIn,
    required this.teamCount,
    this.isTrending = false,
    required this.imageUrl,
  });
}

enum MosaicStatus { live, upcoming, completed, paused }
