import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/models/learning_models.dart';
import '../../data/services/youtube_resource_service.dart';
import '../widgets/youtube_embed_player.dart';

class InAppVideoScreen extends StatefulWidget {
  const InAppVideoScreen({
    super.key,
    required this.title,
    required this.url,
    this.creator,
    this.skill,
    this.duration,
    this.difficulty,
    this.color = AppColors.primary,
    this.playlist = const [],
    this.initialIndex = 0,
  });

  factory InAppVideoScreen.fromPlaylist({
    required List<LearningResource> playlist,
    int initialIndex = 0,
  }) {
    final safe = playlist.isEmpty ? 0 : initialIndex.clamp(0, playlist.length - 1);
    final current = playlist[safe];
    return InAppVideoScreen(
      title: current.title,
      url: current.url,
      creator: current.creator,
      skill: current.skill,
      duration: current.duration,
      difficulty: current.difficulty,
      color: current.color,
      playlist: playlist,
      initialIndex: safe,
    );
  }

  factory InAppVideoScreen.fromResource(LearningResource resource) {
    return InAppVideoScreen.fromPlaylist(playlist: [resource]);
  }

  final String title;
  final String url;
  final String? creator;
  final String? skill;
  final String? duration;
  final String? difficulty;
  final Color color;
  final List<LearningResource> playlist;
  final int initialIndex;

  @override
  State<InAppVideoScreen> createState() => _InAppVideoScreenState();
}

class _InAppVideoScreenState extends State<InAppVideoScreen> {
  late int _index = widget.initialIndex;

  List<LearningResource> get _lessons {
    if (widget.playlist.isNotEmpty) return widget.playlist;
    return [
      LearningResource(
        title: widget.title,
        creator: widget.creator ?? 'Job Sensei Learning',
        skill: widget.skill ?? 'Lesson',
        duration: widget.duration ?? 'Self-paced',
        difficulty: widget.difficulty ?? 'Recommended',
        color: widget.color,
        icon: Icons.play_arrow_rounded,
        url: widget.url,
      ),
    ];
  }

  LearningResource get _current => _lessons[_index.clamp(0, _lessons.length - 1)];

  String? get _videoId {
    final direct = youtubeVideoId(_current.url);
    if (direct != null) return direct;
    return youtubeVideoId(
      YouTubeResourceService.playableUrlForSkill(_current.skill),
    );
  }

  void _openAt(int index) {
    if (index < 0 || index >= _lessons.length || index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    final videoId = _videoId;
    final next = _index + 1 < _lessons.length ? _lessons[_index + 1] : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        foregroundColor: Colors.white,
        title: Text(current.skill, style: const TextStyle(fontSize: 16)),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: videoId == null
                ? const ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: Text(
                        'This lesson is not a playable video.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                : YoutubeEmbedPlayer(
                    key: ValueKey(videoId),
                    videoId: videoId,
                  ),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  AppBadge(label: current.skill, color: current.color),
                  const SizedBox(height: 10),
                  Text(
                    current.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'By ${current.creator}  ·  ${current.duration}  ·  ${current.difficulty}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This lesson was picked because ${current.skill} is part of your skill-gap plan. '
                    'Watch it here, then move to the next lesson in the list.',
                    style: const TextStyle(color: AppColors.muted, height: 1.45),
                  ),
                  if (next != null) ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () => _openAt(_index + 1),
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('Watch next lesson'),
                      ),
                    ),
                  ],
                  if (_lessons.length > 1) ...[
                    const SizedBox(height: 26),
                    const Text(
                      'Up next',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._lessons.asMap().entries.map((entry) {
                      final selected = entry.key == _index;
                      final lesson = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: ListTile(
                            onTap: () => _openAt(entry.key),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: selected
                                  ? AppColors.primary
                                  : AppColors.primary.withValues(alpha: 0.12),
                              foregroundColor:
                                  selected ? Colors.white : AppColors.primary,
                              child: Icon(
                                selected
                                    ? Icons.play_arrow_rounded
                                    : Icons.play_circle_outline_rounded,
                              ),
                            ),
                            title: Text(
                              lesson.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${lesson.skill} · ${lesson.duration}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
