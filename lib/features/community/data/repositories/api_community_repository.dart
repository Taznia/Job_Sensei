import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/community_models.dart';
import '../../domain/repositories/community_repository.dart';

class ApiCommunityRepository implements CommunityRepository {
  ApiCommunityRepository({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  @override
  Future<CommunitySnapshot> loadCommunity() async {
    final groupsRaw = await _client.get('/communities') as List<dynamic>;
    final postsRaw = await _client.get('/posts') as List<dynamic>;
    return CommunitySnapshot(
      groups: groupsRaw
          .map((item) => CommunityGroup.fromJson(item as Map<String, dynamic>))
          .toList(),
      posts: postsRaw
          .map((item) => CommunityPost.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<CommunityGroup> createCommunity(CreateCommunityRequest request) async {
    final data = await _client.post('/communities', data: {
      'name': request.name,
      'description': request.description,
      'category': request.category,
      'visualKey': request.visualKey,
    }) as Map<String, dynamic>;
    return CommunityGroup.fromJson(data);
  }

  @override
  Future<CommunityGroup> setMembership({
    required String communityId,
    required bool joined,
  }) async {
    final data = joined
        ? await _client.post('/communities/$communityId/join')
        : await _client.delete('/communities/$communityId/leave');
    return CommunityGroup.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<CommunityGroup> removeMember({
    required String communityId,
    required String userId,
  }) async {
    final data = await _client.delete(
      '/communities/$communityId/members/$userId',
    ) as Map<String, dynamic>;
    return CommunityGroup.fromJson(data);
  }

  @override
  Future<CommunityPost> createPost(CreatePostRequest request) async {
    final files = <MultipartFile>[];
    for (final attachment in request.attachments) {
      if (attachment.bytes != null) {
        files.add(MultipartFile.fromBytes(
          attachment.bytes!,
          filename: attachment.name,
        ));
      } else if (attachment.localPath != null) {
        files.add(await MultipartFile.fromFile(
          attachment.localPath!,
          filename: attachment.name,
        ));
      }
    }

    final form = FormData.fromMap({
      'body': request.body,
      'type': request.type,
      if (request.communityId != null) 'communityId': request.communityId,
      if (request.communityName != null) 'communityName': request.communityName,
      if (files.isNotEmpty) 'files': files,
    });

    final data =
        await _client.post('/posts', data: form) as Map<String, dynamic>;
    return CommunityPost.fromJson(data);
  }

  @override
  Future<void> deletePost(String postId) async {
    await _client.delete('/posts/$postId');
  }

  @override
  Future<CommunityPost> togglePostLike(String postId) async {
    final data =
        await _client.post('/posts/$postId/like') as Map<String, dynamic>;
    return CommunityPost.fromJson(data);
  }

  @override
  Future<CommunityPost> togglePostFollow(String postId) async {
    final data =
        await _client.post('/posts/$postId/follow') as Map<String, dynamic>;
    return CommunityPost.fromJson(data);
  }

  @override
  Future<CommunityPost> addComment({
    required String postId,
    required String body,
    String? parentCommentId,
  }) async {
    final data = await _client.post('/posts/$postId/comments', data: {
      'body': body,
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
    }) as Map<String, dynamic>;
    return CommunityPost.fromJson(data);
  }

  @override
  Future<void> reportPost({
    required String postId,
    required String reason,
  }) {
    return _client.post('/posts/$postId/report', data: {'reason': reason});
  }
}
