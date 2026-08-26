import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/models/learning_path_models.dart';
import '../../data/repositories/learning_path_repository.dart';
import '../../data/repositories/learning_progress_repository.dart';
import '../../../../app/injector.dart';
import '../../../../shared/models/learning_progress_models.dart';

class StructuredLearningScreen extends StatefulWidget {
  const StructuredLearningScreen({
    super.key,
    this.initialSkills,
    this.repository,
    this.progressRepository,
  });

  final List<String>? initialSkills;
  final LearningPathRepository? repository;
  final LearningProgressRepository? progressRepository;

  @override
  State<StructuredLearningScreen> createState() =>
      _StructuredLearningScreenState();
}

class _StructuredLearningScreenState extends State<StructuredLearningScreen> {
  late final LearningPathRepository _repository =
      widget.repository ?? ApiLearningPathRepository();
  late Future<List<StructuredLearningPath>> _paths;

  List<String> get _skills =>
      widget.initialSkills ?? const ['State Management', 'Docker', 'Django'];

  @override
  void initState() {
    super.initState();
    _paths = _repository.pathsForSkills(_skills);
  }

  @override
  Widget build(BuildContext context) {
    final requestedSkills = widget.initialSkills ?? const <String>[];
    final selectedSkill =
        requestedSkills.length == 1 ? requestedSkills.first : null;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => _paths = _repository.pathsForSkills(_skills));
            await _paths;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
            children: [
              ScreenIntro(
                eyebrow: selectedSkill == null
                    ? 'Structured curriculum'
                    : 'Recommended from Skill Gap',
                title: selectedSkill == null
                    ? 'Learning Paths'
                    : 'Learn $selectedSkill',
                description:
                    'Each published path contains ordered lessons and resources selected for that lesson.',
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<StructuredLearningPath>>(
                future: _paths,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 56),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return const EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Learning resources unavailable',
                      message:
                          'The server could not load learning resources. Please try again.',
                    );
                  }
                  final paths = snapshot.data ?? const [];
                  if (paths.isEmpty) {
                    return EmptyState(
                      icon: Icons.hourglass_top_rounded,
                      title: 'Learning path coming soon',
                      message: selectedSkill == null
                          ? 'An Admin must publish a path before it appears here.'
                          : 'No published path exists for $selectedSkill yet. It remains in the curriculum queue.',
                    );
                  }
                  return Column(
                    children: paths
                        .map(
                          (path) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _LearningPathCard(
                              path: path,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => LearningPathDetailsScreen(
                                    path: path,
                                    repository: _repository,
                                    progressRepository: widget
                                            .progressRepository ??
                                        Injector.learningProgressRepository(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearningPathCard extends StatelessWidget {
  const _LearningPathCard({required this.path, required this.onTap});

  final StructuredLearningPath path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppBadge(
                      label: path.skill.name,
                      icon: Icons.school_outlined,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(path.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 7),
              Text(
                path.description,
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppBadge(label: path.difficulty.toUpperCase()),
                  AppBadge(
                    label: '${path.lessonCount} lessons',
                    icon: Icons.format_list_numbered_rounded,
                  ),
                  AppBadge(
                    label: path.estimatedDuration,
                    icon: Icons.schedule_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LearningPathDetailsScreen extends StatefulWidget {
  const LearningPathDetailsScreen({
    super.key,
    required this.path,
    required this.repository,
    required this.progressRepository,
  });

  final StructuredLearningPath path;
  final LearningPathRepository repository;
  final LearningProgressRepository progressRepository;

  @override
  State<LearningPathDetailsScreen> createState() =>
      _LearningPathDetailsScreenState();
}

class _LearningPathDetailsScreenState extends State<LearningPathDetailsScreen> {
  late final Future<StructuredLearningPath> _details =
      widget.path.lessons.isNotEmpty
          ? Future.value(widget.path)
          : widget.repository.pathDetails(widget.path.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning path')),
      body: FutureBuilder<StructuredLearningPath>(
        future: _details,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final path = snapshot.data;
          if (path == null) {
            return const EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Path unavailable',
              message: 'The learning path could not be loaded.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            children: [
              AppBadge(label: path.skill.name),
              const SizedBox(height: 12),
              Text(path.title,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(path.description,
                  style: const TextStyle(color: AppColors.muted, height: 1.45)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  AppBadge(label: path.difficulty.toUpperCase()),
                  AppBadge(label: path.estimatedDuration),
                ],
              ),
              const SizedBox(height: 24),
              const SectionTitle('Ordered lessons'),
              const SizedBox(height: 10),
              ...path.lessons.map(
                (lesson) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${lesson.orderIndex}'),
                      ),
                      title: Text(lesson.title),
                      subtitle: Text(lesson.estimatedDuration),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LessonDetailsScreen(
                              lesson: lesson,
                              pathId: path.id,
                              repository: widget.progressRepository),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Lesson completion and progress records connect here through Nazifa\'s Learning Progress module.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}

class LessonDetailsScreen extends StatefulWidget {
  const LessonDetailsScreen(
      {super.key,
      required this.lesson,
      required this.pathId,
      required this.repository});

  final LearningLesson lesson;
  final String pathId;
  final LearningProgressRepository repository;

  @override
  State<LessonDetailsScreen> createState() => _LessonDetailsScreenState();
}

class _LessonDetailsScreenState extends State<LessonDetailsScreen> {
  late Future<List<LearningProgress>> _progress =
      widget.repository.forPath(widget.pathId);

  bool _completed(String resourceId, List<LearningProgress> progress) =>
      progress.any((item) => item.resourceId == resourceId && item.completed);

  Future<void> _open(LessonResource resource) async {
    await widget.repository
        .start(pathId: widget.pathId, resourceId: resource.id);
    await launchUrl(Uri.parse(resource.url),
        mode: LaunchMode.externalApplication);
    await widget.repository
        .complete(pathId: widget.pathId, resourceId: resource.id);
    if (mounted) {
      setState(() => _progress = widget.repository.forPath(widget.pathId));
    }
  }

  Future<void> _complete(LessonResource resource) async {
    await widget.repository
        .complete(pathId: widget.pathId, resourceId: resource.id);
    if (mounted)
      setState(() => _progress = widget.repository.forPath(widget.pathId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lesson ${widget.lesson.orderIndex}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          Text(widget.lesson.title,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(widget.lesson.estimatedDuration,
              style: const TextStyle(color: AppColors.primary)),
          const SizedBox(height: 18),
          Text(widget.lesson.description,
              style: const TextStyle(color: AppColors.muted, height: 1.45)),
          const SizedBox(height: 24),
          const SectionTitle('Learning resources'),
          const SizedBox(height: 10),
          FutureBuilder<List<LearningProgress>>(
            future: _progress,
            builder: (context, snapshot) {
              final progress = snapshot.data ?? const <LearningProgress>[];
              if (widget.lesson.resources.isEmpty) {
                return const EmptyState(
                    icon: Icons.library_books_outlined,
                    title: 'Resources coming soon',
                    message:
                        'An Admin can attach videos, articles, or documentation.');
              }
              return Column(
                  children: widget.lesson.resources.map((resource) {
                final done = _completed(resource.id, progress);
                return Card(
                  child: ListTile(
                    leading: Icon(
                        done
                            ? Icons.check_circle
                            : Icons.play_circle_outline_rounded,
                        color: done ? AppColors.success : AppColors.primary),
                    title: Text(resource.title),
                    subtitle: Text(
                        done ? 'COMPLETED' : resource.platform.toUpperCase()),
                    trailing: done
                        ? const Icon(Icons.verified_rounded,
                            color: AppColors.success)
                        : IconButton(
                            icon: const Icon(Icons.open_in_new_rounded),
                            onPressed: () => _open(resource)),
                    onTap: () => _open(resource),
                  ),
                );
              }).toList());
            },
          ),
          if (widget.lesson.resources.isNotEmpty) ...[
            const SizedBox(height: 12),
            FutureBuilder<List<LearningProgress>>(
              future: _progress,
              builder: (context, snapshot) {
                final done = (snapshot.data ?? const <LearningProgress>[])
                    .where((item) => item.completed)
                    .map((item) => item.resourceId)
                    .toSet();
                final allDone = widget.lesson.resources
                    .every((item) => done.contains(item.id));
                return FilledButton.icon(
                  onPressed: allDone
                      ? null
                      : () => _complete(widget.lesson.resources
                          .firstWhere((item) => !done.contains(item.id))),
                  icon: const Icon(Icons.task_alt_rounded),
                  label: Text(
                      allDone ? 'Lesson completed' : 'Mark lesson completed'),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
