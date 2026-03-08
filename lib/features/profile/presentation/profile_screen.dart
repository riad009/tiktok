import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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
      backgroundColor: AppColors.darkBg,
      extendBodyBehindAppBar: true,
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
                child: Text('User not found',
                    style: TextStyle(color: AppColors.textMuted)));
          }
          return CustomScrollView(
            slivers: [
              // ── Banner + Avatar header ─────────────────────
              SliverToBoxAdapter(child: _buildBannerHeader(user)),

              // ── Stats row ──────────────────────────────────
              SliverToBoxAdapter(child: _buildStatsRow(user)),

              // ── Action buttons ─────────────────────────────
              SliverToBoxAdapter(child: _buildActions(user)),

              // ── Photo grid ─────────────────────────────────
              videosAsync.when(
                data: (videos) {
                  final photos =
                      videos.where((v) => v.imageUrl.isNotEmpty).toList();
                  if (photos.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.photo,
                                size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text('No posts yet',
                                style: GoogleFonts.inter(
                                    color: AppColors.textMuted,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  }
                  return _buildPhotoGrid(photos);
                },
                loading: () => const SliverFillRemaining(
                    child: Center(
                        child: CupertinoActivityIndicator(
                            radius: 12, color: AppColors.primary))),
                error: (e, _) => SliverFillRemaining(
                    child: Center(child: Text('Error: $e'))),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
        loading: () => const Center(
            child:
                CupertinoActivityIndicator(radius: 14, color: AppColors.primary)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.textMuted))),
      ),
    );
  }

  // ── Banner + Avatar ────────────────────────────────────────────
  Widget _buildBannerHeader(UserModel user) {
    final bannerUrl =
        'https://picsum.photos/seed/${user.username}/800/400';
    final avatarUrl = user.photoUrl.isNotEmpty
        ? user.photoUrl
        : 'https://i.pravatar.cc/150?u=${user.username}';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Banner image
        SizedBox(
          height: 220,
          width: double.infinity,
          child: Image.network(
            bannerUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.4),
                    AppColors.darkBg,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.darkBg.withOpacity(0.6),
                  AppColors.darkBg,
                ],
                stops: const [0.3, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // Top bar: back + menu
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (Navigator.of(context).canPop())
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 20),
                  ),
                )
              else
                const SizedBox(width: 40),
              GestureDetector(
                onTap: () => _showProfileMenu(user),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_horiz,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),

        // Avatar + Name + Bio
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Avatar with online dot
              GestureDetector(
                onTap: _isOwnProfile ? _changePhoto : null,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primary, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.darkCard,
                        backgroundImage: NetworkImage(avatarUrl),
                      ),
                    ),
                    // Green online dot
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.darkBg, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Name
              Text(
                (user.displayName.isNotEmpty &&
                        !user.displayName.contains('@'))
                    ? user.displayName
                    : '@${user.username}',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              // Bio / subtitle
              Text(
                user.bio.isNotEmpty
                    ? user.bio
                    : 'Dj / Producer / Artist',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stats Row ──────────────────────────────────────────────────
  Widget _buildStatsRow(UserModel user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(_formatCount(user.followingCount), 'Following'),
          // Vertical divider
          Container(
            width: 1,
            height: 32,
            color: AppColors.darkBorder,
          ),
          _buildStat(_formatCount(user.followersCount), 'Followers'),
          Container(
            width: 1,
            height: 32,
            color: AppColors.darkBorder,
          ),
          _buildStat(_formatCount(user.postsCount), 'Post'),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  // ── Action Buttons ─────────────────────────────────────────────
  Widget _buildActions(UserModel user) {
    if (_isOwnProfile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            // Edit Profile button
            GestureDetector(
              onTap: () => _editProfile(user),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF9B6DFF)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Text('Edit Profile',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Creator tools
            _buildMenuTile(
              icon: CupertinoIcons.chart_bar_alt_fill,
              label: 'Creator Dashboard',
              color: AppColors.secondary,
              onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (_) =>
                          const CreatorDashboardScreen())),
            ),
            _buildMenuTile(
              icon: CupertinoIcons.money_dollar_circle,
              label: 'Monetization',
              color: AppColors.goldBadge,
              onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (_) =>
                          const MonetizationScreen())),
            ),
            if (user.isAdmin)
              _buildMenuTile(
                icon: CupertinoIcons.shield_lefthalf_fill,
                label: 'Admin Panel',
                color: AppColors.error,
                onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (_) =>
                            const AdminPanelScreen())),
              ),
          ],
        ),
      );
    }

    // Other user profile
    final isFollowing = ref.watch(isFollowingProvider(_targetUid));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: isFollowing.when(
              data: (following) => GestureDetector(
                onTap: () => _toggleFollow(following),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: following
                        ? null
                        : const LinearGradient(
                            colors: [
                              AppColors.primary,
                              Color(0xFF9B6DFF)
                            ],
                          ),
                    color: following
                        ? AppColors.darkCard
                        : null,
                    borderRadius: BorderRadius.circular(28),
                    border: following
                        ? Border.all(color: AppColors.darkBorder)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      following ? 'Following' : 'Follow',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
              loading: () => const SizedBox(height: 48),
              error: (_, __) => const SizedBox(height: 48),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _startChat(user),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: const Icon(CupertinoIcons.chat_bubble_fill,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Photo Grid (3-column with varied heights) ──────────────────
  SliverPadding _buildPhotoGrid(List<VideoModel> photos) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final v = photos[index];
            // Vary height for masonry-style look
            final isLarge = index % 5 == 0;
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: isLarge ? 0.65 : 0.85,
                child: Image.network(
                  v.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.darkCard,
                    child: const Center(
                      child: Icon(CupertinoIcons.photo_fill,
                          color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: photos.length,
        ),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            const Spacer(),
            const Icon(CupertinoIcons.chevron_right,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────

  void _showProfileMenu(UserModel user) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          if (_isOwnProfile) ...[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _editProfile(user);
              },
              child: const Text('Edit Profile'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                AuthPersistence.clear();
                ref.read(authUserProvider.notifier).state = null;
              },
              child: const Text('Log Out'),
            ),
          ] else ...[
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Report User'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Block User'),
            ),
          ],
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
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
    final image = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512);
    if (image == null) return;

    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    // Read image bytes and encode as base64 (works on web + mobile)
    final bytes = await image.readAsBytes();
    final base64Str = base64Encode(bytes);

    final updatedUser = await ref
        .read(userRepositoryProvider)
        .uploadProfilePhoto(uid, base64Str);

    if (updatedUser != null && mounted) {
      // Update auth state so avatar refreshes everywhere
      ref.read(authUserProvider.notifier).state = updatedUser;
      ref.invalidate(userProfileProvider(uid));
      ref.invalidate(allUsersProvider);
    }
  }

  void _editProfile(UserModel user) {
    final nameController =
        TextEditingController(text: user.displayName);
    final bioController =
        TextEditingController(text: user.bio);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
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
            Text('Edit Profile',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration:
                  const InputDecoration(labelText: 'Display Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Save',
              icon: CupertinoIcons.checkmark_alt,
              onPressed: () async {
                final updated = await ref.read(userRepositoryProvider).updateProfile(
                      user.uid,
                      displayName: nameController.text.trim(),
                      bio: bioController.text.trim(),
                    );
                if (updated != null) {
                  ref.read(authUserProvider.notifier).state = updated;
                  ref.invalidate(userProfileProvider(user.uid));
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }
}
