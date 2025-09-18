# Tessera Mobile Interaction Patterns & Visual Mockups

Version: 1.0.0
Date: 2025-01-16
Designer: UX Design Authority
Parent Document: mobile-ux-specifications.md

## Visual Mockup Descriptions

### 1. Mosaic Viewport - Overview Level (0.01x - 0.05x zoom)

```
┌─────────────────────────────────────┐
│ Status Bar                     9:41 │
├─────────────────────────────────────┤
│ ← Mosaic Name          Phase: Claim │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │   [Aggregated Color Blocks] │   │
│  │                             │   │
│  │   Each pixel = 100x100 tiles│   │
│  │                             │   │
│  │   Shows heat map of claims  │   │
│  │                             │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│         ┌──────────┐               │
│         │ Mini-map │ (120x120px)   │
│         └──────────┘               │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  Team 1: ████████░░░░░░ 45%       │
│  Team 2: ██████░░░░░░░░ 32%       │
│  Unclaimed: ████░░░░░░░ 23%       │
│                                     │
│        [ Zoom to My Tiles ]         │
│                                     │
└─────────────────────────────────────┘
```

**Interaction Notes:**
- Double-tap anywhere: Zoom to 0.25x (Navigation level)
- Pinch out: Smooth zoom to next level
- Tap on minimap: Jump to that region
- Swipe up on bottom panel: Expand for detailed stats

### 2. Mosaic Viewport - Interaction Level (0.26x - 1.0x zoom)

```
┌─────────────────────────────────────┐
│ Status Bar                     9:41 │
├─────────────────────────────────────┤
│ ← Back            Timer: 03:45     │
├─────────────────────────────────────┤
│                                     │
│  Grid of Individual Tiles (20x20)  │
│  ┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐ │
│  ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤ │
│  │█│░│█│░│░│█│█│░│█│░│░│█│█│░│█│ │
│  ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤ │
│  │░│█│░│█│█│░│░│█│░│█│█│░│░│█│░│ │
│  ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤ │
│  │█│░│█│░│░│█│█│░│█│░│░│█│█│░│█│ │
│  ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤ │
│  │  Tiles show claim patterns   │ │
│  │  █ = Claimed (with intensity)│ │
│  │  ░ = Unclaimed               │ │
│  │  ◈ = Currently selected      │ │
│  └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘ │
│                                     │
│  Floating minimap ┌────┐          │
│                   │□   │          │
│                   └────┘          │
├─────────────────────────────────────┤
│         [ Claim Selected Tile ]     │
└─────────────────────────────────────┘
```

**Touch Zones:**
- Each tile: Minimum 44x44px touch target
- When tiles are smaller than 44px visually, invisible expanded hit boxes
- Long press on tile: Opens detail sheet
- Tap on tile: Select with visual feedback

### 3. Tile Selection & Claim Flow

```
Step 1: Tile Selection
┌─────────────────────────────────────┐
│                                     │
│         [Mosaic View]               │
│                                     │
│         ┌──────────┐                │
│         │          │                │
│         │  Tapped  │ ← Ripple       │
│         │   Tile   │   Animation    │
│         │          │                │
│         └──────────┘                │
│                                     │
│  Haptic: Light tap feedback        │
└─────────────────────────────────────┘
                 ↓
Step 2: Claim Confirmation Sheet
┌─────────────────────────────────────┐
│         [Dimmed Mosaic View]        │
│                                     │
├─────────────────────────────────────┤
│ ╭───────────────────────────────╮   │
│ │  Claim This Tile?             │   │
│ ├───────────────────────────────┤   │
│ │  Position: (47, 23)           │   │
│ │  Status: Unclaimed            │   │
│ │  Nearby: 3 team tiles         │   │
│ │                               │   │
│ │  ┌─────────────────────────┐  │   │
│ │  │    [Claim Tile]         │  │   │
│ │  └─────────────────────────┘  │   │
│ │                               │   │
│ │  [ Cancel ]                   │   │
│ ╰───────────────────────────────╯   │
│                                     │
│  Sheet Height: 220px                │
│  Animation: Spring curve up         │
└─────────────────────────────────────┘
                 ↓
Step 3: Claim Animation
┌─────────────────────────────────────┐
│                                     │
│         [Mosaic View]               │
│                                     │
│         ┌──────────┐                │
│      ○○○│          │○○○             │
│     ○○○○│  Claimed │○○○○            │
│      ○○○│   Tile   │○○○             │
│         └──────────┘                │
│                                     │
│  Radial claim effect spreading      │
│  Haptic: Success pattern            │
│  Duration: 500ms                    │
└─────────────────────────────────────┘
```

### 4. Mobile Mosaic Creation Flow

```
Screen 1: Basic Setup
┌─────────────────────────────────────┐
│ ← Cancel    Create Mosaic    Next → │
├─────────────────────────────────────┤
│                                     │
│  Mosaic Name                        │
│  ┌─────────────────────────────┐   │
│  │ Epic Battle Arena           │   │
│  └─────────────────────────────┘   │
│                                     │
│  Size                              │
│  ┌──────┐ ┌──────┐ ┌──────┐       │
│  │Small │ │Medium│ │Large │       │
│  │50x50 │ │100x  │ │200x  │       │
│  └──────┘ └──────┘ └──────┘       │
│           Selected                  │
│                                     │
│  Game Mode                         │
│  ┌────────────────────────────┐   │
│  │ Competitive │Collab│Artist│   │
│  └────────────────────────────┘   │
│                                     │
│  Progress: ●○○○○                   │
└─────────────────────────────────────┘
                 ↓
Screen 2: Image Upload
┌─────────────────────────────────────┐
│ ← Back     Upload Images     Next → │
├─────────────────────────────────────┤
│                                     │
│  Team Images (4 required)           │
│                                     │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ │
│  │ IMG │ │ IMG │ │  +  │ │  +  │ │
│  │  1  │ │  2  │ │     │ │     │ │
│  └─────┘ └─────┘ └─────┘ └─────┘ │
│                                     │
│  ┌─────────────────────────────┐   │
│  │      📷 Take Photo          │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │      🖼️ Choose from Gallery │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │      ☁️ Import from Cloud   │   │
│  └─────────────────────────────┘   │
│                                     │
│  Progress: ●●○○○                   │
└─────────────────────────────────────┘
                 ↓
Screen 3: Image Positioning
┌─────────────────────────────────────┐
│ ← Back    Position Image     Done √ │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │    ┌─────────────────┐     │   │
│  │    │                 │     │   │
│  │    │  Draggable      │     │   │
│  │    │  Image with     │     │   │
│  │    │  Pinch Zoom     │     │   │
│  │    │                 │     │   │
│  │    └─────────────────┘     │   │
│  │                             │   │
│  │  Grid overlay (optional)    │   │
│  └─────────────────────────────┘   │
│                                     │
│  ⟲ Rotate  ⊞ Grid  ↻ Reset        │
│                                     │
│  Progress: ●●●○○                   │
└─────────────────────────────────────┘
```

### 5. Team Formation Phase UI

```
┌─────────────────────────────────────┐
│ Status Bar                     9:41 │
├─────────────────────────────────────┤
│      TEAM FORMATION PHASE          │
│         Timer: 01:45                │
├─────────────────────────────────────┤
│                                     │
│  Your Reputation: ⭐⭐⭐⭐⭐ Gold    │
│  Tiles Claimed: 42                  │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  🔵 Blue Defenders    12/50  │   │
│  │  Captain: Player123         │   │
│  │  Avg Rep: ⭐⭐⭐⭐            │   │
│  │  [ Join Team ]              │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  🔴 Red Warriors      8/50   │   │
│  │  Captain: ProGamer42        │   │
│  │  Avg Rep: ⭐⭐⭐              │   │
│  │  [ Join Team ]              │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │    [ Create New Team ]       │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

### 6. Assembly Phase Battle View

```
┌─────────────────────────────────────┐
│ Status Bar                     9:41 │
├─────────────────────────────────────┤
│   ASSEMBLY PHASE - Team Battle     │
│         Timer: 08:32                │
├─────────────────────────────────────┤
│                                     │
│  [Mosaic View with Team Colors]    │
│                                     │
│  Live tile flips animated          │
│  Team territories visible          │
│                                     │
├─────────────────────────────────────┤
│  Your Team: Blue Defenders         │
│  Territory: ████████░░░░ 62%      │
│                                     │
│  Next Action In: 1.3s              │
│                                     │
│  ┌─────────────────────────────┐   │
│  │      [ Place Tile ]         │   │
│  └─────────────────────────────┘   │
│                                     │
│  Rally Available ⚡                 │
│                                     │
└─────────────────────────────────────┘
```

## Gesture Reference Guide

### Core Gestures

| Gesture | Context | Action | Visual Feedback | Haptic |
|---------|---------|--------|-----------------|---------|
| Tap | Tile | Select | Highlight ring | Light |
| Long Press | Tile | Show details | Bottom sheet | Medium |
| Double Tap | Mosaic | Zoom in | Smooth animation | None |
| Pinch | Mosaic | Zoom | Real-time scale | None |
| Pan | Mosaic | Navigate | Momentum scroll | None |
| Two-finger tap | Mosaic | Zoom out | Animated transition | Light |
| Swipe up | Bottom panel | Expand info | Sheet slides up | None |
| Swipe down | Bottom sheet | Dismiss | Sheet slides down | None |
| Edge swipe | Any screen | Navigate back | Page transition | None |

### Context-Specific Gestures

#### During Claim Phase
- **Rapid tap**: Queue multiple claims (with cooldown indicator)
- **Drag select**: Multi-tile selection (premium feature)
- **3D touch/Force touch**: Preview tile without claiming

#### During Assembly Phase
- **Tap and hold**: Preview tile placement
- **Swipe from team panel**: Quick place at last position
- **Shake device**: Trigger rally (when available)

#### In Creation Mode
- **Pinch on image**: Scale image in position editor
- **Two-finger rotate**: Rotate image (15° snaps)
- **Triple tap**: Reset image position

## Touch Target Specifications

### Minimum Sizes

```
Standard Touch Target
┌──────────────┐
│              │ 44px (10mm)
│    Touch     │
│     Zone     │ 
│              │
└──────────────┘
     44px

Extended Touch Target (for small visual elements)
     Visual Element
     ┌────┐
┌────┼────┼────┐
│    │ 20 │    │ Invisible
│    └────┘    │ Extended
│              │ Hit Box
└──────────────┘
     44px
```

### Tile Touch Targets at Different Zoom Levels

```
Zoom < 0.5x: Each tile has 44px minimum hit box
┌────────┐
│ ┌──┐   │ Visual: 20px
│ │  │   │ Touch: 44px
│ └──┘   │
└────────┘

Zoom 0.5x-1x: Hit box equals visual size
┌────────┐
│        │ Visual: 44px
│        │ Touch: 44px
└────────┘

Zoom > 1x: Touch target equals visual size
┌────────────┐
│            │ Visual: 88px
│            │ Touch: 88px
└────────────┘
```

## Loading States & Transitions

### Progressive Loading Sequence

```
1. Initial Load (0-500ms)
┌─────────────────────────┐
│                         │
│     Loading Mosaic      │
│                         │
│    ████░░░░░░░ 40%     │
│                         │
└─────────────────────────┘

2. Low-Res Preview (500-1000ms)
┌─────────────────────────┐
│  ░░░░░░░░░░░░░░░░░░░  │
│  ░░▓▓▓▓▓▓▓▓▓▓▓▓▓░░░  │
│  ░░▓▓▓▓▓▓▓▓▓▓▓▓▓░░░  │
│  ░░░░░░░░░░░░░░░░░░░  │
└─────────────────────────┘

3. Full Resolution (1000ms+)
┌─────────────────────────┐
│  ┌─┬─┬─┬─┬─┬─┬─┬─┐    │
│  ├─┼─┼─┼─┼─┼─┼─┼─┤    │
│  │█│░│█│░│█│░│█│░│    │
│  ├─┼─┼─┼─┼─┼─┼─┼─┤    │
│  Fully loaded tiles     │
└─────────────────────────┘
```

## Error States & Recovery

### Network Error Handling

```
Connection Lost
┌─────────────────────────────────────┐
│ ⚠️ Connection Lost - Offline Mode   │
├─────────────────────────────────────┤
│                                     │
│  [Cached Mosaic View]               │
│  Last updated: 2 min ago            │
│                                     │
│  Actions are queued for sync        │
│                                     │
│  [ Retry Connection ]               │
│                                     │
└─────────────────────────────────────┘

Reconnecting
┌─────────────────────────────────────┐
│ 🔄 Reconnecting... (attempt 3/5)    │
├─────────────────────────────────────┤
│                                     │
│  [Static Mosaic View]               │
│                                     │
│  Syncing 3 pending actions...       │
│  ████████░░░░░░ 75%                │
│                                     │
└─────────────────────────────────────┘
```

## Accessibility Overlays

### VoiceOver/TalkBack Descriptions

```
Focus on Tile:
"Tile at row 23, column 45
Currently unclaimed
Double tap to select for claiming
Available actions in actions menu"

Focus on Team Panel:
"Blue Defenders team
12 of 50 members
Average reputation 4 stars
Currently controlling 45% of territory
Double tap to join team"

Focus on Minimap:
"Minimap showing full mosaic overview
Your viewport indicated by white rectangle
Current zoom level 25%
Drag to navigate to different area"
```

## Performance Indicators

### Frame Rate Monitor (Debug Mode)

```
┌──────────────┐
│ FPS: 58.3    │
│ Frame: 12ms  │
│ Tiles: 1,432 │
│ Memory: 124MB│
└──────────────┘
```

### Network Quality Indicator

```
Excellent:  ●●●● Full bars, green
Good:       ●●●○ 3 bars, green
Fair:       ●●○○ 2 bars, yellow
Poor:       ●○○○ 1 bar, red
Offline:    ✕○○○ X symbol, gray
```

## Implementation Priorities

### Phase 1: Core Interaction (MVP)
1. Basic pan and zoom
2. Tile selection and claiming
3. Progressive loading
4. Network status handling

### Phase 2: Enhanced Experience
1. Gesture optimization
2. Minimap implementation
3. Animation polish
4. Offline mode

### Phase 3: Advanced Features
1. Multi-tile selection
2. Advanced creation tools
3. Accessibility enhancements
4. Performance optimizations

## Testing Checklist

### Interaction Testing
- [ ] All gestures respond within 50ms
- [ ] Touch targets never smaller than 44px
- [ ] Zoom levels snap appropriately
- [ ] Pan has momentum scrolling
- [ ] Long press shows correct details
- [ ] Double tap zooms to expected level

### Performance Testing
- [ ] 60fps during pan at overview zoom
- [ ] 30fps minimum at interaction zoom
- [ ] Progressive loading completes in <3s on 4G
- [ ] Memory usage stays under 200MB
- [ ] Battery drain <5% per 30 minutes

### Accessibility Testing
- [ ] All elements have proper labels
- [ ] Focus order is logical
- [ ] Contrast ratios meet WCAG AA
- [ ] Works with screen readers
- [ ] Supports one-handed operation
- [ ] Respects system text size

## Version History

- 1.0.0 (2025-01-16): Initial interaction patterns and mockups
  - Complete gesture reference
  - Visual mockup descriptions
  - Touch target specifications
  - Loading and error states
  - Accessibility overlays

---

*This document provides concrete visual and interaction patterns that complement the mobile-ux-specifications.md document. All mockups and patterns must be implemented according to these specifications.*