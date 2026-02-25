import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/data/mock_data.dart';
import '../../../models/music_model.dart';
import 'music_player_screen.dart';

class MusicScreen extends ConsumerWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = MockData.musicTracks;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Music'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Trending section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                    child: const Icon(Icons.trending_up, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 8),
                  const Text('Trending Tracks',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),

          // Horizontal trending cards
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: tracks.length > 4 ? 4 : tracks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  final track = tracks[i];
                  return _TrendingCard(track: track, rank: i + 1);
                },
              ),
            ),
          ),

          // All tracks header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('All Tracks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),

          // Track list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _TrackTile(track: tracks[i], index: i),
              childCount: tracks.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final MusicTrack track;
  final int rank;

  const _TrendingCard({required this.track, required this.rank});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MusicPlayerScreen(track: track)),
      ),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
          color: AppColors.darkCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      track.coverUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.darkCard,
                        child: const Icon(Icons.music_note, size: 40, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  // Rank badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text('#$rank',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                  // Play icon
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(track.artistName,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final MusicTrack track;
  final int index;

  const _TrackTile({required this.track, required this.index});

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MusicPlayerScreen(track: track)),
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 52, height: 52,
          child: Image.network(
            track.coverUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.darkCard,
              child: const Icon(Icons.music_note, color: AppColors.textMuted),
            ),
          ),
        ),
      ),
      title: Text(track.title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Row(
        children: [
          Text(track.artistName,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(width: 8),
          Text('• ${_formatDuration(track.duration)}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_outline, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(_formatCount(track.usageCount),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
