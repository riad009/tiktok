import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/live_badge.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/data/mock_data.dart';
import '../../../core/services/api_service.dart';
import '../../../models/livestream_model.dart';

// ══════════════════════════════════════════════════════════════════
//  LIVESTREAM HUB — Browse active streams & replays
// ══════════════════════════════════════════════════════════════════

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: const Text('Live', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.only(right: 12),
            onPressed: _startLivestream,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.video_camera_solid, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Go Live', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
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
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              dividerHeight: 0,
              tabs: const [Tab(text: 'Live Now'), Tab(text: 'Replays')],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LiveNowTab(),
          _ReplaysTab(),
        ],
      ),
    );
  }

  void _startLivestream() {
    final user = ref.read(authUserProvider);
    if (user == null) return;

    final titleController = TextEditingController();

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Go Live'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            const Text('Enter a title for your livestream'),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: titleController,
              placeholder: 'Stream title...',
              padding: const EdgeInsets.all(12),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(ctx);

              // Try API first, fall back to mock
              try {
                final result = await ApiService.createStream(
                  userId: user.uid,
                  title: title,
                );
                if (result != null && mounted) {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => _LiveStreamingView(
                        streamId: result['id'] ?? '',
                        streamKey: result['streamKey'] ?? '',
                        playbackUrl: result['playbackUrl'] ?? '',
                        title: title,
                        hostUsername: user.username,
                        hostPhotoUrl: user.photoUrl,
                      ),
                    ),
                  );
                  return;
                }
              } catch (_) {}

              // Fallback — mock livestream
              if (mounted) {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => _LiveStreamingView(
                      streamId: 'local-${DateTime.now().millisecondsSinceEpoch}',
                      streamKey: '',
                      playbackUrl: '',
                      title: title,
                      hostUsername: user.username,
                      hostPhotoUrl: user.photoUrl,
                    ),
                  ),
                );
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}

// ── Live Now Tab ─────────────────────────────────────────────────

class _LiveNowTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final livestreamsAsync = ref.watch(activeLivestreamsProvider);

    return livestreamsAsync.when(
      data: (streams) {
        final liveStreams = streams.where((s) => s.isLive).toList();
        if (liveStreams.isEmpty) {
          return _buildEmpty(
            icon: CupertinoIcons.video_camera,
            title: 'No one is live right now',
            subtitle: 'Be the first to go live!',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: liveStreams.length,
          itemBuilder: (_, i) => _LivestreamCard(stream: liveStreams[i]),
        );
      },
      loading: () => const Center(
        child: CupertinoActivityIndicator(radius: 14, color: AppColors.primary),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ── Replays Tab ──────────────────────────────────────────────────

class _ReplaysTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final replays = MockData.replays;
    if (replays.isEmpty) {
      return _buildEmpty(
        icon: CupertinoIcons.play_rectangle,
        title: 'No replays yet',
        subtitle: 'Past livestreams will appear here',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: replays.length,
      itemBuilder: (_, i) => _LivestreamCard(stream: replays[i], isReplay: true),
    );
  }
}

// ── Livestream Card ──────────────────────────────────────────────

class _LivestreamCard extends StatelessWidget {
  final LivestreamModel stream;
  final bool isReplay;

  const _LivestreamCard({required this.stream, this.isReplay = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => _LiveStreamViewerView(stream: stream),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: stream.isLive
                ? AppColors.liveRed.withValues(alpha: 0.3)
                : AppColors.darkBorder,
          ),
        ),
        child: Column(
          children: [
            // Thumbnail / Preview
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3),
                    AppColors.secondary.withValues(alpha: 0.2),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(CupertinoIcons.video_camera_solid,
                        size: 48, color: AppColors.textMuted),
                  ),
                  // LIVE badge or Replay badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: stream.isLive
                        ? const LiveBadge()
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.darkCard.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('REPLAY',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary)),
                          ),
                  ),
                  // Viewer count
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.eye, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(_formatCount(stream.viewerCount),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.darkBorder,
                    backgroundImage: stream.hostPhotoUrl.isNotEmpty
                        ? NetworkImage(stream.hostPhotoUrl)
                        : null,
                    child: stream.hostPhotoUrl.isEmpty
                        ? Text(
                            stream.hostUsername.isNotEmpty
                                ? stream.hostUsername[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontWeight: FontWeight.w700))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stream.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('@${stream.hostUsername}',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (stream.isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Watch',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

// ── Viewer View (watching someone else's stream) ─────────────────

class _LiveStreamViewerView extends ConsumerStatefulWidget {
  final LivestreamModel stream;
  const _LiveStreamViewerView({required this.stream});

  @override
  ConsumerState<_LiveStreamViewerView> createState() =>
      _LiveStreamViewerViewState();
}

class _LiveStreamViewerViewState extends ConsumerState<_LiveStreamViewerView> {
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  final List<LiveChatMessage> _messages = [];
  int _viewerCount = 0;
  int _reactionCount = 0;
  sio.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _viewerCount = widget.stream.viewerCount;
    _reactionCount = widget.stream.totalReactions;
    // Seed with mock chat as fallback
    _messages.addAll([
      LiveChatMessage(
          id: 'lc1',
          senderId: 'user-005',
          username: 'tech_alex',
          text: 'This is awesome! 🔥',
          timestamp: DateTime.now().subtract(const Duration(minutes: 2))),
      LiveChatMessage(
          id: 'lc2',
          senderId: 'user-002',
          username: 'sarah_creates',
          text: 'Love the vibes!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 1))),
      LiveChatMessage(
          id: 'lc3',
          senderId: 'user-007',
          username: 'traveler_jay',
          text: 'Can you do a tutorial?',
          timestamp: DateTime.now().subtract(const Duration(seconds: 30))),
    ]);
    _connectSocket();
  }

  void _connectSocket() {
    try {
      final baseUrl = ApiService.socketUrl;
      final user = ref.read(authUserProvider);
      _socket = sio.io(baseUrl, sio.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .build());

      _socket!.connect();

      _socket!.onConnect((_) {
        _socket!.emit('join_stream', {
          'streamId': widget.stream.id,
          'username': user?.username ?? 'viewer',
        });
      });

      _socket!.on('chat_message', (data) {
        if (mounted) {
          setState(() {
            _messages.add(LiveChatMessage(
              id: data['id'] ?? 'rt-${DateTime.now().millisecondsSinceEpoch}',
              senderId: data['username'] ?? '',
              username: data['username'] ?? 'unknown',
              text: data['text'] ?? '',
              timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
            ));
          });
          _scrollToBottom();
        }
      });

      _socket!.on('viewer_count', (count) {
        if (mounted) setState(() => _viewerCount = count is int ? count : int.tryParse(count.toString()) ?? _viewerCount);
      });

      _socket!.on('reaction', (data) {
        if (mounted) setState(() => _reactionCount++);
      });
    } catch (e) {
      // Socket unavailable — continue with mock
      debugPrint('Socket connection failed: $e');
    }
  }

  @override
  void dispose() {
    _socket?.emit('leave_stream');
    _socket?.disconnect();
    _socket?.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(authUserProvider);
    // Send via socket if connected
    if (_socket?.connected == true) {
      _socket!.emit('chat_message', {
        'streamId': widget.stream.id,
        'username': user?.username ?? 'You',
        'text': text,
        'photoUrl': user?.photoUrl ?? '',
      });
    } else {
      // Fallback to local-only
      setState(() {
        _messages.add(LiveChatMessage(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
          senderId: user?.uid ?? 'anon',
          username: user?.username ?? 'You',
          text: text,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
    _chatController.clear();
  }

  void _sendReaction() {
    if (_socket?.connected == true) {
      final user = ref.read(authUserProvider);
      _socket!.emit('reaction', {
        'streamId': widget.stream.id,
        'emoji': '❤️',
        'username': user?.username ?? 'viewer',
      });
    }
    setState(() => _reactionCount++);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Background / video placeholder
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      Colors.black,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.stream.isLive
                            ? CupertinoIcons.video_camera_solid
                            : CupertinoIcons.play_rectangle_fill,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.stream.isLive
                            ? 'Live Stream'
                            : 'Replay',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Host info
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.darkCard,
                      backgroundImage: widget.stream.hostPhotoUrl.isNotEmpty
                          ? NetworkImage(widget.stream.hostPhotoUrl)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.stream.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text('@${widget.stream.hostUsername}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    // Viewer count
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.eye, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('$_viewerCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Close
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.xmark,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Chat overlay (bottom half)
            Positioned(
              bottom: 70,
              left: 0,
              right: 60,
              height: 250,
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.white],
                  stops: const [0.0, 0.3],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg = _messages[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: RichText(
                          text: TextSpan(children: [
                            TextSpan(
                              text: '${msg.username}  ',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
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
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Reaction button (right side)
            Positioned(
              right: 12,
              bottom: 140,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _sendReaction,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('❤️', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_formatCount(_reactionCount),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Shared! 🔗'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.share,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Chat input
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _chatController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Say something...',
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (_) => _sendChat(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendChat,
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
            ),
          ],
        ),
      ),
    );
  }

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

// ── Host Streaming View (when you go live) ───────────────────────

class _LiveStreamingView extends ConsumerStatefulWidget {
  final String streamId;
  final String streamKey;
  final String playbackUrl;
  final String title;
  final String hostUsername;
  final String hostPhotoUrl;

  const _LiveStreamingView({
    required this.streamId,
    required this.streamKey,
    required this.playbackUrl,
    required this.title,
    required this.hostUsername,
    required this.hostPhotoUrl,
  });

  @override
  ConsumerState<_LiveStreamingView> createState() =>
      _LiveStreamingViewState();
}

class _LiveStreamingViewState extends ConsumerState<_LiveStreamingView> {
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  final List<LiveChatMessage> _messages = [];
  int _viewerCount = 0;
  int _reactionCount = 0;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  sio.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed += const Duration(seconds: 1);
        });
      }
    });

    _connectSocket();
  }

  void _connectSocket() {
    try {
      final baseUrl = ApiService.socketUrl;
      _socket = sio.io(baseUrl, sio.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .build());

      _socket!.connect();

      _socket!.onConnect((_) {
        // Join stream as host
        _socket!.emit('join_stream', {
          'streamId': widget.streamId,
          'username': widget.hostUsername,
        });
        if (mounted) {
          setState(() {
            _messages.add(LiveChatMessage(
              id: 'sys-1',
              senderId: 'system',
              username: 'system',
              text: '🎉 You are now live!',
              timestamp: DateTime.now(),
            ));
          });
        }
      });

      _socket!.on('chat_message', (data) {
        if (mounted) {
          setState(() {
            _messages.add(LiveChatMessage(
              id: data['id'] ?? 'rt-${DateTime.now().millisecondsSinceEpoch}',
              senderId: data['username'] ?? '',
              username: data['username'] ?? 'unknown',
              text: data['text'] ?? '',
              timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
            ));
          });
        }
      });

      _socket!.on('viewer_count', (count) {
        if (mounted) setState(() => _viewerCount = count is int ? count : int.tryParse(count.toString()) ?? _viewerCount);
      });

      _socket!.on('reaction', (data) {
        if (mounted) setState(() => _reactionCount++);
      });

      _socket!.onDisconnect((_) {
        debugPrint('Host socket disconnected');
      });
    } catch (e) {
      debugPrint('Socket connection failed: $e');
      // Fallback: add system message locally
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _messages.add(LiveChatMessage(
              id: 'sys-1',
              senderId: 'system',
              username: 'system',
              text: '🎉 You are now live!',
              timestamp: DateTime.now(),
            ));
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _socket?.emit('leave_stream');
    _socket?.disconnect();
    _socket?.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    if (_socket?.connected == true) {
      _socket!.emit('chat_message', {
        'streamId': widget.streamId,
        'username': widget.hostUsername,
        'text': text,
        'photoUrl': '',
      });
    } else {
      setState(() {
        _messages.add(LiveChatMessage(
          id: 'host-${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'host',
          username: widget.hostUsername,
          text: text,
          timestamp: DateTime.now(),
        ));
      });
    }
    _chatController.clear();
  }

  void _endStream() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('End Livestream?'),
        content: Text(
            'Duration: ${_formatDuration(_elapsed)}\nViewers: $_viewerCount'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('End Stream'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview placeholder
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.secondary.withValues(alpha: 0.1),
                      Colors.black,
                    ],
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.video_camera_solid,
                          size: 64, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text('Camera Preview',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // LIVE indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.liveRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('LIVE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Duration
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_formatDuration(_elapsed),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    // Viewer count
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.eye,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('$_viewerCount',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // End stream button
                    GestureDetector(
                      onTap: _endStream,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.liveRed,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('End',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Chat messages (bottom half)
            Positioned(
              bottom: 70,
              left: 0,
              right: 60,
              height: 200,
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.white],
                  stops: const [0.0, 0.3],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg = _messages[i];
                    final isSystem = msg.senderId == 'system';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSystem
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: isSystem
                            ? Text(msg.text,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13))
                            : RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                    text: '${msg.username}  ',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w700,
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
                                ]),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Reactions on right side
            Positioned(
              right: 12,
              bottom: 140,
              child: Column(
                children: [
                  Text('❤️ $_reactionCount',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12)),
                ],
              ),
            ),

            // Chat input
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.black.withValues(alpha: 0.7),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _chatController,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Chat with viewers...',
                            hintStyle: TextStyle(
                                color: AppColors.textMuted, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (_) => _sendChat(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendChat,
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
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper ───────────────────────────────────────────────────────

Widget _buildEmpty({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: AppColors.textMuted),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(subtitle,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14)),
      ],
    ),
  );
}
