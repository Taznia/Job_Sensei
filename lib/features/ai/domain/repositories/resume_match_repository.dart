import '../../../../shared/models/resume_match_models.dart';

/// Contract for AI Resume Match.
abstract interface class ResumeMatchRepository {
  /// Runs a fresh analysis and stores it as history.
  Future<ResumeMatch> analyse({
    required String resumeId,
    required String jobDescription,
  });

  /// Past analyses, newest first, optionally narrowed to one resume.
  Future<List<ResumeMatch>> history({String? resumeId});

  Future<void> delete(String id);
}
