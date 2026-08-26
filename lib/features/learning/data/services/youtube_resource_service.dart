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
    if (skills.isEmpty) return const [];
    if (_apiKey.isEmpty) return demoForSkills(skills);
    final results = <LearningResource>[];

    for (final skill in skills.take(3)) {
      final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
        'part': 'snippet',
        'type': 'video',
        'maxResults': '3',
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
        results.add(LearningResource(
          title: (snippet['title'] as String? ?? 'YouTube tutorial')
              .replaceAll('&amp;', '&'),
          creator: snippet['channelTitle'] as String? ?? 'YouTube',
          skill: skill,
          duration: 'Self-paced',
          difficulty: 'Recommended',
          color: AppColorsForResources.forSkill(skill),
          icon: Icons.play_arrow_rounded,
          url: 'https://www.youtube.com/watch?v=$videoId',
        ));
      }
    }
    return results.isEmpty ? demoResources : results;
  }

  /// Local demo paths keep the Module 3 -> Module 4 hand-off usable without
  /// a configured YouTube API key. Production uses YouTube search above.
  static List<LearningResource> demoForSkills(List<String> skills) {
    return skills
        .map(
          (skill) => LearningResource(
            title: '$skill learning path',
            creator: 'Job Sensei Learning',
            skill: skill,
            duration: 'Self-paced',
            difficulty: 'Recommended',
            color: AppColorsForResources.forSkill(skill),
            icon: Icons.school_rounded,
            url:
                'https://www.youtube.com/results?search_query=${Uri.encodeComponent('$skill tutorial')}',
          ),
        )
        .toList();
  }

  static const demoResources = <LearningResource>[
    LearningResource(
      title: 'TypeScript for React Developers',
      creator: 'Code Academy',
      skill: 'TypeScript',
      duration: '2h 18m',
      difficulty: 'Intermediate',
      color: Color(0xFF2563EB),
      icon: Icons.code_rounded,
      url:
          'https://www.youtube.com/results?search_query=typescript+for+react+developers',
    ),
    LearningResource(
      title: 'Mastering GraphQL from Zero',
      creator: 'freeCodeCamp',
      skill: 'GraphQL',
      duration: '3h 42m',
      difficulty: 'Beginner',
      color: Color(0xFFE535AB),
      icon: Icons.hub_rounded,
      url: 'https://www.youtube.com/results?search_query=graphql+full+course',
    ),
    LearningResource(
      title: 'Docker Fundamentals in Practice',
      creator: 'TechWorld with Nana',
      skill: 'Docker',
      duration: '1h 46m',
      difficulty: 'Beginner',
      color: Color(0xFF0891B2),
      icon: Icons.inventory_2_outlined,
      url: 'https://www.youtube.com/results?search_query=docker+fundamentals',
    ),
    LearningResource(
      title: 'Frontend System Design Interviews',
      creator: 'Engineering with Utsav',
      skill: 'System Design',
      duration: '58m',
      difficulty: 'Advanced',
      color: Color(0xFFF97316),
      icon: Icons.account_tree_rounded,
      url:
          'https://www.youtube.com/results?search_query=frontend+system+design',
    ),
  ];
}

abstract final class AppColorsForResources {
  static Color forSkill(String skill) {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFFE535AB),
      const Color(0xFF0891B2),
      const Color(0xFFF97316),
    ];
    return colors[skill.hashCode.abs() % colors.length];
  }
}
