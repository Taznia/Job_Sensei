import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/injector.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/models/career_profile_models.dart';
import '../../../../shared/models/learning_models.dart';
import '../../../jobs/data/job_api_repository.dart';
import '../../../jobs/job_models.dart';
import 'structured_learning_screen.dart';

class LearningHubScreen extends StatefulWidget {
  const LearningHubScreen({super.key, this.initialJob, this.repository});

  final JobPosting? initialJob;
  final JobRepository? repository;

  @override
  State<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends State<LearningHubScreen> {
  late final JobRepository _repository = widget.repository ?? ApiJobRepository();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Future<List<JobPosting>> _suggestions = Future.value(const []);
  Timer? _searchDebounce;
  JobPosting? _selectedJob;
  Future<JobSkillGapAnalysis>? _analysis;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedJob = widget.initialJob;
    if (_selectedJob != null) {
      _searchController.text = _selectedJob!.title;
      _analysis = _repository.skillGap(_selectedJob!);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _search(String value) {
    _searchDebounce?.cancel();
    setState(() {
      _query = value.trim();
      if (_query.isEmpty) _suggestions = Future.value(const []);
    });
    if (_query.isEmpty) return;
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _suggestions = _repository.listJobs(query: _query));
    });
  }

  void _selectJob(JobPosting job) {
    _searchDebounce?.cancel();
    _searchController.text = job.title;
    _searchFocus.unfocus();
    setState(() {
      _query = '';
      _selectedJob = job;
      _analysis = _repository.skillGap(job);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Skill Gap Analysis'),
        centerTitle: false,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          const Text(
            'Know what to learn next',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 3),
          const Text(
            'Search a job and compare its skills with your profile.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            onChanged: _search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search any job',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        _search('');
                        _searchFocus.requestFocus();
                      },
                      icon: const Icon(Icons.close_rounded, size: 19),
                    ),
            ),
          ),
          if (_query.isNotEmpty) ...[
            const SizedBox(height: 8),
            FutureBuilder<List<JobPosting>>(
              future: _suggestions,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const _SuggestionLoading();
                }
                if (snapshot.hasError) {
                  return const _ErrorState(
                    message: 'Could not search jobs from the server.',
                  );
                }
                final jobs = snapshot.data ?? const <JobPosting>[];
                if (jobs.isEmpty) {
                  return const _EmptyState(
                    message: 'No jobs match your search.',
                  );
                }
                return _JobSuggestions(jobs: jobs, onSelected: _selectJob);
              },
            ),
          ],
          const SizedBox(height: 18),
          if (_selectedJob == null)
            const _EmptyState(
              message: 'Search and select a job to see your skill analysis.',
            )
          else
            FutureBuilder<JobSkillGapAnalysis>(
              future: _analysis,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const _ErrorState(
                    message: 'The server could not analyze this job.',
                  );
                }
                return _AnalysisContent(analysis: snapshot.data!);
              },
            ),
        ],
      ),
    );
  }
}

class _JobSuggestions extends StatelessWidget {
  const _JobSuggestions({required this.jobs, required this.onSelected});

  final List<JobPosting> jobs;
  final ValueChanged<JobPosting> onSelected;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: jobs
              .map(
                (job) => ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F0FE),
                    child: Icon(
                      Icons.work_outline_rounded,
                      color: AppColors.primary,
                      size: 19,
                    ),
                  ),
                  title: Text(
                    job.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('${job.company} • ${job.location}'),
                  trailing: const Icon(Icons.north_west_rounded, size: 17),
                  onTap: () => onSelected(job),
                ),
              )
              .toList(),
        ),
      );
}

class _SuggestionLoading extends StatelessWidget {
  const _SuggestionLoading();

  @override
  Widget build(BuildContext context) => const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Searching jobs…'),
            ],
          ),
        ),
      );
}
class _AnalysisContent extends StatelessWidget {
  const _AnalysisContent({required this.analysis});
  final JobSkillGapAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final strengths = analysis.strongSkillDetails.isNotEmpty
        ? analysis.strongSkillDetails
        : analysis.strongSkills
            .map((skill) => JobSkillMatch(
                  name: skill.name,
                  currentLevel: _level(skill.level),
                  requiredLevel: 80,
                ))
            .toList();
    final groups = <String, List<JobSkillRequirement>>{};
    for (final gap in analysis.missingSkills) {
      groups.putIfAbsent(_category(gap.category), () => []).add(gap);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MatchCard(analysis: analysis),
        const SizedBox(height: 22),
        if (strengths.isNotEmpty) ...[
          const _GroupHeader(
              title: 'Your strengths', icon: Icons.auto_awesome_rounded),
          const SizedBox(height: 8),
          ...strengths.map((skill) => _SkillRow(
                name: skill.name,
                current: skill.currentLevel,
                required: skill.requiredLevel,
                color: AppColors.primary,
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => SkillDetailScreen(
                    skillName: skill.name,
                    current: skill.currentLevel,
                    required: skill.requiredLevel,
                    reason:
                        'This is one of your strongest matches for the selected role.',
                    learningPathId: null,
                  ),
                )),
              )),
          const SizedBox(height: 22),
        ],
        const _GroupHeader(
            title: 'Skills to improve', icon: Icons.bolt_rounded),
        const SizedBox(height: 5),
        const Text('Tap a skill to open its dedicated learning path.',
            style: TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 10),
        if (groups.isEmpty)
          const _EmptyState(
              message: 'Your profile covers every listed requirement.')
        else
          ...groups.entries.map((entry) => _SkillGroup(
                title: entry.key,
                skills: entry.value,
              )),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: analysis.missingSkills.isNotEmpty
                ? () {
                    Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => StructuredLearningScreen(
                        initialSkills: analysis.missingSkills
                            .map((skill) => skill.name)
                            .toList(),
                        progressRepository:
                            Injector.learningProgressRepository(),
                      ),
                    ));
                  }
                : null,
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            label: const Text('Find learning resources'),
          ),
        ),
      ],
    );
  }

  static String _category(String value) => value
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map((part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  static int _level(SkillLevel level) => switch (level) {
        SkillLevel.beginner => 25,
        SkillLevel.intermediate => 50,
        SkillLevel.advanced => 75,
        SkillLevel.expert => 95,
      };
}

class _SkillGroup extends StatelessWidget {
  const _SkillGroup({required this.title, required this.skills});
  final String title;
  final List<JobSkillRequirement> skills;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Row(
              children: [
                Icon(
                    title.toLowerCase().contains('tool')
                        ? Icons.build_circle_outlined
                        : Icons.code_rounded,
                    size: 15,
                    color: AppColors.primary),
                const SizedBox(width: 6),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
                const Spacer(),
                Text('${skills.length} skills',
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
          ...skills.map((skill) => _SkillRow(
                name: skill.name,
                current: skill.currentLevel,
                required: skill.requiredLevel,
                color: _priorityColor(skill.priority),
                priority: skill.priority.name.toUpperCase(),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => SkillDetailScreen(
                            skillName: skill.name,
                            current: skill.currentLevel,
                            required: skill.requiredLevel,
                            reason: skill.reason,
                            learningPathId: skill.learningPathId,
                          ),
                        )),
              )),
        ],
      );

  static Color _priorityColor(SkillPriority priority) => switch (priority) {
        SkillPriority.high => AppColors.danger,
        SkillPriority.medium => AppColors.warning,
        SkillPriority.low => AppColors.success,
      };
}

class SkillDetailScreen extends StatelessWidget {
  const SkillDetailScreen(
      {super.key,
      required this.skillName,
      required this.current,
      required this.required,
      required this.reason,
      required this.learningPathId});
  final String skillName;
  final int current;
  final int required;
  final String reason;
  final String? learningPathId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skill Detail')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(22)),
            child: Column(children: [
              CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: .1),
                  child: const Icon(Icons.bolt_rounded,
                      color: AppColors.primary, size: 28)),
              const SizedBox(height: 12),
              Text(skillName,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('${current.clamp(0, 100)}% current proficiency',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              _ProgressLine(
                  current: current,
                  required: required,
                  color: AppColors.primary),
            ]),
          ),
          const SizedBox(height: 12),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Why this matters',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text(reason,
                            style: const TextStyle(
                                color: AppColors.muted, height: 1.4))
                      ]))),
          const SizedBox(height: 12),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Skill requirement',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        const Text('Your proficiency',
                            style: TextStyle(
                                color: AppColors.muted, fontSize: 12)),
                        Text('${current.clamp(0, 100)}%'),
                        const SizedBox(height: 10),
                        const Text('Job requirement',
                            style: TextStyle(
                                color: AppColors.muted, fontSize: 12)),
                        Text('${required.clamp(0, 100)}%')
                      ]))),
          const SizedBox(height: 18),
          SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => StructuredLearningScreen(
                                  initialSkills: [skillName],
                                  progressRepository:
                                      Injector.learningProgressRepository()))),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Find learning resources'))),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.analysis});
  final JobSkillGapAnalysis analysis;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0B57D0), AppColors.primary, AppColors.cyan],
            stops: [0, 0.58, 1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: .22),
                blurRadius: 18,
                offset: const Offset(0, 8))
          ]),
      child: Row(children: [
        SizedBox(
            width: 92,
            height: 92,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                  value: analysis.matchPercent / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white24,
                  color: Colors.white),
              Text('${analysis.matchPercent}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 21))
            ])),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('OVERALL MATCH SCORE',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8)),
          const SizedBox(height: 6),
          Text(analysis.job.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17)),
          const SizedBox(height: 4),
          Text('${analysis.missingSkills.length} skills to acquire',
              style: const TextStyle(color: Colors.white70, fontSize: 12))
        ]))
      ]));
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.icon, this.count});
  final String title;
  final IconData icon;
  final int? count;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 7),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        if (count != null) ...[
          const Spacer(),
          Text('$count skills',
              style: const TextStyle(color: AppColors.muted, fontSize: 11))
        ]
      ]);
}

class _SkillRow extends StatelessWidget {
  const _SkillRow(
      {required this.name,
      required this.current,
      required this.required,
      required this.color,
      this.priority,
      this.onTap});
  final String name;
  final int current;
  final int required;
  final Color color;
  final String? priority;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
              child: Column(children: [
                Row(children: [
                  Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 13))),
                  if (priority != null)
                    AppBadge(label: priority!, color: color),
                  if (onTap != null)
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.muted, size: 20)
                ]),
                const SizedBox(height: 9),
                _ProgressLine(
                    current: current, required: required, color: color)
              ]))));
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine(
      {required this.current, required this.required, required this.color});
  final int current;
  final int required;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final c = current.clamp(0, 100);
    final r = required.clamp(1, 100);
    return Column(children: [
      Row(children: [
        Text('$c% proficiency',
            style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        const Spacer(),
        Text('$r% required',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 10))
      ]),
      const SizedBox(height: 5),
      Stack(children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
                value: c / 100,
                minHeight: 6,
                backgroundColor: AppColors.border,
                color: color)),
        Positioned.fill(
            child: Align(
                alignment: Alignment((r / 50) - 1, 0),
                child: Container(width: 2, color: AppColors.ink)))
      ])
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Text(message, style: const TextStyle(color: AppColors.muted))));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({this.message = 'Learning data is unavailable.'});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(28),
          child: EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Something went wrong',
              message: message)));
}
