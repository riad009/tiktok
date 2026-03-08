import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../profile/presentation/profile_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.screenGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  children: [
                    Text('Notifications',
                        style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => ref.invalidate(notificationsProvider),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: const Icon(CupertinoIcons.refresh,
                            color: AppColors.textSecondary, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Notification list ───────────────────────
              Expanded(
                child: notifAsync.when(
                  data: (notifications) {
                    if (notifications.isEmpty) {
                      return _buildEmpty();
                    }

                    // Group by time: Today, This Week, Earlier
                    final now = DateTime.now();
                    final today = <Map<String, dynamic>>[];
                    final thisWeek = <Map<String, dynamic>>[];
                    final earlier = <Map<String, dynamic>>[];

                    for (final n in notifications) {
                      final createdAt = DateTime.tryParse(
                              n['createdAt']?.toString() ?? '') ??
                          now;
                      final diff = now.difference(createdAt);
                      if (diff.inHours < 24) {
                        today.add(n);
                      } else if (diff.inDays < 7) {
                        thisWeek.add(n);
                      } else {
                        earlier.add(n);
                      }
                    }

                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        ref.invalidate(notificationsProvider);
                      },
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 100),
                        children: [
                          if (today.isNotEmpty) ...[
                            _buildSectionHeader('Today'),
                            ...today.map((n) => _NotificationTile(data: n)),
                          ],
                          if (thisWeek.isNotEmpty) ...[
                            _buildSectionHeader('This Week'),
                            ...thisWeek
                                .map((n) => _NotificationTile(data: n)),
                          ],
                          if (earlier.isNotEmpty) ...[
                            _buildSectionHeader('Earlier'),
                            ...earlier
                                .map((n) => _NotificationTile(data: n)),
                          ],
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(
                      child: CupertinoActivityIndicator(
                          radius: 14, color: AppColors.primary)),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.exclamationmark_circle,
                            size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('Failed to load notifications',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        CupertinoButton(
                          onPressed: () =>
                              ref.invalidate(notificationsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.bell,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text("You're all caught up!",
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text('When people interact with your content,\nyou\'ll see it here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.3)),
    );
  }
}

// ── Notification Tile ────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _NotificationTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final type = data['type'] ?? '';
    final actorUsername = data['actorUsername'] ?? '';
    final actorDisplayName = data['actorDisplayName'] ?? actorUsername;
    final actorPhoto = data['actorPhotoUrl'] ?? '';
    final actorId = data['actorId'] ?? '';
    final createdAt =
        DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
            DateTime.now();

    // Icon + color based on type
    IconData icon;
    Color iconColor;
    String message;

    switch (type) {
      case 'like':
        icon = CupertinoIcons.heart_fill;
        iconColor = const Color(0xFFFF6B6B);
        message = 'liked your post';
      case 'comment':
        icon = CupertinoIcons.chat_bubble_fill;
        iconColor = AppColors.primary;
        final commentText = data['commentText'] ?? '';
        message = commentText.isNotEmpty
            ? 'commented: "$commentText"'
            : 'commented on your post';
      case 'message':
        icon = CupertinoIcons.paperplane_fill;
        iconColor = AppColors.secondary;
        final msgText = data['messageText'] ?? '';
        message = msgText.isNotEmpty
            ? 'sent you a message: "$msgText"'
            : 'sent you a message';
      default:
        icon = CupertinoIcons.bell_fill;
        iconColor = AppColors.textMuted;
        message = 'interacted with you';
    }

    final postImageUrl = data['postImageUrl'] ?? '';

    return GestureDetector(
      onTap: () {
        // Navigate to profile of actor
        if (actorId.isNotEmpty) {
          Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (_) => ProfileScreen(userId: actorId)),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkCard.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            // Actor avatar with type indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.darkSurface,
                  backgroundImage: actorPhoto.isNotEmpty
                      ? CachedNetworkImageProvider(actorPhoto)
                      : null,
                  child: actorPhoto.isEmpty
                      ? Text(
                          actorUsername.isNotEmpty
                              ? actorUsername[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary),
                        )
                      : null,
                ),
                // Type badge
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.darkBg, width: 2),
                    ),
                    child: Icon(icon, color: Colors.white, size: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: actorDisplayName.isNotEmpty
                              ? actorDisplayName
                              : '@$actorUsername',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        TextSpan(
                          text: ' $message',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(createdAt),
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            // Post thumbnail (if applicable)
            if (type != 'message' && postImageUrl.isNotEmpty) ...[
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CachedNetworkImage(
                    imageUrl: postImageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.darkSurface,
                      child: const Icon(CupertinoIcons.photo,
                          color: AppColors.textMuted, size: 16),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}
