import 'package:flutter/material.dart';

enum SkillPriority { high, medium, low }

class SkillGap {
  const SkillGap({
    required this.name,
    required this.category,
    required this.currentLevel,
    required this.requiredLevel,
    required this.priority,
    required this.impact,
  });

  final String name;
  final String category;
  final int currentLevel;
  final int requiredLevel;
  final SkillPriority priority;
  final String impact;

  bool get matched => currentLevel >= requiredLevel;
}

class RoleGapSnapshot {
  const RoleGapSnapshot({
    required this.role,
    required this.targetRole,
    required this.roles,
    required this.gaps,
    required this.matchPercent,
    required this.total,
    required this.matched,
    required this.lacking,
  });

  final String role;
  final String targetRole;
  final List<String> roles;
  final List<SkillGap> gaps;
  final int matchPercent;
  final int total;
  final int matched;
  final int lacking;

  factory RoleGapSnapshot.fromJson(Map<String, dynamic> json) {
    final stats = Map<String, dynamic>.from(
      json['stats'] is Map ? json['stats'] as Map : const {},
    );
    final gaps = <SkillGap>[];
    for (final raw in json['gaps'] as List<dynamic>? ?? const []) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final name = item['name'] as String? ?? '';
      if (name.isEmpty) continue;
      gaps.add(
        SkillGap(
          name: name,
          category: item['category'] as String? ?? 'Technical skill',
          currentLevel: (item['currentLevel'] as num?)?.toInt() ?? 0,
          requiredLevel: (item['requiredLevel'] as num?)?.toInt() ?? 80,
          priority: switch ((item['priority'] as String?)?.toLowerCase()) {
            'low' => SkillPriority.low,
            'medium' => SkillPriority.medium,
            _ => SkillPriority.high,
          },
          impact: item['impact'] as String? ?? '',
        ),
      );
    }
    final matched = (stats['matched'] as num?)?.toInt() ??
        gaps.where((item) => item.matched).length;
    final total = (stats['total'] as num?)?.toInt() ?? gaps.length;
    final matchPercent = (stats['matchPercent'] as num?)?.toInt() ??
        (gaps.isEmpty
            ? 0
            : ((gaps
                            .map((item) => (item.currentLevel /
                                    item.requiredLevel.clamp(1, 100))
                                .clamp(0.0, 1.0))
                            .fold<double>(0, (a, b) => a + b) /
                        gaps.length) *
                    100)
                .round());
    return RoleGapSnapshot(
      role: json['role'] as String? ?? '',
      targetRole: json['targetRole'] as String? ?? '',
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      gaps: gaps,
      matchPercent: matchPercent,
      total: total,
      matched: matched,
      lacking: (stats['lacking'] as num?)?.toInt() ?? total - matched,
    );
  }

  factory RoleGapSnapshot.fromGaps({
    required String role,
    required String targetRole,
    required List<String> roles,
    required List<SkillGap> gaps,
  }) {
    final matched = gaps.where((item) => item.matched).length;
    final total = gaps.length;
    final matchPercent = gaps.isEmpty
        ? 0
        : ((gaps
                        .map((item) => (item.currentLevel /
                                item.requiredLevel.clamp(1, 100))
                            .clamp(0.0, 1.0))
                        .fold<double>(0, (a, b) => a + b) /
                    gaps.length) *
                100)
            .round();
    return RoleGapSnapshot(
      role: role,
      targetRole: targetRole,
      roles: roles,
      gaps: gaps,
      matchPercent: matchPercent,
      total: total,
      matched: matched,
      lacking: total - matched,
    );
  }

  RoleGapSnapshot copyWith({
    String? role,
    String? targetRole,
    List<String>? roles,
    List<SkillGap>? gaps,
    int? matchPercent,
    int? total,
    int? matched,
    int? lacking,
  }) {
    return RoleGapSnapshot(
      role: role ?? this.role,
      targetRole: targetRole ?? this.targetRole,
      roles: roles ?? this.roles,
      gaps: gaps ?? this.gaps,
      matchPercent: matchPercent ?? this.matchPercent,
      total: total ?? this.total,
      matched: matched ?? this.matched,
      lacking: lacking ?? this.lacking,
    );
  }
}

class LearningResource {
  const LearningResource({
    required this.title,
    required this.creator,
    required this.skill,
    required this.duration,
    required this.difficulty,
    required this.color,
    required this.icon,
    required this.url,
    this.thumbnailUrl,
    this.platform = 'YouTube',
    this.rating,
  });

  final String title;
  final String creator;
  final String skill;
  final String duration;
  final String difficulty;
  final Color color;
  final IconData icon;
  final String url;
  final String? thumbnailUrl;
  final String platform;
  final String? rating;

  factory LearningResource.fromApi(Map<String, dynamic> json) {
    final skill = json['skill'] as String? ?? '';
    final url = json['url'] as String? ?? '';
    return LearningResource(
      title: json['title'] as String? ?? 'Learning resource',
      creator: json['creator'] as String? ?? 'Job Sensei Learning',
      skill: skill,
      duration: json['duration'] as String? ?? 'Self-paced',
      difficulty: json['difficulty'] as String? ?? 'Recommended',
      color: _colorForSkill(skill),
      icon: Icons.play_arrow_rounded,
      url: url,
      thumbnailUrl: json['thumbnailUrl'] as String? ?? youtubeThumb(url),
      platform: json['platform'] as String? ?? 'YouTube',
    );
  }
}

String? youtubeVideoId(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;
  final v = uri.queryParameters['v'];
  if (v != null && v.length >= 11) return v.substring(0, 11);
  if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.first;
  }
  final embed = uri.pathSegments.indexOf('embed');
  if (embed >= 0 && embed + 1 < uri.pathSegments.length) {
    return uri.pathSegments[embed + 1];
  }
  final shorts = uri.pathSegments.indexOf('shorts');
  if (shorts >= 0 && shorts + 1 < uri.pathSegments.length) {
    return uri.pathSegments[shorts + 1];
  }
  return null;
}

String? youtubeThumb(String url) {
  final id = youtubeVideoId(url);
  if (id == null || id.isEmpty) return null;
  return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
}

Color _colorForSkill(String skill) {
  const colors = [
    Color(0xFF2563EB),
    Color(0xFFE535AB),
    Color(0xFF0891B2),
    Color(0xFFF97316),
  ];
  return colors[skill.hashCode.abs() % colors.length];
}
