import '../../../../shared/models/resume_models.dart';

/// Storage-agnostic contract for the resume builder, so the screens can be
/// driven by the API in the app and by a fake in widget tests.
abstract interface class ResumeRepository {
  Future<List<Resume>> listResumes();

  Future<Resume> getResume(String id);

  Future<Resume> createResume(ResumeDraft draft);

  Future<Resume> updateResume(String id, ResumeDraft draft);

  Future<void> deleteResume(String id);

  /// Server-side copy: creates a new resume from an existing one.
  Future<Resume> duplicateResume(Resume resume);

  Future<Resume> setDefault(String id);
}
