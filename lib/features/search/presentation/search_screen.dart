import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/data/mock_data.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../music/presentation/music_player_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(14)),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _query = val.trim();
                        _isSearching = _query.isNotEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search users, hashtags, posts...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.textMuted),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _query = '';
                                  _isSearching = false;
                                });
                              })
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(text: 'Users'),
                  Tab(text: 'Hashtags'),
                  Tab(text: 'Posts'),
                  Tab(text: 'Music'),
                  Tab(text: 'Mentions'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildHashtagsTab(),
          _buildPostsTab(),
          _buildMusicTab(),
          _buildMentionsTab(),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    if (!_isSearching) {
      return _buildEmptySearch('Search for users by username');
    }
    return FutureBuilder(
      future: ref.read(userRepositoryProvider).searchUsers(_query),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        final users = snap.data ?? [];
        if (users.isEmpty) return _buildEmptySearch('No users found');

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          itemBuilder: (_, i) {
            final user = users[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.darkCard,
                backgroundImage: user.photoUrl.isNotEmpty
                    ? NetworkImage(user.photoUrl)
                    : null,
                child: user.photoUrl.isEmpty
                    ? Text(user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                        style: const TextStyle(fontWeight: FontWeight.w700))
                    : null,
              ),
              title: Text(user.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('@${user.username}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              trailing: Text('${_formatCount(user.followersCount)} followers',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ProfileScreen(userId: user.uid)));
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHashtagsTab() {
    final hashtagsAsync = ref.watch(trendingHashtagsProvider);

    return hashtagsAsync.when(
      data: (hashtags) {
        final filtered = _isSearching
            ? Map.fromEntries(hashtags.entries
                .where((e) => e.key.contains(_query.toLowerCase())))
            : hashtags;

        if (filtered.isEmpty) return _buildEmptySearch('No hashtags found');

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final entry = filtered.entries.elementAt(i);
            return ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(40),
                    borderRadius: BorderRadius.circular(12)),
                child: const Center(
                    child: Text('#',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800))),
              ),
              title: Text('#${entry.key}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${_formatCount(entry.value)} posts',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            );
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildPostsTab() {
    final feedAsync = ref.watch(feedVideosProvider);

    return feedAsync.when(
      data: (videos) {
        final filtered = _isSearching
            ? videos
                .where((v) =>
                    v.caption.toLowerCase().contains(_query.toLowerCase()) ||
                    v.hashtags.any(
                        (h) => h.toLowerCase().contains(_query.toLowerCase())))
                .toList()
            : videos;

        if (filtered.isEmpty) return _buildEmptySearch('No posts found');

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 9 / 16,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final video = filtered[i];
            return Stack(
              fit: StackFit.expand,
              children: [
                video.thumbnailUrl.isNotEmpty
                    ? Image.network(video.thumbnailUrl, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.darkCard,
                        child: const Center(
                            child: Icon(Icons.videocam_rounded,
                                color: AppColors.textMuted))),
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Row(
                    children: [
                      const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 2),
                      Text(_formatCount(video.viewsCount),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptySearch(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  Widget _buildMusicTab() {
    final tracks = MockData.musicTracks;
    final filtered = _isSearching
        ? tracks.where((t) =>
            t.title.toLowerCase().contains(_query.toLowerCase()) ||
            t.artistName.toLowerCase().contains(_query.toLowerCase())).toList()
        : tracks;

    if (filtered.isEmpty) return _buildEmptySearch('No music found');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final track = filtered[i];
        return ListTile(
          leading: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
              image: track.coverUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(track.coverUrl),
                      fit: BoxFit.cover)
                  : null,
            ),
            child: track.coverUrl.isEmpty
                ? const Icon(Icons.music_note_rounded,
                    color: AppColors.secondary)
                : null,
          ),
          title: Text(track.title,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(track.artistName,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          trailing: Text('${_formatCount(track.usageCount)} uses',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12)),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => MusicPlayerScreen(track: track)));
          },
        );
      },
    );
  }

  Widget _buildMentionsTab() {
    final feedAsync = ref.watch(feedVideosProvider);

    return feedAsync.when(
      data: (videos) {
        final mentionVideos = _isSearching
            ? videos
                .where((v) =>
                    v.caption.toLowerCase().contains('@${_query.toLowerCase()}'))
                .toList()
            : videos.where((v) => v.caption.contains('@')).toList();

        if (mentionVideos.isEmpty) return _buildEmptySearch('No mentions found');

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: mentionVideos.length,
          itemBuilder: (_, i) {
            final video = mentionVideos[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.accent.withAlpha(40),
                backgroundImage: video.userPhotoUrl.isNotEmpty
                    ? NetworkImage(video.userPhotoUrl)
                    : null,
                child: video.userPhotoUrl.isEmpty
                    ? Text(
                        video.username.isNotEmpty
                            ? video.username[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontWeight: FontWeight.w700))
                    : null,
              ),
              title: Text('@${video.username}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                video.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swipe_rounded,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(_formatCount(video.viewsCount),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
