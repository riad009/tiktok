import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/live_badge.dart' hide AnimatedBuilder;
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/artistcase_logo.dart';
import '../../../models/livestream_model.dart';

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
                tabs: const [Tab(text: 'Live Now'), Tab(text: 'Replays')],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_LiveNowTab(onOpen: _openLiveViewer), _ReplaysTab()],
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

  Future<void> _createStream() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      final info = await ApiService.createStream(
        userId: uid,
        title: _titleCtrl.text.trim().isEmpty
            ? 'Untitled Stream'
            : _titleCtrl.text.trim(),
      );
      if (info != null && mounted) setState(() => _streamInfo = info);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.redAccent),
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
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary))
                    : ElevatedButton.icon(
                        onPressed: _createStream,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const SizedBox.shrink(),
                        label: Ink(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const SizedBox(
                            height: 52,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.videocam, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Create Stream',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                ],
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
}

// Copyable credential tile
class _CredentialTile extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool obscured;
  const _CredentialTile(
      {required this.label,
      required this.value,
      required this.icon,
      this.obscured = false});
  @override
  State<_CredentialTile> createState() => _CredentialTileState();
}

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
        child: Stack(children: [
          // Thumbnail / gradient bg
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
              child: const Center(
                  child: Icon(Icons.videocam, size: 40, color: Colors.white24)),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(200)],
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
                Text(stream.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 6),
                Row(children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primary,
                    backgroundImage: stream.hostPhotoUrl.isNotEmpty
                        ? NetworkImage(stream.hostPhotoUrl) : null,
                    child: stream.hostPhotoUrl.isEmpty
                        ? const Icon(Icons.person, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(stream.hostUsername,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Replays tab ───────────────────────────────────────────────────
class _ReplaysTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUidProvider);
    if (uid == null) {
      return const Center(
          child: Text('Sign in to see your replays',
              style: TextStyle(color: AppColors.textMuted)));
    }
    final replaysAsync = ref.watch(userReplaysProvider(uid));
    return replaysAsync.when(
      data: (replays) {
        if (replays.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.replay, size: 64, color: AppColors.textMuted),
                SizedBox(height: 16),
                Text('No replays yet',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 16)),
                SizedBox(height: 8),
                Text('Your streams will appear here automatically',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 14)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: replays.length,
          itemBuilder: (ctx, i) {
            final r = replays[i];
            return GestureDetector(
              onTap: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                    builder: (_) => _ReplayPlayerScreen(replay: r)),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(children: [
                  Container(
                    width: 60, height: 60,
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
                        Text(r['title'] ?? 'Replay',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                          r['status'] == 'ready'
                              ? 'Ready to watch'
                              : 'Processing...',
                          style: TextStyle(
                              color: r['status'] == 'ready'
                                  ? Colors.greenAccent
                                  : AppColors.textMuted,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: AppColors.textMuted),
                ]),
              ),
            );
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) =>
          const Center(child: Text('Error loading replays')),
    );
  }
}

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
