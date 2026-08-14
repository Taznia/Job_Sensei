import '../../../../shared/models/community_models.dart';

abstract interface class CommunityRepository {
  Future<CommunitySnapshot> loadCommunity();

  Future<CommunityGroup> createCommunity(CreateCommunityRequest request);

  Future<CommunityGroup> setMembership({
    required String communityId,
    required bool joined,
  });

  Future<CommunityPost> createPost(CreatePostRequest request);

  Future<CommunityPost> togglePostLike(String postId);

  Future<CommunityPost> togglePostFollow(String postId);

  Future<CommunityPost> addComment({
    required String postId,
    required String body,
  });
}
