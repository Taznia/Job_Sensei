import 'package:flutter/material.dart';

import '../../app/injector.dart';
import '../../app/shell_tabs.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../jobs/data/job_api_repository.dart';
import '../jobs/job_details_page.dart';
import '../jobs/job_models.dart';

/// Summary home tab. Job match and skill-gap analysis stay on Jobs / Learn.
class SeekerHomePage extends StatefulWidget {
  const SeekerHomePage({super.key});

  @override
  State<SeekerHomePage> createState() => _SeekerHomePageState();
}

class _SeekerHomePageState extends State<SeekerHomePage> {
  final _jobs = ApiJobRepository();
  List<JobPosting> _picks = const [];

  @override
  void initState() {
    super.initState();
    _loadPicks();
  }

  Future<void> _loadPicks() async {
    try {
      final jobs = await _jobs.listJobs();
      if (!mounted) return;
      setState(() => _picks = jobs.take(3).toList());
    } catch (_) {
      if (!mounted) return;
      setState(() => _picks = demoJobs.take(3).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Injector.authService().currentUser;
    final name = user?.name.trim() ?? '';
    final firstName =
        name.isEmpty ? 'there' : name.split(RegExp(r'\s+')).first;
    final role = user?.targetRole.trim();
    final roleLabel =
        (role == null || role.isEmpty) ? 'Set a target role' : role;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 108),
          children: [
            GradientHero(
              eyebrow: 'Job Sensei',
              title: 'Hi, $firstName',
              description:
                  'Your next role, skill gaps, and lessons are in one place. Start with a job or jump into Learn.',
              trailing: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                child: Text(
                  firstName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              stats: [
                HeroStatChip(
                  icon: Icons.flag_outlined,
                  label: roleLabel,
                ),
                const HeroStatChip(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Momo is ready',
                ),
              ],
            ),
            const SizedBox(height: 22),
            SectionTitle(
              'For you',
              action: _picks.isEmpty ? null : 'See all',
              onAction: _picks.isEmpty ? null : ShellTabs.openJobs,
            ),
            const SizedBox(height: 12),
            if (_picks.isEmpty)
              const _HomeHint(
                icon: Icons.work_outline_rounded,
                title: 'Jobs will show up here',
                detail: 'Open Jobs to search roles and check your match.',
                onTap: ShellTabs.openJobs,
              )
            else
              SizedBox(
                height: 168,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _picks.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final job = _picks[index];
                    return _HomeJobCard(
                      job: job,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => JobDetailsPage(job: job),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            const SectionTitle('Jump in'),
            const SizedBox(height: 12),
            _ActionTile(
              color: AppColors.primary,
              icon: Icons.work_rounded,
              title: 'Explore jobs',
              detail: 'See match % and the skills each role still needs.',
              cta: 'Open Jobs',
              onTap: ShellTabs.openJobs,
            ),
            const SizedBox(height: 12),
            _ActionTile(
              color: const Color(0xFF0EA5E9),
              icon: Icons.play_circle_fill_rounded,
              title: 'Watch lessons',
              detail: 'Close the gaps for your target role, in the app.',
              cta: 'Open Learn',
              onTap: ShellTabs.openLearn,
            ),
            const SizedBox(height: 12),
            _ActionTile(
              color: AppColors.violet,
              icon: Icons.person_rounded,
              title: 'Update profile',
              detail: 'Skills here drive job match and learning.',
              cta: 'Open Profile',
              onTap: ShellTabs.openProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeJobCard extends StatelessWidget {
  const _HomeJobCard({required this.job, required this.onTap});

  final JobPosting job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 228,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CompanyMark(name: job.company, size: 36),
                      const Spacer(),
                      AppBadge(label: job.workMode),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    job.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.25,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${job.company}  ·  ${job.location}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.detail,
    required this.cta,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String detail;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.72)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detail,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cta,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHint extends StatelessWidget {
  const _HomeHint({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEAF3FF),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyMark extends StatelessWidget {
  const _CompanyMark({required this.name, this.size = 42});

  final String name;
  final double size;

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
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.32,
        ),
      ),
    );
  }
}
