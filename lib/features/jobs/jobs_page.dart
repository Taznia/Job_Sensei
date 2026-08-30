import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import 'job_details_page.dart';
import 'data/job_api_repository.dart';
import 'job_models.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  final JobRepository _repository = ApiJobRepository();
  final _searchController = TextEditingController();
  List<JobPosting> _jobs = const [];
  bool _loading = true;
  bool _failed = false;
  String _query = '';
  String _filter = 'All';

  static const _filters = ['All', 'Remote', 'Hybrid', 'On-site', 'Full time'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({String? query}) async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final jobs = await _repository.listJobs(query: query);
      if (!mounted) return;
      setState(() {
        _jobs = jobs.isEmpty && (query == null || query.isEmpty)
            ? demoJobs
            : jobs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _jobs = (query == null || query.isEmpty) ? demoJobs : const [];
        _loading = false;
        _failed = _jobs.isEmpty;
      });
    }
  }

  List<JobPosting> get _visible {
    final q = _query.trim().toLowerCase();
    return _jobs.where((job) {
      final haystack = [
        job.title,
        job.company,
        job.location,
        job.workMode,
        job.type,
        ...job.requiredSkills.map((skill) => skill.name),
      ].join(' ').toLowerCase();
      final matchesQuery = q.isEmpty || haystack.contains(q);
      if (!matchesQuery) return false;
      if (_filter == 'All') return true;
      final compact = _filter.toLowerCase().replaceAll(RegExp(r'[\s-]'), '');
      final mode = job.workMode.toLowerCase().replaceAll(RegExp(r'[\s-]'), '');
      final type = job.type.toLowerCase().replaceAll(RegExp(r'[\s-]'), '');
      return mode.contains(compact) || type.contains(compact);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(query: _searchController.text.trim()),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 108),
            children: [
              GradientHero(
                eyebrow: 'Open roles',
                title: 'Jobs',
                description:
                    'Pick a role, see how you match, then close the gaps in Learn.',
                stats: [
                  HeroStatChip(
                    icon: Icons.work_outline_rounded,
                    label: '${_jobs.length} roles',
                  ),
                  const HeroStatChip(
                    icon: Icons.auto_graph_rounded,
                    label: 'Match inside each job',
                  ),
                ],
                footer: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  style: const TextStyle(color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Search title, company, location, or skill',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final label = _filters[index];
                      final selected = _filter == label;
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) => setState(() => _filter = label),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_failed)
                const EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Jobs unavailable',
                  message: 'Try again when the job service is reachable.',
                )
              else if (visible.isEmpty)
                const EmptyState(
                  icon: Icons.work_outline_rounded,
                  title: 'No matching jobs',
                  message: 'Try another title, location, or filter.',
                )
              else ...[
                SectionTitle('Available jobs', action: '${visible.length} roles'),
                const SizedBox(height: 12),
                ...visible.map(
                  (job) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _JobCard(
                      job: job,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => JobDetailsPage(job: job),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.onTap});

  final JobPosting job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skills = job.requiredSkills.take(3).toList();
    final extra = job.requiredSkills.length - skills.length;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CompanyMark(name: job.company),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            job.company,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppBadge(
                      label: job.location,
                      icon: Icons.location_on_outlined,
                    ),
                    AppBadge(
                      label: job.workMode,
                      icon: Icons.wifi_tethering_rounded,
                    ),
                    AppBadge(
                      label: job.type,
                      icon: Icons.schedule_rounded,
                      color: AppColors.violet,
                    ),
                  ],
                ),
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final skill in skills)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F6FB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            skill.name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      if (extra > 0)
                        Text(
                          '+$extra more',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'View match and skill gap',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyMark extends StatelessWidget {
  const _CompanyMark({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.primary,
      const Color(0xFF0EA5E9),
      AppColors.violet,
      const Color(0xFF0F766E),
    ];
    final trimmed = name.trim().isEmpty ? 'JS' : name.trim();
    final color = colors[trimmed.hashCode.abs() % colors.length];
    final parts = trimmed.split(RegExp(r'\s+'));
    final initials = parts.length == 1
        ? parts.first.substring(0, parts.first.length >= 2 ? 2 : 1)
        : '${parts[0][0]}${parts[1][0]}';
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
      ),
    );
  }
}
