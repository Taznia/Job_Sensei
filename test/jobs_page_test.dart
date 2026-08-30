import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobsensei_frontend/features/jobs/data/job_api_repository.dart';
import 'package:jobsensei_frontend/features/jobs/job_models.dart';
import 'package:jobsensei_frontend/features/jobs/job_search_models.dart';
import 'package:jobsensei_frontend/features/jobs/jobs_page.dart';

/// Serves the bundled sample jobs and a canned match score.
///
/// The page and the match card both call the API, so without an injected
/// repository this test waits on real HTTP and `pumpAndSettle` never settles
/// while the loading spinners animate.
class _FakeJobRepository implements JobRepository {
  JobSearchQuery? lastQuery;
  int savedCalls = 0;

  @override
  Future<List<JobPosting>> listJobs({String? query}) async => demoJobs;

  @override
  Future<JobSearchResult> searchJobs(JobSearchQuery query) async {
    lastQuery = query;
    return JobSearchResult(
      total: demoJobs.length,
      page: 1,
      pages: 1,
      sort: query.sort,
      jobs: demoJobs,
    );
  }

  @override
  Future<JobFilterOptions> filterOptions() async => const JobFilterOptions(
        companies: ['Northwind Labs'],
        locations: ['Remote'],
        skills: ['Flutter', 'Dart'],
        types: ['full-time', 'internship'],
        workModes: ['remote', 'onsite'],
        experienceLevels: ['junior', 'senior'],
        salaryMin: 20000,
        salaryMax: 200000,
      );

  @override
  Future<void> setSaved(String jobId, {required bool saved}) async {
    savedCalls++;
  }

  @override
  Future<JobMatchScore> matchScore(String jobId, {String? resumeId}) async {
    return const JobMatchScore(
      overallScore: 72,
      verdict: 'good',
      verdictLabel: 'Good match',
      summary: 'Good match — you meet 72% of what this role looks for.',
      strengths: [],
      breakdown: [
        JobMatchArea(
          area: 'Skills',
          score: 30,
          max: 45,
          detail: 'Evidenced 2 of the 3 skills this role lists.',
        ),
      ],
      matchedSkills: ['Flutter', 'Dart'],
      skillsNotEvidenced: 1,
    );
  }

  @override
  Future<JobSkillGapAnalysis> skillGap(JobPosting job) async {
    return JobSkillGapAnalysis(
      job: job,
      strongSkills: const [],
      missingSkills: job.requiredSkills,
    );
  }
}

void main() {
  testWidgets('opening a job shows match and hands analysis to Learn',
      (tester) async {
    final repository = _FakeJobRepository();
    await tester.pumpWidget(
      MaterialApp(home: JobsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flutter Developer'), findsOneWidget);
    await tester.tap(find.text('Flutter Developer'));
    await tester.pumpAndSettle();

    expect(find.text('Job Match'), findsOneWidget);

    // The match card is tall, so the Learn button sits below the fold in the
    // default test viewport.
    await tester.scrollUntilVisible(
      find.text('Analyze Skills in Learn'),
      300,
    );
    expect(find.text('Analyze Skills in Learn'), findsOneWidget);
  });

  testWidgets('the match card shows the Module 4 score and its breakdown',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: JobsPage(repository: _FakeJobRepository())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Flutter Developer'));
    await tester.pumpAndSettle();

    expect(find.text('Good match'), findsOneWidget);
    expect(find.text('72%'), findsOneWidget);
    // The breakdown is what makes the score accountable.
    expect(find.text('How this score is made up'), findsOneWidget);
    expect(find.text('30/45'), findsOneWidget);
  });

  testWidgets('filters reach the search query', (tester) async {
    final repository = _FakeJobRepository();
    await tester.pumpWidget(
      MaterialApp(home: JobsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();

    // Working arrangement sits well down the filter sheet.
    final remoteChip = find.widgetWithText(ChoiceChip, 'Remote');
    await tester.ensureVisible(remoteChip);
    await tester.pumpAndSettle();
    await tester.tap(remoteChip);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Show results'));
    await tester.pumpAndSettle();

    expect(repository.lastQuery?.workMode, 'remote');
    expect(find.text('Filters (1)'), findsOneWidget);
  });

  testWidgets('saving a job calls the repository', (tester) async {
    final repository = _FakeJobRepository();
    await tester.pumpWidget(
      MaterialApp(home: JobsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Save for later').first);
    await tester.pumpAndSettle();

    expect(repository.savedCalls, 1);
  });
}
