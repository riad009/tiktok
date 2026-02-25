import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_persistence.dart';
import '../../../core/data/mock_data.dart';
import '../../../models/user_model.dart';
import '../../../models/video_model.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../dashboard/presentation/creator_dashboard_screen.dart';
import '../../monetization/presentation/monetization_screen.dart';
import '../../admin/presentation/admin_panel_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId; // null = current user
  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _targetUid =>
      widget.userId ?? ref.read(currentUidProvider) ?? '';

  bool get _isOwnProfile =>
      widget.userId == null ||
      widget.userId == ref.read(currentUidProvider);

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider(_targetUid));
    final videosAsync = ref.watch(userVideosProvider(_targetUid));

    return Scaffold(
      appBar: AppBar(
        title: userAsync.when(
          data: (u) => Text('@${u?.username ?? ''}'),
          loading: () => const SizedBox.shrink(),
          error: (_, _s) => const Text('Profile'),
        ),
        actions: [
          if (_isOwnProfile)
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () {
                AuthPersistence.clear();
                ref.read(authUserProvider.notifier).state = null;
              },
            ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }
          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverToBoxAdapter(child: _buildHeader(user)),
              SliverToBoxAdapter(
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  isScrollable: false,
                  labelPadding: EdgeInsets.zero,
                  tabs: const [
                    Tab(icon: Icon(Icons.video_collection_rounded, size: 22)),
                    Tab(icon: Icon(Icons.photo_library_rounded, size: 22)),
                    Tab(icon: Icon(Icons.favorite_rounded, size: 22)),
                    Tab(icon: Icon(Icons.repeat_rounded, size: 22)),
                    Tab(icon: Icon(Icons.live_tv_rounded, size: 22)),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                // ── Reels tab ────────────────────────────
                videosAsync.when(
                  data: (videos) {
                    final reels = videos.where((v) => v.videoUrl.isNotEmpty).toList();
                    if (reels.isEmpty) {
                      return _buildEmptyTab(Icons.video_collection_outlined, 'No reels yet');
                    }
                    return _buildPostsGrid(reels);
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),

                // ── Photos tab ───────────────────────────
                _buildPhotosTab(),

                // ── Liked tab ────────────────────────────
                _buildLikedTab(),

                // ── Reposts tab ──────────────────────────
                _buildRepostsTab(),

                // ── Livestreams tab ──────────────────────
                _buildLivestreamsTab(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  // ── Post Grid builder ──────────────────────────────────────────

  Widget _buildPostsGrid(List<VideoModel> posts) {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 9 / 16,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (_, i) {
        final v = posts[i];
        final displayUrl = v.imageUrl.isNotEmpty
            ? v.imageUrl
            : v.thumbnailUrl.isNotEmpty
                ? v.thumbnailUrl
                : '';
        return Stack(
          fit: StackFit.expand,
          children: [
            displayUrl.isNotEmpty
                ? Image.network(displayUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.darkCard,
                      child: const Center(child: Icon(Icons.broken_image, color: AppColors.textMuted)),
                    ))
                : Container(
                    color: AppColors.darkCard,
                    child: const Center(
                      child: Icon(Icons.videocam_rounded, color: AppColors.textMuted))),
            // Overlay gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              left: 4,
              child: Row(
                children: [
                  Icon(
                    v.videoUrl.isNotEmpty ? Icons.play_arrow_rounded : Icons.photo,
                    color: Colors.white, size: 14),
                  const SizedBox(width: 2),
                  Text(_formatCount(v.viewsCount),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (v.likesCount > 0)
              Positioned(
                bottom: 4,
                right: 4,
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 12),
                    const SizedBox(width: 2),
                    Text(_formatCount(v.likesCount),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPhotosTab() {
    final photos = MockData.imagePosts
        .where((v) => v.userId == _targetUid && v.imageUrl.isNotEmpty)
        .toList();
    // Also include videos that have images
    final allPhotos = [
      ...photos,
      ...MockData.videos.where((v) => v.userId == _targetUid && v.imageUrl.isNotEmpty),
    ];

    if (allPhotos.isEmpty) {
      return _buildEmptyTab(Icons.photo_library_outlined, 'No photos yet');
    }
    return _buildPostsGrid(allPhotos);
  }

  Widget _buildLikedTab() {
    final liked = MockData.likedPosts;
    if (liked.isEmpty) {
      return _buildEmptyTab(Icons.favorite_border, 'No liked posts');
    }
    return _buildPostsGrid(liked);
  }

  Widget _buildRepostsTab() {
    final reposts = MockData.repostedPosts;
    if (reposts.isEmpty) {
      return _buildEmptyTab(Icons.repeat_rounded, 'No reposts yet');
    }
    return _buildPostsGrid(reposts);
  }

  Widget _buildLivestreamsTab() {
    final streams = MockData.livestreamsForUser(_targetUid);
    // If no user-specific streams, show all replays
    final displayStreams = streams.isNotEmpty ? streams : MockData.replays;

    if (displayStreams.isEmpty) {
      return _buildEmptyTab(Icons.live_tv_outlined, 'No livestreams yet');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: displayStreams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final stream = displayStreams[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 80, height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.darkBorder,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        'https://picsum.photos/seed/live${stream.id}/160/120',
                        fit: BoxFit.cover,
                        width: 80, height: 60,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: stream.isLive ? AppColors.liveRed : Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        stream.isLive ? 'LIVE' : 'REPLAY',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stream.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.visibility, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text('${_formatCount(stream.viewerCount)} viewers',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(width: 10),
                        Icon(Icons.favorite, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(_formatCount(stream.totalReactions),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              if (!stream.isLive)
                IconButton(
                  icon: const Icon(Icons.play_circle_outline, color: AppColors.primary),
                  onPressed: () {},
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyTab(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────

  Widget _buildHeader(UserModel user) {
    final isFollowing = _isOwnProfile
        ? const AsyncValue<bool>.data(false)
        : ref.watch(isFollowingProvider(_targetUid));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar
          GestureDetector(
            onTap: _isOwnProfile ? _changePhoto : null,
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.darkCard,
              backgroundImage:
                  user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
              child: user.photoUrl.isEmpty
                  ? Text(user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.w800))
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(user.displayName,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800)),
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(user.bio,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
          ],
          const SizedBox(height: 20),
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatColumn(label: 'Following', count: user.followingCount),
              _StatColumn(label: 'Followers', count: user.followersCount),
              _StatColumn(label: 'Likes', count: user.postsCount),
            ],
          ),
          const SizedBox(height: 16),
          // Action buttons
          if (_isOwnProfile) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editProfile(user),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.darkBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Creator Tools menu
            _buildMenuTile(
              icon: Icons.analytics_outlined,
              label: 'Creator Dashboard',
              color: AppColors.secondary,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CreatorDashboardScreen())),
            ),
            _buildMenuTile(
              icon: Icons.monetization_on_outlined,
              label: 'Monetization',
              color: AppColors.goldBadge,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MonetizationScreen())),
            ),
            if (user.isAdmin)
              _buildMenuTile(
                icon: Icons.admin_panel_settings,
                label: 'Admin Panel',
                color: AppColors.error,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AdminPanelScreen())),
              ),
          ]
          else
            Row(
              children: [
                Expanded(
                  child: isFollowing.when(
                    data: (following) => GradientButton(
                      text: following ? 'Following' : 'Follow',
                      icon: following ? Icons.check_rounded : Icons.person_add_rounded,
                      onPressed: () => _toggleFollow(following),
                    ),
                    loading: () => const SizedBox(height: 44),
                    error: (_, _s) => const SizedBox(height: 44),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _startChat(user),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.darkBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  void _toggleFollow(bool currentlyFollowing) {
    final currentUid = ref.read(currentUidProvider);
    if (currentUid == null) return;
    final repo = ref.read(userRepositoryProvider);
    if (currentlyFollowing) {
      repo.unfollowUser(currentUid, _targetUid);
    } else {
      repo.followUser(currentUid, _targetUid);
    }
  }

  void _startChat(UserModel otherUser) async {
    final currentUser = ref.read(authUserProvider);
    if (currentUser == null) return;

    final convo = await ApiService.getOrCreateConversation(
      currentUser.uid,
      otherUser.uid,
    );

    if (convo != null && mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: convo.id,
          otherUserName: otherUser.displayName,
        ),
      ));
    }
  }

  void _changePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (image == null) return;

    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    await ref.read(userRepositoryProvider).uploadProfilePhoto(uid, File(image.path));
  }

  void _editProfile(UserModel user) {
    final nameController = TextEditingController(text: user.displayName);
    final bioController = TextEditingController(text: user.bio);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Edit Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Save',
              icon: Icons.check_rounded,
              onPressed: () {
                ref.read(userRepositoryProvider).updateProfile(
                  user.uid,
                  displayName: nameController.text.trim(),
                  bio: bioController.text.trim(),
                );
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final int count;
  const _StatColumn({required this.label, required this.count});

  String get _formatted {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_formatted,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }
}
