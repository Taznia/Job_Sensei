/// Models for AI Resume Match.
///
/// Distinct from the job match score in the jobs feature: that one rule-scores
/// a resume against a stored Job. This one is the structured advice Gemini
/// returns for a resume against a free-text job description the user pasted.
library;

class ProjectHighlight {
  const ProjectHighlight({
    required this.project,
    required this.reason,
    required this.suggestedBullets,
  });

  final String project;
  final String reason;
  final List<String> suggestedBullets;

  factory ProjectHighlight.fromJson(Map<String, dynamic> json) {
    return ProjectHighlight(
      project: json['project']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      suggestedBullets: _stringList(json['suggestedBullets']),
    );
  }
}

class ResumeMatch {
  const ResumeMatch({
    required this.id,
    required this.matchScore,
    required this.strongKeywords,
    required this.recommendedKeywords,
    required this.projectHighlights,
    required this.skillOrdering,
    required this.summaryImprovement,
    required this.overallFeedback,
    required this.strengths,
    required this.gaps,
    this.resumeId = '',
    this.resumeTitle = '',
    this.jobDescription = '',
    this.createdAt,
  });

  final String id;
  final int matchScore;
  final List<String> strongKeywords;
  final List<String> recommendedKeywords;
  final List<ProjectHighlight> projectHighlights;
  final List<String> skillOrdering;
  final String summaryImprovement;
  final String overallFeedback;
  final List<String> strengths;
  final List<String> gaps;

  final String resumeId;
  final String resumeTitle;
  final String jobDescription;
  final DateTime? createdAt;

  factory ResumeMatch.fromJson(Map<String, dynamic> json) {
    return ResumeMatch(
      id: json['id']?.toString() ?? '',
      matchScore: (json['matchScore'] as num?)?.toInt() ?? 0,
      strongKeywords: _stringList(json['strongKeywords']),
      recommendedKeywords: _stringList(json['recommendedKeywords']),
      projectHighlights: json['projectHighlights'] is List
          ? (json['projectHighlights'] as List)
              .whereType<Map>()
              .map((item) =>
                  ProjectHighlight.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      skillOrdering: _stringList(json['skillOrdering']),
      summaryImprovement: json['summaryImprovement']?.toString() ?? '',
      overallFeedback: json['overallFeedback']?.toString() ?? '',
      strengths: _stringList(json['strengths']),
      gaps: _stringList(json['gaps']),
      resumeId: json['resumeId']?.toString() ?? '',
      resumeTitle: json['resumeTitle']?.toString() ?? 'Untitled',
      jobDescription: json['jobDescription']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal(),
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList();
}
