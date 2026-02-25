import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/artistcase_logo.dart';
import '../../../models/video_model.dart';
import '../../../models/comment_model.dart';
import '../../stories/presentation/create_story_screen.dart';

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

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isAnimating = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Snap to next/previous page on any mouse wheel tick
  void _onPointerScroll(PointerScrollEvent event, int totalPages) {
    if (_isAnimating) return;

    if (event.scrollDelta.dy > 0 && _currentPage < totalPages - 1) {
      // Scroll down → next page
      _isAnimating = true;
      _currentPage++;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      ).then((_) => _isAnimating = false);
    } else if (event.scrollDelta.dy < 0 && _currentPage > 0) {
      // Scroll up → previous page
      _isAnimating = true;
      _currentPage--;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      ).then((_) => _isAnimating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedVideosProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      extendBodyBehindAppBar: true,
      // Transparent overlaid app bar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xCC000000), Colors.transparent],
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
              child: const Text('Following',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 4),
            ShaderMask(
              shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
              child: const Text('For You',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: feedAsync.when(
        data: (videos) {
          if (videos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined,
                      size: 64, color: AppColors.textMuted),
                  SizedBox(height: 16),
                  Text('No posts yet. Be the first to post!',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }
          return Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                _onPointerScroll(event, videos.length);
              }
            },
            child: ScrollConfiguration(
              behavior: _WebScrollBehavior(),
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                allowImplicitScrolling: true,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (page) => _currentPage = page,
                itemCount: videos.length,
                itemBuilder: (context, index) =>
                    _PostCard(video: videos[index], isActive: true),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text('Error loading feed',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(feedVideosProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Post card ─────────────────────────────────────────────────────
class _PostCard extends ConsumerStatefulWidget {
  final VideoModel video;
  final bool isActive;
  const _PostCard({required this.video, required this.isActive});

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard>
    with SingleTickerProviderStateMixin {
  bool _showHeart = false;
  bool _isLiked = false;
  int _likesCount = 0;
  late AnimationController _heartCtrl;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.video.likesCount;
    _checkLiked();

    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 10),
    ]).animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.easeOut));
    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_heartCtrl);
  }

  void _checkLiked() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final liked = await ApiService.isLiked(widget.video.id, uid);
    if (mounted) setState(() => _isLiked = liked);
  }

  void _onDoubleTap() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    setState(() => _showHeart = true);
    _heartCtrl.forward(from: 0).then((_) {
      if (mounted) setState(() => _showHeart = false);
    });

    if (!_isLiked) {
      await ApiService.likePost(widget.video.id, uid);
      if (mounted) setState(() { _isLiked = true; _likesCount++; });
    }
  }

  void _toggleLike() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    if (_isLiked) {
      await ApiService.unlikePost(widget.video.id, uid);
      if (mounted) setState(() { _isLiked = false; _likesCount--; });
    } else {
      await ApiService.likePost(widget.video.id, uid);
      if (mounted) setState(() { _isLiked = true; _likesCount++; });
    }
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
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
          // ── Background ─────────────────────────────────────────
          if (hasImage)
            Image.network(
              video.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildGradientBg(video),
            )
          else
            _buildGradientBg(video),

          // ── Top scrim ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment(0, 0.3),
                colors: [Color(0x99000000), Colors.transparent],
              ),
            ),
          ),

          // ── Bottom scrim ───────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment(0, -0.2),
                colors: [Color(0xDD000000), Colors.transparent],
              ),
            ),
          ),

          // ── Center caption (no image) ──────────────────────────
          if (!hasImage && video.caption.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  video.caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                  ),
                ),
              ),
            ),

          // ── Right-side action buttons ──────────────────────────
          Positioned(
            right: 12,
            bottom: 110,
            child: Column(
              children: [
                // Avatar
                _UserAvatar(
                  photoUrl: video.userPhotoUrl,
                  username: video.username,
                ),
                const SizedBox(height: 24),

                // Like
                _ActionButton(
                  icon: _isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: _formatCount(_likesCount),
                  color: _isLiked ? Colors.redAccent : Colors.white,
                  onTap: _toggleLike,
                ),
                const SizedBox(height: 20),

                // Comment
                _ActionButton(
                  icon: Icons.chat_bubble_rounded,
                  label: _formatCount(video.commentsCount),
                  onTap: () => _showComments(context, video.id),
                ),
                const SizedBox(height: 20),

                // Share
                _ActionButton(
                  icon: Icons.reply_rounded,
                  label: 'Share',
                  onTap: () {},
                  mirrorX: true,
                ),
                const SizedBox(height: 20),

                // Share to Story
                _ActionButton(
                  icon: Icons.auto_stories_rounded,
                  label: 'Story',
                  color: AppColors.accent,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CreateStoryScreen(),
                    ));
                  },
                ),
                const SizedBox(height: 20),

                // Swipes (renamed from Views)
                _ActionButton(
                  icon: Icons.swipe_rounded,
                  label: _formatCount(video.viewsCount),
                  onTap: () {},
                ),
              ],
            ),
          ),

          // ── Bottom info ────────────────────────────────────────
          Positioned(
            left: 16,
            right: 80,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username
                Row(
                  children: [
                    Text(
                      '@${video.username}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          shadows: [Shadow(blurRadius: 6, color: Colors.black)]),
                    ),
                  ],
                ),
                if (hasImage && video.caption.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    video.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black)]),
                  ),
                ],
                if (video.hashtags.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    video.hashtags.map((t) => '#$t').join(' '),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),

          // ── Watermark ──────────────────────────────────────────
          const ArtistcaseWatermark(size: 14, opacity: 0.25),

          // ── Double-tap heart animation ─────────────────────────
          if (_showHeart)
            Center(
              child: AnimatedBuilder(
                animation: _heartCtrl,
                builder: (_, __) => Opacity(
                  opacity: _heartOpacity.value,
                  child: Transform.scale(
                    scale: _heartScale.value,
                    child: const Icon(Icons.favorite_rounded,
                        size: 110,
                        color: Colors.redAccent,
                        shadows: [Shadow(blurRadius: 20, color: Colors.black)]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGradientBg(VideoModel video) {
    final seed = video.id.hashCode.abs();
    final h1 = (seed % 360).toDouble();
    final h2 = ((seed + 120) % 360).toDouble();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HSLColor.fromAHSL(1, h1, 0.6, 0.15).toColor(),
            HSLColor.fromAHSL(1, h2, 0.7, 0.25).toColor(),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.article_rounded, size: 70, color: Colors.white12),
      ),
    );
  }

  void _showComments(BuildContext context, String videoId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a1a),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CommentsSheet(videoId: videoId),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

// ── User avatar with + follow badge ──────────────────────────────
class _UserAvatar extends StatelessWidget {
  final String photoUrl;
  final String username;
  const _UserAvatar({required this.photoUrl, required this.username});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipOval(
            child: photoUrl.isNotEmpty
                ? Image.network(photoUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initials())
                : _initials(),
          ),
        ),
        Positioned(
          bottom: -8,
          child: Container(
            width: 20, height: 20,
            decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle),
            child: const Icon(Icons.add, size: 12, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _initials() {
    return Container(
      color: AppColors.primary.withAlpha(60),
      child: Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool mirrorX;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color = Colors.white,
    required this.onTap,
    this.mirrorX = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Transform(
            alignment: Alignment.center,
            transform: mirrorX
                ? (Matrix4.identity()..scale(-1.0, 1.0))
                : Matrix4.identity(),
            child: Icon(icon, size: 34, color: color,
                shadows: const [Shadow(blurRadius: 6, color: Colors.black54)]),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w700,
                shadows: const [Shadow(blurRadius: 4, color: Colors.black)]),
          ),
        ],
      ),
    );
  }
}

// ── Comments sheet ────────────────────────────────────────────────
class _CommentsSheet extends ConsumerStatefulWidget {
  final String videoId;
  const _CommentsSheet({required this.videoId});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _commentController = TextEditingController();
  List<CommentModel> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  void _loadComments() async {
    final comments = await ApiService.getComments(widget.videoId);
    if (mounted) setState(() { _comments = comments; _loading = false; });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _post() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    _commentController.clear();
    final comment = await ApiService.addComment(
        postId: widget.videoId, userId: uid, text: text);
    if (comment != null && mounted) {
      setState(() => _comments.add(comment));
      ref.invalidate(feedVideosProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Text('${_comments.length} Comments',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16)),
            const Divider(color: Color(0xFF2a2a2a), height: 20),

            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : _comments.isEmpty
                      ? const Center(
                          child: Text('No comments yet — be the first!',
                              style: TextStyle(color: AppColors.textMuted)))
                      : ListView.builder(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _comments.length,
                          itemBuilder: (_, i) {
                            final c = _comments[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                        AppColors.primary.withAlpha(40),
                                    backgroundImage: c.userPhotoUrl.isNotEmpty
                                        ? NetworkImage(c.userPhotoUrl)
                                        : null,
                                    child: c.userPhotoUrl.isEmpty
                                        ? Text(
                                            c.username.isNotEmpty
                                                ? c.username[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700))
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(c.username,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: AppColors.textSecondary)),
                                        const SizedBox(height: 3),
                                        Text(c.text,
                                            style: const TextStyle(
                                                fontSize: 14, height: 1.4)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),

            // Input bar
            Container(
              padding: EdgeInsets.only(
                  left: 16,
                  right: 12,
                  top: 10,
                  bottom: MediaQuery.of(context).padding.bottom + 10),
              decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: Color(0xFF2a2a2a)))),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          color: const Color(0xFF2a2a2a),
                          borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                        controller: _commentController,
                        onSubmitted: (_) => _post(),
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(color: AppColors.textMuted),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _post,
                    child: Container(
                      width: 40, height: 40,
                      decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
