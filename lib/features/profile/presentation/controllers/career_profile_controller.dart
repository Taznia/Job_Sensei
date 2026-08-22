import 'package:flutter/foundation.dart';

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

  CareerProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get hasProfile => _profile != null;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _profile = await _repository.loadProfile();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Could not load your profile. Please try again.';
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
      return true;
    } catch (_) {
      _errorMessage = 'Could not save your changes. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
