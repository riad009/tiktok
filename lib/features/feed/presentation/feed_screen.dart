import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/artistcase_logo.dart';
import '../../../models/video_model.dart';
import '../../../models/comment_model.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedVideosProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: const Text('Artistcase',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ),
      ),
      body: feedAsync.when(
        data: (videos) {
          if (videos.isEmpty) {
            return const Center(
              child: Text('No posts yet. Be the first to post!',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            itemBuilder: (context, index) =>
                _PostCard(video: videos[index]),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text('Error loading feed\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCard extends ConsumerStatefulWidget {
  final VideoModel video;
  const _PostCard({required this.video});

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard> {
  bool _showHeart = false;
  bool _isLiked = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.video.likesCount;
    _checkLiked();
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
    Future.delayed(const Duration(milliseconds: 800),
        () { if (mounted) setState(() => _showHeart = false); });

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
  Widget build(BuildContext context) {
    final video = widget.video;
    final hasImage = video.imageUrl.isNotEmpty;

    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background: image or gradient
          if (hasImage)
            Image.network(
              video.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildGradientBg(video),
            )
          else
            _buildGradientBg(video),

          // Dark gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withAlpha(180),
                ],
              ),
            ),
          ),

          // Caption overlay in center if no image and has caption
          if (!hasImage && video.caption.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  video.caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Right side action buttons
          Positioned(
            right: 12,
            bottom: 120,
            child: Column(
              children: [
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
                  icon: Icons.comment_rounded,
                  label: _formatCount(video.commentsCount),
                  onTap: () => _showComments(context, video.id),
                ),
                const SizedBox(height: 20),
                // Repost
                _ActionButton(
                  icon: Icons.repeat_rounded,
                  label: 'Repost',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reposted! 🔄'), backgroundColor: AppColors.success),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Share
                _ActionButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                // Views
                _ActionButton(
                  icon: Icons.visibility_rounded,
                  label: _formatCount(video.viewsCount),
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Bottom info
          Positioned(
            left: 16,
            right: 80,
            bottom: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${video.username}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                if (hasImage && video.caption.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(video.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, height: 1.4)),
                ],
                if (video.hashtags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    video.hashtags.map((t) => '#$t').join(' '),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),

          // Artistcase watermark
          const ArtistcaseWatermark(size: 14, opacity: 0.3),

          // Double-tap heart animation
          if (_showHeart)
            const Center(
              child: Icon(Icons.favorite_rounded,
                  size: 100, color: Colors.redAccent),
            ),
        ],
      ),
    );
  }

  Widget _buildGradientBg(VideoModel video) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color((video.id.hashCode.abs() * 0xFFFFFF ~/ 100) | 0xFF000000),
            Color(((video.id.hashCode.abs() + 42) * 0xFFFFFF ~/ 100) | 0xFF000000),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.article_rounded, size: 60, color: Colors.white24),
      ),
    );
  }

  void _showComments(BuildContext context, String videoId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CommentsSheet(videoId: videoId),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
      required this.label,
      this.color = Colors.white,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Comments Sheet ───────────────────────────────────────────────
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
      postId: widget.videoId,
      userId: uid,
      text: text,
    );

    if (comment != null && mounted) {
      setState(() => _comments.add(comment));
      // Also refresh feed to update comment count
      ref.invalidate(feedVideosProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, controller) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Text('Comments (${_comments.length})',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const Divider(color: AppColors.darkBorder),

            // Comments list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _comments.isEmpty
                      ? const Center(
                          child: Text('No comments yet — be the first!',
                              style: TextStyle(color: AppColors.textMuted)),
                        )
                      : ListView.builder(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _comments.length,
                          itemBuilder: (_, i) {
                            final c = _comments[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primary.withAlpha(40),
                                    backgroundImage: c.userPhotoUrl.isNotEmpty
                                        ? NetworkImage(c.userPhotoUrl)
                                        : null,
                                    child: c.userPhotoUrl.isEmpty
                                        ? Text(c.username.isNotEmpty ? c.username[0].toUpperCase() : '?',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.username,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13)),
                                        const SizedBox(height: 2),
                                        Text(c.text,
                                            style: const TextStyle(
                                                fontSize: 14, height: 1.3)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),

            // Input
            Container(
              padding: EdgeInsets.only(
                  left: 16,
                  right: 8,
                  top: 10,
                  bottom: MediaQuery.of(context).padding.bottom + 10),
              decoration: const BoxDecoration(
                  border:
                      Border(top: BorderSide(color: AppColors.darkBorder))),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          color: AppColors.darkSurface,
                          borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                        controller: _commentController,
                        onSubmitted: (_) => _post(),
                        decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                      onPressed: _post,
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
