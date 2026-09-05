import '../../../../shared/models/tracked_application_models.dart';

/// Contract for the Application Tracker.
abstract interface class TrackedApplicationRepository {
  /// Every application for the signed-in user, job-board and tracked alike.
  Future<List<TrackedApplication>> listApplications();

  Future<TrackedApplication> track({
    required String jobTitle,
    required String companyName,
    String? resumeId,
  });

  Future<TrackedApplication> updateStatus(
    String id,
    AppStatus status, {
    DateTime? interviewDate,
  });

  Future<void> deleteTracked(String id);
}
