import 'package:flutter/material.dart';

import '../../app/injector.dart';
import '../../app/router.dart';
import '../../core/widgets/app_widgets.dart';
import 'data/job_api_repository.dart';
import 'job_models.dart';
import 'widgets/job_match_card.dart';

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
  bool get _isSeeker =>
      Injector.authService().currentUser?.role == 'seeker' ||
      Injector.authService().currentUser == null;

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
            JobMatchCard(
              job: widget.job,
              repository: _repository,
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
