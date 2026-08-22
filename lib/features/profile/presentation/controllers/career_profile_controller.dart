import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';

import '../../../../shared/models/career_profile_models.dart';
import '../../domain/repositories/career_profile_repository.dart';

/// Holds the single [CareerProfile] for the signed-in seeker.
///
/// Every mutation goes through [_run], which keeps one in-flight flag so the UI
/// can disable save buttons, and swaps in the whole profile the repository
/// returns rather than patching local state — derived values like completeness
/// would otherwise drift out of sync with the stored record.
class CareerProfileController extends ChangeNotifier {
  CareerProfileController(this._repository);

  final CareerProfileRepository _repository;

  CareerProfile? _profile;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _requiresSignIn = false;

  CareerProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  /// True when the API rejected the call for want of a valid session, so
  /// the screen can offer sign-in instead of a pointless retry.
  bool get requiresSignIn => _requiresSignIn;
  bool get hasProfile => _profile != null;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _profile = await _repository.loadProfile();
      _errorMessage = null;
      _requiresSignIn = false;
    } catch (error) {
      _applyError(error, 'Could not load your profile. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveBasics(ProfileBasicsDraft draft) =>
      _run(() => _repository.saveBasics(draft));

  Future<bool> savePreferences(JobPreferences preferences) =>
      _run(() => _repository.savePreferences(preferences));

  Future<bool> saveEducation(EducationEntry entry) =>
      _run(() => _repository.upsertEducation(entry));

  Future<bool> removeEducation(String id) =>
      _run(() => _repository.removeEducation(id));

  Future<bool> saveExperience(WorkExperience entry) =>
      _run(() => _repository.upsertExperience(entry));

  Future<bool> removeExperience(String id) =>
      _run(() => _repository.removeExperience(id));

  Future<bool> saveSkill(SkillEntry entry) =>
      _run(() => _repository.upsertSkill(entry));

  Future<bool> removeSkill(String id) => _run(() => _repository.removeSkill(id));

  Future<bool> saveCertification(Certification entry) =>
      _run(() => _repository.upsertCertification(entry));

  Future<bool> removeCertification(String id) =>
      _run(() => _repository.removeCertification(id));

  Future<bool> savePortfolioLink(PortfolioLink link) =>
      _run(() => _repository.upsertPortfolioLink(link));

  Future<bool> removePortfolioLink(String id) =>
      _run(() => _repository.removePortfolioLink(id));

  /// Surfaces the API's own message when it has one — "Invalid email or
  /// password" beats a generic failure — and flags 401s for the sign-in path.
  void _applyError(Object error, String fallback) {
    if (error is AppException) {
      _requiresSignIn = error.statusCode == 401;
      _errorMessage = _requiresSignIn
          ? 'Sign in to view and edit your career profile.'
          : error.message;
      return;
    }
    _requiresSignIn = false;
    _errorMessage = fallback;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Returns whether the write succeeded, so callers can close a sheet only on
  /// success and leave the user's input on screen when it fails.
  Future<bool> _run(Future<CareerProfile> Function() operation) async {
    _isSaving = true;
    notifyListeners();
    try {
      _profile = await operation();
      _errorMessage = null;
      _requiresSignIn = false;
      return true;
    } catch (error) {
      _applyError(error, 'Could not save your changes. Please try again.');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
