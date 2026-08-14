import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../shared/models/community_models.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  int _filter = 0;

  final _groups = <CommunityGroup>[
    CommunityGroup(
      name: 'React Developers',
      description: 'Hooks, architecture, frontend careers',
      members: '2.4k',
      icon: Icons.code_rounded,
      color: AppColors.primary,
      isJoined: true,
    ),
    CommunityGroup(
      name: 'Product Managers',
      description: 'Product thinking and leadership',
      members: '1.8k',
      icon: Icons.view_kanban_rounded,
      color: AppColors.violet,
    ),
    CommunityGroup(
      name: 'Data Scientists',
      description: 'ML, analytics, and data careers',
      members: '3.1k',
      icon: Icons.query_stats_rounded,
      color: AppColors.success,
    ),
    CommunityGroup(
      name: 'Flutter Developers',
      description: 'Dart, mobile UI, and clean code',
      members: '1.2k',
      icon: Icons.flutter_dash_rounded,
      color: AppColors.cyan,
    ),
    CommunityGroup(
      name: 'UI Designers',
      description: 'Figma, UX research, design systems',
      members: '2.7k',
      icon: Icons.palette_outlined,
      color: AppColors.danger,
    ),
    CommunityGroup(
      name: 'Fresh Graduates',
      description: 'First jobs, portfolios, interviews',
      members: '4.6k',
      icon: Icons.school_rounded,
      color: AppColors.warning,
    ),
  ];

  final _posts = <CommunityPost>[
    CommunityPost(
      author: 'Wali Khan',
      role: 'Frontend Developer',
      body: 'Accepted my System Design interview call! What topics should I '
          'prioritize this week beyond caching and API design?',
      time: '10 min ago',
      tags: ['Interview', 'System Design'],
      likes: 24,
      comments: 8,
    ),
    CommunityPost(
      author: 'Alex Kim',
      role: 'React Developer',
      body: 'I collected the React performance resources that helped me reduce '
          'our dashboard load time. Sharing the checklist with everyone.',
      time: '42 min ago',
      tags: ['React', 'Resources'],
      likes: 51,
      comments: 13,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CommunityGroup> get _visibleGroups {
    return _groups.where((group) {
      final matchesSearch =
          group.name.toLowerCase().contains(_query.toLowerCase()) ||
              group.description.toLowerCase().contains(_query.toLowerCase());
      final matchesFilter = _filter == 0 || (_filter == 1 && group.isJoined);
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _createPost() async {
    final post = await Navigator.of(context).push<CommunityPost>(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (post == null || !mounted) return;
    setState(() => _posts.insert(0, post));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your post is now live.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
            sliver: SliverList.list(
              children: [
                ScreenIntro(
                  eyebrow: 'Grow together',
                  title: 'Community',
                  description:
                      'Find your people, ask better questions, and share what you learn.',
                  trailing: IconButton.filled(
                    tooltip: 'Create post',
                    onPressed: _createPost,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search communities or skills',
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
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Discover'),
                      selected: _filter == 0,
                      onSelected: (_) => setState(() => _filter = 0),
                    ),
                    ChoiceChip(
                      label: const Text('My groups'),
                      selected: _filter == 1,
                      onSelected: (_) => setState(() => _filter = 1),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SectionTitle(
                    _filter == 0 ? 'Popular communities' : 'My communities'),
                const SizedBox(height: 12),
              ],
            ),
          ),
          if (_visibleGroups.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.groups_2_outlined,
                title: 'No communities found',
                message: 'Try another search or discover a new group.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverGrid.builder(
                itemCount: _visibleGroups.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisExtent: 186,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final group = _visibleGroups[index];
                  return _GroupCard(
                    group: group,
                    onOpen: () => Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => CommunityDetailScreen(
                              group: group,
                              posts: _posts,
                            ),
                          ),
                        )
                        .then((_) => setState(() {})),
                    onJoin: () =>
                        setState(() => group.isJoined = !group.isJoined),
                  );
                },
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 12),
            sliver: SliverToBoxAdapter(
              child: SectionTitle(
                'Trending discussions',
                action: 'Create post',
                onAction: _createPost,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
            sliver: SliverList.separated(
              itemCount: _posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _PostCard(
                post: _posts[index],
                onChanged: () => setState(() {}),
              ),
            ),
          ),
        ],
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: group.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(group.icon, color: group.color),
                  ),
                  const Spacer(),
                  Text(
                    '${group.members} members',
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Text(
                group.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                group.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 34,
                child: group.isJoined
                    ? OutlinedButton(
                        onPressed: onJoin,
                        child: const Text('Joined'),
                      )
                    : FilledButton(
                        onPressed: onJoin, child: const Text('Join')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen({
    super.key,
    required this.group,
    required this.posts,
  });

  final CommunityGroup group;
  final List<CommunityPost> posts;

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  Future<void> _createPost() async {
    final post = await Navigator.of(context).push<CommunityPost>(
      MaterialPageRoute(
          builder: (_) => CreatePostScreen(group: widget.group.name)),
    );
    if (post != null) setState(() => widget.posts.insert(0, post));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.group.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPost,
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.group.color, AppColors.cyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(widget.group.icon, color: Colors.white, size: 34),
                const SizedBox(height: 18),
                Text(
                  widget.group.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(widget.group.description,
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.groups_2_outlined,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text('${widget.group.members} members',
                        style: const TextStyle(color: Colors.white)),
                    const Spacer(),
                    FilledButton.tonal(
                      onPressed: () => setState(
                        () => widget.group.isJoined = !widget.group.isJoined,
                      ),
                      child:
                          Text(widget.group.isJoined ? 'Joined' : 'Join group'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Community discussions'),
          const SizedBox(height: 12),
          ...widget.posts.map((post) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PostCard(post: post, onChanged: () => setState(() {})),
              )),
        ],
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({required this.post, required this.onChanged});

  final CommunityPost post;
  final VoidCallback onChanged;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _liked = false;

  void _showComments() {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
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
              controller: controller,
              autofocus: true,
              maxLines: 3,
              decoration:
                  const InputDecoration(hintText: 'Write a helpful reply…'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    widget.post.comments++;
                    widget.onChanged();
                  }
                  Navigator.pop(context);
                },
                child: const Text('Post reply'),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(controller.dispose);
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
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: Text(widget.post.author.characters.first,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.post.author,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('${widget.post.role} · ${widget.post.time}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz_rounded, color: AppColors.muted),
              ],
            ),
            const SizedBox(height: 14),
            Text(widget.post.body),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  widget.post.tags.map((tag) => AppBadge(label: tag)).toList(),
            ),
            const Divider(height: 26),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _liked = !_liked;
                      widget.post.likes += _liked ? 1 : -1;
                    });
                    widget.onChanged();
                  },
                  icon: Icon(_liked ? Icons.favorite : Icons.favorite_border,
                      size: 18, color: _liked ? AppColors.danger : null),
                  label: Text('${widget.post.likes}'),
                ),
                TextButton.icon(
                  onPressed: _showComments,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: Text('${widget.post.comments}'),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Follow discussion',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Discussion followed.')),
                  ),
                  icon: const Icon(Icons.bookmark_border_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key, this.group});

  final String? group;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bodyController = TextEditingController();
  String _type = 'Question';

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  void _publish() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      CommunityPost(
        author: 'Taznia',
        role: 'Job Sensei member',
        body: _bodyController.text.trim(),
        time: 'Just now',
        tags: [_type, if (widget.group != null) widget.group!],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create post')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const ScreenIntro(
              eyebrow: 'Share with care',
              title: 'Start a conversation',
              description:
                  'Ask a focused question or share a resource that helps others grow.',
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Post type'),
              items: const [
                'Question',
                'Resource',
                'Experience',
                'Career update'
              ]
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _bodyController,
              maxLines: 8,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'What would you like to discuss?',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().length < 15) {
                  return 'Please add at least 15 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _publish,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Publish post'),
            ),
          ],
        ),
      ),
    );
  }
}
