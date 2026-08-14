import 'dart:typed_data';

enum CommunityPrivacy { public, private }

enum AttachmentKind { image, document }

class CommunityGroup {
  const CommunityGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.visualKey,
    required this.memberCount,
    required this.privacy,
    required this.createdById,
    required this.createdAt,
    this.isJoined = false,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String visualKey;
  final int memberCount;
  final CommunityPrivacy privacy;
  final String createdById;
  final DateTime createdAt;
  final bool isJoined;

  CommunityGroup copyWith({
    int? memberCount,
    bool? isJoined,
  }) {
    return CommunityGroup(
      id: id,
      name: name,
      description: description,
      category: category,
      visualKey: visualKey,
      memberCount: memberCount ?? this.memberCount,
      privacy: privacy,
      createdById: createdById,
      createdAt: createdAt,
      isJoined: isJoined ?? this.isJoined,
    );
  }
}

class CommunityAttachment {
  const CommunityAttachment({
    required this.id,
    required this.name,
    required this.kind,
    required this.sizeBytes,
    this.url,
    this.localPath,
  });

  final String id;
  final String name;
  final AttachmentKind kind;
  final int sizeBytes;
  final String? url;
  final String? localPath;
}

/// A local attachment waiting to be uploaded by a repository implementation.
/// A REST/Firebase repository can upload [bytes] or [localPath], then save the
/// resulting URL as a [CommunityAttachment].
class PendingAttachment {
  const PendingAttachment({
    required this.name,
    required this.kind,
    required this.sizeBytes,
    this.extension,
    this.localPath,
    this.bytes,
  });

  final String name;
  final AttachmentKind kind;
  final int sizeBytes;
  final String? extension;
  final String? localPath;
  final Uint8List? bytes;
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.author,
    required this.role,
    required this.body,
    required this.createdAt,
    required this.tags,
    this.communityId,
    this.attachments = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isFollowed = false,
  });

  final String id;
  final String authorId;
  final String author;
  final String role;
  final String body;
  final DateTime createdAt;
  final List<String> tags;
  final String? communityId;
  final List<CommunityAttachment> attachments;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isFollowed;

  CommunityPost copyWith({
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    bool? isFollowed,
  }) {
    return CommunityPost(
      id: id,
      authorId: authorId,
      author: author,
      role: role,
      body: body,
      createdAt: createdAt,
      tags: tags,
      communityId: communityId,
      attachments: attachments,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }
}

class CreateCommunityRequest {
  const CreateCommunityRequest({
    required this.name,
    required this.description,
    required this.category,
    required this.privacy,
    required this.visualKey,
  });

  final String name;
  final String description;
  final String category;
  final CommunityPrivacy privacy;
  final String visualKey;
}

class CreatePostRequest {
  const CreatePostRequest({
    required this.body,
    required this.type,
    this.communityId,
    this.communityName,
    this.attachments = const [],
  });

  final String body;
  final String type;
  final String? communityId;
  final String? communityName;
  final List<PendingAttachment> attachments;
}

class CommunitySnapshot {
  const CommunitySnapshot({required this.groups, required this.posts});

  final List<CommunityGroup> groups;
  final List<CommunityPost> posts;
}
