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
  late Future<List<JobPosting>> _jobs;

  @override
  void initState() {
    super.initState();
    _jobs = _repository.listJobs();
  }

  void _search(String value) {
    setState(() {
      _jobs = _repository.listJobs(query: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            const ScreenIntro(
                eyebrow: 'Find your next role',
                title: 'Jobs',
                description:
                    'Open a job to see its match. Skill analysis and learning are available in Learn.'),
            const SizedBox(height: 20),
            TextField(
                onChanged: _search,
                decoration: const InputDecoration(
                    hintText: 'Search title, company, location, or skill',
                    prefixIcon: Icon(Icons.search_rounded))),
            const SizedBox(height: 20),
            FutureBuilder<List<JobPosting>>(
              future: _jobs,
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return snapshot.hasError
                      ? const EmptyState(
                          icon: Icons.cloud_off_rounded,
                          title: 'Jobs unavailable',
                          message:
                              'Try again when the job service is reachable.')
                      : const Center(child: CircularProgressIndicator());
                final jobs = snapshot.data!;
                return Column(children: [
                  SectionTitle('Available jobs',
                      action: '${jobs.length} roles'),
                  const SizedBox(height: 10),
                  if (jobs.isEmpty)
                    const EmptyState(
                        icon: Icons.work_outline_rounded,
                        title: 'No matching jobs',
                        message: 'Try another title, location, or skill.')
                  else
                    ...jobs.map((job) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _JobCard(
                            job: job,
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) =>
                                        JobDetailsPage(job: job))))))
                ]);
              },
            ),
          ],
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
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(job.company, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 12),
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
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '${job.requiredSkills.length} required skills  -  View match and skill gap',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
