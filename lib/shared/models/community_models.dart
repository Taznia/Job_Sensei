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

  factory CommunityGroup.fromJson(Map<String, dynamic> json) {
    return CommunityGroup(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      visualKey: json['visualKey'] as String? ?? 'code',
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      privacy: json['privacy'] == 'private'
          ? CommunityPrivacy.private
          : CommunityPrivacy.public,
      createdById: json['createdById'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isJoined: json['isJoined'] == true,
    );
  }

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

  factory CommunityAttachment.fromJson(Map<String, dynamic> json) {
    return CommunityAttachment(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      kind: json['kind'] == 'image'
          ? AttachmentKind.image
          : AttachmentKind.document,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      url: json['url'] as String?,
      localPath: json['localPath'] as String?,
    );
  }

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

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.authorId,
    required this.author,
    required this.body,
    required this.createdAt,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id'] as String,
      authorId: json['authorId'] as String? ?? '',
      author: json['author'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String authorId;
  final String author;
  final String body;
  final DateTime createdAt;
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
    this.comments = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isFollowed = false,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      authorId: json['authorId'] as String? ?? '',
      author: json['author'] as String? ?? '',
      role: json['role'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
      communityId: json['communityId'] as String?,
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .map((item) =>
              CommunityAttachment.fromJson(item as Map<String, dynamic>))
          .toList(),
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((item) =>
              CommunityComment.fromJson(item as Map<String, dynamic>))
          .toList(),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] == true,
      isFollowed: json['isFollowed'] == true,
    );
  }

  final String id;
  final String authorId;
  final String author;
  final String role;
  final String body;
  final DateTime createdAt;
  final List<String> tags;
  final String? communityId;
  final List<CommunityAttachment> attachments;
  final List<CommunityComment> comments;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isFollowed;

  CommunityPost copyWith({
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    bool? isFollowed,
    List<CommunityComment>? comments,
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
      comments: comments ?? this.comments,
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
