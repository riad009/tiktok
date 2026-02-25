import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/live_badge.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/artistcase_logo.dart';
import '../../../core/data/mock_data.dart';
import '../../../models/livestream_model.dart';
import '../../../models/clip_model.dart';

class LivestreamScreen extends ConsumerStatefulWidget {
  const LivestreamScreen({super.key});

  @override
  ConsumerState<LivestreamScreen> createState() => _LivestreamScreenState();
}

class _LivestreamScreenState extends ConsumerState<LivestreamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const LiveBadge(size: 16),
                  const SizedBox(width: 12),
                  const Text(
                    'Live',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  _buildGoLiveButton(),
                ],
              ),
            ),
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
                dividerHeight: 0,
                tabs: const [
                  Tab(text: 'Live Now'),
                  Tab(text: 'Replays'),
                  Tab(text: 'Clips'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLiveNowTab(),
                  _buildReplaysTab(),
                  _buildClipsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoLiveButton() {
    return GestureDetector(
      onTap: () => _showGoLiveSheet(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text(
              'Go Live',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveNowTab() {
    final livestreams = ref.watch(activeLivestreamsProvider);
    return livestreams.when(
      data: (streams) {
        if (streams.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.live_tv, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text(
                  'No one is live right now',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to go live!',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: streams.length,
          itemBuilder: (context, i) => _LivestreamCard(
            livestream: streams[i],
            onTap: () => _openLiveViewer(streams[i]),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (_, __) => const Center(child: Text('Error loading streams')),
    );
  }

  Widget _buildReplaysTab() {
    return StreamBuilder<List<LivestreamModel>>(
      stream: ref.read(livestreamRepositoryProvider).getReplays(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        final replays = snap.data ?? [];
        if (replays.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.replay, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text(
                  'No replays yet',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: replays.length,
          itemBuilder: (context, i) => _ReplayCard(replay: replays[i]),
        );
      },
    );
  }

  void _showGoLiveSheet() {
    final titleController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.darkBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  LiveBadge(size: 14),
                  SizedBox(width: 10),
                  Text(
                    'Start Livestream',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'What\'s your stream about?',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.darkCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.title, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 12, offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        final title = titleController.text.trim().isEmpty
                            ? 'Untitled Stream'
                            : titleController.text.trim();
                        final user = ref.read(currentUserProvider).value;
                        if (user == null) return;

                        // Create livestream locally (no Firestore needed)
                        final streamId = const Uuid().v4();
                        final stream = LivestreamModel(
                          id: streamId,
                          hostId: user.uid,
                          hostUsername: user.username,
                          hostPhotoUrl: user.photoUrl,
                          title: title,
                          isLive: true,
                          startedAt: DateTime.now(),
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LivestreamHostView(
                                livestreamId: stream.id,
                                localStream: stream,
                              ),
                            ),
                          );
                        }
                      },
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Go Live Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openLiveViewer(LivestreamModel stream) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LivestreamViewerScreen(livestreamId: stream.id),
      ),
    );
  }

  Widget _buildClipsTab() {
    final clipsAsync = ref.watch(allClipsProvider);
    return clipsAsync.when(
      data: (clips) {
        if (clips.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.content_cut, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No clips yet', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  'Clips are auto-generated from\nyour livestream highlights',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.6), fontSize: 13),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: clips.length,
          itemBuilder: (context, i) => _ClipCard(clip: clips[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('Error loading clips', style: TextStyle(color: AppColors.error))),
    );
  }
}


// ── Livestream Card ──────────────────────────────────────────────
class _LivestreamCard extends StatelessWidget {
  final LivestreamModel livestream;
  final VoidCallback onTap;

  const _LivestreamCard({required this.livestream, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.liveRed.withValues(alpha: 0.3)),
        ),
        child: Stack(
          children: [
            // Camera preview placeholder
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.secondary.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.videocam, size: 40, color: Colors.white24),
                ),
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
            // LIVE badge
            const Positioned(
              top: 8, left: 8,
              child: LiveBadge(size: 10),
            ),
            // Viewer count
            Positioned(
              top: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.remove_red_eye, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      '${livestream.viewerCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            // Host info
            Positioned(
              left: 10, right: 10, bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    livestream.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary,
                        backgroundImage: livestream.hostPhotoUrl.isNotEmpty
                            ? NetworkImage(livestream.hostPhotoUrl)
                            : null,
                        child: livestream.hostPhotoUrl.isEmpty
                            ? const Icon(Icons.person, size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          livestream.hostUsername,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
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
}

// ── Replay Card ─────────────────────────────────────────────────
class _ReplayCard extends StatelessWidget {
  final LivestreamModel replay;

  const _ReplayCard({required this.replay});

  @override
  Widget build(BuildContext context) {
    final duration = replay.endedAt != null
        ? replay.endedAt!.difference(replay.startedAt)
        : Duration.zero;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.3),
                  AppColors.primary.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: const Icon(Icons.replay, color: Colors.white54, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  replay.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${replay.hostUsername} · ${_formatDuration(duration)} · ${replay.peakViewers} peak viewers',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.play_circle_fill, color: AppColors.primary, size: 36),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

// ── Host View ───────────────────────────────────────────────────
class LivestreamHostView extends ConsumerStatefulWidget {
  final String livestreamId;
  final LivestreamModel? localStream;
  const LivestreamHostView({super.key, required this.livestreamId, this.localStream});

  @override
  ConsumerState<LivestreamHostView> createState() => _LivestreamHostViewState();
}

class _LivestreamHostViewState extends ConsumerState<LivestreamHostView> {
  final _chatController = TextEditingController();
  late LivestreamModel _localStreamData;
  final List<LiveChatMessage> _localChat = [];
  bool _isLive = true;
  int _viewerCount = 0;
  int _totalReactions = 0;

  @override
  void initState() {
    super.initState();
    _localStreamData = widget.localStream ?? LivestreamModel(
      id: widget.livestreamId,
      hostId: '',
      hostUsername: 'You',
      title: 'My Stream',
    );
    // Simulate viewers joining
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _viewerCount = 1);
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _viewerCount = 3);
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _localChat.insert(0, LiveChatMessage(
            id: 'bot1', senderId: 'system', username: 'Artistcase',
            text: 'You are now live! 🎉', timestamp: DateTime.now(),
          ));
        });
      }
    });
    // Notify followers (simulated)
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _localChat.insert(0, LiveChatMessage(
            id: 'notify1', senderId: 'system', username: 'Artistcase',
            text: '📢 Your followers have been notified!', timestamp: DateTime.now(),
          ));
        });
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview placeholder
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.secondary.withValues(alpha: 0.15),
                    Colors.black,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, size: 80, color: Colors.white12),
                    const SizedBox(height: 12),
                    Text(
                      _isLive ? 'You are LIVE' : 'Stream Ended',
                      style: TextStyle(color: _isLive ? AppColors.liveRed : Colors.white24, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _localStreamData.title,
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16, right: 16,
            child: Row(
              children: [
                const LiveBadge(size: 14),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.remove_red_eye, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '$_viewerCount',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_totalReactions > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text('❤️', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text('$_totalReactions', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _endStream(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'End',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chat overlay
          Positioned(
            left: 12, right: 80, bottom: 80,
            height: 250,
            child: ListView.builder(
              reverse: true,
              itemCount: _localChat.length,
              itemBuilder: (context, i) {
                final msg = _localChat[i];
                if (msg.reaction != null && msg.text.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${msg.username} ${msg.reaction}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GlassCard(
                    blur: 5, opacity: 0.2,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    borderRadius: BorderRadius.circular(12),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${msg.username} ',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          TextSpan(
                            text: msg.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Reaction buttons (right side)
          Positioned(
            right: 12, bottom: 120,
            child: Column(
              children: ['❤️', '🔥', '👏', '💎'].map((emoji) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _sendReaction(emoji),
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Chat input
          Positioned(
            left: 12, right: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Say something...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendChat(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendChat,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Artistcase watermark
          const ArtistcaseWatermark(size: 16, opacity: 0.25),
        ],
      ),
    );
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    setState(() {
      _localChat.insert(0, LiveChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: user.uid,
        username: user.username,
        userPhotoUrl: user.photoUrl,
        text: text,
        timestamp: DateTime.now(),
      ));
    });
    _chatController.clear();
  }

  void _sendReaction(String emoji) {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    setState(() {
      _totalReactions++;
      _localChat.insert(0, LiveChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: user.uid,
        username: user.username,
        text: '',
        reaction: emoji,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _endStream() {
    setState(() => _isLive = false);
    final duration = DateTime.now().difference(_localStreamData.startedAt);
    _showStreamSummary(duration);
  }

  void _showStreamSummary(Duration streamDuration) {
    // Auto-generate mock clips
    final clips = [
      ClipModel(
        id: 'gen-clip-1',
        livestreamId: widget.livestreamId,
        hostId: _localStreamData.hostId,
        hostUsername: _localStreamData.hostUsername,
        hostPhotoUrl: _localStreamData.hostPhotoUrl,
        title: '🔥 Peak reactions burst!',
        thumbnailUrl: MockData.thumbnail(20),
        startTime: streamDuration * 0.3,
        endTime: streamDuration * 0.3 + const Duration(seconds: 45),
        highlightType: 'peak_reactions',
      ),
      ClipModel(
        id: 'gen-clip-2',
        livestreamId: widget.livestreamId,
        hostId: _localStreamData.hostId,
        hostUsername: _localStreamData.hostUsername,
        hostPhotoUrl: _localStreamData.hostPhotoUrl,
        title: '💬 Chat went wild!',
        thumbnailUrl: MockData.thumbnail(21),
        startTime: streamDuration * 0.6,
        endTime: streamDuration * 0.6 + const Duration(seconds: 30),
        highlightType: 'chat_burst',
      ),
      if (_totalReactions > 5)
        ClipModel(
          id: 'gen-clip-3',
          livestreamId: widget.livestreamId,
          hostId: _localStreamData.hostId,
          hostUsername: _localStreamData.hostUsername,
          hostPhotoUrl: _localStreamData.hostPhotoUrl,
          title: '⭐ Best moment!',
          thumbnailUrl: MockData.thumbnail(22),
          startTime: streamDuration * 0.5,
          endTime: streamDuration * 0.5 + const Duration(seconds: 35),
          highlightType: 'peak_viewers',
        ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => _StreamSummarySheet(
        streamTitle: _localStreamData.title,
        duration: streamDuration,
        peakViewers: _viewerCount,
        totalReactions: _totalReactions,
        totalMessages: _localChat.length,
        clips: clips,
        onDone: () {
          Navigator.pop(ctx);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Viewer Screen ───────────────────────────────────────────────
class LivestreamViewerScreen extends ConsumerStatefulWidget {
  final String livestreamId;
  const LivestreamViewerScreen({super.key, required this.livestreamId});

  @override
  ConsumerState<LivestreamViewerScreen> createState() =>
      _LivestreamViewerScreenState();
}

class _LivestreamViewerScreenState
    extends ConsumerState<LivestreamViewerScreen> {
  final _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      ref.read(livestreamRepositoryProvider).joinLivestream(
            widget.livestreamId, user.uid);
    }
  }

  @override
  void dispose() {
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      ref.read(livestreamRepositoryProvider).leaveLivestream(
            widget.livestreamId, user.uid);
    }
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(livestreamProvider(widget.livestreamId));
    final chat = ref.watch(liveChatProvider(widget.livestreamId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video placeholder
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.live_tv, size: 64, color: Colors.white12),
                    const SizedBox(height: 12),
                    stream.when(
                      data: (s) => Text(
                        s?.title ?? 'Livestream',
                        style: TextStyle(color: Colors.white38, fontSize: 18),
                      ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16, right: 16,
            child: stream.when(
              data: (s) {
                if (s == null) return const SizedBox();
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      backgroundImage: s.hostPhotoUrl.isNotEmpty
                          ? NetworkImage(s.hostPhotoUrl) : null,
                      child: s.hostPhotoUrl.isEmpty
                          ? const Icon(Icons.person, size: 18, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.hostUsername,
                          style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Row(
                          children: [
                            const LiveBadge(size: 8, showPulse: false),
                            const SizedBox(width: 8),
                            Text(
                              '${s.viewerCount} watching',
                              style: TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ),

          // Chat overlay + input (same layout as host)
          Positioned(
            left: 12, right: 80, bottom: 80,
            height: 250,
            child: chat.when(
              data: (messages) => ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final msg = messages[i];
                  if (msg.reaction != null && msg.text.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${msg.username} ${msg.reaction}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: GlassCard(
                      blur: 5, opacity: 0.2,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      borderRadius: BorderRadius.circular(12),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${msg.username} ',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600, fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: msg.text,
                              style: const TextStyle(
                                color: Colors.white, fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ),

          // Reaction buttons
          Positioned(
            right: 12, bottom: 120,
            child: Column(
              children: ['❤️', '🔥', '👏', '💎'].map((emoji) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      final user = ref.read(currentUserProvider).value;
                      if (user == null) return;
                      ref.read(livestreamRepositoryProvider).sendLiveChat(
                            livestreamId: widget.livestreamId,
                            senderId: user.uid,
                            username: user.username,
                            text: '',
                            reaction: emoji,
                          );
                      ref.read(livestreamRepositoryProvider).addReaction(widget.livestreamId);
                    },
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Chat input
          Positioned(
            left: 12, right: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Say something...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendChat(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendChat,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Artistcase watermark
          const ArtistcaseWatermark(size: 16, opacity: 0.25),
        ],
      ),
    );
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    ref.read(livestreamRepositoryProvider).sendLiveChat(
          livestreamId: widget.livestreamId,
          senderId: user.uid,
          username: user.username,
          userPhotoUrl: user.photoUrl,
          text: text,
        );
    _chatController.clear();
  }
}

// ── Clip Card ───────────────────────────────────────────────────
class _ClipCard extends StatefulWidget {
  final ClipModel clip;
  const _ClipCard({required this.clip});

  @override
  State<_ClipCard> createState() => _ClipCardState();
}

class _ClipCardState extends State<_ClipCard> {
  bool _postedToFeed = false;
  bool _sharedToStory = false;

  @override
  void initState() {
    super.initState();
    _postedToFeed = widget.clip.postedToFeed;
    _sharedToStory = widget.clip.sharedToStory;
  }

  String _highlightLabel(String type) {
    switch (type) {
      case 'peak_reactions':
        return '🔥 Peak Reactions';
      case 'peak_viewers':
        return '👥 Peak Viewers';
      case 'chat_burst':
        return '💬 Chat Burst';
      default:
        return '✂️ Manual Clip';
    }
  }

  Color _highlightColor(String type) {
    switch (type) {
      case 'peak_reactions':
        return AppColors.error;
      case 'peak_viewers':
        return AppColors.primary;
      case 'chat_burst':
        return AppColors.accent;
      default:
        return AppColors.textMuted;
    }
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes;
    final sec = d.inSeconds % 60;
    return '${min}m ${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    final clip = widget.clip;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_highlightColor(clip.highlightType).withValues(alpha: 0.3), AppColors.darkCard],
                    ),
                  ),
                  child: Icon(Icons.play_circle_outline, color: Colors.white.withValues(alpha: 0.7), size: 36),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(clip.duration),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clip.title,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _highlightColor(clip.highlightType).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _highlightLabel(clip.highlightType),
                      style: TextStyle(color: _highlightColor(clip.highlightType), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${clip.viewsCount}', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(width: 12),
                      Icon(Icons.favorite, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${clip.likesCount}', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _postedToFeed ? Icons.check_circle : Icons.add_circle_outline,
                  color: _postedToFeed ? AppColors.success : AppColors.textMuted,
                  size: 22,
                ),
                tooltip: _postedToFeed ? 'Posted to feed' : 'Post to feed',
                onPressed: () {
                  setState(() => _postedToFeed = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Clip posted to feed! 🎬'), backgroundColor: AppColors.success),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  _sharedToStory ? Icons.check_circle : Icons.amp_stories_outlined,
                  color: _sharedToStory ? AppColors.accent : AppColors.textMuted,
                  size: 22,
                ),
                tooltip: _sharedToStory ? 'Shared to story' : 'Share to story',
                onPressed: () {
                  setState(() => _sharedToStory = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Clip shared to story! ✨'), backgroundColor: AppColors.accent),
                  );
                },
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── Stream Summary Sheet ────────────────────────────────────────
class _StreamSummarySheet extends StatelessWidget {
  final String streamTitle;
  final Duration duration;
  final int peakViewers;
  final int totalReactions;
  final int totalMessages;
  final List<ClipModel> clips;
  final VoidCallback onDone;

  const _StreamSummarySheet({
    required this.streamTitle,
    required this.duration,
    required this.peakViewers,
    required this.totalReactions,
    required this.totalMessages,
    required this.clips,
    required this.onDone,
  });

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.darkBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Title
          const Text(
            'Stream Summary',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            streamTitle,
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Stats Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _StatTile(icon: Icons.timer, label: 'Duration', value: _formatDuration(duration), color: AppColors.primary),
                const SizedBox(width: 12),
                _StatTile(icon: Icons.visibility, label: 'Peak Viewers', value: '$peakViewers', color: AppColors.accent),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _StatTile(icon: Icons.favorite, label: 'Reactions', value: '$totalReactions', color: AppColors.error),
                const SizedBox(width: 12),
                _StatTile(icon: Icons.chat_bubble, label: 'Messages', value: '$totalMessages', color: AppColors.success),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Auto-generated clips
          if (clips.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Auto-Generated Clips',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${clips.length} clips',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...clips.map((c) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _ClipCard(clip: c),
            )),
          ],

          const SizedBox(height: 24),
          // Done button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onDone,
                    child: const Center(
                      child: Text(
                        'Done',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }
}

// ── Stat Tile (for stream summary) ──────────────────────────────
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
