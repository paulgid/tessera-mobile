import 'package:flutter/material.dart';

class Team {
  final int id;
  final String name;
  final Color color;
  final int tileCount;
  final double percentage;

  Team({
    required this.id,
    required this.name,
    required this.color,
    this.tileCount = 0,
    this.percentage = 0.0,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Team ${json['id']}',
      color: _getTeamColor(json['id'] as int),
      tileCount: json['tile_count'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static Color _getTeamColor(int teamId) {
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
        return Colors.grey;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tile_count': tileCount,
      'percentage': percentage,
    };
  }

  Team copyWith({
    int? id,
    String? name,
    Color? color,
    int? tileCount,
    double? percentage,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      tileCount: tileCount ?? this.tileCount,
      percentage: percentage ?? this.percentage,
    );
  }
}