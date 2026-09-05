import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/models/resume_models.dart';
import '../../domain/repositories/resume_repository.dart';

/// Holds the signed-in seeker's resumes.
///
/// Mutations re-read the list from the repository rather than patching local
/// state, so server-owned values — `isDefault`, `updatedAt`, the list order —
/// cannot drift out of sync with what is stored.
class ResumeController extends ChangeNotifier {
  ResumeController(this._repository);

  final ResumeRepository _repository;

  List<Resume> _resumes = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _requiresSignIn = false;

  List<Resume> get resumes => _resumes;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  /// True when the API refused the call for want of a valid session, so the
  /// screen can offer sign-in instead of a pointless retry.
  bool get requiresSignIn => _requiresSignIn;
  bool get hasResumes => _resumes.isNotEmpty;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _resumes = await _repository.listResumes();
      _errorMessage = null;
      _requiresSignIn = false;
    } catch (error) {
      _applyError(error, 'Could not load your resumes. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create(ResumeDraft draft) =>
      _run(() => _repository.createResume(draft));

  Future<bool> update(String id, ResumeDraft draft) =>
      _run(() => _repository.updateResume(id, draft));

  Future<bool> remove(String id) => _run(() => _repository.deleteResume(id));

  Future<bool> duplicate(Resume resume) =>
      _run(() => _repository.duplicateResume(resume));

  Future<bool> setDefault(String id) => _run(() => _repository.setDefault(id));

  /// Runs [action], then refreshes the list. Returns false when it failed, so
  /// the caller can keep an edit sheet open instead of dismissing it.
  Future<bool> _run(Future<void> Function() action) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      _resumes = await _repository.listResumes();
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
