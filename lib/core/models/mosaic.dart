import 'package:flutter/foundation.dart';

@immutable
class Mosaic {
  final String mosaicId;
  final int formationMode;
  final MosaicStatus status;
  final DateTime? createdAt;
  final String? name;
  final String? description;

  const Mosaic({
    required this.mosaicId,
    required this.formationMode,
    required this.status,
    this.createdAt,
    this.name,
    this.description,
  });

  factory Mosaic.fromJson(Map<String, dynamic> json) {
    return Mosaic(
      mosaicId: json['mosaicId'] as String,
      formationMode: json['formation_mode'] as int? ?? 0,
      status: MosaicStatus.fromJson(json['status'] as Map<String, dynamic>),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      name: json['name'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'mosaicId': mosaicId,
    'formation_mode': formationMode,
    'status': status.toJson(),
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (name != null) 'name': name,
    if (description != null) 'description': description,
  };

  // Helper getters for UI
  bool get isLive => status.running && status.phase > 0;
  bool get isUpcoming => !status.running && status.phase == 0;
  bool get isCompleted => status.phase == 3;

  String get displayName => name ?? 'Mosaic ${mosaicId.substring(0, 8)}';

  String get phaseText {
    switch (status.phase) {
      case 0:
        return 'Waiting';
      case 1:
        return 'Claim Phase';
      case 2:
        return 'Assembly Phase';
      case 3:
        return 'Complete';
      default:
        return 'Unknown';
    }
  }
}

@immutable
class MosaicStatus {
  final bool running;
  final int phase;
  final int totalBots;
  final int activeBots;
  final int claimedTiles;
  final int totalTiles;
  final DateTime lastUpdate;

  const MosaicStatus({
    required this.running,
    required this.phase,
    required this.totalBots,
    required this.activeBots,
    required this.claimedTiles,
    required this.totalTiles,
    required this.lastUpdate,
  });

  factory MosaicStatus.fromJson(Map<String, dynamic> json) {
    return MosaicStatus(
      running: json['running'] as bool? ?? false,
      phase: json['phase'] as int? ?? 0,
      totalBots: json['total_bots'] as int? ?? 0,
      activeBots: json['active_bots'] as int? ?? 0,
      claimedTiles: json['claimed_tiles'] as int? ?? 0,
      totalTiles: json['total_tiles'] as int? ?? 0,
      lastUpdate: DateTime.parse(json['last_update'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'running': running,
    'phase': phase,
    'total_bots': totalBots,
    'active_bots': activeBots,
    'claimed_tiles': claimedTiles,
    'total_tiles': totalTiles,
    'last_update': lastUpdate.toIso8601String(),
  };

  double get claimProgress => totalTiles > 0 ? claimedTiles / totalTiles : 0.0;

  String get progressText => '${(claimProgress * 100).toStringAsFixed(1)}%';
}
