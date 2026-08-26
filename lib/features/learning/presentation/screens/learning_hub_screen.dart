import 'package:flutter/material.dart';

import '../../../../app/injector.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../services/job_service.dart';
import '../../../../services/learning_service.dart';
import '../../../../shared/models/learning_models.dart';
import '../../../jobs/data/job_api_repository.dart';
import '../../../jobs/job_models.dart';
import '../../data/role_catalog.dart';
import 'learning_resources_screen.dart';

class LearningHubScreen extends StatefulWidget {
  const LearningHubScreen({super.key, this.initialJob, this.repository});

  final JobPosting? initialJob;
  final JobRepository? repository;

  @override
  State<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends State<LearningHubScreen> {
  late final JobRepository _jobs = widget.repository ?? ApiJobRepository();
  final _learning = LearningService();
  final _jobService = JobService();

  late String _role = _savedTargetRole();
  final Map<String, int> _levels = Map<String, int>.from(kDemoSkillLevels);
  late RoleGapSnapshot _snapshot = snapshotForRole(
    role: _role,
    levels: _levels,
    roles: mergeCatalogRoles(const []),
  );
  JobPosting? _selectedJob;
  JobSkillGapAnalysis? _jobAnalysis;
  bool _jobLoading = false;
  List<JobPosting> _targetJobs = const [];
  List<String> _catalogRoles = mergeCatalogRoles(const []);

  static String _savedTargetRole() {
    final saved = Injector.authService().currentUser?.targetRole.trim() ?? '';
    return saved.isEmpty ? 'Senior Frontend Engineer' : saved;
  }

  @override
  void initState() {
    super.initState();
    _selectedJob = widget.initialJob;
    if (_selectedJob != null) {
      _loadJob(_selectedJob!);
    } else {
      _refreshRole(_role);
    }
    _loadTargetJobs();
  }

  RoleGapSnapshot _localSnapshot(String role) {
    return snapshotForRole(
      role: role,
      levels: _levels,
      roles: _catalogRoles,
    );
  }

  Future<void> _refreshRole(String role) async {
    try {
      final json = await _learning.skillGaps(role: role);
      final api = RoleGapSnapshot.fromJson(json);
      for (final gap in api.gaps) {
        _levels[gap.name.toLowerCase()] = gap.currentLevel;
      }
      _catalogRoles = mergeCatalogRoles([
        ..._catalogRoles,
        ...api.roles,
        api.role,
        role,
      ]);
    } catch (_) {
      // Local catalog still shows the selected role's requirements.
    }
    if (!mounted || _role != role) return;
    setState(() => _snapshot = _localSnapshot(role));
  }

  Future<void> _loadTargetJobs() async {
    try {
      final response = await _jobService.recommended();
      final raw = response['items'];
      final items = raw is List ? raw : const [];
      final jobs = items
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(_jobFromJson)
          .toList();
      if (!mounted) return;
      setState(() => _targetJobs = jobs.take(4).toList());
    } catch (_) {
      // Role analysis still works without job chips.
    }
  }

  void _selectRole(String role) {
    setState(() {
      _role = role;
      _selectedJob = null;
      _jobAnalysis = null;
      _jobLoading = false;
      _snapshot = _localSnapshot(role);
    });
    _refreshRole(role);
  }

  void _selectJob(JobPosting job) {
    _loadJob(job);
  }

  Future<void> _loadJob(JobPosting job) async {
    setState(() {
      _selectedJob = job;
      _jobLoading = true;
    });
    try {
      final analysis = await _jobs.skillGap(job);
      if (!mounted || _selectedJob?.id != job.id) return;
      setState(() {
        _jobAnalysis = analysis;
        _jobLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedJob = null;
        _jobAnalysis = null;
        _jobLoading = false;
        _snapshot = _localSnapshot(_role);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobMode = _selectedJob != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: jobMode
            ? (_jobLoading || _jobAnalysis == null
                ? const Center(child: CircularProgressIndicator())
                : _JobGapBody(
                    analysis: _jobAnalysis!,
                    roles: _catalogRoles,
                    selectedRole: _role,
                    jobs: _targetJobs,
                    selectedJob: _selectedJob,
                    onSelectRole: _selectRole,
                    onSelectJob: _selectJob,
                    onClearJob: () => setState(() {
                      _selectedJob = null;
                      _jobAnalysis = null;
                      _jobLoading = false;
                      _snapshot = _localSnapshot(_role);
                    }),
                  ))
            : _RoleGapBody(
                snapshot: _snapshot,
                jobs: _targetJobs,
                selectedJob: _selectedJob,
                onSelectRole: _selectRole,
                onSelectJob: _selectJob,
              ),
      ),
    );
  }

  static JobPosting _jobFromJson(Map<String, dynamic> json) {
    final names = json['skills'] as List<dynamic>? ??
        json['requirements'] as List<dynamic>? ??
        const [];
    return JobPosting(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled role',
      company: json['company'] as String? ?? '',
      location: json['location'] as String? ?? '',
      type: json['type'] as String? ?? '',
      workMode: json['workMode'] as String? ?? '',
      description: json['description'] as String? ?? '',
      requiredSkills: names
          .map(
            (name) => JobSkillRequirement(
              id: name.toString().toLowerCase(),
              name: name.toString(),
              category: 'TECHNICAL',
              priority: SkillPriority.high,
              reason: '${name.toString()} is listed for this role.',
            ),
          )
          .toList(),
    );
  }
}

class _RoleGapBody extends StatelessWidget {
  const _RoleGapBody({
    required this.snapshot,
    required this.jobs,
    required this.selectedJob,
    required this.onSelectRole,
    required this.onSelectJob,
  });

  final RoleGapSnapshot snapshot;
  final List<JobPosting> jobs;
  final JobPosting? selectedJob;
  final ValueChanged<String> onSelectRole;
  final ValueChanged<JobPosting> onSelectJob;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<SkillGap>>{};
    for (final gap in snapshot.gaps) {
      groups.putIfAbsent(_prettyCategory(gap.category), () => []).add(gap);
    }
    final missing = snapshot.gaps.where((item) => !item.matched).toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const Text(
                'Skill Gap Analysis',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: Color(0xFF17233D),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Know what you need to grow.',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 18),
              _TargetRoleField(
                label: snapshot.role,
                roles: mergeCatalogRoles([
                  ...snapshot.roles,
                  snapshot.role,
                ]),
                onSelected: onSelectRole,
              ),
              if (jobs.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'TARGETED JOBS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: jobs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      final selected = selectedJob?.id == job.id;
                      return ChoiceChip(
                        selected: selected,
                        label: Text(job.title, overflow: TextOverflow.ellipsis),
                        onSelected: (_) => onSelectJob(job),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _MatchScoreCard(
                percent: snapshot.matchPercent,
                lacking: snapshot.lacking,
                total: snapshot.total,
                matched: snapshot.matched,
              ),
              const SizedBox(height: 22),
              if (groups.isEmpty)
                const EmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'No catalog skills yet',
                  message: 'This role does not have a skill catalog.',
                )
              else
                ...groups.entries.map(
                  (entry) => _GapGroup(
                    title: entry.key,
                    skills: entry.value,
                    onOpen: (skill) => _openSkill(context, skill),
                  ),
                ),
            ],
          ),
        ),
        _ResourcesCta(
          enabled: snapshot.gaps.isNotEmpty,
          onPressed: () => _openResources(
            context,
            (missing.isEmpty ? snapshot.gaps : missing)
                .map((item) => item.name)
                .toList(),
            targetRole: snapshot.role,
          ),
        ),
      ],
    );
  }
}

class _JobGapBody extends StatelessWidget {
  const _JobGapBody({
    required this.analysis,
    required this.roles,
    required this.selectedRole,
    required this.jobs,
    required this.selectedJob,
    required this.onSelectRole,
    required this.onSelectJob,
    required this.onClearJob,
  });

  final JobSkillGapAnalysis analysis;
  final List<String> roles;
  final String selectedRole;
  final List<JobPosting> jobs;
  final JobPosting? selectedJob;
  final ValueChanged<String> onSelectRole;
  final ValueChanged<JobPosting> onSelectJob;
  final VoidCallback onClearJob;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<JobSkillRequirement>>{};
    for (final gap in analysis.missingSkills) {
      groups.putIfAbsent(_prettyCategory(gap.category), () => []).add(gap);
    }
    final percent = analysis.matchPercent;
    final total = analysis.strongSkills.length + analysis.missingSkills.length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const Text(
                'Skill Gap Analysis',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: Color(0xFF17233D),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Know what you need to grow.',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 18),
              _TargetRoleField(
                label: selectedRole,
                roles: mergeCatalogRoles([...roles, selectedRole]),
                onSelected: onSelectRole,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onClearJob,
                  child: const Text('Back to target role'),
                ),
              ),
              _MatchScoreCard(
                percent: percent,
                lacking: analysis.missingSkills.length,
                total: total,
                matched: analysis.strongSkills.length,
              ),
              const SizedBox(height: 22),
              ...groups.entries.map(
                (entry) => _JobGapGroup(
                  title: entry.key,
                  skills: entry.value,
                ),
              ),
            ],
          ),
        ),
        _ResourcesCta(
          enabled: analysis.missingSkills.isNotEmpty ||
              analysis.strongSkills.isNotEmpty,
          onPressed: () => _openResources(
            context,
            analysis.missingSkills.isEmpty
                ? analysis.strongSkills.map((item) => item.name).toList()
                : analysis.missingSkills.map((item) => item.name).toList(),
            targetRole: selectedRole,
          ),
        ),
      ],
    );
  }
}

class _TargetRoleField extends StatelessWidget {
  const _TargetRoleField({
    required this.label,
    required this.roles,
    required this.onSelected,
  });

  final String label;
  final List<String> roles;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = mergeCatalogRoles([...roles, label]);
    final value = options.contains(label) ? label : options.first;
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.expand_more_rounded),
      decoration: InputDecoration(
        labelText: 'Target role',
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
      items: [
        for (final role in options)
          DropdownMenuItem(
            value: role,
            child: Text(role, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (picked) {
        if (picked != null && picked != label) onSelected(picked);
      },
    );
  }
}

class _MatchScoreCard extends StatelessWidget {
  const _MatchScoreCard({
    required this.percent,
    required this.lacking,
    required this.total,
    required this.matched,
  });

  final int percent;
  final int lacking;
  final int total;
  final int matched;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), AppColors.primary, Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OVERALL MATCH SCORE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$lacking skills to acquire',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 86,
                height: 86,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (percent.clamp(0, 100)) / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                    ),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatBox(label: 'Total', value: '$total'),
              const SizedBox(width: 8),
              _StatBox(label: 'Match', value: '$matched'),
              const SizedBox(width: 8),
              _StatBox(label: 'Lacking', value: '$lacking'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _GapGroup extends StatelessWidget {
  const _GapGroup({
    required this.title,
    required this.skills,
    required this.onOpen,
  });

  final String title;
  final List<SkillGap> skills;
  final ValueChanged<SkillGap> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              '$title (${skills.length} skill${skills.length == 1 ? '' : 's'})',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
          ...skills.map(
            (skill) => _SkillTile(
              name: skill.name,
              current: skill.currentLevel,
              required: skill.requiredLevel,
              priority: skill.priority,
              onTap: () => onOpen(skill),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobGapGroup extends StatelessWidget {
  const _JobGapGroup({required this.title, required this.skills});

  final String title;
  final List<JobSkillRequirement> skills;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              '$title (${skills.length} skill${skills.length == 1 ? '' : 's'})',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
          ...skills.map(
            (skill) => _SkillTile(
              name: skill.name,
              current: skill.currentLevel,
              required: skill.requiredLevel,
              priority: skill.priority,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SkillDetailScreen(
                    skillName: skill.name,
                    current: skill.currentLevel,
                    required: skill.requiredLevel,
                    reason: skill.reason,
                    priority: skill.priority,
                    category: skill.category,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillTile extends StatelessWidget {
  const _SkillTile({
    required this.name,
    required this.current,
    required this.required,
    required this.priority,
    required this.onTap,
  });

  final String name;
  final int current;
  final int required;
  final SkillPriority priority;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      SkillPriority.high => AppColors.danger,
      SkillPriority.medium => AppColors.warning,
      SkillPriority.low => AppColors.success,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    priority.name[0].toUpperCase() + priority.name.substring(1),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.muted),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (current.clamp(0, 100)) / 100,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$current% proficiency',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourcesCta extends StatelessWidget {
  const _ResourcesCta({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: enabled ? onPressed : null,
            icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
            label: const Text('Watch lessons'),
          ),
        ),
      ),
    );
  }
}

class SkillDetailScreen extends StatelessWidget {
  const SkillDetailScreen({
    super.key,
    required this.skillName,
    required this.current,
    required this.required,
    required this.reason,
    this.priority = SkillPriority.high,
    this.category = 'Technical skill',
    this.learningPathId,
  });

  final String skillName;
  final int current;
  final int required;
  final String reason;
  final SkillPriority priority;
  final String category;
  final String? learningPathId;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      SkillPriority.high => AppColors.danger,
      SkillPriority.medium => AppColors.warning,
      SkillPriority.low => AppColors.success,
    };
    final demand = switch (priority) {
      SkillPriority.high => 85,
      SkillPriority.medium => 62,
      SkillPriority.low => 40,
    };
    final requirementMatch =
        ((current.clamp(0, 100) / required.clamp(1, 100)) * 100)
            .clamp(0, 100)
            .round();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Skill Detail'),
        backgroundColor: const Color(0xFFF7F8FC),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.icon(
            onPressed: () => _openResources(context, [skillName]),
            icon: const Icon(Icons.play_circle_fill_rounded),
            label: const Text('Watch lessons'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            skillName,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.bolt_rounded,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      priority.name[0].toUpperCase() +
                          priority.name.substring(1),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$current%',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'Current proficiency',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Why this matters',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reason,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category breakdown',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  _BreakdownBar(label: _prettyCategory(category), value: current),
                  _BreakdownBar(
                    label: 'Job requirement match',
                    value: requirementMatch,
                  ),
                  _BreakdownBar(label: 'Market demand', value: demand),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownBar extends StatelessWidget {
  const _BreakdownBar({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                '$value%',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (value.clamp(0, 100)) / 100,
              minHeight: 7,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

void _openSkill(BuildContext context, SkillGap skill) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SkillDetailScreen(
        skillName: skill.name,
        current: skill.currentLevel,
        required: skill.requiredLevel,
        reason: skill.impact,
        priority: skill.priority,
        category: skill.category,
      ),
    ),
  );
}

void _openResources(
  BuildContext context,
  List<String> skills, {
  String? targetRole,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => LearningResourcesScreen(
        initialSkills: skills,
        targetRole: targetRole,
      ),
    ),
  );
}

String _prettyCategory(String value) {
  final cleaned = value.replaceAll('_', ' ').trim();
  if (cleaned.isEmpty) return 'Technical skill';
  return cleaned
      .split(' ')
      .map((part) => part.isEmpty
          ? part
          : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}
