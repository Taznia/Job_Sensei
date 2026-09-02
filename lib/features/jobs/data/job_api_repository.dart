import '../../../services/job_service.dart';
import '../../../shared/models/career_profile_models.dart';
import '../../../shared/models/learning_models.dart';
import '../job_models.dart';
import '../job_search_models.dart';

abstract interface class JobRepository {
  Future<List<JobPosting>> listJobs({String? query});
  Future<JobSkillGapAnalysis> skillGap(JobPosting job);

  /// Module 3: filtered, ranked search.
  Future<JobSearchResult> searchJobs(JobSearchQuery query);

  /// Module 3: values the filter sheet may offer.
  Future<JobFilterOptions> filterOptions();

  /// Module 3: bookmark a job for later review.
  Future<void> setSaved(String jobId, {required bool saved});

  /// Module 4: how well the signed-in user fits this job.
  Future<JobMatchScore> matchScore(String jobId, {String? resumeId});

  /// Module 2: import fresh listings from the public job boards.
  Future<JobImportResult> importJobs({int limit});
}

class ApiJobRepository implements JobRepository {
  ApiJobRepository({JobService? service}) : _service = service ?? JobService();
  final JobService _service;

  @override
  Future<List<JobPosting>> listJobs({String? query}) async {
    final response = await _service.list(query: query);
    final items = response['items'] as List<dynamic>? ?? const [];
    return items
        .map((item) => _jobFromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<JobSkillGapAnalysis> skillGap(JobPosting job) async {
    final response = await _service.selectedJobSkillGap(job.id);
    final missing = (response['missingSkills'] as List<dynamic>? ?? const [])
        .map((item) => _requirementFromJson(item as Map<String, dynamic>))
        .toList();
    final matchedJson = response['matchedSkills'] as List<dynamic>? ?? const [];
    final matched = <SkillEntry>[];
    final details = <JobSkillMatch>[];
    for (final raw in matchedJson) {
      final item = Map<String, dynamic>.from(raw as Map);
      final name = item['name'] as String;
      matched.add(SkillEntry(
          id: 'matched-$name', name: name, level: SkillLevel.intermediate));
      details.add(JobSkillMatch(
          name: name,
          currentLevel: item['currentLevel'] as int? ?? 0,
          requiredLevel: item['requiredLevel'] as int? ?? 80));
    }
    return JobSkillGapAnalysis(
        job: job,
        strongSkills: matched,
        strongSkillDetails: details,
        missingSkills: missing);
  }


  @override
  Future<JobSearchResult> searchJobs(JobSearchQuery query) async {
    final response = await _service.search(query.toQueryParameters());
    final items = response['items'] as List<dynamic>? ?? const [];
    return JobSearchResult(
      total: (response['total'] as num?)?.round() ?? 0,
      page: (response['page'] as num?)?.round() ?? 1,
      pages: (response['pages'] as num?)?.round() ?? 1,
      sort: (response['sort'] ?? 'relevance').toString(),
      jobs: items
          .map((item) => _searchJobFromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<JobFilterOptions> filterOptions() async {
    return JobFilterOptions.fromJson(await _service.filterOptions());
  }

  @override
  Future<void> setSaved(String jobId, {required bool saved}) {
    return saved ? _service.save(jobId) : _service.unsave(jobId);
  }

  @override
  Future<JobMatchScore> matchScore(String jobId, {String? resumeId}) async {
    return JobMatchScore.fromJson(
      await _service.match(jobId, resumeId: resumeId),
    );
  }

  @override
  Future<JobImportResult> importJobs({int limit = 40}) async {
    return JobImportResult.fromJson(await _service.importJobs(limit: limit));
  }

  /// The search endpoint returns more than the plain listing does, so it gets
  /// its own mapper rather than widening [_jobFromJson], which other callers
  /// still use against the simpler shape.
  static JobPosting _searchJobFromJson(Map<String, dynamic> json) {
    final names = json['skills'] as List<dynamic>? ?? const [];
    return JobPosting(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled role',
      company: json['company'] as String? ?? 'Unknown company',
      location: json['location'] as String? ?? 'Not specified',
      type: _label(json['type'] as String? ?? 'full-time'),
      workMode: _label(json['workMode'] as String? ?? 'onsite'),
      description: json['description'] as String? ?? '',
      requiredSkills: names
          .map((name) => JobSkillRequirement(
                id: name.toString().toLowerCase(),
                name: name.toString(),
                category: 'TECHNICAL',
                priority: SkillPriority.high,
                reason: '${name.toString()} is listed as a requirement for this role.',
              ))
          .toList(),
      experienceLevel: json['experienceLevel'] as String?,
      salaryMin: (json['salaryMin'] as num?)?.round(),
      salaryMax: (json['salaryMax'] as num?)?.round(),
      currency: json['currency'] as String?,
      isSaved: json['isSaved'] == true,
      postedAt: DateTime.tryParse(json['postedAt']?.toString() ?? '')?.toLocal(),
      sourceLink: json['sourceLink'] as String?,
      source: json['source'] as String?,
    );
  }

  static JobPosting _jobFromJson(Map<String, dynamic> json) {
    final names = json['skills'] as List<dynamic>? ??
        json['requirements'] as List<dynamic>? ??
        const [];
    return JobPosting(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled role',
      company: json['company'] as String? ?? 'Unknown company',
      location: json['location'] as String? ?? 'Not specified',
      type: _label(json['type'] as String? ?? 'full-time'),
      workMode: _label(json['workMode'] as String? ?? 'onsite'),
      description: json['description'] as String? ?? '',
      requiredSkills: names
          .map((name) => JobSkillRequirement(
              id: name.toString().toLowerCase(),
              name: name.toString(),
              category: 'TECHNICAL',
              priority: SkillPriority.high,
              reason:
                  '${name.toString()} is listed as a requirement for this role.'))
          .toList(),
    );
  }

  static JobSkillRequirement _requirementFromJson(Map<String, dynamic> json) =>
      JobSkillRequirement(
        id: json['skillId'] as String? ?? json['skillName'] as String,
        name: json['skillName'] as String,
        category: json['category'] as String? ?? 'TECHNICAL',
        priority: _priority(json['priority'] as String?),
        reason: json['reason'] as String? ??
            'This skill is required for the selected role.',
        learningPathAvailable: json['learningPathAvailable'] as bool? ?? false,
        learningPathId: json['learningPathId'] as String?,
        currentLevel: json['currentLevel'] as int? ?? 0,
        requiredLevel: json['requiredLevel'] as int? ?? 80,
      );

  static String _label(String value) => value
      .replaceAll('-', ' ')
      .split(' ')
      .map((part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
  static SkillPriority _priority(String? value) =>
      switch (value?.toLowerCase()) {
        'low' => SkillPriority.low,
        'medium' => SkillPriority.medium,
        _ => SkillPriority.high
      };
}
