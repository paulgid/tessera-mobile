import 'package:flutter/material.dart';
import 'dart:async';
import '../discovery/discovery_screen.dart';
import '../discovery/widgets/mosaic_preview_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 300);

  List<MosaicPreview> _searchResults = [];
  final List<String> _recentSearches = [
    'summer festival',
    '#competitive',
    'ID: MOS-2341',
  ];

  final List<String> _popularTags = [
    '#art',
    '#gaming',
    '#community',
    '#challenge',
    '#creative',
    '#seasonal',
    '#collaboration',
    '#competitive',
    '#casual',
    '#event',
  ];

  final List<String> _selectedTags = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.length >= 2) {
      setState(() => _isSearching = true);
      _debouncer.run(() => _performSearch(_searchController.text));
    } else {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _searchResults = _getMockSearchResults(query);
      _isSearching = false;
    });
  }

  List<MosaicPreview> _getMockSearchResults(String query) {
    // Mock search results
    return [
      MosaicPreview(
        id: 'MOS-123456',
        name: 'Summer Festival Challenge',
        playerCount: 2341,
        tileCount: 100000,
        status: MosaicStatus.live,
        phase: 'Assembly',
        teamCount: 8,
        imageUrl: '/assets/images/sample_mosaic.jpg',
      ),
      MosaicPreview(
        id: 'MOS-789012',
        name: 'Summer Art Collection',
        playerCount: 1856,
        tileCount: 250000,
        status: MosaicStatus.live,
        phase: 'Claim',
        teamCount: 4,
        imageUrl: '/assets/images/sample_mosaic.jpg',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by name, ID, or tag',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchResults = []);
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isNotEmpty) {
      return _buildSearchResults();
    }

    return _buildEmptyState();
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        // Selected tags
        if (_selectedTags.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.2),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Filters (${_selectedTags.length})',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedTags.clear());
                        _onSearchChanged();
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _selectedTags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() => _selectedTags.remove(tag));
                        _onSearchChanged();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        // Results count
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_searchResults.length} results found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              // View toggle
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.view_list),
                    onPressed: () {},
                    isSelected: true,
                  ),
                  IconButton(
                    icon: const Icon(Icons.grid_view),
                    onPressed: () {},
                    isSelected: false,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Results list
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return MosaicPreviewCard(
                mosaic: _searchResults[index],
                variant: CardVariant.standard,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Recent searches
        if (_recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _recentSearches.clear());
                },
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._recentSearches.map((search) {
            return ListTile(
              leading: const Icon(Icons.history),
              title: Text(search),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() => _recentSearches.remove(search));
                },
              ),
              onTap: () {
                _searchController.text = search;
                _onSearchChanged();
              },
            );
          }),
          const Divider(height: 32),
        ],

        // Quick filters
        const Text(
          'Quick Filters',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildQuickFilter('🔴', 'Live Now', '42'),
        _buildQuickFilter('⏰', 'Starting Soon', '18'),
        _buildQuickFilter('🏆', 'Competitive', '26'),
        _buildQuickFilter('👥', '>1000 Players', '8'),
        _buildQuickFilter('🎯', 'My Teams', '3'),

        const Divider(height: 32),

        // Popular tags
        const Text(
          'Popular Tags',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
                if (_searchController.text.isNotEmpty ||
                    _selectedTags.isNotEmpty) {
                  _onSearchChanged();
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickFilter(String icon, String label, String count) {
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 24)),
      title: Text(label),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(count),
      ),
      onTap: () {
        // Apply quick filter
      },
    );
  }
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
