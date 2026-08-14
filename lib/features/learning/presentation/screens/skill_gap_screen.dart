import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/models/learning_models.dart';

class SkillGapScreen extends StatefulWidget {
  const SkillGapScreen({super.key});

  @override
  State<SkillGapScreen> createState() => _SkillGapScreenState();
}

class _SkillGapScreenState extends State<SkillGapScreen> {
  String _role = 'Senior Frontend Engineer';

  static const _roleSkills = <String, List<SkillGap>>{
    'Senior Frontend Engineer': [
      SkillGap(
        name: 'TypeScript',
        category: 'Technical skill',
        currentLevel: 58,
        requiredLevel: 90,
        priority: SkillPriority.high,
        impact: 'Strong TypeScript is expected for safe, scalable frontend '
            'architecture and is mentioned in most senior-role descriptions.',
      ),
      SkillGap(
        name: 'GraphQL',
        category: 'Technical skill',
        currentLevel: 15,
        requiredLevel: 70,
        priority: SkillPriority.high,
        impact:
            'GraphQL experience unlocks roles working on data-heavy products '
            'and helps you design efficient client-server contracts.',
      ),
      SkillGap(
        name: 'Docker',
        category: 'Tool',
        currentLevel: 35,
        requiredLevel: 65,
        priority: SkillPriority.medium,
        impact:
            'Docker lets you reproduce production environments and collaborate '
            'more smoothly with platform and backend teams.',
      ),
      SkillGap(
        name: 'System Design',
        category: 'Technical skill',
        currentLevel: 45,
        requiredLevel: 82,
        priority: SkillPriority.high,
        impact:
            'Senior interviews test tradeoffs, scalability, performance, and '
            'the ability to lead architecture decisions.',
      ),
      SkillGap(
        name: 'Technical Leadership',
        category: 'Soft skill',
        currentLevel: 68,
        requiredLevel: 85,
        priority: SkillPriority.medium,
        impact:
            'Mentoring, clear decisions, and cross-team communication separate '
            'senior contributors from strong mid-level engineers.',
      ),
    ],
    'Data Scientist': [
      SkillGap(
        name: 'Python',
        category: 'Technical skill',
        currentLevel: 72,
        requiredLevel: 88,
        priority: SkillPriority.medium,
        impact:
            'Production Python supports reproducible analysis and reliable ML pipelines.',
      ),
      SkillGap(
        name: 'Machine Learning',
        category: 'Technical skill',
        currentLevel: 44,
        requiredLevel: 85,
        priority: SkillPriority.high,
        impact:
            'Model selection, evaluation, and feature engineering are central hiring signals.',
      ),
      SkillGap(
        name: 'SQL',
        category: 'Tool',
        currentLevel: 63,
        requiredLevel: 86,
        priority: SkillPriority.high,
        impact:
            'Most data roles require independent exploration of large relational datasets.',
      ),
      SkillGap(
        name: 'Cloud Certification',
        category: 'Certification',
        currentLevel: 20,
        requiredLevel: 55,
        priority: SkillPriority.low,
        impact:
            'A cloud credential validates familiarity with deployed data workloads.',
      ),
    ],
    'Product Manager': [
      SkillGap(
        name: 'Product Analytics',
        category: 'Tool',
        currentLevel: 50,
        requiredLevel: 85,
        priority: SkillPriority.high,
        impact:
            'Analytics turns product choices into measurable hypotheses and outcomes.',
      ),
      SkillGap(
        name: 'Roadmapping',
        category: 'Technical skill',
        currentLevel: 62,
        requiredLevel: 82,
        priority: SkillPriority.medium,
        impact:
            'A clear roadmap aligns customer needs, business goals, and engineering capacity.',
      ),
      SkillGap(
        name: 'Stakeholder Management',
        category: 'Soft skill',
        currentLevel: 70,
        requiredLevel: 90,
        priority: SkillPriority.high,
        impact:
            'Product leaders create alignment when teams have competing goals and constraints.',
      ),
      SkillGap(
        name: 'UX Research',
        category: 'Technical skill',
        currentLevel: 42,
        requiredLevel: 72,
        priority: SkillPriority.medium,
        impact:
            'Research prevents teams from solving assumptions instead of customer problems.',
      ),
    ],
  };

  List<SkillGap> get _skills => _roleSkills[_role]!;
  int get _readiness => (_skills
              .map((skill) => skill.currentLevel / skill.requiredLevel)
              .reduce((a, b) => a + b) /
          _skills.length *
          100)
      .round()
      .clamp(0, 100);

  Color _priorityColor(SkillPriority priority) => switch (priority) {
        SkillPriority.high => AppColors.danger,
        SkillPriority.medium => AppColors.warning,
        SkillPriority.low => AppColors.success,
      };

  void _showSkill(SkillGap skill) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              AppBadge(
                  label: skill.category, color: _priorityColor(skill.priority)),
              const SizedBox(height: 12),
              Text(skill.name,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 18),
              Text('Why this gap matters',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(skill.impact,
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 22),
              _LevelBar(
                  label: 'Your level',
                  value: skill.currentLevel,
                  color: AppColors.primary),
              const SizedBox(height: 12),
              _LevelBar(
                  label: 'Role target',
                  value: skill.requiredLevel,
                  color: AppColors.ink),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('Explore learning resources'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
        children: [
          const ScreenIntro(
            eyebrow: 'Know your next move',
            title: 'Skill Gap Analysis',
            description:
                'Compare your profile with a target role and focus on the gaps with the biggest career impact.',
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _role,
            decoration: const InputDecoration(
              labelText: 'Target career path',
              prefixIcon: Icon(Icons.track_changes_rounded),
            ),
            items: _roleSkills.keys
                .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                .toList(),
            onChanged: (value) => setState(() => _role = value!),
          ),
          const SizedBox(height: 16),
          _ReadinessCard(readiness: _readiness, role: _role, skills: _skills),
          const SizedBox(height: 24),
          const SectionTitle('Prioritized gaps'),
          const SizedBox(height: 6),
          const Text(
            'Ordered by hiring impact and distance from the role target.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          ..._skills.map((skill) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SkillCard(
                  skill: skill,
                  color: _priorityColor(skill.priority),
                  onTap: () => _showSkill(skill),
                ),
              )),
        ],
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({
    required this.readiness,
    required this.role,
    required this.skills,
  });

  final int readiness;
  final String role;
  final List<SkillGap> skills;

  @override
  Widget build(BuildContext context) {
    final high =
        skills.where((skill) => skill.priority == SkillPriority.high).length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.cyan],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PROFILE MATCH',
              style: TextStyle(
                  color: Colors.white70, fontSize: 11, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 82,
                height: 82,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: readiness / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                    ),
                    Text('$readiness%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 7),
                    Text(
                        '$high high-priority gaps · ${skills.length} skills reviewed',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard(
      {required this.skill, required this.color, required this.onTap});

  final SkillGap skill;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gap = skill.requiredLevel - skill.currentLevel;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.bolt_rounded, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(skill.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        Text(skill.category,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 11)),
                      ],
                    ),
                  ),
                  AppBadge(
                    label: skill.priority.name.toUpperCase(),
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.muted),
                ],
              ),
              const SizedBox(height: 14),
              _LevelBar(
                  label: '$gap point gap',
                  value: skill.currentLevel,
                  color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar(
      {required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            const Spacer(),
            Text('$value%',
                style: TextStyle(color: color, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: value / 100,
            color: color,
            backgroundColor: AppColors.border,
          ),
        ),
      ],
    );
  }
}
