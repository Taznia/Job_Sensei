import 'dart:async';

import '../../../../shared/models/community_models.dart';
import '../../domain/repositories/community_repository.dart';

class InMemoryCommunityRepository implements CommunityRepository {
  InMemoryCommunityRepository()
      : _groups = _seedGroups,
        _posts = _seedPosts;

  List<CommunityGroup> _groups;
  List<CommunityPost> _posts;

  static final _seedGroups = <CommunityGroup>[
    CommunityGroup(
      id: 'react-developers',
      name: 'React Developers',
      description: 'Hooks, architecture, frontend careers',
      category: 'Technology',
      visualKey: 'code',
      memberCount: 2400,
      privacy: CommunityPrivacy.public,
      createdById: 'user-alex',
      createdAt: DateTime(2025, 1, 14),
      isJoined: true,
    ),
    CommunityGroup(
      id: 'product-managers',
      name: 'Product Managers',
      description: 'Product thinking, discovery, and leadership',
      category: 'Job role',
      visualKey: 'product',
      memberCount: 1800,
      privacy: CommunityPrivacy.public,
      createdById: 'user-nadia',
      createdAt: DateTime(2025, 2, 4),
    ),
    CommunityGroup(
      id: 'data-scientists',
      name: 'Data Scientists',
      description: 'Machine learning, analytics, and data careers',
      category: 'Technology',
      visualKey: 'data',
      memberCount: 3100,
      privacy: CommunityPrivacy.public,
      createdById: 'user-rahim',
      createdAt: DateTime(2024, 11, 20),
    ),
    CommunityGroup(
      id: 'flutter-developers',
      name: 'Flutter Developers',
      description: 'Dart, mobile UI, and clean architecture',
      category: 'Technology',
      visualKey: 'flutter',
      memberCount: 1200,
      privacy: CommunityPrivacy.public,
      createdById: 'user-taznia',
      createdAt: DateTime(2025, 3, 8),
      isJoined: true,
    ),
    CommunityGroup(
      id: 'ui-designers',
      name: 'UI Designers',
      description: 'Figma, UX research, and design systems',
      category: 'Creative',
      visualKey: 'design',
      memberCount: 2700,
      privacy: CommunityPrivacy.public,
      createdById: 'user-maya',
      createdAt: DateTime(2024, 12, 16),
    ),
    CommunityGroup(
      id: 'fresh-graduates',
      name: 'Fresh Graduates',
      description: 'First jobs, portfolios, and interviews',
      category: 'Career stage',
      visualKey: 'graduate',
      memberCount: 4600,
      privacy: CommunityPrivacy.public,
      createdById: 'user-sadia',
      createdAt: DateTime(2024, 8, 2),
    ),
  ];

  static final _seedPosts = <CommunityPost>[
    CommunityPost(
      id: 'post-system-design',
      authorId: 'user-wali',
      author: 'Wali Khan',
      role: 'Frontend Developer',
      body: 'Accepted my System Design interview call! What topics should I '
          'prioritize this week beyond caching and API design?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      tags: const ['Interview', 'System Design'],
      communityId: 'react-developers',
      likeCount: 24,
      commentCount: 8,
    ),
    CommunityPost(
      id: 'post-react-performance',
      authorId: 'user-alex',
      author: 'Alex Kim',
      role: 'React Developer',
      body: 'I collected the React performance resources that helped me reduce '
          'our dashboard load time. Sharing the checklist with everyone.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
      tags: const ['React', 'Resources'],
      communityId: 'react-developers',
      attachments: const [
        CommunityAttachment(
          id: 'attachment-performance-checklist',
          name: 'react-performance-checklist.pdf',
          kind: AttachmentKind.document,
          sizeBytes: 820000,
          url: 'https://example.com/react-performance-checklist.pdf',
        ),
      ],
      likeCount: 51,
      commentCount: 13,
    ),
  ];

  @override
  Future<CommunitySnapshot> loadCommunity() async {
    await _simulateLatency();
    return CommunitySnapshot(
      groups: List.unmodifiable(_groups),
      posts: List.unmodifiable(_posts),
    );
  }

  @override
  Future<CommunityGroup> createCommunity(
    CreateCommunityRequest request,
  ) async {
    await _simulateLatency();
    final group = CommunityGroup(
      id: 'community-${DateTime.now().microsecondsSinceEpoch}',
      name: request.name,
      description: request.description,
      category: request.category,
      visualKey: request.visualKey,
      memberCount: 1,
      privacy: request.privacy,
      createdById: 'current-user',
      createdAt: DateTime.now(),
      isJoined: true,
    );
    _groups = [group, ..._groups];
    return group;
  }

  @override
  Future<CommunityGroup> setMembership({
    required String communityId,
    required bool joined,
  }) async {
    await _simulateLatency();
    final index = _groups.indexWhere((group) => group.id == communityId);
    if (index < 0) throw StateError('Community not found.');
    final current = _groups[index];
    final updated = current.copyWith(
      isJoined: joined,
      memberCount: (current.memberCount + (joined ? 1 : -1)).clamp(0, 1 << 31),
    );
    _groups = [..._groups]..[index] = updated;
    return updated;
  }

  @override
  Future<CommunityPost> createPost(CreatePostRequest request) async {
    await _simulateLatency();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final attachments = request.attachments.indexed.map((entry) {
      final (index, pending) = entry;
      return CommunityAttachment(
        id: 'attachment-$timestamp-$index',
        name: pending.name,
        kind: pending.kind,
        sizeBytes: pending.sizeBytes,
        localPath: pending.localPath,
      );
    }).toList();
    final post = CommunityPost(
      id: 'post-$timestamp',
      authorId: 'current-user',
      author: 'Taznia',
      role: 'Job Sensei member',
      body: request.body,
      createdAt: DateTime.now(),
      tags: [
        request.type,
        if (request.communityName != null) request.communityName!,
      ],
      communityId: request.communityId,
      attachments: attachments,
    );
    _posts = [post, ..._posts];
    return post;
  }

  @override
  Future<CommunityPost> togglePostLike(String postId) {
    return _updatePost(postId, (post) {
      final liked = !post.isLiked;
      return post.copyWith(
        isLiked: liked,
        likeCount: post.likeCount + (liked ? 1 : -1),
      );
    });
  }

  @override
  Future<CommunityPost> togglePostFollow(String postId) {
    return _updatePost(
      postId,
      (post) => post.copyWith(isFollowed: !post.isFollowed),
    );
  }

  @override
  Future<CommunityPost> addComment({
    required String postId,
    required String body,
  }) {
    return _updatePost(
      postId,
      (post) => post.copyWith(commentCount: post.commentCount + 1),
    );
  }

  Future<CommunityPost> _updatePost(
    String postId,
    CommunityPost Function(CommunityPost post) update,
  ) async {
    await _simulateLatency();
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index < 0) throw StateError('Post not found.');
    final updated = update(_posts[index]);
    _posts = [..._posts]..[index] = updated;
    return updated;
  }

  Future<void> _simulateLatency() =>
      Future<void>.delayed(const Duration(milliseconds: 120));
}
