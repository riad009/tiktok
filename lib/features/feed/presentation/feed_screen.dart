import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/artistcase_logo.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../models/video_model.dart';
import '../../../models/comment_model.dart';
import '../../../models/livestream_model.dart';
import '../../stories/presentation/create_story_screen.dart';
import '../../stories/presentation/stories_screen.dart';
import '../../livestream/presentation/livestream_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../music/presentation/music_screen.dart';
import '../../music/presentation/music_player_screen.dart';
import '../../../models/music_model.dart';

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
  String _selectedFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedVideosProvider);
    final currentUser = ref.watch(authUserProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header: Hey {name} + avatar ──────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hey ${currentUser?.displayName.split(' ').first ?? 'there'}',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (_) => const ProfileScreen())),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.darkCard,
                        backgroundImage: NetworkImage(
                          currentUser?.photoUrl != null &&
                                  currentUser!.photoUrl.isNotEmpty
                              ? currentUser.photoUrl
                              : 'https://i.pravatar.cc/150?u=${currentUser?.username ?? 'default'}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stories row ──────────────────────────────────────
            SliverToBoxAdapter(child: _StoriesRow()),

            // ── Filter chips ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: ['ALL', 'Videos', 'Music'].map((filter) {
                    final isActive = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedFilter = filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.darkBorder,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            filter,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── Live indicator ───────────────────────────────────
            SliverToBoxAdapter(
              child: Builder(builder: (context) {
                final liveAsync = ref.watch(activeLivestreamsProvider);
                final liveStreams = liveAsync.valueOrNull
                        ?.where((s) => s.isLive)
                        .toList() ??
                    [];
                if (liveStreams.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      CupertinoPageRoute(
                          builder: (_) => const LivestreamScreen())),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Row(
                      children: [
                        Text('Live',
                            style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const SizedBox(width: 8),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.liveRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),

            // ── Post cards / Music grid ────────────────────────────
            if (_selectedFilter == 'Music')
              ..._buildMusicSection(ref)
            else
              ...[
                feedAsync.when(
                  data: (videos) {
                    if (videos.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.film,
                                  size: 64, color: AppColors.textMuted),
                              SizedBox(height: 16),
                              Text('No posts yet. Be the first to post!',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 16)),
                            ],
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _FeedPostCard(video: videos[index]);
                        },
                        childCount: videos.length,
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(
                      child: CupertinoActivityIndicator(
                          radius: 14, color: AppColors.primary),
                    ),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.exclamationmark_circle,
                              size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text('Error loading feed',
                              style:
                                  TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          CupertinoButton(
                            onPressed: () =>
                                ref.invalidate(feedVideosProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  /// Build Music section when "Music" filter is active — real Deezer data
  List<Widget> _buildMusicSection(WidgetRef ref) {
    final trendingAsync = ref.watch(trendingMusicProvider);

    return [
      // Search bar
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: GestureDetector(
            onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (_) => const MusicScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.search,
                      color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 10),
                  Text('Search songs, artists...',
                      style: GoogleFonts.inter(
                          color: AppColors.textMuted, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ),

      // Trending header
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Icon(Icons.trending_up,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 8),
              Text('Trending Now',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ],
          ),
        ),
      ),

      trendingAsync.when(
        data: (tracks) {
          if (tracks.isEmpty) {
            return const SliverToBoxAdapter(
              child: Center(
                  child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('No trending music available',
                    style: TextStyle(color: AppColors.textMuted)),
              )),
            );
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final track = tracks[index];
                return _DeezerTrackTile(
                  track: track,
                  rank: index + 1,
                );
              },
              childCount: tracks.length,
            ),
          );
        },
        loading: () => const SliverFillRemaining(
          child: Center(
            child: CupertinoActivityIndicator(
                radius: 14, color: AppColors.primary),
          ),
        ),
        error: (e, _) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  const Icon(CupertinoIcons.exclamationmark_circle,
                      size: 40, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text('Could not load music',
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  CupertinoButton(
                    onPressed: () =>
                        ref.invalidate(trendingMusicProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

// ── Stories Row ──────────────────────────────────────────────────
class _StoriesRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesProvider);

    return SizedBox(
      height: 110,
      child: storiesAsync.when(
        loading: () =>
            const Center(child: CupertinoActivityIndicator()),
        error: (_, __) => const SizedBox(),
        data: (stories) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: stories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // "Your story" with + icon
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) =>
                                const CreateStoryScreen())),
                    child: Column(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color:
                                AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: Icon(Icons.add,
                                color: Colors.white, size: 32),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Your story',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }
              final story = stories[index - 1];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoryViewerScreen(
                          stories: stories,
                          initialIndex: index - 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(18),
                          gradient: AppColors.storyGradient,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(16),
                            color: AppColors.darkBg,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(14),
                            child: Image.network(
                              story.mediaUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(
                                color: AppColors.darkCard,
                                child: const Icon(
                                    Icons.person,
                                    color:
                                        AppColors.textMuted),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 68,
                        child: Text(
                          story.username,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color:
                                  AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Deezer Track Tile — shown when Music filter is active
// ══════════════════════════════════════════════════════════════════
class _DeezerTrackTile extends StatelessWidget {
  final Map<String, dynamic> track;
  final int rank;

  const _DeezerTrackTile({required this.track, required this.rank});

  String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final title = track['title'] ?? '';
    final artist = track['artist']?['name'] ?? '';
    final albumCover = track['album']?['cover_medium'] ?? track['album']?['cover'] ?? '';
    final previewUrl = track['preview'] ?? '';
    final duration = track['duration'] ?? 0;
    final trackRank = track['rank'] ?? 0;

    return GestureDetector(
      onTap: () {
        if (previewUrl.isNotEmpty) {
          // Open preview URL in browser or navigate to MusicPlayer
          _playPreview(context, previewUrl, title, artist, albumCover);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: rank <= 3
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.darkBorder),
        ),
        child: Row(
          children: [
            // Rank number
            SizedBox(
              width: 28,
              child: Text(
                '#$rank',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: rank <= 3
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
              ),
            ),
            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 52,
                height: 52,
                child: albumCover.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: albumCover,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.darkSurface,
                          child: const Icon(CupertinoIcons.music_note,
                              color: AppColors.textMuted, size: 24),
                        ),
                      )
                    : Container(
                        color: AppColors.darkSurface,
                        child: const Icon(CupertinoIcons.music_note,
                            color: AppColors.textMuted, size: 24),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 3),
                  Text(artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            // Duration + play
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatDuration(duration),
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _playPreview(BuildContext context, String url, String title,
      String artist, String cover) {
    // Create a MusicTrack from Deezer data and open the player
    final musicTrack = MusicTrack(
      id: track['id']?.toString() ?? '',
      title: title,
      artistName: artist,
      coverUrl: cover,
      audioUrl: url,
      duration: Duration(seconds: track['duration'] ?? 30),
    );
    Navigator.push(
      context,
      CupertinoPageRoute(
          builder: (_) => MusicPlayerScreen(track: musicTrack)),
    );
  }
}

// ── Feed Post Card (Instagram-style) ──────────────────────────────
class _FeedPostCard extends ConsumerStatefulWidget {
  final VideoModel video;
  const _FeedPostCard({required this.video});

  @override
  ConsumerState<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends ConsumerState<_FeedPostCard> {
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

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final hasImage = video.imageUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.darkCard,
                backgroundImage: NetworkImage(
                  video.userPhotoUrl.isNotEmpty
                      ? video.userPhotoUrl
                      : 'https://i.pravatar.cc/150?u=${video.username}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  video.username.isNotEmpty
                      ? video.username
                      : 'Unknown',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Icon(Icons.more_horiz,
                    color: AppColors.textMuted, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Post image
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onDoubleTap: () {
                  if (!_isLiked) _toggleLike();
                },
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    video.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.darkCard,
                      child: const Center(
                        child: Icon(CupertinoIcons.photo,
                            color: AppColors.textMuted, size: 48),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    AppColors.secondary.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: video.caption.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          video.caption,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Icon(CupertinoIcons.doc_text,
                        color: Colors.white38, size: 48),
              ),
            ),
          const SizedBox(height: 10),

          // Stats row: views, likes, comments
          Row(
            children: [
              // Views
              const Icon(CupertinoIcons.eye,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(_formatCount(video.viewsCount),
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
              const SizedBox(width: 16),
              // Likes
              GestureDetector(
                onTap: _toggleLike,
                child: Icon(
                  _isLiked
                      ? CupertinoIcons.heart_fill
                      : CupertinoIcons.heart,
                  size: 18,
                  color: _isLiked
                      ? AppColors.secondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Text(_formatCount(_likesCount),
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
              const SizedBox(width: 16),
              // Comments
              GestureDetector(
                onTap: () => _showComments(context, video.id),
                child: const Icon(CupertinoIcons.chat_bubble,
                    size: 18, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 4),
              Text(_formatCount(video.commentsCount),
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),

          // Caption + hashtags
          if (video.caption.isNotEmpty && hasImage)
            RichText(
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${video.username} ',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: video.caption,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (video.hashtags.isNotEmpty)
                    TextSpan(
                      text:
                          ' ${video.hashtags.map((t) => '#$t').join(' ')}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),

          if (video.caption.isNotEmpty && hasImage)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '.....more',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textMuted),
              ),
            ),

          const SizedBox(height: 8),
          const Divider(color: AppColors.darkBorder, height: 1),
        ],
      ),
    );
  }

  void _showComments(BuildContext context, String videoId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a1a),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CommentsSheet(videoId: videoId),
    );
  }
}

// ── Comments sheet ────────────────────────────────────────────────
class _CommentsSheet extends ConsumerStatefulWidget {
  final String videoId;
  const _CommentsSheet({required this.videoId});

  @override
  ConsumerState<_CommentsSheet> createState() =>
      _CommentsSheetState();
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
    final comments =
        await ApiService.getComments(widget.videoId);
    if (mounted) {
      setState(() {
        _comments = comments;
        _loading = false;
      });
    }
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
            Container(
              margin:
                  const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Text('${_comments.length} Comments',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.white)),
            const Divider(
                color: Color(0xFF2a2a2a), height: 20),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CupertinoActivityIndicator(
                          radius: 14,
                          color: AppColors.primary))
                  : _comments.isEmpty
                      ? const Center(
                          child: Text(
                              'No comments yet — be the first!',
                              style: TextStyle(
                                  color:
                                      AppColors.textMuted)))
                      : ListView.builder(
                          controller: controller,
                          padding: const EdgeInsets
                              .symmetric(horizontal: 16),
                          itemCount: _comments.length,
                          itemBuilder: (_, i) {
                            final c = _comments[i];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 10),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                        AppColors.primary
                                            .withAlpha(40),
                                    backgroundImage: c
                                            .userPhotoUrl
                                            .isNotEmpty
                                        ? NetworkImage(
                                            c.userPhotoUrl)
                                        : null,
                                    child: c.userPhotoUrl
                                            .isEmpty
                                        ? Text(
                                            c.username
                                                    .isNotEmpty
                                                ? c.username[
                                                        0]
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                                fontSize:
                                                    14,
                                                fontWeight:
                                                    FontWeight
                                                        .w700))
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(c.username,
                                            style: GoogleFonts.inter(
                                                fontWeight:
                                                    FontWeight
                                                        .w700,
                                                fontSize:
                                                    13,
                                                color: AppColors
                                                    .textSecondary)),
                                        const SizedBox(
                                            height: 3),
                                        Text(c.text,
                                            style: GoogleFonts.inter(
                                                fontSize:
                                                    14,
                                                height:
                                                    1.4,
                                                color: Colors
                                                    .white)),
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
                  bottom:
                      MediaQuery.of(context).padding.bottom +
                          10),
              decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: Color(0xFF2a2a2a)))),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                          color: const Color(0xFF2a2a2a),
                          borderRadius:
                              BorderRadius.circular(24)),
                      child: TextField(
                        controller: _commentController,
                        onSubmitted: (_) => _post(),
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white),
                        decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(
                                color: AppColors.textMuted),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _post,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                          gradient:
                              AppColors.primaryGradient,
                          shape: BoxShape.circle),
                      child: const Icon(
                          CupertinoIcons.paperplane_fill,
                          color: Colors.white,
                          size: 18),
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
