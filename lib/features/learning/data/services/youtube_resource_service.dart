import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../shared/models/learning_models.dart';

abstract interface class ResourceService {
  Future<List<LearningResource>> recommendations(List<String> skills);
}

class YouTubeResourceService implements ResourceService {
  YouTubeResourceService({http.Client? client})
      : _client = client ?? http.Client();

  static const _apiKey = String.fromEnvironment('YOUTUBE_API_KEY');
  final http.Client _client;

  @override
  Future<List<LearningResource>> recommendations(List<String> skills) async {
    return lessonsForSkills(skills);
  }

  /// Always returns in-app playable watch URLs for the requested skills.
  static List<LearningResource> lessonsForSkills(List<String> skills) {
    if (skills.isEmpty) return List<LearningResource>.from(catalog);
    final requested = skills
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList();
    final out = <LearningResource>[];
    final seen = <String>{};
    for (final skill in requested) {
      final matches = catalog.where(
        (item) => item.skill.toLowerCase() == skill.toLowerCase(),
      );
      if (matches.isEmpty) {
        final fallback = _genericLesson(skill);
        if (seen.add(fallback.url)) out.add(fallback);
        continue;
      }
      for (final lesson in matches) {
        if (seen.add(lesson.url)) out.add(lesson);
      }
    }
    return out;
  }

  static String playableUrlForSkill(String skill) {
    for (final item in catalog) {
      if (item.skill.toLowerCase() == skill.toLowerCase()) return item.url;
    }
    return 'https://www.youtube.com/watch?v=PkZNo7MFNFg';
  }

  static LearningResource ensurePlayable(LearningResource resource) {
    if (youtubeVideoId(resource.url) != null) {
      return resource.thumbnailUrl == null
          ? LearningResource(
              title: resource.title,
              creator: resource.creator,
              skill: resource.skill,
              duration: resource.duration,
              difficulty: resource.difficulty,
              color: resource.color,
              icon: resource.icon,
              url: resource.url,
              thumbnailUrl: youtubeThumb(resource.url),
              platform: resource.platform,
              rating: resource.rating,
            )
          : resource;
    }
    LearningResource? fallback;
    for (final item in catalog) {
      if (item.skill.toLowerCase() == resource.skill.toLowerCase()) {
        fallback = item;
        break;
      }
    }
    final url = fallback?.url ?? playableUrlForSkill(resource.skill);
    return LearningResource(
      title: resource.title,
      creator: resource.creator,
      skill: resource.skill,
      duration: resource.duration,
      difficulty: resource.difficulty,
      color: resource.color,
      icon: resource.icon,
      url: url,
      thumbnailUrl: youtubeThumb(url) ?? fallback?.thumbnailUrl,
      platform: resource.platform,
      rating: resource.rating,
    );
  }

  static List<LearningResource> merge(
    List<LearningResource> preferred,
    List<LearningResource> extra,
  ) {
    final seen = <String>{};
    final out = <LearningResource>[];
    for (final item in [...preferred, ...extra]) {
      final playable = ensurePlayable(item);
      final key = youtubeVideoId(playable.url) ?? playable.url;
      if (!seen.add(key)) continue;
      out.add(playable);
    }
    return out;
  }

  static LearningResource _genericLesson(String skill) {
    return LearningResource(
      title: '$skill crash course',
      creator: 'freeCodeCamp.org',
      skill: skill,
      duration: 'Self-paced',
      difficulty: 'Recommended',
      color: AppColorsForResources.forSkill(skill),
      icon: Icons.play_arrow_rounded,
      url: 'https://www.youtube.com/watch?v=PkZNo7MFNFg',
      thumbnailUrl: 'https://img.youtube.com/vi/PkZNo7MFNFg/hqdefault.jpg',
      rating: '4.7',
    );
  }

  static LearningResource _lesson({
    required String title,
    required String creator,
    required String skill,
    required String duration,
    required String difficulty,
    required String videoId,
    required double rating,
  }) {
    return LearningResource(
      title: title,
      creator: creator,
      skill: skill,
      duration: duration,
      difficulty: difficulty,
      color: AppColorsForResources.forSkill(skill),
      icon: Icons.play_arrow_rounded,
      url: 'https://www.youtube.com/watch?v=$videoId',
      thumbnailUrl: 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
      rating: rating.toStringAsFixed(1),
    );
  }

  static final catalog = <LearningResource>[
    _lesson(
      title: 'TypeScript Crash Course',
      creator: 'Traversy Media',
      skill: 'TypeScript',
      duration: '1h 14m',
      difficulty: 'Intermediate',
      videoId: '30LWjhZzg50',
      rating: 4.8,
    ),
    _lesson(
      title: 'TypeScript Generics Tutorial',
      creator: 'Web Dev Simplified',
      skill: 'TypeScript',
      duration: '12m',
      difficulty: 'Intermediate',
      videoId: 'nViEqpgwxHE',
      rating: 4.7,
    ),
    _lesson(
      title: 'GraphQL Full Course',
      creator: 'freeCodeCamp.org',
      skill: 'GraphQL',
      duration: '3h 18m',
      difficulty: 'Beginner',
      videoId: 'ed8SzALpx1w',
      rating: 4.9,
    ),
    _lesson(
      title: 'Docker Tutorial for Beginners',
      creator: 'TechWorld with Nana',
      skill: 'Docker',
      duration: '2h 10m',
      difficulty: 'Beginner',
      videoId: '3c-iBn73dDE',
      rating: 4.8,
    ),
    _lesson(
      title: 'Docker Compose Crash Course',
      creator: 'TechWorld with Nana',
      skill: 'Docker',
      duration: '28m',
      difficulty: 'Intermediate',
      videoId: 'DM6Z0GxIvR0',
      rating: 4.7,
    ),
    _lesson(
      title: 'System Design Interview Primer',
      creator: 'Fireship',
      skill: 'System Design',
      duration: '10m',
      difficulty: 'Advanced',
      videoId: 'SqcXvc3ZmRU',
      rating: 4.7,
    ),
    _lesson(
      title: 'System Design Fundamentals',
      creator: 'ByteByteGo',
      skill: 'System Design',
      duration: '8m',
      difficulty: 'Intermediate',
      videoId: 'Y0lDGjdMz1c',
      rating: 4.8,
    ),
    _lesson(
      title: 'React Full Course',
      creator: 'freeCodeCamp.org',
      skill: 'React',
      duration: '12h',
      difficulty: 'Beginner',
      videoId: 'bMknfKXIFA8',
      rating: 4.9,
    ),
    _lesson(
      title: 'React Hooks Tutorial',
      creator: 'Web Dev Simplified',
      skill: 'React',
      duration: '1h',
      difficulty: 'Intermediate',
      videoId: '0ZJgIjIuY7U',
      rating: 4.8,
    ),
    _lesson(
      title: 'Node.js and Express Crash Course',
      creator: 'freeCodeCamp.org',
      skill: 'Node.js',
      duration: '8h',
      difficulty: 'Beginner',
      videoId: 'Oe421EPjeBE',
      rating: 4.8,
    ),
    _lesson(
      title: 'Figma UI Design Tutorial',
      creator: 'AJ&Smart',
      skill: 'Figma',
      duration: '1h',
      difficulty: 'Beginner',
      videoId: 'FTFaQWZBqQ8',
      rating: 4.7,
    ),
    _lesson(
      title: 'Python for Beginners',
      creator: 'freeCodeCamp.org',
      skill: 'Python',
      duration: '4h',
      difficulty: 'Beginner',
      videoId: 'kqtD5dpn9C8',
      rating: 4.8,
    ),
    _lesson(
      title: 'Machine Learning Course',
      creator: 'freeCodeCamp.org',
      skill: 'Machine Learning',
      duration: '4h',
      difficulty: 'Intermediate',
      videoId: 'NWONeJKn6kc',
      rating: 4.8,
    ),
    _lesson(
      title: 'SQL Tutorial for Beginners',
      creator: 'freeCodeCamp.org',
      skill: 'SQL',
      duration: '4h',
      difficulty: 'Beginner',
      videoId: 'HXV3zeQKqGY',
      rating: 4.9,
    ),
    _lesson(
      title: 'AWS Cloud Practitioner Primer',
      creator: 'freeCodeCamp.org',
      skill: 'Cloud Certification',
      duration: '4h',
      difficulty: 'Beginner',
      videoId: 'ulprqHHWlng',
      rating: 4.7,
    ),
    _lesson(
      title: 'Technical Leadership Skills',
      creator: 'LeadDev',
      skill: 'Technical Leadership',
      duration: '18m',
      difficulty: 'Advanced',
      videoId: 'k74IrUNaJVk',
      rating: 4.6,
    ),
    _lesson(
      title: 'Product Analytics Explained',
      creator: 'Mixpanel',
      skill: 'Product Analytics',
      duration: '12m',
      difficulty: 'Beginner',
      videoId: 'sS8K2bPZ3n8',
      rating: 4.6,
    ),
    _lesson(
      title: 'Product Roadmapping',
      creator: 'Product School',
      skill: 'Roadmapping',
      duration: '20m',
      difficulty: 'Intermediate',
      videoId: 'PJjmw9TFZts',
      rating: 4.6,
    ),
    _lesson(
      title: 'Stakeholder Management',
      creator: 'Product School',
      skill: 'Stakeholder Management',
      duration: '15m',
      difficulty: 'Intermediate',
      videoId: 'qWWc-9yba5Q',
      rating: 4.5,
    ),
    _lesson(
      title: 'User Research Basics',
      creator: 'NN/g',
      skill: 'User Research',
      duration: '12m',
      difficulty: 'Beginner',
      videoId: 'ZKxw7T47_Y8',
      rating: 4.6,
    ),
  ];

  /// Kept for older call sites and tests.
  static List<LearningResource> demoForSkills(List<String> skills) =>
      lessonsForSkills(skills);

  static List<LearningResource> get demoResources => catalog;

  Future<List<LearningResource>> searchYoutube(List<String> skills) async {
    if (_apiKey.isEmpty) return lessonsForSkills(skills);
    final results = <LearningResource>[];
    for (final skill in skills.take(3)) {
      final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
        'part': 'snippet',
        'type': 'video',
        'maxResults': '2',
        'q': '$skill complete tutorial career',
        'key': _apiKey,
      });
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) continue;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      for (final raw in items) {
        final item = raw as Map<String, dynamic>;
        final id = item['id'] as Map<String, dynamic>;
        final snippet = item['snippet'] as Map<String, dynamic>;
        final videoId = id['videoId'] as String?;
        if (videoId == null) continue;
        results.add(_lesson(
          title: (snippet['title'] as String? ?? 'YouTube tutorial')
              .replaceAll('&amp;', '&'),
          creator: snippet['channelTitle'] as String? ?? 'YouTube',
          skill: skill,
          duration: 'Self-paced',
          difficulty: 'Recommended',
          videoId: videoId,
          rating: 4.8,
        ));
      }
    }
    return merge(lessonsForSkills(skills), results);
  }
}

abstract final class AppColorsForResources {
  static Color forSkill(String skill) {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFFE535AB),
      const Color(0xFF0891B2),
      const Color(0xFFF97316),
      const Color(0xFF7C3AED),
      const Color(0xFF0F766E),
    ];
    return colors[skill.hashCode.abs() % colors.length];
  }
}
