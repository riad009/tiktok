import 'dart:async';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'dart:js' as js;
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

// ═══════════════════════════════════════════════════════════════════
// LIVESTREAM SCREEN — main tab page with Live Now / Replays
// ═══════════════════════════════════════════════════════════════════

class LivestreamScreen extends ConsumerStatefulWidget {
  const LivestreamScreen({super.key});
  @override
  ConsumerState<LivestreamScreen> createState() => _LivestreamScreenState();
}

class _LivestreamScreenState extends ConsumerState<LivestreamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _openLiveViewer(LivestreamModel stream) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LivestreamViewerScreen(stream: stream),
      ),
    );
  }

  Future<void> _goLive() async {
    final user = ref.read(authUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    // Show the Go Live sheet with camera preview
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _GoLiveSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
              child: Row(
                children: [
                  const LiveBadge(size: 14, showPulse: true),
                  const SizedBox(width: 10),
                  const Text('Livestream',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  _GoLiveButton(onTap: _goLive),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Tabs ────────────────────────────────────────
            TabBar(
              controller: _tab,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              tabs: const [
                Tab(text: 'Live Now'),
                Tab(text: 'Replays'),
              ],
            ),

            // ── Tab content ─────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _LiveNowTab(onOpen: _openLiveViewer),
                  const _ReplaysTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// GO LIVE BUTTON
// ═══════════════════════════════════════════════════════════════════

class _GoLiveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoLiveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam, color: Colors.white, size: 18),
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

// ═══════════════════════════════════════════════════════════════════
// GO LIVE SHEET — requests camera/mic, shows preview, creates stream
// ═══════════════════════════════════════════════════════════════════

class _GoLiveSheet extends ConsumerStatefulWidget {
  const _GoLiveSheet();
  @override
  ConsumerState<_GoLiveSheet> createState() => _GoLiveSheetState();
}

class _GoLiveSheetState extends ConsumerState<_GoLiveSheet> {
  final _titleCtrl = TextEditingController();
  bool _loading = false;
  bool _cameraReady = false;
  bool _permissionDenied = false;
  html.MediaStream? _mediaStream;
  String? _viewId;

  @override
  void initState() {
    super.initState();
    _requestCamera();
  }

  Future<void> _requestCamera() async {
    try {
      // Request camera + microphone permissions
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
        'audio': true,
      });

      _mediaStream = stream;

      // Create an HTML video element and register it for Flutter web
      final videoElement = html.VideoElement()
        ..srcObject = stream
        ..autoplay = true
        ..muted = true // mute self-preview to avoid echo
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.transform = 'scaleX(-1)'; // mirror selfie cam

      _viewId = 'camera-preview-${DateTime.now().millisecondsSinceEpoch}';
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
          _viewId!, (int viewId) => videoElement);

      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      debugPrint('Camera permission error: $e');
      if (mounted) setState(() => _permissionDenied = true);
    }
  }

  Future<void> _createStream() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final user = ref.read(authUserProvider);
      if (user == null) return;

      final title = _titleCtrl.text.trim().isEmpty
          ? 'Untitled Stream'
          : _titleCtrl.text.trim();

      final res = await ApiService.createStream(
        userId: user.uid,
        title: title,
      );

      if (res != null && mounted) {
        final stream = LivestreamModel.fromJson(res);
        Navigator.pop(context); // close sheet

        // Navigate to the host broadcasting screen
        // ignore: use_build_context_synchronously
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _HostBroadcastScreen(
              stream: stream,
              mediaStream: _mediaStream!,
              viewId: _viewId!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    // Don't stop the camera here if we're navigating to host screen
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
            const SizedBox(height: 16),
            const Row(
              children: [
                LiveBadge(size: 14),
                SizedBox(width: 10),
                Text('Go Live',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            // ── Camera preview ────────────────────────────
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: _permissionDenied
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam_off,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          const Text('Camera access denied',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _requestCamera,
                            child: const Text('Try Again',
                                style: TextStyle(color: AppColors.primary)),
                          ),
                        ],
                      ),
                    )
                  : _cameraReady && _viewId != null
                      ? Stack(
                          children: [
                            HtmlElementView(viewType: _viewId!),
                            // LIVE badge on preview
                            Positioned(
                              top: 12, left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.circle,
                                        size: 8, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('PREVIEW',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                  color: AppColors.primary),
                              SizedBox(height: 12),
                              Text('Requesting camera access...',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
            ),
            const SizedBox(height: 16),

            // ── Title input ───────────────────────────────
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "What's your stream about?",
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.darkCard,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                prefixIcon:
                    const Icon(Icons.title, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),

            // ── Go Live button ────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _cameraReady
                      ? AppColors.primaryGradient
                      : const LinearGradient(
                          colors: [Colors.grey, Colors.grey]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _cameraReady
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12, offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _cameraReady ? _createStream : null,
                    child: Center(
                      child: _loading
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.videocam,
                                    color: Colors.white, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  _cameraReady
                                      ? 'Go Live Now 🚀'
                                      : 'Waiting for camera...',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HOST BROADCAST SCREEN — shows camera feed + chat + controls
// ═══════════════════════════════════════════════════════════════════

class _HostBroadcastScreen extends ConsumerStatefulWidget {
  final LivestreamModel stream;
  final html.MediaStream mediaStream;
  final String viewId;

  const _HostBroadcastScreen({
    required this.stream,
    required this.mediaStream,
    required this.viewId,
  });

  @override
  ConsumerState<_HostBroadcastScreen> createState() =>
      _HostBroadcastScreenState();
}

class _HostBroadcastScreenState extends ConsumerState<_HostBroadcastScreen> {
  final _chatCtrl = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  Timer? _timer;
  int _viewers = 0;
  int _duration = 0;
  bool _isMuted = false;
  bool _isCameraOff = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _duration++);
    });
    // Simulate viewer count increases for demo
    Timer.periodic(const Duration(seconds: 5), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _viewers += 1);
    });
  }

  String get _formattedDuration {
    final h = _duration ~/ 3600;
    final m = (_duration % 3600) ~/ 60;
    final s = _duration % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _toggleMute() {
    final audioTracks = widget.mediaStream.getAudioTracks();
    for (final track in audioTracks) {
      track.enabled = !track.enabled!;
    }
    setState(() => _isMuted = !_isMuted);
  }

  void _toggleCamera() {
    final videoTracks = widget.mediaStream.getVideoTracks();
    for (final track in videoTracks) {
      track.enabled = !track.enabled!;
    }
    setState(() => _isCameraOff = !_isCameraOff);
  }

  void _endStream() {
    // Stop all tracks
    for (final track in widget.mediaStream.getTracks()) {
      track.stop();
    }
    // Delete stream from backend
    // ApiService.deleteStream(widget.stream.id); // TODO: implement
    Navigator.pop(context);
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
      });
    });
    _chatCtrl.clear();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chatCtrl.dispose();
    // Stop camera when leaving
    for (final track in widget.mediaStream.getTracks()) {
      track.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera feed (full screen) ────────────────────
          Positioned.fill(
            child: _isCameraOff
                ? Container(
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam_off,
                              size: 64, color: Colors.white24),
                          SizedBox(height: 12),
                          Text('Camera Off',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 16)),
                        ],
                      ),
                    ),
                  )
                : HtmlElementView(viewType: widget.viewId),
          ),

          // ── Top bar ─────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16, right: 16,
            child: Row(
              children: [
                // LIVE badge + timer
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle,
                          size: 8, color: Colors.white),
                      const SizedBox(width: 6),
                      const Text('LIVE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Text(_formattedDuration,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Viewer count
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility,
                          size: 14, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text('$_viewers',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),

                const Spacer(),

                // End stream button
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.darkCard,
                        title: const Text('End Stream?',
                            style: TextStyle(color: Colors.white)),
                        content: const Text(
                            'Are you sure you want to end this livestream?',
                            style: TextStyle(color: AppColors.textSecondary)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _endStream();
                            },
                            child: const Text('End Stream',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('End',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),

          // ── Stream title ────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 56,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(widget.stream.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
          ),

          // ── Chat overlay ────────────────────────────────
          Positioned(
            left: 12, right: 90, bottom: 90,
            height: 200,
            child: ListView.builder(
              reverse: true,
              itemCount: _chatMessages.length,
              itemBuilder: (_, i) {
                final msg = _chatMessages[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(10),
                    ),
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

          // ── Bottom controls ─────────────────────────────
          Positioned(
            left: 12, right: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: Row(children: [
              // Chat input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(24)),
                  child: TextField(
                    controller: _chatCtrl,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14),
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

              // Send
              _ControlButton(
                icon: Icons.send,
                onTap: _sendChat,
                gradient: true,
              ),
              const SizedBox(width: 8),

              // Toggle mic
              _ControlButton(
                icon: _isMuted ? Icons.mic_off : Icons.mic,
                onTap: _toggleMute,
                active: !_isMuted,
              ),
              const SizedBox(width: 8),

              // Toggle camera
              _ControlButton(
                icon: _isCameraOff
                    ? Icons.videocam_off
                    : Icons.videocam,
                onTap: _toggleCamera,
                active: !_isCameraOff,
              ),
            ]),
          ),

          // ── Watermark ───────────────────────────────────
          const ArtistcaseWatermark(size: 14, opacity: 0.25),
        ],
      ),
    );
  }
}

// ── Control button for host screen ──
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final bool gradient;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.active = true,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          gradient: gradient ? AppColors.primaryGradient : null,
          color: gradient
              ? null
              : active
                  ? Colors.white12
                  : Colors.red.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: active ? Colors.white : Colors.red, size: 20),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// LIVE NOW TAB — real-time Socket.io updates
// ═══════════════════════════════════════════════════════════════════

class _LiveNowTab extends ConsumerStatefulWidget {
  final void Function(LivestreamModel) onOpen;
  const _LiveNowTab({required this.onOpen});
  @override
  ConsumerState<_LiveNowTab> createState() => _LiveNowTabState();
}

class _LiveNowTabState extends ConsumerState<_LiveNowTab> {
  List<LivestreamModel> _streams = [];
  bool _initialised = false;
  sio.Socket? _socket;
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
      _socket!.connect();

      _socket!.on('stream_created', (data) {
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

      _socket!.on('stream_ended', (data) {
        if (!mounted) return;
        final id = (data as Map)['id']?.toString() ?? '';
        if (id.isEmpty) return;
        setState(() => _streams = _streams.where((s) => s.id != id).toList());
      });
    } catch (e) {
      debugPrint('LiveNowTab socket error: $e');
    }
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveAsync = ref.watch(activeLivestreamsProvider);
    liveAsync.whenData((data) {
      if (!_initialised) {
        _streams = List.from(data);
        _initialised = true;
      }
    });

    if (!_initialised) {
      return liveAsync.when(
        data: (_) => const SizedBox.shrink(),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const Center(
            child: Text('Error loading streams',
                style: TextStyle(color: AppColors.error))),
      );
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12,
        mainAxisSpacing: 12, childAspectRatio: 0.75,
      ),
      itemCount: _streams.length,
      itemBuilder: (_, i) => _LiveCard(
          stream: _streams[i],
          onTap: () => widget.onOpen(_streams[i])),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// LIVE CARD
// ═══════════════════════════════════════════════════════════════════

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
          borderRadius: BorderRadius.circular(16),
          color: AppColors.darkCard,
          border: Border.all(color: AppColors.darkBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3),
                    AppColors.darkCard,
                  ],
                ),
              ),
              child: Center(
                child: Icon(Icons.videocam,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.2)),
              ),
            ),
            Positioned(
              left: 10, right: 10, bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LiveBadge(size: 10, showPulse: true),
                  const SizedBox(height: 6),
                  Text(stream.title,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(children: [
                    CircleAvatar(
                      radius: 10, backgroundColor: AppColors.primary,
                      backgroundImage: stream.hostPhotoUrl.isNotEmpty
                          ? NetworkImage(stream.hostPhotoUrl) : null,
                      child: stream.hostPhotoUrl.isEmpty
                          ? const Icon(Icons.person,
                              size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(stream.hostUsername,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11)),
                    ),
                    const Icon(Icons.visibility,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('${stream.viewerCount}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// REPLAYS TAB
// ═══════════════════════════════════════════════════════════════════

class _ReplaysTab extends ConsumerWidget {
  const _ReplaysTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider);
    if (user == null) {
      return const Center(
          child: Text('Log in to see replays',
              style: TextStyle(color: AppColors.textMuted)));
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ApiService.getUserReplays(user.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        final replays = snap.data ?? [];
        if (replays.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.replay, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                const Text('No replays yet',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: replays.length,
          itemBuilder: (_, i) {
            final r = replays[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Row(children: [
                Container(
                  width: 64, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_circle_fill,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['title']?.toString() ?? 'Replay',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Viewers: ${r['viewerCount'] ?? 0}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ]),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// VIEWER SCREEN — HLS player + chat + reactions
// ═══════════════════════════════════════════════════════════════════

class LivestreamViewerScreen extends ConsumerStatefulWidget {
  final LivestreamModel stream;
  const LivestreamViewerScreen({super.key, required this.stream});
  @override
  ConsumerState<LivestreamViewerScreen> createState() =>
      _LivestreamViewerScreenState();
}

class _LivestreamViewerScreenState
    extends ConsumerState<LivestreamViewerScreen> {
  final _chatCtrl = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  final List<int> _floatingEmojiIds = [];
  final Map<int, String> _floatingEmojis = {};
  int _viewers = 0;
  bool _hlsReady = false;
  VideoPlayerController? _videoCtrl;
  ChewieController? _chewieCtrl;

  @override
  void initState() {
    super.initState();
    _viewers = widget.stream.viewerCount;
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url = widget.stream.playbackUrl;
    if (url.isEmpty) {
      if (mounted) setState(() => _hlsReady = true);
      return;
    }
    try {
      _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoCtrl!.initialize();
      _chewieCtrl = ChewieController(
        videoPlayerController: _videoCtrl!,
        autoPlay: true, looping: true,
        showControls: false, allowFullScreen: false, allowMuting: true,
      );
      if (mounted) setState(() => _hlsReady = true);
    } catch (e) {
      debugPrint('HLS player error: $e');
      if (mounted) setState(() => _hlsReady = true);
    }
  }

  void _addFloatingEmoji(String emoji) {
    final id = DateTime.now().microsecondsSinceEpoch;
    setState(() {
      _floatingEmojiIds.add(id);
      _floatingEmojis[id] = emoji;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _floatingEmojiIds.remove(id);
          _floatingEmojis.remove(id);
        });
      }
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
      });
      if (_chatMessages.length > 100) _chatMessages.removeLast();
    });
    _chatCtrl.clear();
  }

  void _sendReaction(String emoji) {
    _addFloatingEmoji(emoji);
    final user = ref.read(authUserProvider);
    if (user == null) return;
    setState(() {
      _chatMessages.insert(0, {
        'username': user.username,
        'text': emoji,
      });
    });
  }

  @override
  void dispose() {
    _chatCtrl.dispose();
    _chewieCtrl?.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Video player ─────────────────────────────────
          Positioned.fill(
            child: _hlsReady && _chewieCtrl != null
                ? Chewie(controller: _chewieCtrl!)
                : _buildLoadingPlaceholder(),
          ),

          // ── Floating emojis ──────────────────────────────
          ..._floatingEmojiIds.map((id) => Positioned(
                right: 70, bottom: 200,
                child: _FloatingEmojiWidget(
                    key: ValueKey(id), emoji: _floatingEmojis[id] ?? '❤️'),
              )),

          // ── Top bar ──────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16, right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18, backgroundColor: AppColors.primary,
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
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Row(children: [
                        const LiveBadge(size: 8, showPulse: true),
                        const SizedBox(width: 6),
                        Text('$_viewers watching',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12)),
                        const SizedBox(width: 8),
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

          // ── Chat overlay ─────────────────────────────────
          Positioned(
            left: 12, right: 72, bottom: 76, height: 240,
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
                              fontWeight: FontWeight.w700, fontSize: 13),
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

          // ── Reaction buttons ─────────────────────────────
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
                        color: Colors.black45, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12)),
                    child: Center(
                        child: Text(e,
                            style: const TextStyle(fontSize: 22))),
                  ),
                ),
              )).toList(),
            ),
          ),

          // ── Chat input ───────────────────────────────────
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
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14),
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

          // ── Watermark ────────────────────────────────────
          const ArtistcaseWatermark(size: 14, opacity: 0.25),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.live_tv, size: 64, color: Colors.white12),
            const SizedBox(height: 16),
            Text(widget.stream.title,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 18)),
            const SizedBox(height: 12),
            const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            ),
            const SizedBox(height: 8),
            const Text('Loading stream...',
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// FLOATING EMOJI ANIMATION
// ═══════════════════════════════════════════════════════════════════

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
