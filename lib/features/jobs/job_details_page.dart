import 'package:flutter/material.dart';

import '../../app/injector.dart';
import '../../app/router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import 'data/job_api_repository.dart';
import 'job_models.dart';

class JobDetailsPage extends StatefulWidget {
  const JobDetailsPage({super.key, required this.job, this.repository});

  final JobPosting job;
  final JobRepository? repository;

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  late final JobRepository _repository =
      widget.repository ?? ApiJobRepository();
  late final Future<JobSkillGapAnalysis> _analysis = _loadAnalysis();
  bool get _isSeeker =>
      Injector.authService().currentUser?.role == 'seeker' ||
      Injector.authService().currentUser == null;

  Future<JobSkillGapAnalysis> _loadAnalysis() async {
    try {
      return await _repository.skillGap(widget.job);
    } catch (_) {
      return JobSkillGapAnalysis(
        job: widget.job,
        strongSkills: const [],
        missingSkills: widget.job.requiredSkills,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          GradientHero(
            eyebrow: widget.job.company,
            title: widget.job.title,
            description: widget.job.description,
            stats: [
              HeroStatChip(
                icon: Icons.location_on_outlined,
                label: widget.job.location,
              ),
              HeroStatChip(
                icon: Icons.wifi_tethering_rounded,
                label: widget.job.workMode,
              ),
              HeroStatChip(
                icon: Icons.schedule_rounded,
                label: widget.job.type,
              ),
            ],
          ),
          if (_isSeeker) ...[
            const SizedBox(height: 26),
            const SectionTitle('Job Match'),
            const SizedBox(height: 10),
            FutureBuilder<JobSkillGapAnalysis>(
              future: _analysis,
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return snapshot.hasError
                      ? const EmptyState(
                          icon: Icons.cloud_off_rounded,
                          title: 'Match unavailable',
                          message: 'The backend could not analyze this job.')
                      : const Center(child: CircularProgressIndicator());
                return _MatchCard(analysis: snapshot.data!);
              },
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRouter.learning, arguments: widget.job),
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Analyze Skills in Learn')),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Resume optimization will open here.'))),
              icon: const Icon(Icons.auto_fix_high_rounded),
              label: const Text('Optimize Resume')),
          const SizedBox(height: 10),
          OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Application flow will open here.'))),
              icon: const Icon(Icons.send_outlined),
              label: const Text('Apply Now')),
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
          gradient:
              const LinearGradient(colors: [AppColors.primary, AppColors.cyan]),
          borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${analysis.matchPercent}% Match',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Based on your backend Career Profile skills',
            style: TextStyle(color: Colors.white70)),
        if (analysis.strongSkills.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Strong skills',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.strongSkills
                  .map((skill) => Chip(
                      avatar: const Icon(Icons.check_circle_rounded,
                          size: 16, color: AppColors.success),
                      label: Text(skill.name),
                      backgroundColor: Colors.white))
                  .toList())
        ]
      ]));
}
