import 'package:flutter/material.dart';

import '../../../../app/injector.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
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
  late final JobRepository _repository =
      widget.repository ?? ApiJobRepository();
  late Future<List<JobPosting>> _jobs = _repository.listJobs();
  JobPosting? _selectedJob;
  Future<JobSkillGapAnalysis>? _analysis;

  @override
  void initState() {
    super.initState();
    _selectedJob = widget.initialJob;
    _jobs = _loadJobs();
  }

  Future<List<JobPosting>> _loadJobs() async {
    final jobs = await _repository.listJobs();
    if (_selectedJob != null &&
        !jobs.any((job) => job.id == _selectedJob!.id)) {
      return [_selectedJob!, ...jobs];
    }
    if (_selectedJob == null && jobs.isNotEmpty) {
      _selectedJob = jobs.first;
    }
    if (_selectedJob != null) _analysis = _repository.skillGap(_selectedJob!);
    return jobs;
  }

  void _select(JobPosting job) => setState(() {
        _selectedJob = job;
        _analysis = _repository.skillGap(job);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<List<JobPosting>>(
          future: _jobs,
          builder: (context, jobsSnapshot) {
            if (!jobsSnapshot.hasData) {
              return jobsSnapshot.hasError
                  ? const EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Jobs unavailable',
                      message:
                          'The learning analysis needs the backend job service.')
                  : const Center(child: CircularProgressIndicator());
            }
            final jobs = jobsSnapshot.data!;
            final selected = _selectedJob;
            if (selected == null)
              return const EmptyState(
                  icon: Icons.work_outline_rounded,
                  title: 'No jobs available',
                  message: 'Publish a job before starting a skill analysis.');
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
              children: [
                const ScreenIntro(
                    eyebrow: 'Module 3 + Module 4',
                    title: 'Learn for your next role',
                    description:
                        'Choose any backend job to identify skill gaps and follow personalized lessons and resources.'),
                const SizedBox(height: 20),
                DropdownButtonFormField<JobPosting>(
                    value: selected,
                    decoration: const InputDecoration(
                        labelText: 'Choose a job',
                        prefixIcon: Icon(Icons.work_outline_rounded)),
                    items: jobs
                        .map((job) => DropdownMenuItem(
                            value: job, child: Text(job.title)))
                        .toList(),
                    onChanged: (job) {
                      if (job != null) _select(job);
                    }),
                const SizedBox(height: 18),
                FutureBuilder<JobSkillGapAnalysis>(
                  future: _analysis,
                  builder: (context, analysisSnapshot) {
                    if (!analysisSnapshot.hasData)
                      return analysisSnapshot.hasError
                          ? const EmptyState(
                              icon: Icons.cloud_off_rounded,
                              title: 'Analysis unavailable',
                              message:
                                  'The selected job could not be analyzed.')
                          : const Center(child: CircularProgressIndicator());
                    final analysis = analysisSnapshot.data!;
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SummaryCard(analysis: analysis),
                          const SizedBox(height: 24),
                          const SectionTitle('Module 3: Skill Gap Analysis'),
                          const SizedBox(height: 8),
                          const Text(
                              'Missing skills are returned by the backend and prioritized for this job.',
                              style: TextStyle(color: AppColors.muted)),
                          const SizedBox(height: 12),
                          if (analysis.missingSkills.isEmpty)
                            const EmptyState(
                                icon: Icons.verified_rounded,
                                title: 'No skill gaps found',
                                message:
                                    'Your profile covers this job’s listed requirements.')
                          else
                            ...analysis.missingSkills.map((gap) => Card(
                                child: ListTile(
                                    leading: Icon(Icons.school_outlined,
                                        color: _color(gap.priority)),
                                    title: Text(gap.name),
                                    subtitle: Text(
                                        '${gap.category} · ${gap.priority.name.toUpperCase()} priority\n${gap.reason}'),
                                    isThreeLine: true,
                                    trailing: gap.learningPathId == null
                                        ? null
                                        : const Icon(
                                            Icons.chevron_right_rounded),
                                    onTap: gap.learningPathId == null
                                        ? null
                                        : () => Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                                builder: (_) => StructuredLearningScreen(
                                                    initialSkills: [gap.name],
                                                    progressRepository:
                                                        Injector.learningProgressRepository())))))),
                          const SizedBox(height: 24),
                          const SectionTitle('Module 4: Personalized Learning'),
                          const SizedBox(height: 8),
                          const Text(
                              'Open any missing skill to study its backend-published learning path, lessons, and resources.',
                              style: TextStyle(color: AppColors.muted)),
                        ]);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Color _color(SkillPriority priority) => switch (priority) {
        SkillPriority.high => AppColors.danger,
        SkillPriority.medium => AppColors.warning,
        SkillPriority.low => AppColors.success
      };
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.analysis});
  final JobSkillGapAnalysis analysis;
  @override
  Widget build(BuildContext context) => Card(
      color: AppColors.primary,
      child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            const Icon(Icons.track_changes_rounded,
                color: Colors.white, size: 34),
            const SizedBox(width: 14),
            Expanded(
                child: Text(
                    '${analysis.job.title}\n${analysis.matchPercent}% job match · ${analysis.missingSkills.length} skill gaps',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.4)))
          ])));
}
