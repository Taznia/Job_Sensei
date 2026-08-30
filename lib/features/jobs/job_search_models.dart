/// Models for job search (Module 3) and job match scoring (Module 4).
///
/// Kept separate from [JobPosting] and the skill-gap models in job_models.dart,
/// which belong to other parts of the jobs feature.
library;

import 'job_models.dart';

/// Everything the filter sheet can constrain a search by. Empty fields are
/// omitted from the query string, so the default instance means "no filters".
class JobSearchQuery {
  const JobSearchQuery({
    this.text = '',
    this.company = '',
    this.location = '',
    this.skills = const [],
    this.type,
    this.workMode,
    this.experienceLevel,
    this.salaryMin,
    this.salaryMax,
    this.sort = 'relevance',
    this.page = 1,
    this.limit = 20,
  });

  final String text;
  final String company;
  final String location;
  final List<String> skills;
  final String? type;
  final String? workMode;
  final String? experienceLevel;
  final int? salaryMin;
  final int? salaryMax;
  final String sort;
  final int page;
  final int limit;

  /// How many filters beyond the free-text box are active — drives the badge
  /// on the filter button so the user can see the list is constrained.
  int get activeFilterCount {
    var count = 0;
    if (company.trim().isNotEmpty) count++;
    if (location.trim().isNotEmpty) count++;
    if (skills.isNotEmpty) count++;
    if (type != null) count++;
    if (workMode != null) count++;
    if (experienceLevel != null) count++;
    if (salaryMin != null || salaryMax != null) count++;
    return count;
  }

  bool get hasFilters => activeFilterCount > 0;

  Map<String, dynamic> toQueryParameters() {
    return {
      if (text.trim().isNotEmpty) 'q': text.trim(),
      if (company.trim().isNotEmpty) 'company': company.trim(),
      if (location.trim().isNotEmpty) 'location': location.trim(),
      if (skills.isNotEmpty) 'skill': skills.join(','),
      if (type != null) 'type': type,
      if (workMode != null) 'workMode': workMode,
      if (experienceLevel != null) 'experienceLevel': experienceLevel,
      if (salaryMin != null) 'salaryMin': salaryMin,
      if (salaryMax != null) 'salaryMax': salaryMax,
      'sort': sort,
      'page': page,
      'limit': limit,
    };
  }

  JobSearchQuery copyWith({
    String? text,
    String? company,
    String? location,
    List<String>? skills,
    String? type,
    String? workMode,
    String? experienceLevel,
    int? salaryMin,
    int? salaryMax,
    String? sort,
    int? page,
    int? limit,
    // Nullable fields need an explicit clear, since `null` means "unchanged".
    bool clearType = false,
    bool clearWorkMode = false,
    bool clearExperienceLevel = false,
    bool clearSalary = false,
  }) {
    return JobSearchQuery(
      text: text ?? this.text,
      company: company ?? this.company,
      location: location ?? this.location,
      skills: skills ?? this.skills,
      type: clearType ? null : (type ?? this.type),
      workMode: clearWorkMode ? null : (workMode ?? this.workMode),
      experienceLevel: clearExperienceLevel
          ? null
          : (experienceLevel ?? this.experienceLevel),
      salaryMin: clearSalary ? null : (salaryMin ?? this.salaryMin),
      salaryMax: clearSalary ? null : (salaryMax ?? this.salaryMax),
      sort: sort ?? this.sort,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

/// One page of results, with the total so the header can say "N jobs found".
class JobSearchResult {
  const JobSearchResult({
    required this.total,
    required this.page,
    required this.pages,
    required this.sort,
    required this.jobs,
  });

  const JobSearchResult.empty()
      : total = 0,
        page = 1,
        pages = 1,
        sort = 'relevance',
        jobs = const <JobPosting>[];

  final int total;
  final int page;
  final int pages;
  final String sort;
  final List<JobPosting> jobs;

  bool get hasMore => page < pages;
}

/// Values the API says actually exist, so the sheet never offers a filter that
/// would return nothing.
class JobFilterOptions {
  const JobFilterOptions({
    this.companies = const [],
    this.locations = const [],
    this.skills = const [],
    this.types = const [],
    this.workModes = const [],
    this.experienceLevels = const [],
    this.salaryMin,
    this.salaryMax,
  });

  final List<String> companies;
  final List<String> locations;
  final List<String> skills;
  final List<String> types;
  final List<String> workModes;
  final List<String> experienceLevels;
  final int? salaryMin;
  final int? salaryMax;

  factory JobFilterOptions.fromJson(Map<String, dynamic> json) {
    List<String> list(Object? value) => (value is List)
        ? value.map((e) => e.toString()).toList()
        : const <String>[];

    final range = json['salaryRange'];
    return JobFilterOptions(
      companies: list(json['companies']),
      locations: list(json['locations']),
      skills: list(json['skills']),
      types: list(json['types']),
      workModes: list(json['workModes']),
      experienceLevels: list(json['experienceLevels']),
      salaryMin: range is Map ? (range['min'] as num?)?.round() : null,
      salaryMax: range is Map ? (range['max'] as num?)?.round() : null,
    );
  }
}

/* ------------------------------------------------ Module 4: match score --- */

/// One scored area of the comparison, e.g. Skills 45/45.
class JobMatchArea {
  const JobMatchArea({
    required this.area,
    required this.score,
    required this.max,
    required this.detail,
  });

  final String area;
  final int score;
  final int max;
  final String detail;

  double get fraction => max == 0 ? 0 : (score / max).clamp(0, 1).toDouble();

  factory JobMatchArea.fromJson(Map<String, dynamic> json) => JobMatchArea(
        area: (json['area'] ?? '').toString(),
        score: (json['score'] as num?)?.round() ?? 0,
        max: (json['max'] as num?)?.round() ?? 0,
        detail: (json['detail'] ?? '').toString(),
      );
}

/// A qualification worth surfacing, e.g. "Skills you already have".
class JobMatchStrength {
  const JobMatchStrength({required this.label, required this.detail});

  final String label;
  final String detail;

  factory JobMatchStrength.fromJson(Map<String, dynamic> json) =>
      JobMatchStrength(
        label: (json['label'] ?? '').toString(),
        detail: (json['detail'] ?? '').toString(),
      );
}

/// The Module 4 result: how well this seeker fits this job, and why.
///
/// Carries no learning recommendations by design — closing a gap is the
/// skill-gap feature's job, and two answers to the same question would be
/// worse than one.
class JobMatchScore {
  const JobMatchScore({
    required this.overallScore,
    required this.verdict,
    required this.verdictLabel,
    required this.summary,
    required this.strengths,
    required this.breakdown,
    required this.matchedSkills,
    required this.skillsNotEvidenced,
    this.resumeTitle,
  });

  final int overallScore;
  final String verdict;
  final String verdictLabel;
  final String summary;
  final List<JobMatchStrength> strengths;
  final List<JobMatchArea> breakdown;
  final List<String> matchedSkills;
  final int skillsNotEvidenced;

  /// Which resume was compared, when one was.
  final String? resumeTitle;

  factory JobMatchScore.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> objects(Object? value) => (value is List)
        ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
        : const <Map<String, dynamic>>[];

    final resume = json['resume'];
    return JobMatchScore(
      overallScore: (json['overallScore'] as num?)?.round() ?? 0,
      verdict: (json['verdict'] ?? 'low').toString(),
      verdictLabel: (json['verdictLabel'] ?? 'Match').toString(),
      summary: (json['summary'] ?? '').toString(),
      strengths: objects(json['strengths'])
          .map(JobMatchStrength.fromJson)
          .toList(),
      breakdown:
          objects(json['breakdown']).map(JobMatchArea.fromJson).toList(),
      matchedSkills: (json['matchedSkills'] is List)
          ? (json['matchedSkills'] as List).map((e) => e.toString()).toList()
          : const [],
      skillsNotEvidenced: (json['skillsNotEvidenced'] as num?)?.round() ?? 0,
      resumeTitle: resume is Map ? resume['title']?.toString() : null,
    );
  }
}
