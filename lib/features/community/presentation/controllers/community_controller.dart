import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/models/community_models.dart';
import '../../domain/repositories/community_repository.dart';

class CommunityController extends ChangeNotifier {
  CommunityController(this._repository);

  final CommunityRepository _repository;

  List<CommunityGroup> _groups = const [];
  List<CommunityPost> _posts = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CommunityGroup> get groups => List.unmodifiable(_groups);
  List<CommunityPost> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _setLoading(true);
    try {
      final snapshot = await _repository.loadCommunity();
      _groups = snapshot.groups;
      _posts = snapshot.posts;
      _errorMessage = null;
    } on AppException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Could not load communities. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<CommunityGroup?> createCommunity(
    CreateCommunityRequest request,
  ) async {
    return _run(() async {
      final created = await _repository.createCommunity(request);
      _groups = [created, ..._groups];
      return created;
    });
  }

  Future<void> joinCommunity(String communityId) async {
    await _run(() async {
      final updated = await _repository.setMembership(
        communityId: communityId,
        joined: true,
      );
      _replaceGroup(updated);
    });
  }

  Future<void> leaveCommunity(String communityId) async {
    await _run(() async {
      final updated = await _repository.setMembership(
        communityId: communityId,
        joined: false,
      );
      _replaceGroup(updated);
    });
  }

  Future<CommunityPost?> createPost(CreatePostRequest request) async {
    return _run(() async {
      final created = await _repository.createPost(request);
      _posts = [created, ..._posts];
      return created;
    });
  }

  Future<void> toggleLike(String postId) async {
    await _run(() async {
      _replacePost(await _repository.togglePostLike(postId));
    });
  }

  Future<void> toggleFollow(String postId) async {
    await _run(() async {
      _replacePost(await _repository.togglePostFollow(postId));
    });
  }

  Future<CommunityPost?> addComment(String postId, String body) {
    return _run(() async {
      final updated = await _repository.addComment(postId: postId, body: body);
      _replacePost(updated);
      return updated;
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _replaceGroup(CommunityGroup updated) {
    _groups = _groups
        .map((group) => group.id == updated.id ? updated : group)
        .toList();
  }

  void _replacePost(CommunityPost updated) {
    _posts =
        _posts.map((post) => post.id == updated.id ? updated : post).toList();
  }

  Future<T?> _run<T>(Future<T> Function() operation) async {
    try {
      final result = await operation();
      _errorMessage = null;
      notifyListeners();
      return result;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      notifyListeners();
      return null;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
