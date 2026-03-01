import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
  int _selectedTab = 0;

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

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.screenGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: userAsync.when(
          data: (u) => Text('@${u?.username ?? ''}'),
          loading: () => const SizedBox.shrink(),
          error: (_, _s) => const Text('Profile'),
        ),
        actions: [
          if (_isOwnProfile)
            CupertinoButton(
              padding: const EdgeInsets.only(right: 8),
              child: const Icon(CupertinoIcons.square_arrow_right, color: AppColors.textMuted, size: 22),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: _selectedTab,
                    backgroundColor: AppColors.iosTertiaryGroupedBg,
                    thumbColor: AppColors.darkBorder,
                    children: const {
                      0: Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6), child: Icon(CupertinoIcons.film, size: 18)),
                      1: Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6), child: Icon(CupertinoIcons.photo, size: 18)),
                      2: Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6), child: Icon(CupertinoIcons.heart_fill, size: 18)),
                      3: Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6), child: Icon(CupertinoIcons.arrow_2_squarepath, size: 18)),
                      4: Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6), child: Icon(CupertinoIcons.video_camera, size: 18)),
                    },
                    onValueChanged: (val) {
                      setState(() {
                        _selectedTab = val!;
                        _tabController.animateTo(val);
                      });
                    },
                  ),
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
                      return _buildEmptyTab(CupertinoIcons.film, 'No reels yet');
                    }
                    return _buildPostsGrid(reels);
                  },
                  loading: () => const Center(child: CupertinoActivityIndicator(radius: 12)),
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
        loading: () => const Center(child: CupertinoActivityIndicator(radius: 14)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
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
                      child: const Center(child: Icon(CupertinoIcons.photo_fill, color: AppColors.textMuted)),
                    ))
                : Container(
                    color: AppColors.darkCard,
                    child: const Center(
                      child: Icon(CupertinoIcons.videocam_fill, color: AppColors.textMuted))),
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
                    v.videoUrl.isNotEmpty ? CupertinoIcons.play_fill : CupertinoIcons.photo,
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
                    const Icon(CupertinoIcons.heart_fill, color: Colors.white, size: 12),
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
    final videosAsync = ref.watch(userVideosProvider(_targetUid));
    return videosAsync.when(
      data: (videos) {
        final photos = videos.where((v) => v.imageUrl.isNotEmpty).toList();
        if (photos.isEmpty) {
          return _buildEmptyTab(CupertinoIcons.photo, 'No photos yet');
        }
        return _buildPostsGrid(photos);
      },
      loading: () => const Center(child: CupertinoActivityIndicator(radius: 12)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildLikedTab() {
    return _buildEmptyTab(CupertinoIcons.heart, 'Liked posts will appear here');
  }

  Widget _buildRepostsTab() {
    return _buildEmptyTab(CupertinoIcons.arrow_2_squarepath, 'Reposts will appear here');
  }

  Widget _buildLivestreamsTab() {
    return _buildEmptyTab(CupertinoIcons.video_camera, 'Past livestreams will appear here');
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
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _editProfile(user),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.iosTertiaryGroupedBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.pencil, size: 16, color: AppColors.textPrimary),
                          SizedBox(width: 6),
                          Text('Edit Profile', style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Creator Tools menu
            _buildMenuTile(
              icon: CupertinoIcons.chart_bar_alt_fill,
              label: 'Creator Dashboard',
              color: AppColors.secondary,
              onTap: () => Navigator.push(context,
                  CupertinoPageRoute(builder: (_) => const CreatorDashboardScreen())),
            ),
            _buildMenuTile(
              icon: CupertinoIcons.money_dollar_circle,
              label: 'Monetization',
              color: AppColors.goldBadge,
              onTap: () => Navigator.push(context,
                  CupertinoPageRoute(builder: (_) => const MonetizationScreen())),
            ),
            if (user.isAdmin)
              _buildMenuTile(
                icon: CupertinoIcons.shield_lefthalf_fill,
                label: 'Admin Panel',
                color: AppColors.error,
                onTap: () => Navigator.push(context,
                    CupertinoPageRoute(builder: (_) => const AdminPanelScreen())),
              ),
          ]
          else
            Row(
              children: [
                Expanded(
                  child: isFollowing.when(
                    data: (following) => GradientButton(
                      text: following ? 'Following' : 'Follow',
                      icon: following ? CupertinoIcons.checkmark_alt : CupertinoIcons.person_add,
                      onPressed: () => _toggleFollow(following),
                    ),
                    loading: () => const SizedBox(height: 44),
                    error: (_, _s) => const SizedBox(height: 44),
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _startChat(user),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.iosTertiaryGroupedBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(CupertinoIcons.chat_bubble, size: 16, color: AppColors.textPrimary),
                        SizedBox(width: 6),
                        Text('Message', style: TextStyle(
                          color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
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
            Icon(CupertinoIcons.chevron_right, color: AppColors.textMuted, size: 18),
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
      Navigator.of(context).push(CupertinoPageRoute(
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
              icon: CupertinoIcons.checkmark_alt,
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
