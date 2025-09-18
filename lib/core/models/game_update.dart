import 'package:flutter/material.dart';
import 'tile.dart';
import 'team.dart';

// Helper function for team color
Color _getTeamColorStatic(int teamId) {
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

enum GamePhase { idle, claim, formation, assembly, complete }

class GameUpdate {
  final String type;
  final GamePhase? phase;
  final List<Tile>? tiles;
  final List<Team>? teams;
  final GameMetrics? metrics;
  final String? message;
  final dynamic data;

  GameUpdate({
    required this.type,
    this.phase,
    this.tiles,
    this.teams,
    this.metrics,
    this.message,
    this.data,
  });

  factory GameUpdate.fromJson(Map<String, dynamic> json) {
    return GameUpdate(
      type: json['type'] as String,
      phase: _parsePhase(json['phase'] as String?),
      tiles: _parseTiles(json['tiles']),
      teams: _parseTeams(json['teams']),
      metrics: json['metrics'] != null
          ? GameMetrics.fromJson(json['metrics'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
      data: json['data'],
    );
  }

  static GamePhase? _parsePhase(String? phase) {
    if (phase == null) return null;
    switch (phase.toLowerCase()) {
      case 'idle':
        return GamePhase.idle;
      case 'claim':
        return GamePhase.claim;
      case 'formation':
        return GamePhase.formation;
      case 'assembly':
        return GamePhase.assembly;
      case 'complete':
        return GamePhase.complete;
      default:
        return null;
    }
  }

  static List<Tile>? _parseTiles(dynamic tilesData) {
    if (tilesData == null) return null;
    if (tilesData is List) {
      return tilesData
          .map((tile) => Tile.fromJson(tile as Map<String, dynamic>))
          .toList();
    }
    return null;
  }

  static List<Team>? _parseTeams(dynamic teamsData) {
    if (teamsData == null) return null;
    if (teamsData is List) {
      return teamsData
          .map((team) => Team.fromJson(team as Map<String, dynamic>))
          .toList();
    }
    if (teamsData is Map) {
      // Handle teams from metrics
      return teamsData.entries
          .map(
            (entry) => Team(
              id: int.parse(entry.key),
              name: 'Team ${entry.key}',
              color: _getTeamColorStatic(int.parse(entry.key)),
              tileCount: entry.value as int,
            ),
          )
          .toList();
    }
    return null;
  }
}

class GameMetrics {
  final int claimedTiles;
  final int totalPlacements;
  final int activeBots;
  final double placementsPerSec;
  final Map<int, int> teamTiles;
  final int? winnerTeamId;
  final double? convergence;

  GameMetrics({
    required this.claimedTiles,
    required this.totalPlacements,
    required this.activeBots,
    required this.placementsPerSec,
    required this.teamTiles,
    this.winnerTeamId,
    this.convergence,
  });

  factory GameMetrics.fromJson(Map<String, dynamic> json) {
    // Parse team tiles from the teams object
    final Map<int, int> teamTiles = {};
    if (json['teams'] != null) {
      final teams = json['teams'] as Map<String, dynamic>;
      teams.forEach((key, value) {
        teamTiles[int.parse(key)] = value as int;
      });
    }

    return GameMetrics(
      claimedTiles: json['claimed_tiles'] as int? ?? 0,
      totalPlacements: json['total_placements'] as int? ?? 0,
      activeBots: json['active_bots'] as int? ?? 0,
      placementsPerSec: (json['placements_per_sec'] as num?)?.toDouble() ?? 0.0,
      teamTiles: teamTiles,
      winnerTeamId: json['winner_team_id'] as int?,
      convergence: (json['convergence'] as num?)?.toDouble(),
    );
  }
}
