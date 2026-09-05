import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/models/resume_match_models.dart';
import '../../domain/repositories/resume_match_repository.dart';

/// Drives the AI Resume Match screen: one in-flight analysis plus the history
/// of past ones.
///
/// An analysis is a slow, billable call, so [analyse] guards against being
/// fired twice while one is already running.
class ResumeMatchController extends ChangeNotifier {
  ResumeMatchController(this._repository);

  final ResumeMatchRepository _repository;

  ResumeMatch? _result;
  List<ResumeMatch> _history = const [];
  bool _isAnalysing = false;
  bool _isLoadingHistory = false;
  String? _errorMessage;
  bool _requiresSignIn = false;

  ResumeMatch? get result => _result;
  List<ResumeMatch> get history => _history;
  bool get isAnalysing => _isAnalysing;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get errorMessage => _errorMessage;
  bool get requiresSignIn => _requiresSignIn;

  Future<void> loadHistory() async {
    _isLoadingHistory = true;
    notifyListeners();
    try {
      _history = await _repository.history();
      _errorMessage = null;
      _requiresSignIn = false;
    } catch (error) {
      _applyError(error, 'Could not load your past analyses.');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Returns true when an analysis came back. The result is exposed on
  /// [result]; the history is refreshed so the second tab stays current.
  Future<bool> analyse({
    required String resumeId,
    required String jobDescription,
  }) async {
    if (_isAnalysing) return false;

    _isAnalysing = true;
    _errorMessage = null;
    _result = null;
    notifyListeners();

    try {
      _result = await _repository.analyse(
        resumeId: resumeId,
        jobDescription: jobDescription,
      );
      _requiresSignIn = false;
      // Best-effort: a failed refresh must not discard a successful analysis.
      try {
        _history = await _repository.history();
      } catch (_) {
        // Leave the previous history in place.
      }
      return true;
    } catch (error) {
      _applyError(error, 'The analysis could not be completed. Please try again.');
      return false;
    } finally {
      _isAnalysing = false;
      notifyListeners();
    }
  }

  /// Brings a past analysis back into the result pane.
  void showFromHistory(ResumeMatch match) {
    _result = match;
    notifyListeners();
  }

  Future<bool> remove(String id) async {
    try {
      await _repository.delete(id);
      _history = _history.where((item) => item.id != id).toList();
      if (_result?.id == id) _result = null;
      notifyListeners();
      return true;
    } catch (error) {
      _applyError(error, 'Could not delete that analysis.');
      notifyListeners();
      return false;
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
