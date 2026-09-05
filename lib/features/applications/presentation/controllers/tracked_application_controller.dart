import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/models/tracked_application_models.dart';
import '../../domain/repositories/tracked_application_repository.dart';

/// Holds every application belonging to the signed-in seeker.
///
/// The list mixes two kinds of row: applications made to a Job posting inside
/// Job Sensei (read-only here — the recruiter drives those) and ones the user
/// tracks manually. [TrackedApplication.isFromJobBoard] tells them apart.
class TrackedApplicationController extends ChangeNotifier {
  TrackedApplicationController(this._repository);

  final TrackedApplicationRepository _repository;

  List<TrackedApplication> _applications = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _requiresSignIn = false;

  List<TrackedApplication> get applications => _applications;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get requiresSignIn => _requiresSignIn;
  bool get hasApplications => _applications.isNotEmpty;

  /// Counts per status, for the summary row at the top of the tracker.
  Map<AppStatus, int> get statusCounts {
    final counts = <AppStatus, int>{};
    for (final application in _applications) {
      counts[application.status] = (counts[application.status] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _applications = await _repository.listApplications();
      _errorMessage = null;
      _requiresSignIn = false;
    } catch (error) {
      _applyError(error, 'Could not load your applications. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> track({
    required String jobTitle,
    required String companyName,
    String? resumeId,
  }) {
    return _run(() => _repository.track(
          jobTitle: jobTitle,
          companyName: companyName,
          resumeId: resumeId,
        ));
  }

  Future<bool> moveTo(
    TrackedApplication application,
    AppStatus status, {
    DateTime? interviewDate,
  }) {
    return _run(() => _repository.updateStatus(
          application.id,
          status,
          interviewDate: interviewDate,
        ));
  }

  Future<bool> remove(String id) => _run(() => _repository.deleteTracked(id));

  Future<bool> _run(Future<void> Function() action) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      _applications = await _repository.listApplications();
      _requiresSignIn = false;
      return true;
    } catch (error) {
      _applyError(error, 'Could not save. Please try again.');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _applyError(Object error, String fallback) {
    if (error is AppException) {
      _errorMessage = error.message;
      _requiresSignIn = error.statusCode == 401;
      return;
    }
    _errorMessage = fallback;
    _requiresSignIn = false;
  }
}
