import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/errors/app_exception.dart';
import '../../core/widgets/app_widgets.dart';
import 'data/job_api_repository.dart';
import 'job_details_page.dart';
import 'job_models.dart';
import 'job_search_models.dart';
import 'widgets/job_filter_sheet.dart';

/// Job search — Module 3 (Adreed Saadad Hasan, 22301190).
///
/// Filters by title, company, skill, location, salary range, job type,
/// experience level, and remote or on-site preference, with the most relevant
/// results first, and lets the user save jobs for later.
///
/// Filtering happens on the server rather than over a downloaded page, so a
/// filter applies to the whole collection instead of only the rows already
/// fetched.
class JobsPage extends StatefulWidget {
  const JobsPage({super.key, this.repository});

  final JobRepository? repository;

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  /// Typing should not fire a request per keystroke.
  static const _debounce = Duration(milliseconds: 350);

  late final JobRepository _repository = widget.repository ?? ApiJobRepository();
  final _searchController = TextEditingController();

  Timer? _debounceTimer;
  JobSearchQuery _query = const JobSearchQuery();
  JobSearchResult _result = const JobSearchResult.empty();
  JobFilterOptions _options = const JobFilterOptions();

  bool _loading = true;

  /// True when the API could not be reached and the screen is showing the
  /// bundled sample listings instead. Surfaced in the UI — sample data that
  /// looks live is worse than an empty list.
  bool _usingSampleData = false;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    _search();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Filter values are cosmetic — a failure here leaves the sheet with free-text
  /// fields only, which still works, so it is not surfaced as an error.
  Future<void> _loadFilterOptions() async {
    try {
      final options = await _repository.filterOptions();
      if (mounted) setState(() => _options = options);
    } catch (_) {
      // Intentionally ignored; see above.
    }
  }

  Future<void> _search({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await _repository.searchJobs(_query.copyWith(page: 1));
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
        _error = null;
        _usingSampleData = false;
      });
    } on AppException catch (error) {
      _handleSearchFailure(error.message);
    } catch (_) {
      _handleSearchFailure('Could not load jobs. Please try again.');
    }
  }

  /// Falling back only makes sense for an unfiltered search — showing sample
  /// jobs in response to "remote React roles over 100k" would be nonsense.
  bool get _canFallBack =>
      _query.text.trim().isEmpty && !_query.hasFilters && demoJobs.isNotEmpty;

  JobSearchResult _sampleResult() => JobSearchResult(
        total: demoJobs.length,
        page: 1,
        pages: 1,
        sort: _query.sort,
        jobs: demoJobs,
      );

  void _handleSearchFailure(String message) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_canFallBack) {
          _result = _sampleResult();
          _usingSampleData = true;
          _error = null;
        } else {
          _error = message;
        }
      });
  }

  /// Appends the next page rather than replacing, so the list grows.
  Future<void> _loadMore() async {
    if (_loadingMore || !_result.hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = await _repository.searchJobs(
        _query.copyWith(page: _result.page + 1),
      );
      if (!mounted) return;
      setState(() {
        _result = JobSearchResult(
          total: next.total,
          page: next.page,
          pages: next.pages,
          sort: next.sort,
          jobs: [..._result.jobs, ...next.jobs],
        );
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      _toast('Could not load more results.');
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      _query = _query.copyWith(text: value, page: 1);
      _search();
    });
  }

  Future<void> _openFilters() async {
    final updated = await JobFilterSheet.show(
      context,
      query: _query,
      options: _options,
    );
    if (updated == null || !mounted) return;
    _query = updated;
    await _search();
  }

  Future<void> _changeSort(String sort) async {
    _query = _query.copyWith(sort: sort, page: 1);
    await _search();
  }

  /// Optimistic: the icon flips immediately and reverts if the write fails,
  /// because a bookmark that lags a tap feels broken.
  Future<void> _toggleSaved(JobPosting job) async {
    final next = !job.isSaved;
    _replaceJob(job.copyWith(isSaved: next));
    try {
      await _repository.setSaved(job.id, saved: next);
      _toast(next ? 'Saved for later.' : 'Removed from saved jobs.');
    } on AppException catch (error) {
      _replaceJob(job);
      _toast(
        error.statusCode == 401
            ? 'Sign in to save jobs.'
            : error.message,
        isError: true,
      );
    } catch (_) {
      _replaceJob(job);
      _toast('Could not update your saved jobs.', isError: true);
    }
  }

  void _replaceJob(JobPosting job) {
    if (!mounted) return;
    setState(() {
      _result = JobSearchResult(
        total: _result.total,
        page: _result.page,
        pages: _result.pages,
        sort: _result.sort,
        jobs: [
          for (final item in _result.jobs) item.id == job.id ? job : item,
        ],
      );
    });
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? AppColors.danger : null,
        ),
      );
  }

  void _clearFilters() {
    _searchController.clear();
    _query = const JobSearchQuery();
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _search(showSpinner: false),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 108),
            children: [
              GradientHero(
                eyebrow: 'Open roles',
                title: 'Jobs',
                description:
                    'Filter by skill, location, pay and seniority. Save the ones worth a second look.',
                stats: [
                  HeroStatChip(
                    icon: Icons.work_outline_rounded,
                    label: '${_result.total} matching',
                  ),
                  const HeroStatChip(
                    icon: Icons.auto_graph_rounded,
                    label: 'Match score inside each job',
                  ),
                ],
                footer: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Search title, company, or description',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ControlBar(
                activeFilters: _query.activeFilterCount,
                sort: _query.sort,
                onFilters: _openFilters,
                onSort: _changeSort,
              ),
              const SizedBox(height: 12),
              _ResultHeader(
                total: _result.total,
                loading: _loading,
                hasFilters: _query.hasFilters || _query.text.isNotEmpty,
                onClear: _clearFilters,
              ),
              const SizedBox(height: 10),
              if (_usingSampleData) ...[
                const _SampleDataNotice(),
                const SizedBox(height: 12),
              ],
              ..._body(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body() {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_error != null) {
      return [
        _ErrorPanel(message: _error!, onRetry: _search),
      ];
    }

    if (_result.jobs.isEmpty) {
      return [
        EmptyState(
          icon: Icons.search_off_rounded,
          title: 'No jobs match those filters',
          message: _query.hasFilters
              ? 'Try widening the salary range or clearing a filter.'
              : 'Nothing is open right now. Pull down to refresh.',
        ),
        if (_query.hasFilters)
          Center(
            child: TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear filters'),
            ),
          ),
      ];
    }

    return [
      for (final job in _result.jobs)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _JobCard(
            job: job,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                // Same repository instance, so a test (or a swapped backend) reaches
                // the details page too.
                builder: (_) => JobDetailsPage(
                  job: job,
                  repository: _repository,
                ),
              ),
            ),
            onToggleSaved: () => _toggleSaved(job),
          ),
        ),
      if (_result.hasMore)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: OutlinedButton(
            onPressed: _loadingMore ? null : _loadMore,
            child: _loadingMore
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Load more (${_result.total - _result.jobs.length} left)'),
          ),
        ),
    ];
  }
}

/// Shown when the API is unreachable and the bundled sample jobs are on
/// screen, so nobody mistakes them for live listings.
class _SampleDataNotice extends StatelessWidget {
  const _SampleDataNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Showing sample jobs — the Job Sensei API is not reachable, so search and filters are not live.',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------------------------------------- controls --- */

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.activeFilters,
    required this.sort,
    required this.onFilters,
    required this.onSort,
  });

  final int activeFilters;
  final String sort;
  final VoidCallback onFilters;
  final ValueChanged<String> onSort;

  static const _sorts = {
    'relevance': 'Most relevant',
    'newest': 'Newest',
    'salary': 'Highest pay',
    'title': 'A–Z',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onFilters,
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: Text(
              activeFilters == 0 ? 'Filters' : 'Filters ($activeFilters)',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 46),
              backgroundColor:
                  activeFilters == 0 ? null : AppColors.primary.withValues(alpha: 0.08),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sorts.containsKey(sort) ? sort : 'relevance',
                isExpanded: true,
                icon: const Icon(Icons.expand_more_rounded, size: 20),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
                items: _sorts.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onSort(value);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({
    required this.total,
    required this.loading,
    required this.hasFilters,
    required this.onClear,
  });

  final int total;
  final bool loading;
  final bool hasFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            loading
                ? 'Searching…'
                : '$total ${total == 1 ? 'JOB' : 'JOBS'} FOUND',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
        if (hasFilters)
          TextButton(onPressed: onClear, child: const Text('Clear')),
      ],
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

/* ----------------------------------------------------------------- card --- */

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.onTap,
    required this.onToggleSaved,
  });

  final JobPosting job;
  final VoidCallback onTap;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final salary = job.salaryLabel;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${job.company} · ${job.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onToggleSaved,
                    tooltip: job.isSaved ? 'Remove from saved' : 'Save for later',
                    icon: Icon(
                      job.isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: job.isSaved ? AppColors.primary : AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AppBadge(label: job.type, color: AppColors.primary),
                    AppBadge(label: job.workMode, color: AppColors.cyan),
                    if (job.experienceLevel != null)
                      AppBadge(
                        label: _humanise(job.experienceLevel!),
                        color: AppColors.violet,
                      ),
                    if (salary != null)
                      AppBadge(label: salary, color: AppColors.success),
                    // Shows where an imported listing came from (Module 2).
                    if (job.isImported)
                      AppBadge(
                        label: 'via ${_humanise(job.source!)}',
                        color: AppColors.muted,
                      ),
                  ],
                ),
              ),
              if (job.requiredSkills.isNotEmpty) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    job.requiredSkills.take(5).map((s) => s.name).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11.5,
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

  static String _humanise(String value) {
    final words = value.replaceAll('-', ' ').split(' ');
    return words
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
