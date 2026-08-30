import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobsensei_frontend/features/community/data/repositories/in_memory_community_repository.dart';
import 'package:jobsensei_frontend/features/community/presentation/controllers/community_controller.dart';
import 'package:jobsensei_frontend/features/community/presentation/screens/community_screen.dart';
import 'package:jobsensei_frontend/features/community/presentation/screens/create_community_screen.dart';
import 'package:jobsensei_frontend/shared/models/community_models.dart';

void main() {
  testWidgets('create community no longer offers private access',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CreateCommunityScreen()),
    );

    expect(find.text('Private'), findsNothing);
    expect(find.text('Community access'), findsNothing);
    expect(find.byIcon(Icons.public_rounded), findsOneWidget);
  });

  testWidgets('community creator can manage members and remove posts',
      (tester) async {
    final repository = _OwnerCommunityRepository();
    final controller = CommunityController(repository);
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        home: CommunityDetailScreen(
          communityId: repository.group.id,
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CREATOR'), findsOneWidget);
    expect(find.byTooltip('Manage members'), findsOneWidget);
    expect(find.byTooltip('Remove post'), findsOneWidget);

    await tester.tap(find.byTooltip('Manage members'));
    await tester.pumpAndSettle();

    expect(find.text('Taznia'), findsOneWidget);
    expect(find.text('Wali Khan'), findsWidgets);
    expect(find.text('OWNER'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Remove'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove member'));
    await tester.pumpAndSettle();

    expect(controller.groups.single.memberCount, 1);
    expect(controller.groups.single.members, hasLength(1));

    await tester.tap(find.byTooltip('Remove post'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove post'));
    await tester.pumpAndSettle();

    expect(controller.posts, isEmpty);
    expect(find.text('Start the first discussion'), findsOneWidget);
    controller.dispose();
  });
}

class _OwnerCommunityRepository extends InMemoryCommunityRepository {
  CommunityGroup group = CommunityGroup(
    id: 'taznia-community',
    name: 'Flutter Bangladesh',
    description: 'A public community for Flutter developers.',
    category: 'Technology',
    visualKey: 'flutter',
    memberCount: 2,
    privacy: CommunityPrivacy.public,
    createdById: 'user-taznia',
    createdAt: DateTime(2026, 8, 1),
    isJoined: true,
    isOwner: true,
    members: const [
      CommunityMember(
        id: 'user-taznia',
        name: 'Taznia',
        email: 'demo@jobsensei.app',
        role: 'seeker',
      ),
      CommunityMember(
        id: 'user-wali',
        name: 'Wali Khan',
        email: 'wali@jobsensei.app',
        role: 'seeker',
      ),
    ],
  );

  List<CommunityPost> communityPosts = [
    CommunityPost(
      id: 'wali-post',
      authorId: 'user-wali',
      author: 'Wali Khan',
      role: 'Frontend Developer',
      body: 'Sharing a useful Flutter testing resource with everyone.',
      createdAt: DateTime(2026, 8, 20),
      tags: const ['Flutter'],
      communityId: 'taznia-community',
    ),
  ];

  @override
  Future<CommunitySnapshot> loadCommunity() async {
    return CommunitySnapshot(groups: [group], posts: communityPosts);
  }

  @override
  Future<CommunityGroup> removeMember({
    required String communityId,
    required String userId,
  }) async {
    final members =
        group.members.where((member) => member.id != userId).toList();
    group = group.copyWith(
      members: members,
      memberCount: members.length,
    );
    return group;
  }

  @override
  Future<void> deletePost(String postId) async {
    communityPosts = communityPosts.where((post) => post.id != postId).toList();
  }
}
