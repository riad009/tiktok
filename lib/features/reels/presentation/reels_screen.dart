import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/rich_text_caption.dart';
import '../../../models/video_model.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../../stories/presentation/create_story_screen.dart';
import '../../stories/presentation/stories_screen.dart';
import '../../livestream/presentation/livestream_screen.dart';

/// Custom scroll behavior that enables mouse drag on web
class _WebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _selectedTab = 1; // 0 = Following, 1 = For You

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedVideosProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Full-screen swipeable reels ──────────────
          feedAsync.when(
            data: (videos) {
              if (videos.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.film,
                          size: 64, color: AppColors.textMuted),
                      SizedBox(height: 16),
                      Text('No reels yet. Be the first!',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 16)),
                    ],
                  ),
                );
              }
              return ScrollConfiguration(
                behavior: _WebScrollBehavior(),
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: videos.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    return _ReelCard(
                      video: videos[index],
                      isActive: index == _currentPage,
                    );
                  },
                ),
              );
            },
            loading: () => const Center(
              child: CupertinoActivityIndicator(
                  radius: 16, color: AppColors.primary),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.exclamationmark_circle,
                      size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text('Error loading reels',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    onPressed: () => ref.invalidate(feedVideosProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),

          // ── Top bar: Following / For You ───────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedTab = 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        Text(
                          'Following',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: _selectedTab == 0
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: _selectedTab == 0
                                ? Colors.white
                                : Colors.white.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 24,
                          height: 3,
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _selectedTab = 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        Text(
                          'For You',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: _selectedTab == 1
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: _selectedTab == 1
                                ? Colors.white
                                : Colors.white.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 24,
                          height: 3,
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Search icon (top right) ──────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (_) => const SearchScreen())),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.search,
                    color: Colors.white, size: 22),
              ),
            ),
          ),

          // ── Live icon (top left) ──────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (_) => const LivestreamScreen())),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.liveRed,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('LIVE',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Single Reel Card — full screen content with overlays
// ══════════════════════════════════════════════════════════════════
class _ReelCard extends ConsumerStatefulWidget {
  final VideoModel video;
  final bool isActive;
  const _ReelCard({required this.video, required this.isActive});

  @override
  ConsumerState<_ReelCard> createState() => _ReelCardState();
}

class _ReelCardState extends ConsumerState<_ReelCard>
    with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  int _likesCount = 0;
  bool _showHeart = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.video.likesCount;
    _checkLiked();

    _heartController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _heartScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _heartController, curve: Curves.elasticOut));
    _heartController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _heartController.reverse();
            setState(() => _showHeart = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _checkLiked() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final liked = await ApiService.isLiked(widget.video.id, uid);
    if (mounted) setState(() => _isLiked = liked);
  }

  void _toggleLike() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    if (_isLiked) {
      await ApiService.unlikePost(widget.video.id, uid);
      if (mounted) {
        setState(() {
          _isLiked = false;
          _likesCount--;
        });
      }
    } else {
      await ApiService.likePost(widget.video.id, uid);
      if (mounted) {
        setState(() {
          _isLiked = true;
          _likesCount++;
        });
      }
    }
    ref.invalidate(likedVideosProvider);
  }

  void _onDoubleTap() {
    if (!_isLiked) _toggleLike();
    setState(() => _showHeart = true);
    _heartController.forward(from: 0);
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final hasImage = video.imageUrl.isNotEmpty;

    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image/gradient ──────────────
          if (hasImage)
            Image.network(
              video.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildGradientBg(video),
            )
          else
            _buildGradientBg(video),

          // ── Gradient overlay (bottom) ──────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // ── Bottom-left: User info + Caption ──────
          Positioned(
            bottom: 100,
            left: 16,
            right: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) =>
                          ProfileScreen(userId: video.userId),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.darkCard,
                        backgroundImage: NetworkImage(
                          video.userPhotoUrl.isNotEmpty
                              ? video.userPhotoUrl
                              : 'https://i.pravatar.cc/150?u=${video.username}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '@${video.username}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.white.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Follow',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Caption with @mentions and #hashtags
                if (video.caption.isNotEmpty)
                  RichTextCaption(
                    text: video.caption,
                    fontSize: 14,
                    maxLines: 3,
                    onMentionTap: (username) {
                      // Find user and navigate
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const SearchScreen(),
                        ),
                      );
                    },
                    onHashtagTap: (hashtag) {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const SearchScreen(),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 10),

                // Music disc row
                Row(
                  children: [
                    const Icon(CupertinoIcons.music_note,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        video.musicTitle.isNotEmpty
                            ? '${video.musicTitle} - ${video.musicArtist}'
                            : 'Original Sound - @${video.username}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Right action bar ──────────────────────
          Positioned(
            right: 12,
            bottom: 120,
            child: Column(
              children: [
                // Like
                _ActionButton(
                  icon: _isLiked
                      ? CupertinoIcons.heart_fill
                      : CupertinoIcons.heart,
                  label: _formatCount(_likesCount),
                  color: _isLiked ? AppColors.liveRed : Colors.white,
                  onTap: _toggleLike,
                ),
                const SizedBox(height: 20),

                // Comment
                _ActionButton(
                  icon: CupertinoIcons.chat_bubble,
                  label: _formatCount(video.commentsCount),
                  onTap: () => _showComments(video.id),
                ),
                const SizedBox(height: 20),

                // Share
                _ActionButton(
                  icon: CupertinoIcons.share,
                  label: 'Share',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Shared! 🔗'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Music disc
                _SpinningDisc(
                  imageUrl: video.userPhotoUrl.isNotEmpty
                      ? video.userPhotoUrl
                      : 'https://i.pravatar.cc/150?u=${video.username}',
                  isActive: widget.isActive,
                ),
              ],
            ),
          ),

          // ── Double-tap heart animation ────────────
          if (_showHeart)
            Center(
              child: AnimatedBuilder(
                animation: _heartController,
                builder: (_, __) => Transform.scale(
                  scale: _heartScale.value,
                  child: Icon(
                    CupertinoIcons.heart_fill,
                    size: 100,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGradientBg(VideoModel video) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.6),
            AppColors.secondary.withOpacity(0.4),
            AppColors.darkBg,
          ],
        ),
      ),
      child: Center(
        child: video.caption.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  video.caption,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              )
            : const Icon(CupertinoIcons.play_rectangle_fill,
                size: 80, color: AppColors.textMuted),
      ),
    );
  }

  void _showComments(String videoId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollCtrl) {
          return _CommentsSheet(
            videoId: videoId,
            scrollController: scrollCtrl,
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Action Button (right side)
// ══════════════════════════════════════════════════════════════════
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Spinning Music Disc
// ══════════════════════════════════════════════════════════════════
class _SpinningDisc extends StatefulWidget {
  final String imageUrl;
  final bool isActive;
  const _SpinningDisc({required this.imageUrl, required this.isActive});

  @override
  State<_SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<_SpinningDisc>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _SpinningDisc old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Transform.rotate(
        angle: _controller.value * 6.28,
        child: child,
      ),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 8),
          image: DecorationImage(
            image: NetworkImage(widget.imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Comments Sheet
// ══════════════════════════════════════════════════════════════════
class _CommentsSheet extends ConsumerStatefulWidget {
  final String videoId;
  final ScrollController scrollController;
  const _CommentsSheet(
      {required this.videoId, required this.scrollController});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(authUserProvider);
    if (user == null) return;

    await ApiService.addComment(
      postId: widget.videoId,
      userId: user.uid,
      text: text,
    );
    _commentController.clear();
    ref.invalidate(commentsProvider(widget.videoId));
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.videoId));

    return Column(
      children: [
        // Handle
        Container(
          width: 40,
          height: 5,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: AppColors.textMuted,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Comments',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
        const Divider(height: 1, color: AppColors.darkBorder),
        Expanded(
          child: commentsAsync.when(
            data: (comments) {
              if (comments.isEmpty) {
                return const Center(
                  child: Text('No comments yet. Be the first!',
                      style: TextStyle(color: AppColors.textMuted)),
                );
              }
              return ListView.builder(
                controller: widget.scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: comments.length,
                itemBuilder: (_, i) {
                  final c = comments[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.darkSurface,
                          backgroundImage: NetworkImage(
                            'https://i.pravatar.cc/100?u=${c.username}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.username,
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                              const SizedBox(height: 3),
                              RichTextCaption(
                                text: c.text,
                                fontSize: 13,
                                defaultColor: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CupertinoActivityIndicator(color: AppColors.primary),
            ),
            error: (_, __) => const Center(
              child: Text('Error loading comments',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          ),
        ),

        // Comment input
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            border:
                Border(top: BorderSide(color: AppColors.darkBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: const TextStyle(
                        color: AppColors.textMuted, fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.darkCard,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _postComment(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _postComment,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: const Icon(CupertinoIcons.arrow_up,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
