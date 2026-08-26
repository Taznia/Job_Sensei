import '../../../services/job_service.dart';
import '../../../shared/models/career_profile_models.dart';
import '../../../shared/models/learning_models.dart';
import '../job_models.dart';

abstract interface class JobRepository {
  Future<List<JobPosting>> listJobs({String? query});
  Future<JobSkillGapAnalysis> skillGap(JobPosting job);
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
    final matched = (response['matchedSkills'] as List<dynamic>? ?? const [])
        .map((name) => SkillEntry(
            id: 'matched-${name.toString()}',
            name: name.toString(),
            level: SkillLevel.intermediate))
        .toList();
    return JobSkillGapAnalysis(
        job: job, strongSkills: matched, missingSkills: missing);
  }

  static JobPosting _jobFromJson(Map<String, dynamic> json) {
    final names = (json['skills'] as List<dynamic>? ??
        json['requirements'] as List<dynamic>? ??
        const []);
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
