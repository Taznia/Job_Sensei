import 'package:flutter_test/flutter_test.dart';
import 'package:jobsensei_frontend/features/community/data/repositories/in_memory_community_repository.dart';
import 'package:jobsensei_frontend/shared/models/community_models.dart';

void main() {
  group('InMemoryCommunityRepository', () {
    test('creates a joined community through a request object', () async {
      final repository = InMemoryCommunityRepository();

      final created = await repository.createCommunity(
        const CreateCommunityRequest(
          name: 'Cloud Engineers',
          description: 'A community for learning modern cloud engineering.',
          category: 'Technology',
          privacy: CommunityPrivacy.public,
          visualKey: 'code',
        ),
      );

      expect(created.id, isNotEmpty);
      expect(created.isJoined, isTrue);
      expect(created.memberCount, 1);
      final snapshot = await repository.loadCommunity();
      expect(snapshot.groups.first.id, created.id);
    });

    test('membership changes return a new immutable model', () async {
      final repository = InMemoryCommunityRepository();
      final before = (await repository.loadCommunity()).groups.first;

      final after = await repository.setMembership(
        communityId: before.id,
        joined: false,
      );

      expect(before.isJoined, isTrue);
      expect(after.isJoined, isFalse);
      expect(after.memberCount, before.memberCount - 1);
    });

    test('post request preserves attachment metadata', () async {
      final repository = InMemoryCommunityRepository();

      final post = await repository.createPost(
        const CreatePostRequest(
          body: 'Sharing a useful document for everyone in this community.',
          type: 'Resource',
          attachments: [
            PendingAttachment(
              name: 'career-guide.pdf',
              kind: AttachmentKind.document,
              sizeBytes: 125000,
              extension: 'pdf',
            ),
          ],
        ),
      );

      expect(post.attachments, hasLength(1));
      expect(post.attachments.single.name, 'career-guide.pdf');
      expect(post.attachments.single.kind, AttachmentKind.document);
    });

    test('comments are visible and new replies are preserved', () async {
      final repository = InMemoryCommunityRepository();
      final before = (await repository.loadCommunity()).posts.first;

      expect(before.comments, isNotEmpty);
      final updated = await repository.addComment(
        postId: before.id,
        body: 'A new helpful reply.',
      );

      expect(updated.commentCount, before.commentCount + 1);
      expect(updated.comments.length, before.comments.length + 1);
      expect(updated.comments.last.author, 'Taznia');
      expect(updated.comments.last.body, 'A new helpful reply.');
    });
  });
}
