import 'package:flutter/material.dart';

class Tile {
  final int x;
  final int y;
  final int? teamId;
  final bool isClaimed;
  final double claimIntensity;
  final int placementCount;
  final String? pattern;

  Tile({
    required this.x,
    required this.y,
    this.teamId,
    this.isClaimed = false,
    this.claimIntensity = 0.0,
    this.placementCount = 0,
    this.pattern,
  });

  factory Tile.fromJson(Map<String, dynamic> json) {
    return Tile(
      x: json['x'] as int,
      y: json['y'] as int,
      teamId: json['team_id'] as int?,
      isClaimed: json['is_claimed'] as bool? ?? false,
      claimIntensity: (json['claim_intensity'] as num?)?.toDouble() ?? 0.0,
      placementCount: json['placement_count'] as int? ?? 0,
      pattern: json['pattern'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'team_id': teamId,
      'is_claimed': isClaimed,
      'claim_intensity': claimIntensity,
      'placement_count': placementCount,
      'pattern': pattern,
    };
  }

  Color get color {
    if (teamId == null) return Colors.grey.shade800;

    // Team colors matching the backend
    switch (teamId) {
      case 1:
        return const Color(0xFFFF6B6B); // Red
      case 2:
        return const Color(0xFF4ECDC4); // Blue
      case 3:
        return const Color(0xFF95E77E); // Green
      case 4:
        return const Color(0xFFFFE66D); // Yellow
      default:
        return Colors.grey.shade800;
    }
  }

  Tile copyWith({
    int? x,
    int? y,
    int? teamId,
    bool? isClaimed,
    double? claimIntensity,
    int? placementCount,
    String? pattern,
  }) {
    return Tile(
      x: x ?? this.x,
      y: y ?? this.y,
      teamId: teamId ?? this.teamId,
      isClaimed: isClaimed ?? this.isClaimed,
      claimIntensity: claimIntensity ?? this.claimIntensity,
      placementCount: placementCount ?? this.placementCount,
      pattern: pattern ?? this.pattern,
    );
  }
}
