import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../models/clip_model.dart';
import 'clip_player_screen.dart';

class ClipsScreen extends ConsumerWidget {
  const ClipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clipsAsync = ref.watch(allClipsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: Text('Clips',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w800, fontSize: 22)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: clipsAsync.when(
        data: (clips) {
          if (clips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(CupertinoIcons.scissors,
                        size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  Text('No clips yet',
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Clips from livestreams will appear here',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: clips.length,
            itemBuilder: (context, index) {
              return _ClipCard(clip: clips[index]);
            },
          );
        },
        loading: () => const Center(
          child: CupertinoActivityIndicator(
              radius: 14, color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.exclamationmark_circle,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text('Error: $e',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClipCard extends StatelessWidget {
  final ClipModel clip;
  const _ClipCard({required this.clip});

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  Color _highlightColor(String type) {
    switch (type) {
      case 'peak_reactions':
        return AppColors.liveRed;
      case 'peak_viewers':
        return AppColors.accent;
      case 'chat_burst':
        return AppColors.success;
      case 'manual':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }

  String _highlightLabel(String type) {
    switch (type) {
      case 'peak_reactions':
        return '🔥 Peak';
      case 'peak_viewers':
        return '👀 Viewers';
      case 'chat_burst':
        return '💬 Chat';
      case 'manual':
        return '✂️ Manual';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => ClipPlayerScreen(clip: clip)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail area
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Thumbnail or gradient
                  if (clip.thumbnailUrl.isNotEmpty)
                    Image.network(
                      clip.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  else
                    _buildPlaceholder(),

                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Duration badge
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatDuration(clip.duration),
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  ),

                  // Highlight type badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _highlightColor(clip.highlightType)
                            .withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _highlightLabel(clip.highlightType),
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ),

                  // Play icon
                  Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clip.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: AppColors.darkBorder,
                        backgroundImage: clip.hostPhotoUrl.isNotEmpty
                            ? NetworkImage(clip.hostPhotoUrl)
                            : null,
                        child: clip.hostPhotoUrl.isEmpty
                            ? Text(
                                clip.hostUsername.isNotEmpty
                                    ? clip.hostUsername[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700))
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '@${clip.hostUsername}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.eye,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(_formatCount(clip.viewsCount),
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(width: 10),
                      const Icon(CupertinoIcons.heart,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(_formatCount(clip.likesCount),
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.3),
            AppColors.secondary.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(CupertinoIcons.scissors,
            size: 32, color: AppColors.textMuted),
      ),
    );
  }
}
