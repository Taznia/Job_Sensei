import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/models/community_models.dart';
import '../../data/repositories/in_memory_community_repository.dart';
import '../../domain/repositories/community_repository.dart';
import '../controllers/community_controller.dart';
import '../widgets/community_visuals.dart';
import 'create_community_screen.dart';
import 'create_post_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key, this.repository});

  final CommunityRepository? repository;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late final CommunityController _controller = CommunityController(
    widget.repository ?? InMemoryCommunityRepository(),
  )..addListener(_refresh);
  final _searchController = TextEditingController();
  String _query = '';
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  List<CommunityGroup> get _visibleGroups {
    final normalizedQuery = _query.trim().toLowerCase();
    return _controller.groups.where((group) {
      final matchesSearch = normalizedQuery.isEmpty ||
          group.name.toLowerCase().contains(normalizedQuery) ||
          group.description.toLowerCase().contains(normalizedQuery) ||
          group.category.toLowerCase().contains(normalizedQuery);
      final matchesFilter = _filter == 0 || group.isJoined;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _createCommunity() async {
    final request = await Navigator.of(context).push<CreateCommunityRequest>(
      MaterialPageRoute(builder: (_) => const CreateCommunityScreen()),
    );
    if (request == null || !mounted) return;
    final created = await _controller.createCommunity(request);
    if (created == null || !mounted) return;
    setState(() => _filter = 1);
    _showMessage('${created.name} was created successfully.');
  }

  Future<void> _createPost() async {
    final request = await Navigator.of(context).push<CreatePostRequest>(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (request == null || !mounted) return;
    final created = await _controller.createPost(request);
    if (created != null && mounted) _showMessage('Your post is now live.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final joinedCount =
        _controller.groups.where((group) => group.isJoined).length;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _controller.load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              sliver: SliverList.list(
                children: [
                  _CommunityHero(
                    groupCount: _controller.groups.length,
                    joinedCount: joinedCount,
                    onCreateCommunity: _createCommunity,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Search communities, roles, or skills',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CommunityFilter(
                    value: _filter,
                    joinedCount: joinedCount,
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                  const SizedBox(height: 22),
                  SectionTitle(
                    _filter == 0 ? 'Popular communities' : 'My communities',
                    action: _filter == 1 ? 'Discover' : null,
                    onAction: () => setState(() => _filter = 0),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            if (_controller.isLoading && _controller.groups.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_controller.errorMessage != null &&
                _controller.groups.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _LoadError(onRetry: _controller.load),
              )
            else if (_visibleGroups.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.groups_2_outlined,
                  title: _filter == 1
                      ? 'No joined communities yet'
                      : 'No communities found',
                  message: _filter == 1
                      ? 'Discover a group or create your own community.'
                      : 'Try another search term or category.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverGrid.builder(
                  itemCount: _visibleGroups.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    mainAxisExtent: 220,
                    crossAxisSpacing: 13,
                    mainAxisSpacing: 13,
                  ),
                  itemBuilder: (context, index) {
                    final group = _visibleGroups[index];
                    return _GroupCard(
                      group: group,
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CommunityDetailScreen(
                            communityId: group.id,
                            controller: _controller,
                          ),
                        ),
                      ),
                      onJoin: () async {
                        await _controller.joinCommunity(group.id);
                        if (mounted) _showMessage('Joined ${group.name}.');
                      },
                    );
                  },
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 30, 18, 12),
              sliver: SliverToBoxAdapter(
                child: SectionTitle(
                  'Trending discussions',
                  action: 'Create post',
                  onAction: _createPost,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
              sliver: SliverList.separated(
                itemCount: _controller.posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 13),
                itemBuilder: (context, index) => CommunityPostCard(
                  post: _controller.posts[index],
                  controller: _controller,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityHero extends StatelessWidget {
  const _CommunityHero({
    required this.groupCount,
    required this.joinedCount,
    required this.onCreateCommunity,
  });

  final int groupCount;
  final int joinedCount;
  final VoidCallback onCreateCommunity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B57D0), AppColors.primary, AppColors.cyan],
          stops: [0, 0.58, 1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.24),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -50,
            child: CircleAvatar(
              radius: 72,
              backgroundColor: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GROW TOGETHER',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Community',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Find your people. Build skills. Move careers forward.',
                          style: TextStyle(color: Colors.white70, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  IconButton.filled(
                    tooltip: 'Create community',
                    onPressed: onCreateCommunity,
                    icon: const Icon(Icons.add_rounded, size: 28),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(52, 52),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _HeroStat(
                      icon: Icons.explore_outlined,
                      label: '$groupCount discoverable'),
                  _HeroStat(
                      icon: Icons.favorite_outline_rounded,
                      label: '$joinedCount joined'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}

class _CommunityFilter extends StatelessWidget {
  const _CommunityFilter({
    required this.value,
    required this.joinedCount,
    required this.onChanged,
  });

  final int value;
  final int joinedCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterButton(
              selected: value == 0,
              label: 'Discover',
              icon: Icons.explore_outlined,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _FilterButton(
              selected: value == 1,
              label: 'My groups ($joinedCount)',
              icon: Icons.groups_2_outlined,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 17, color: selected ? Colors.white : AppColors.muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.onOpen,
    required this.onJoin,
  });

  final CommunityGroup group;
  final VoidCallback onOpen;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final color = CommunityVisuals.colorFor(group.visualKey);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient:
                      LinearGradient(colors: [color, color.withOpacity(0.35)]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 17, 15, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.11),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(CommunityVisuals.iconFor(group.visualKey),
                            color: color),
                      ),
                      const Spacer(),
                      if (group.privacy == CommunityPrivacy.private)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.lock_outline_rounded,
                              size: 15, color: AppColors.muted),
                        ),
                      Text(
                        '${CommunityVisuals.memberCount(group.memberCount)} members',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppBadge(label: group.category, color: color),
                  const SizedBox(height: 8),
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    group.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: group.isJoined
                        ? FilledButton.tonalIcon(
                            onPressed: onOpen,
                            icon: const Icon(Icons.arrow_forward_rounded,
                                size: 16),
                            label: const Text('Open'),
                          )
                        : FilledButton.icon(
                            onPressed: onJoin,
                            icon: const Icon(Icons.add_rounded, size: 17),
                            label: const Text('Join'),
                            style:
                                FilledButton.styleFrom(backgroundColor: color),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen({
    super.key,
    required this.communityId,
    required this.controller,
  });

  final String communityId;
  final CommunityController controller;

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  CommunityGroup get _group => widget.controller.groups.firstWhere(
        (group) => group.id == widget.communityId,
      );

  List<CommunityPost> get _posts => widget.controller.posts
      .where((post) => post.communityId == widget.communityId)
      .toList();

  Future<void> _createPost() async {
    final group = _group;
    final request = await Navigator.of(context).push<CreatePostRequest>(
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(
          communityId: group.id,
          communityName: group.name,
        ),
      ),
    );
    if (request == null || !mounted) return;
    final post = await widget.controller.createPost(request);
    if (post != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post published.')),
      );
    }
  }

  Future<void> _leaveCommunity() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave ${_group.name}?'),
        content: const Text(
          'You can join again later. Your previous posts will remain in the community.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Leave community'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.controller.leaveCommunity(widget.communityId);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    final color = CommunityVisuals.colorFor(group.visualKey);
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          if (group.isJoined)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'leave') _leaveCommunity();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: AppColors.danger),
                      SizedBox(width: 10),
                      Text('Leave community'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: group.isJoined
          ? FloatingActionButton.extended(
              onPressed: _createPost,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Create post'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 96),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, Color.lerp(color, AppColors.cyan, 0.7)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        CommunityVisuals.iconFor(group.visualKey),
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const Spacer(),
                    _HeroStat(
                      icon: group.privacy == CommunityPrivacy.public
                          ? Icons.public_rounded
                          : Icons.lock_outline_rounded,
                      label: group.privacy.name,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  group.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(group.description,
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.groups_2_outlined,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${CommunityVisuals.memberCount(group.memberCount)} members',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const Spacer(),
                    if (group.isJoined)
                      const AppBadge(label: 'MEMBER', color: Colors.white)
                    else
                      FilledButton.tonal(
                        onPressed: () =>
                            widget.controller.joinCommunity(group.id),
                        child: const Text('Join group'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          SectionTitle(
            'Community discussions',
            action: group.isJoined ? 'Create post' : null,
            onAction: _createPost,
          ),
          const SizedBox(height: 12),
          if (_posts.isEmpty)
            const EmptyState(
              icon: Icons.forum_outlined,
              title: 'Start the first discussion',
              message:
                  'Ask a question or share a useful resource with this community.',
            )
          else
            ..._posts.map((post) => Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: CommunityPostCard(
                      post: post, controller: widget.controller),
                )),
        ],
      ),
    );
  }
}

class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    required this.controller,
  });

  final CommunityPost post;
  final CommunityController controller;

  Future<void> _showComments(BuildContext context) async {
    final textController = TextEditingController();
    final comment = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          4,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Join the discussion'),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  const InputDecoration(hintText: 'Write a helpful reply…'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final value = textController.text.trim();
                  if (value.isNotEmpty) Navigator.pop(context, value);
                },
                child: const Text('Post reply'),
              ),
            ),
          ],
        ),
      ),
    );
    textController.dispose();
    if (comment != null) await controller.addComment(post.id, comment);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.cyan],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      post.author.characters.first,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.author,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text(
                        '${post.role} · ${CommunityVisuals.relativeTime(post.createdAt)}',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: post.isFollowed
                      ? 'Unfollow discussion'
                      : 'Follow discussion',
                  onPressed: () => controller.toggleFollow(post.id),
                  icon: Icon(
                    post.isFollowed
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color:
                        post.isFollowed ? AppColors.primary : AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(post.body, style: const TextStyle(height: 1.5)),
            if (post.attachments.isNotEmpty) ...[
              const SizedBox(height: 13),
              ...post.attachments.map((attachment) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PostAttachment(attachment: attachment),
                  )),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: post.tags.map((tag) => AppBadge(label: tag)).toList(),
            ),
            const Divider(height: 26),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => controller.toggleLike(post.id),
                  icon: Icon(
                    post.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color: post.isLiked ? AppColors.danger : null,
                  ),
                  label: Text('${post.likeCount}'),
                ),
                TextButton.icon(
                  onPressed: () => _showComments(context),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: Text('${post.commentCount}'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PostAttachment extends StatelessWidget {
  const _PostAttachment({required this.attachment});

  final CommunityAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final isImage = attachment.kind == AttachmentKind.image;
    final color = isImage ? AppColors.primary : AppColors.violet;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isImage ? Icons.image_outlined : Icons.description_outlined,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12),
                ),
                Text(
                  CommunityVisuals.fileSize(attachment.sizeBytes),
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          Icon(Icons.open_in_new_rounded, size: 17, color: color),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.muted),
          const SizedBox(height: 12),
          const Text('Could not load communities.'),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
