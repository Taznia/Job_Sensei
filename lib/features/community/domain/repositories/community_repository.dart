import '../../../../shared/models/community_models.dart';

abstract interface class CommunityRepository {
  Future<CommunitySnapshot> loadCommunity();

  Future<CommunityGroup> createCommunity(CreateCommunityRequest request);

  Future<CommunityGroup> setMembership({
    required String communityId,
    required bool joined,
  });

  Future<CommunityGroup> removeMember({
    required String communityId,
    required String userId,
  });

  Future<CommunityPost> createPost(CreatePostRequest request);

  Future<void> deletePost(String postId);

  Future<CommunityPost> togglePostLike(String postId);

  Future<CommunityPost> togglePostFollow(String postId);

  Future<CommunityPost> addComment({
    required String postId,
    required String body,
    String? parentCommentId,
  });

  Future<void> reportPost({
    required String postId,
    required String reason,
  });
}
