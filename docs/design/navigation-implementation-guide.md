# Navigation Implementation Guide for Frontend Engineers

Version: 1.0.0
Date: 2025-01-17
Designer: UX Design Authority
Parent Document: navigation-patterns.md
Target Platform: Flutter

## Overview

This guide provides detailed implementation instructions for building the navigation and discovery features specified in the navigation-patterns.md document. Frontend engineers should follow these specifications exactly to ensure design compliance.

## Required Flutter Packages

```yaml
dependencies:
  # Core navigation
  go_router: ^12.0.0
  
  # State management
  riverpod: ^2.4.0
  hooks_riverpod: ^2.4.0
  
  # UI components
  flutter_staggered_grid_view: ^0.7.0
  shimmer: ^3.0.0
  cached_network_image: ^3.3.0
  
  # Search and filtering
  flutter_typeahead: ^5.0.0
  
  # Animations
  animations: ^2.0.8
  flutter_animate: ^4.3.0
  
  # Performance
  infinite_scroll_pagination: ^4.0.0
  flutter_sticky_header: ^0.6.5
  
  # Utilities
  collection: ^1.17.0
  intl: ^0.18.0
```

## Component Structure

### 1. Main Discovery Screen Component

```dart
// Path: lib/features/discovery/screens/discovery_screen.dart

/*
IMPLEMENTATION REQUIREMENTS:

1. Screen Layout:
   - SafeArea wrapper for status bar
   - CustomScrollView with slivers
   - Pull-to-refresh functionality
   - Bottom navigation integration

2. Sections (in order):
   - Featured banner (SliverToBoxAdapter)
   - Live now carousel (SliverToBoxAdapter)
   - Starting soon carousel (SliverToBoxAdapter)  
   - Browse all button (SliverToBoxAdapter)

3. State Management:
   - Use Riverpod for featured/live/upcoming providers
   - Implement AsyncValue for loading states
   - Cache data for 5 minutes

4. Performance:
   - Lazy load images with CachedNetworkImage
   - Use const constructors where possible
   - Implement AutomaticKeepAliveClientMixin for tab persistence
*/
```

### 2. Mosaic Preview Card Components

```dart
// Path: lib/features/discovery/widgets/mosaic_cards/

/*
CARD VARIANTS TO IMPLEMENT:

1. CompactMosaicCard (72px height):
   - Properties: mosaicId, title, playerCount, status, phase
   - Layout: Row with thumbnail, text column, status indicator
   - Interactions: Tap for detail, long press for preview
   
2. StandardMosaicCard (280px height):
   - Properties: mosaic object with all details
   - Layout: Column with hero image, stats bar, progress, actions
   - Hero image: 16:9 aspect ratio with gradient overlay
   - Include AnimatedContainer for hover/press states
   
3. FeaturedMosaicCard (flexible height):
   - Properties: enhanced mosaic data with live stats
   - Layout: Expanded card with animations
   - Live indicators: Use Stream for real-time updates
   - Team distribution: Custom painter for progress bars

SHARED REQUIREMENTS:
- All cards must handle null/empty states gracefully
- Implement skeleton loading states using Shimmer
- Touch targets minimum 44x44px
- Use Hero animations for image transitions
*/
```

### 3. List/Grid View Implementation

```dart
// Path: lib/features/discovery/screens/browse_screen.dart

/*
LIST VIEW REQUIREMENTS:

1. Use CustomScrollView with slivers:
   - SliverAppBar (collapsible filter bar)
   - SliverPersistentHeader (filter chips)
   - SliverList with SliverChildBuilderDelegate

2. Infinite Scroll:
   - Use infinite_scroll_pagination package
   - Page size: 20 items
   - Show loading indicator at bottom
   - Handle error states with retry

3. Item Interactions:
   - Dismissible for swipe actions (favorite/remove)
   - OpenContainer for smooth transitions
   - Long press shows context menu

GRID VIEW REQUIREMENTS:

1. Use StaggeredGrid:
   - 2 columns on phones (<600px)
   - 3 columns on tablets (>=600px)
   - Square aspect ratio for items

2. Responsive:
   - Use LayoutBuilder for breakpoints
   - Adjust spacing based on screen size
   - Maintain touch target sizes

TOGGLE IMPLEMENTATION:
- IconButton in app bar for view toggle
- Persist preference in SharedPreferences
- Animate transition between views
*/
```

### 4. Search Interface

```dart
// Path: lib/features/discovery/screens/search_screen.dart

/*
SEARCH BAR REQUIREMENTS:

1. TextField Configuration:
   - autofocus: true on search screen
   - textInputAction: TextInputAction.search
   - Debounce input by 300ms
   - Show clear button when text present

2. Instant Results:
   - Show after 2 characters typed
   - Display inline below search bar
   - Maximum 5 instant results
   - "See all" button for full results

3. Search Sections:
   - Recent searches (stored locally)
   - Quick filters (predefined chips)
   - Popular tags (scrollable row)

IMPLEMENTATION NOTES:
- Use flutter_typeahead for autocomplete
- Store search history in Hive/SharedPreferences
- Implement custom SearchDelegate
- Handle empty states with suggestions
*/
```

### 5. Filter System

```dart
// Path: lib/features/discovery/widgets/filters/

/*
FILTER COMPONENTS:

1. FilterBottomSheet:
   - DraggableScrollableSheet implementation
   - Initial size: 0.7, min: 0.3, max: 0.95
   - Sections with ExpansionTiles
   - Apply button sticks to bottom

2. Filter Types:
   
   StatusFilter (CheckboxListTile):
   - Options: Live, Upcoming, Completed, Paused
   - Multiple selection allowed
   - Show count for each option
   
   SizeRangeFilter (RangeSlider):
   - Min: 10K tiles, Max: 10M tiles
   - Logarithmic scale
   - Show selected range as text
   
   PlayerCountFilter (RangeSlider):
   - Min: 10, Max: 10,000
   - Linear scale
   - Live update of results count
   
   TeamConfigFilter (RadioListTile):
   - Single selection
   - Options: Any, 2-4, 5-8, 9+, FFA
   
   TagFilter (Wrap with Chips):
   - Multiple selection
   - Predefined + custom tags
   - Search within tags

3. Filter State Management:
   - Use ChangeNotifier for filter state
   - Persist filters during session
   - Show active filter count as badge
   - Provide "Reset all" functionality
*/
```

### 6. Navigation Transitions

```dart
// Path: lib/core/navigation/transitions.dart

/*
TRANSITION SPECIFICATIONS:

1. List to Detail:
   - Use OpenContainer from animations package
   - openBuilder: Detail screen
   - closedBuilder: List item
   - transitionDuration: 350ms
   - transitionType: ContainerTransitionType.fade

2. Bottom Sheet Preview:
   - showModalBottomSheet with custom builder
   - isScrollControlled: true
   - backgroundColor: Colors.transparent
   - Custom drag handle widget
   - Backdrop filter for blur effect

3. Tab Transitions:
   - Use IndexedStack for tab persistence
   - Fade transition between tabs
   - Maintain scroll position per tab
   - Double-tap to scroll to top

GESTURE HANDLING:
- Implement GestureDetector for custom gestures
- Use InteractiveViewer for zoomable content
- Add haptic feedback for interactions (HapticFeedback.lightImpact())
*/
```

### 7. Performance Optimization

```dart
// Path: lib/core/performance/

/*
OPTIMIZATION REQUIREMENTS:

1. Image Loading:
   - CachedNetworkImage for all images
   - Placeholder: BlurHash or color extraction
   - Error widget with retry option
   - Memory cache: 50 images max
   - Disk cache: 200MB limit

2. List Virtualization:
   - Use ListView.builder (never ListView with children)
   - Set itemExtent when possible
   - Implement AutomaticKeepAlive selectively
   - Dispose controllers in dispose()

3. State Management:
   - Use const constructors
   - Implement equatable for models
   - Use Selector for granular rebuilds
   - Avoid setState in loops

4. Network Optimization:
   - Implement request debouncing
   - Cancel previous requests on new search
   - Use ComputeIsolate for JSON parsing
   - Batch API calls when possible

MONITORING:
- Use Flutter Inspector for performance
- Track frame rendering with SchedulerBinding
- Monitor memory with Observatory
- Profile with Timeline events
*/
```

### 8. Live Indicators

```dart
// Path: lib/features/discovery/widgets/indicators/

/*
LIVE INDICATOR COMPONENTS:

1. PlayerCountIndicator:
   - StreamBuilder for real-time updates
   - AnimatedSwitcher for number changes
   - Format: NumberFormat.compact()
   - Update interval: 5 seconds

2. ActivitySparkline:
   - Custom painter for mini graph
   - 60 data points (last minute)
   - Animate new data points
   - Color based on trend

3. PhaseCountdown:
   - Timer.periodic for countdown
   - Format: mm:ss
   - Red pulse animation at <10s
   - Auto-refresh on phase change

4. TrendingBadge:
   - Animated visibility
   - Pulse animation (AnimationController)
   - Show when >90th percentile
   - Fire emoji with glow effect

IMPLEMENTATION:
- Use Provider for live data streams
- Implement dispose() for timers/streams
- Throttle updates to prevent jank
- Use RepaintBoundary for isolated redraws
*/
```

### 9. Accessibility Implementation

```dart
/*
ACCESSIBILITY REQUIREMENTS:

1. Semantic Labels:
   - All interactive widgets need semanticsLabel
   - Use ExcludeSemantics for decorative elements
   - Provide context in button labels

2. Focus Management:
   - Implement FocusTraversalGroup
   - Set proper focus order
   - Show focus indicators

3. Screen Reader:
   - Use Semantics widget for custom widgets
   - Announce live updates with SemanticsService
   - Group related content

4. Visual Accessibility:
   - Respect textScaleFactor
   - Minimum touch targets: 44x44px
   - Sufficient color contrast (4.5:1)

Example:
Semantics(
  label: 'Join Summer Festival mosaic with 2,341 active players',
  button: true,
  child: MosaicCard(...),
)
*/
```

### 10. Error Handling

```dart
// Path: lib/core/error/

/*
ERROR STATE WIDGETS:

1. NetworkErrorWidget:
   - Icon: wifi_off
   - Message: "Unable to load mosaics"
   - Action: Retry button
   - Show cached content if available

2. EmptyResultWidget:
   - Illustration: Custom SVG
   - Message: Context-specific
   - Suggestions: Chips for actions
   - Call-to-action button

3. LoadingErrorWidget:
   - Show after 10s timeout
   - Option to retry
   - Link to report issue
   - Switch to lite mode option

IMPLEMENTATION:
- Create reusable error widgets
- Use AnimatedSwitcher for transitions
- Log errors to analytics
- Implement exponential backoff for retries
*/
```

## Testing Requirements

```dart
/*
TESTING CHECKLIST:

1. Unit Tests:
   - All view models
   - Filter logic
   - Search algorithms
   - Data transformations

2. Widget Tests:
   - Card components
   - Navigation flows
   - Filter interactions
   - Search functionality

3. Integration Tests:
   - Full discovery flow
   - List to detail navigation
   - Search and filter combination
   - Performance scrolling

4. Golden Tests:
   - All card variants
   - Error states
   - Loading states
   - Different screen sizes

USE THESE TEST PACKAGES:
- flutter_test
- mocktail for mocking
- golden_toolkit for visual regression
- patrol for integration tests
*/
```

## Code Organization

```
lib/features/discovery/
├── screens/
│   ├── discovery_screen.dart
│   ├── browse_screen.dart
│   ├── search_screen.dart
│   └── filter_screen.dart
├── widgets/
│   ├── mosaic_cards/
│   │   ├── compact_mosaic_card.dart
│   │   ├── standard_mosaic_card.dart
│   │   └── featured_mosaic_card.dart
│   ├── filters/
│   │   ├── filter_bottom_sheet.dart
│   │   ├── status_filter.dart
│   │   └── range_filter.dart
│   ├── indicators/
│   │   ├── player_count_indicator.dart
│   │   ├── activity_sparkline.dart
│   │   └── phase_countdown.dart
│   └── search/
│       ├── search_bar.dart
│       ├── instant_results.dart
│       └── search_suggestions.dart
├── providers/
│   ├── discovery_provider.dart
│   ├── search_provider.dart
│   └── filter_provider.dart
└── models/
    ├── mosaic_preview.dart
    ├── filter_options.dart
    └── search_result.dart
```

## Design Compliance Checklist

Before submitting implementation for review:

- [ ] All touch targets are minimum 44x44px
- [ ] Colors match design-language.md specifications
- [ ] Typography follows defined scale
- [ ] Spacing uses only defined values
- [ ] Animations use specified durations and easings
- [ ] Loading states implemented for all async operations
- [ ] Error states handle all failure scenarios
- [ ] Accessibility requirements met
- [ ] Performance targets achieved (60fps scroll)
- [ ] Search responds in <300ms
- [ ] Images load in <1s on 4G
- [ ] Memory usage stays under limits
- [ ] All gestures have haptic feedback
- [ ] Navigation maintains state correctly
- [ ] Deep linking works for all screens

## Review Process

1. Self-review against this checklist
2. Run automated tests
3. Profile performance on low-end device
4. Submit for design review with screenshots
5. Address feedback with specific commits
6. Final approval from UX Design Authority

---

This implementation guide provides precise instructions for building the navigation system. Follow these specifications exactly and reference the parent design documents for visual details.