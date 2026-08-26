import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/models/learning_models.dart';
import '../../data/services/youtube_resource_service.dart';

class LearningResourcesScreen extends StatefulWidget {
  const LearningResourcesScreen({
    super.key,
    this.service,
    this.initialSkills,
  });

  final ResourceService? service;
  final List<String>? initialSkills;

  @override
  State<LearningResourcesScreen> createState() =>
      _LearningResourcesScreenState();
}

class _LearningResourcesScreenState extends State<LearningResourcesScreen> {
  late final ResourceService _service =
      widget.service ?? YouTubeResourceService();
  late Future<List<LearningResource>> _future;
  String _filter = 'All';
  final _bookmarked = <String>{};

  static const _defaultSkills = [
    'TypeScript',
    'GraphQL',
    'Docker',
    'System Design'
  ];

  List<String> get _skills => widget.initialSkills ?? _defaultSkills;

  @override
  void initState() {
    super.initState();
    _future = _service.recommendations(_skills);
  }

  void _refresh() {
    setState(() => _future = _service.recommendations(_skills));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          _refresh();
          await _future;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              sliver: SliverList.list(
                children: [
                  ScreenIntro(
                    eyebrow: 'Your learning path',
                    title: 'Learning Resources',
                    description:
                        'Focused recommendations selected from your highest-impact skill gaps.',
                    trailing: IconButton.filledTonal(
                      tooltip: 'Refresh recommendations',
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PathSummary(skills: _skills),
                  const SizedBox(height: 22),
                  const SectionTitle('Recommended for you'),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', ..._skills]
                          .map((skill) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(skill),
                                  selected: _filter == skill,
                                  onSelected: (_) =>
                                      setState(() => _filter = skill),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            FutureBuilder<List<LearningResource>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded,
                            size: 42, color: AppColors.muted),
                        const SizedBox(height: 12),
                        const Text('Could not load recommendations.'),
                        TextButton(
                            onPressed: _refresh,
                            child: const Text('Try again')),
                      ],
                    ),
                  );
                }
                final resources = (snapshot.data ?? [])
                    .where((item) => _filter == 'All' || item.skill == _filter)
                    .toList();
                if (resources.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.video_library_outlined,
                      title: 'No resources in this filter',
                      message: 'Choose another skill to continue learning.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                  sliver: SliverList.separated(
                    itemCount: resources.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final resource = resources[index];
                      return _ResourceCard(
                        resource: resource,
                        bookmarked: _bookmarked.contains(resource.url),
                        onBookmark: () => setState(() {
                          if (!_bookmarked.add(resource.url)) {
                            _bookmarked.remove(resource.url);
                          }
                        }),
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ResourceDetailScreen(resource: resource),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PathSummary extends StatelessWidget {
  const _PathSummary({required this.skills});

  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D28D9), AppColors.violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                const Icon(Icons.route_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('4-skill learning sprint',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(skills.join(' · '),
                    maxLines: 2,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const Text('3/6',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.resource,
    required this.bookmarked,
    required this.onBookmark,
    required this.onOpen,
  });

  final LearningResource resource;
  final bool bookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 142,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [resource.color, resource.color.withOpacity(0.62)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -36,
                    child: CircleAvatar(
                      radius: 72,
                      backgroundColor: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow_rounded,
                          color: resource.color, size: 34),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: AppBadge(label: resource.skill, color: Colors.white),
                  ),
                  Positioned(
                    top: 6,
                    right: 8,
                    child: IconButton.filledTonal(
                      onPressed: onBookmark,
                      icon: Icon(bookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(resource.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(resource.creator,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 16, color: AppColors.muted),
                      const SizedBox(width: 5),
                      Text(resource.duration,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 11)),
                      const SizedBox(width: 14),
                      const Icon(Icons.signal_cellular_alt_rounded,
                          size: 16, color: AppColors.muted),
                      const SizedBox(width: 5),
                      Text(resource.difficulty,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 11)),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_rounded,
                          color: AppColors.primary),
                    ],
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

class ResourceDetailScreen extends StatelessWidget {
  const ResourceDetailScreen({super.key, required this.resource});

  final LearningResource resource;

  Future<void> _launch(BuildContext context) async {
    final uri = Uri.parse(resource.url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Container(
            height: 240,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF111827), resource.color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: IconButton.filled(
                onPressed: () => _launch(context),
                icon: const Icon(Icons.play_arrow_rounded, size: 42),
                style: IconButton.styleFrom(
                  minimumSize: const Size(76, 76),
                  backgroundColor: Colors.white,
                  foregroundColor: resource.color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          AppBadge(label: resource.skill, color: resource.color),
          const SizedBox(height: 12),
          Text(resource.title,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('By ${resource.creator}',
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                      child: _DetailMetric(
                          icon: Icons.schedule, label: resource.duration)),
                  Expanded(
                      child: _DetailMetric(
                          icon: Icons.signal_cellular_alt,
                          label: resource.difficulty)),
                  const Expanded(
                      child: _DetailMetric(
                          icon: Icons.play_circle_outline, label: 'YouTube')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text('Why this is recommended',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Your skill analysis identified ${resource.skill} as an important gap. '
            'This resource offers a practical route from concepts to portfolio-ready work.',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 22),
          Text('What you will practice',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          const _LearningPoint('Core concepts explained through examples'),
          const _LearningPoint(
              'A practical project you can discuss in interviews'),
          const _LearningPoint('Common mistakes and professional workflows'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _launch(context),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Watch on YouTube'),
          ),
        ],
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 6),
        Text(label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _LearningPoint extends StatelessWidget {
  const _LearningPoint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: 9),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
