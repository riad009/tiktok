import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/live_badge.dart' hide AnimatedBuilder;
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/artistcase_logo.dart';
import '../../../core/data/mock_data.dart';
import '../../../models/livestream_model.dart';
import '../../../models/clip_model.dart';

// ── HLS Video Player widget (works on iOS, Android, Web) ─────────
class _HLSPlayer extends StatefulWidget {
  final String hlsUrl;
  final bool autoPlay;
  final bool showControls;
  final bool isLive;

  const _HLSPlayer({
    required this.hlsUrl,
    this.autoPlay = true,
    this.showControls = false,
    this.isLive = true,
  });

  @override
  State<_HLSPlayer> createState() => _HLSPlayerState();
}

class _HLSPlayerState extends State<_HLSPlayer> {
  VideoPlayerController? _vp;
  ChewieController? _chewie;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _vp = VideoPlayerController.networkUrl(Uri.parse(widget.hlsUrl));
      await _vp!.initialize();
      _chewie = ChewieController(
        videoPlayerController: _vp!,
        autoPlay: widget.autoPlay,
        looping: false,
        showControls: widget.showControls,
        aspectRatio: _vp!.value.aspectRatio,
        errorBuilder: (_, msg) => _errorWidget(msg),
        placeholder: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          bufferedColor: Colors.white30,
          backgroundColor: Colors.white10,
        ),
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  Widget _errorWidget(String msg) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white38, size: 48),
            const SizedBox(height: 8),
            Text('Stream unavailable',
                style: const TextStyle(color: Colors.white38)),
          ],
        ),
      );

  @override
  void dispose() {
    _chewie?.dispose();
    _vp?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return _errorWidget('');
    if (_chewie == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    return Chewie(controller: _chewie!);
  }
}

// ── Main Livestream screen ────────────────────────────────────────
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
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const LiveBadge(size: 16),
                  const SizedBox(width: 12),
                  const Text('Live',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _GoLiveButton(onTap: _showGoLiveSheet),
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

  void _openLiveViewer(LivestreamModel stream) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LivestreamViewerScreen(stream: stream),
      ),
    );
  }

  void _showGoLiveSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _GoLiveSheet(),
    );
  }
}

// ── Go Live button ────────────────────────────────────────────────
class _GoLiveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoLiveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(90),
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
            Text('Go Live',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ── Go Live sheet — calls real Mux API ───────────────────────────
class _GoLiveSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_GoLiveSheet> createState() => _GoLiveSheetState();
}

class _GoLiveSheetState extends ConsumerState<_GoLiveSheet> {
  final _titleCtrl = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _streamInfo; // {streamKey, rtmpUrl, streamId}

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
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
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.darkBorder,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                LiveBadge(size: 14),
                SizedBox(width: 10),
                Text('Start Livestream',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),

            if (_streamInfo == null) ...[
              // Step 1: enter title
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  hintText: "What's your stream about?",
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.darkCard,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  prefixIcon:
                      const Icon(Icons.title, color: AppColors.primary),
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
                          ),
                        ),
                      ),
              ),
            ] else ...[
              // Step 2: show RTMP credentials
              const Text(
                'Your stream is ready! 🎉',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Open OBS, Streamlabs, or your iPhone camera app and enter these settings:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              _CredentialTile(
                label: 'RTMP Server URL',
                value: _streamInfo!['rtmpUrl'] ?? 'rtmps://global-live.mux.com:443/app',
                icon: Icons.link,
              ),
              const SizedBox(height: 12),
              _CredentialTile(
                label: 'Stream Key',
                value: _streamInfo!['streamKey'] ?? '—',
                icon: Icons.key,
                obscured: true,
              ),
              const SizedBox(height: 20),
              // iPhone instructions
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(60)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('📱', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Text('iPhone 11 (iOS)',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: Colors.white)),
                    ]),
                    SizedBox(height: 8),
                    Text(
                      '1. Download Larix Broadcaster (free)\n'
                      '2. Settings → Connections → New Connection\n'
                      '3. Paste the RTMP URL + Stream Key above\n'
                      '4. Tap the record button to go live ✅\n\n'
                      'HLS playback is automatic — viewers see your stream instantly.',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done — I\'m streaming!',
                      style: TextStyle(color: AppColors.primary, fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
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

class _CredentialTileState extends State<_CredentialTile> {
  bool _show = false;
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.value));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final display = widget.obscured && !_show
        ? '••••••••••••••••'
        : widget.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(widget.label,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(display,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis),
              ),
              if (widget.obscured)
                IconButton(
                  icon: Icon(
                      _show ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: AppColors.textMuted),
                  onPressed: () => setState(() => _show = !_show),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _copy,
                child: Row(
                  children: [
                    Icon(
                        _copied ? Icons.check_circle : Icons.copy,
                        size: 18,
                        color: _copied ? Colors.greenAccent : AppColors.primary),
                    const SizedBox(width: 4),
                    Text(_copied ? 'Copied!' : 'Copy',
                        style: TextStyle(
                            fontSize: 12,
                            color: _copied ? Colors.greenAccent : AppColors.primary,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Live Now tab ──────────────────────────────────────────────────
class _LiveNowTab extends ConsumerStatefulWidget {
  final void Function(LivestreamModel) onOpen;
  const _LiveNowTab({required this.onOpen});

  @override
  ConsumerState<_LiveNowTab> createState() => _LiveNowTabState();
}

class _LiveNowTabState extends ConsumerState<_LiveNowTab> {
  // Mutable list — seeded from provider, updated by socket events
  List<LivestreamModel> _streams = [];
  bool _initialised = false;

  // Socket.io connection (lazy — initialised after first build)
  dynamic _socket;

  static const _socketUrl = 'http://localhost:3001';

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  void _connectSocket() {
    try {
      _socket = sio.io(
        _socketUrl,
        sio.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );
      _socket.connect();

      // 📡 New stream created — add to top of list
      _socket.on('stream_created', (data) {
        if (!mounted) return;
        try {
          final stream = LivestreamModel.fromJson(
            Map<String, dynamic>.from(data as Map),
          );
          setState(() {
            if (!_streams.any((s) => s.id == stream.id)) {
              _streams = [stream, ..._streams];
            }
          });
        } catch (_) {}
      });

      // 📡 Stream ended — remove from list
      _socket.on('stream_ended', (data) {
        if (!mounted) return;
        final id = (data as Map)['id']?.toString() ?? '';
        if (id.isEmpty) return;
        setState(() => _streams = _streams.where((s) => s.id != id).toList());
      });
    } catch (e) {
      debugPrint('LiveNowTab socket error (degraded): $e');
    }
  }

  @override
  void dispose() {
    _socket?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Seed from provider on first load
    final liveAsync = ref.watch(activeLivestreamsProvider);
    liveAsync.whenData((data) {
      if (!_initialised && data.isNotEmpty) {
        _streams = List.from(data);
        _initialised = true;
      }
    });

    if (!_initialised && liveAsync is AsyncLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_streams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.live_tv, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('No one is live right now',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Be the first to go live!',
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 14)),
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
      itemCount: _streams.length,
      itemBuilder: (_, i) => _LiveCard(
          stream: _streams[i],
          onTap: () => widget.onOpen(_streams[i])),
    );
  }
}


class _LiveCard extends StatelessWidget {
  final LivestreamModel stream;
  final VoidCallback onTap;
  const _LiveCard({required this.stream, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withAlpha(80)),
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

  void _endStream() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('End Livestream?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to end your livestream?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isLive = false);
              _showStreamSummary();
            },
            child: const Text('End Stream',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showStreamSummary() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _StreamSummarySheet(
        viewerCount: _viewerCount,
        totalReactions: _totalReactions,
        onDone: () {
          Navigator.pop(ctx);
          Navigator.pop(context);
        },
      ),
    );
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
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withAlpha(50),
                    AppColors.secondary.withAlpha(50),
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
          const Positioned(top: 8, left: 8, child: LiveBadge(size: 10)),
          Positioned(
            top: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.remove_red_eye,
                      size: 12, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text('${stream.viewerCount}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
          Positioned(
            left: 10, right: 10, bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(colors: [
                        AppColors.secondary.withAlpha(80),
                        AppColors.primary.withAlpha(80),
                      ]),
                    ),
                    child: const Icon(Icons.play_circle_fill,
                        color: Colors.white70, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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

// ── Replay Player Screen ──────────────────────────────────────────
class _ReplayPlayerScreen extends StatelessWidget {
  final Map<String, dynamic> replay;
  const _ReplayPlayerScreen({required this.replay});

  @override
  Widget build(BuildContext context) {
    final playbackUrl = replay['playbackUrl'] as String? ?? '';
    final title = replay['title'] as String? ?? 'Replay';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(title),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // HLS Player — iOS/Android/Web compatible via video_player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: playbackUrl.isNotEmpty
                ? _HLSPlayer(
                    hlsUrl: playbackUrl,
                    showControls: true,
                    isLive: false,
                  )
                : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hourglass_empty,
                            color: Colors.white38, size: 48),
                        SizedBox(height: 8),
                        Text('Replay is processing...',
                            style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  ),
          ),
          // Artistcase watermark over player
          const ArtistcaseWatermark(size: 14, opacity: 0.3),
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

// ── Viewer Screen — Socket.io + HLS from Mux ─────────────────────
class LivestreamViewerScreen extends ConsumerStatefulWidget {
  final LivestreamModel stream;
  const LivestreamViewerScreen({super.key, required this.stream});

  @override
  ConsumerState<LivestreamViewerScreen> createState() =>
      _LivestreamViewerScreenState();
}

class _LivestreamViewerScreenState
    extends ConsumerState<LivestreamViewerScreen>
    with SingleTickerProviderStateMixin {
  final _chatCtrl = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  final List<_FloatingEmoji> _floatingEmojis = [];

  int _viewers = 0;
  bool _hlsReady = false;
  late AnimationController _emojiAnim;

  @override
  void initState() {
    super.initState();
    _viewers = widget.stream.viewerCount;
    _emojiAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _waitForHls();
  }

  /// Poll / wait until HLS stream starts (Mux can take 10–30 s)
  Future<void> _waitForHls() async {
    if (widget.stream.playbackUrl.isNotEmpty) {
      if (mounted) setState(() => _hlsReady = true);
      return;
    }
    int attempts = 0;
    while (mounted && !_hlsReady && attempts < 20) {
      await Future.delayed(const Duration(seconds: 2));
      attempts++;
    }
    if (mounted) setState(() => _hlsReady = true);
  }

  void _addFloatingEmoji(String emoji) {
    final fe = _FloatingEmoji(emoji: emoji, id: DateTime.now().microsecondsSinceEpoch);
    setState(() => _floatingEmojis.add(fe));
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _floatingEmojis.remove(fe));
    });
  }

  void _sendChat() {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(authUserProvider);
    if (user == null) return;
    setState(() {
      _chatMessages.insert(0, {
        'username': user.username,
        'text': text,
        'photoUrl': user.photoUrl,
      });
      if (_chatMessages.length > 100) _chatMessages.removeLast();
    });
    _chatCtrl.clear();
  }

  void _sendReaction(String emoji) {
    final user = ref.read(authUserProvider);
    if (user == null) return;
    _addFloatingEmoji(emoji);
    setState(() {
      _chatMessages.insert(0, {
        'username': user.username,
        'text': emoji,
        'photoUrl': user.photoUrl,
      });
    });
  }

  @override
  void dispose() {
    _chatCtrl.dispose();
    _emojiAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playbackUrl = widget.stream.playbackUrl;
    final hasHls = playbackUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── HLS Video ─────────────────────────────────────────
          Positioned.fill(
            child: hasHls && _hlsReady
                ? _HLSPlayer(
                    hlsUrl: playbackUrl,
                    showControls: false,
                    isLive: true,
                  )
                : _StreamLoadingPlaceholder(
                    title: widget.stream.title,
                    isRetrying: !_hlsReady,
                  ),
          ),

          // ── Floating emojis ────────────────────────────────────
          ...(_floatingEmojis.map((fe) => Positioned(
                right: 70,
                bottom: 200,
                child: _FloatingEmojiWidget(
                    key: ValueKey(fe.id), emoji: fe.emoji),
              ))),

          // ── Top bar ────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16, right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  backgroundImage: widget.stream.hostPhotoUrl.isNotEmpty
                      ? NetworkImage(widget.stream.hostPhotoUrl) : null,
                  child: widget.stream.hostPhotoUrl.isEmpty
                      ? const Icon(Icons.person, size: 18, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.stream.hostUsername,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      Row(children: [
                        const LiveBadge(size: 8, showPulse: true),
                        const SizedBox(width: 6),
                        Text('$_viewers watching',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12)),
                        const SizedBox(width: 8),
                        // HD quality badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(4)),
                          child: const Text('HD',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                        color: Colors.black45, shape: BoxShape.circle),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // ── Chat overlay ────────────────────────────────────
          Positioned(
            left: 12, right: 72, bottom: 76,
            height: 240,
            child: ListView.builder(
              reverse: true,
              itemCount: _chatMessages.length,
              itemBuilder: (_, i) {
                final msg = _chatMessages[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GlassCard(
                    blur: 4, opacity: 0.15,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    borderRadius: BorderRadius.circular(12),
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: '${msg['username']} ',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                        TextSpan(
                          text: msg['text'],
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Reaction buttons ──────────────────────────────────
          Positioned(
            right: 12, bottom: 110,
            child: Column(
              children: ['❤️', '🔥', '👏', '💎'].map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _sendReaction(e),
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12)),
                    child: Center(
                        child: Text(e,
                            style: const TextStyle(fontSize: 22))),
                  ),
                ),
              )).toList(),
            ),
          ),

          // ── Chat input ────────────────────────────────────────
          Positioned(
            left: 12, right: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(24)),
                  child: TextField(
                    controller: _chatCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                        hintText: 'Say something...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10)),
                    onSubmitted: (_) => _sendChat(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendChat,
                child: Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle),
                  child: const Icon(Icons.send,
                      color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),

          // ── Artistcase watermark ──────────────────────────────
          const ArtistcaseWatermark(size: 14, opacity: 0.25),
        ],
      ),
    );
  }
}

// ── Stream loading placeholder ────────────────────────────────────
class _StreamLoadingPlaceholder extends StatelessWidget {
  final String title;
  final bool isRetrying;
  const _StreamLoadingPlaceholder(
      {required this.title, required this.isRetrying});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.live_tv, size: 64, color: Colors.white12),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(color: Colors.white38, fontSize: 18)),
            const SizedBox(height: 12),
            if (isRetrying) ...[
              const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2),
              ),
              const SizedBox(height: 8),
              const Text('Waiting for stream to start...',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Floating emoji reaction ───────────────────────────────────────
class _FloatingEmoji {
  final String emoji;
  final int id;
  _FloatingEmoji({required this.emoji, required this.id});
}

class _FloatingEmojiWidget extends StatefulWidget {
  final String emoji;
  const _FloatingEmojiWidget({super.key, required this.emoji});
  @override
  State<_FloatingEmojiWidget> createState() => _FloatingEmojiWidgetState();
}

class _FloatingEmojiWidgetState extends State<_FloatingEmojiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3));
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1.0)));
    _slide = Tween<double>(begin: 0, end: -120).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _slide.value),
        child: Opacity(
          opacity: _opacity.value,
          child: Text(widget.emoji,
              style: const TextStyle(fontSize: 30)),
        ),
      ),
    );
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

// ── Stream Summary + Auto-Clip Prompt ─────────────────────────────
class _StreamSummarySheet extends StatefulWidget {
  final int viewerCount;
  final int totalReactions;
  final VoidCallback onDone;

  const _StreamSummarySheet({
    required this.viewerCount,
    required this.totalReactions,
    required this.onDone,
  });

  @override
  State<_StreamSummarySheet> createState() => _StreamSummarySheetState();
}

class _StreamSummarySheetState extends State<_StreamSummarySheet> {
  bool _isClipping = false;
  double _clipProgress = 0;

  void _startAutoClip() {
    setState(() => _isClipping = true);
    // Simulate clip generation progress
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return false;
      setState(() => _clipProgress += 0.025);
      if (_clipProgress >= 1.0) {
        // Done — show success then dismiss
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) widget.onDone();
        return false;
      }
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('🎬 Stream Ended',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Great stream! Here\'s your summary.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),

            // Stats row
            Row(
              children: [
                _StatTile(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: '${(5 + widget.viewerCount).clamp(1, 60)}m',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _StatTile(
                  icon: Icons.visibility_outlined,
                  label: 'Peak Viewers',
                  value: '${widget.viewerCount}',
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 12),
                _StatTile(
                  icon: Icons.favorite_outline,
                  label: 'Reactions',
                  value: '${widget.totalReactions}',
                  color: AppColors.liveRed,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Auto-clip section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary, size: 32),
                  const SizedBox(height: 10),
                  const Text('Auto-Generate Clips?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text(
                    'We can automatically clip the best moments from your livestream and upload them to your feed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  if (_isClipping) ...[
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _clipProgress,
                        backgroundColor: AppColors.darkBorder,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _clipProgress >= 1.0
                          ? '✅ Clips uploaded to your feed!'
                          : 'Generating clips… ${(_clipProgress * 100).toInt()}%',
                      style: TextStyle(
                        color: _clipProgress >= 1.0 ? Colors.green : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ] else ...[
                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _startAutoClip,
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Yes — Auto Clip & Upload',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: widget.onDone,
                      child: const Text('No thanks',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
