import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../services/learning_service.dart';
import '../../../../shared/models/learning_models.dart';
import '../../data/services/youtube_resource_service.dart';
import 'in_app_video_screen.dart';

class LearningResourcesScreen extends StatefulWidget {
  const LearningResourcesScreen({
    super.key,
    this.service,
    this.initialSkills,
    this.targetRole,
  });

  final ResourceService? service;
  final List<String>? initialSkills;
  final String? targetRole;

  @override
  State<LearningResourcesScreen> createState() =>
      _LearningResourcesScreenState();
}

class _LearningResourcesScreenState extends State<LearningResourcesScreen> {
  late Future<List<LearningResource>> _future;
  String _filter = 'All';
  final _learning = LearningService();

  List<String> get _skills {
    final requested = widget.initialSkills ?? const <String>[];
    final unique = <String>[];
    final seen = <String>{};
    for (final skill in requested) {
      final trimmed = skill.trim();
      if (trimmed.isEmpty || !seen.add(trimmed.toLowerCase())) continue;
      unique.add(trimmed);
    }
    return unique.isEmpty
        ? const ['TypeScript', 'GraphQL', 'Docker', 'System Design']
        : unique;
  }

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<LearningResource>> _load() async {
    if (widget.service != null) {
      return widget.service!.recommendations(_skills);
    }
    final local = YouTubeResourceService.lessonsForSkills(_skills);
    final fromApi = <LearningResource>[];
    try {
      final raw = await _learning.resources();
      for (final item in raw) {
        if (item is! Map) continue;
        final resource =
            LearningResource.fromApi(Map<String, dynamic>.from(item));
        if (_skills.any(
            (skill) => skill.toLowerCase() == resource.skill.toLowerCase())) {
          fromApi.add(YouTubeResourceService.ensurePlayable(resource));
        }
      }
    } catch (_) {}
    return YouTubeResourceService.merge(local, fromApi);
  }

  void _watch(List<LearningResource> playlist, int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InAppVideoScreen.fromPlaylist(
          playlist: playlist,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.targetRole?.trim();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(role == null || role.isEmpty ? 'Lessons for you' : role),
      ),
      body: FutureBuilder<List<LearningResource>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? const <LearningResource>[];
          final visible = _filter == 'All'
              ? all
              : all
                  .where((item) =>
                      item.skill.toLowerCase() == _filter.toLowerCase())
                  .toList();
          final groups = <String, List<LearningResource>>{};
          for (final skill in _skills) {
            final lessons = visible
                .where((item) =>
                    item.skill.toLowerCase() == skill.toLowerCase())
                .toList();
            if (lessons.isNotEmpty) groups[skill] = lessons;
          }
          for (final lesson in visible) {
            final known = groups.keys.any(
              (skill) => skill.toLowerCase() == lesson.skill.toLowerCase(),
            );
            if (known) continue;
            groups[lesson.skill] = visible
                .where((item) =>
                    item.skill.toLowerCase() == lesson.skill.toLowerCase())
                .toList();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _load());
              await _future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                Text(
                  'Close your skill gaps',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  all.isEmpty
                      ? 'Lessons will appear here once a path is published.'
                      : '${all.length} in-app lessons matched to the skills you still need.',
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final skill in ['All', ..._skills])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(skill),
                              selected: _filter == skill,
                              onSelected: (_) =>
                                  setState(() => _filter = skill),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: EmptyState(
                      icon: Icons.video_library_outlined,
                      title: 'No lessons in this filter',
                      message: 'Choose another skill to keep learning.',
                    ),
                  )
                else
                  ...groups.entries.map((entry) {
                    final lessons = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${lessons.length} lesson${lessons.length == 1 ? '' : 's'}  ·  tap to watch in the app',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...lessons.asMap().entries.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _LessonCard(
                                    resource: item.value,
                                    onWatch: () => _watch(lessons, item.key),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.resource, required this.onWatch});

  final LearningResource resource;
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onWatch,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          resource.color,
                          resource.color.withValues(alpha: 0.55),
                        ],
                      ),
                      image: resource.thumbnailUrl == null
                          ? null
                          : DecorationImage(
                              image: NetworkImage(resource.thumbnailUrl!),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withValues(alpha: 0.28),
                                BlendMode.darken,
                              ),
                            ),
                    ),
                  ),
                  const Center(
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.play_arrow_rounded,
                          size: 32, color: AppColors.primary),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: AppBadge(label: resource.skill, color: Colors.white),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        resource.duration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${resource.creator}  ·  ${resource.difficulty}',
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onWatch,
                      icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                      label: const Text('Watch in app'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
