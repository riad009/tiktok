import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/data/mock_data.dart';
import '../../../core/services/api_service.dart';

/// ──────────────────────────────────────────────────────────────────────────────
///  Advanced Video Editor – Filters, Trim/Crop, Captions, Tags, Watermark
/// ──────────────────────────────────────────────────────────────────────────────

class VideoEditorScreen extends StatefulWidget {
  final XFile? videoFile;
  const VideoEditorScreen({super.key, this.videoFile});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // ── Video file state ─────────────────────────────────────────
  XFile? _selectedVideo;
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;
  String _videoFileName = '';
  bool _pickingVideo = false;

  // ── Filter state ─────────────────────────────────────────────
  int _selectedFilter = 0;
  double _filterIntensity = 1.0;

  // ── Trim state ───────────────────────────────────────────────
  double _trimStart = 0.0;
  double _trimEnd = 1.0;
  int _selectedAspect = 0;
  final _aspects = ['9:16', '1:1', '16:9', '4:5'];

  // ── Caption state ────────────────────────────────────────────
  final List<_CaptionOverlay> _captions = [];
  int? _activeCaptionIndex;
  final _captionTextCtrl = TextEditingController();
  double _captionFontSize = 22;
  Color _captionColor = Colors.white;
  Color _captionBgColor = Colors.black54;
  int _captionFontIndex = 0;
  final _captionFonts = ['Inter', 'Outfit', 'Roboto Mono', 'Dancing Script', 'Pacifico'];

  // ── Tag state ────────────────────────────────────────────────
  final List<String> _mentions = [];
  final List<String> _hashtags = [];
  final _mentionCtrl = TextEditingController();
  final _hashtagCtrl = TextEditingController();

  // ── Watermark state ──────────────────────────────────────────
  bool _watermarkEnabled = true;
  double _watermarkOpacity = 0.35;
  double _watermarkSize = 16;
  int _watermarkPosition = 3; // 0=TL 1=TR 2=BL 3=BR 4=center

  // ── Music state ──────────────────────────────────────────────
  final _musicSearchCtrl = TextEditingController();
  List<_DeezerTrack> _musicSearchResults = [];
  bool _musicSearching = false;
  _DeezerTrack? _selectedMusic;
  double _musicVolume = 0.7;
  bool _musicLooping = true;
  double _musicStartOffset = 0.0; // 0..1 where in the track to start

  // ── Audio player ─────────────────────────────────────────────
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentlyPlayingId;

  // ── Filters data ─────────────────────────────────────────────
  static const _identity = <double>[1,0,0,0,0, 0,1,0,0,0, 0,0,1,0,0, 0,0,0,1,0];

  static final List<_FilterPreset> _filters = [
    _FilterPreset('Original', null, Colors.transparent),
    _FilterPreset('Vivid', <double>[1.3,0,0,0,0, 0,1.3,0,0,0, 0,0,1.3,0,0, 0,0,0,1,0], Colors.deepOrange),
    _FilterPreset('Warm', <double>[1.2,0.1,0,0,10, 0,1,0,0,0, 0,0,0.8,0,0, 0,0,0,1,0], Colors.orange),
    _FilterPreset('Cool', <double>[0.8,0,0,0,0, 0,1,0.1,0,0, 0,0,1.3,0,10, 0,0,0,1,0], Colors.blue),
    _FilterPreset('Noir', <double>[0.33,0.33,0.33,0,0, 0.33,0.33,0.33,0,0, 0.33,0.33,0.33,0,0, 0,0,0,1,0], Colors.grey),
    _FilterPreset('Retro', <double>[0.9,0.2,0,0,20, 0,0.8,0,0,10, 0,0,0.6,0,0, 0,0,0,1,0], const Color(0xFF8D6E63)),
    _FilterPreset('Glow', <double>[1.1,0,0.1,0,15, 0,1.1,0.1,0,15, 0,0,1,0,10, 0,0,0,1,0], Colors.pink),
    _FilterPreset('Sunset', <double>[1.3,0,0,0,25, 0,0.9,0,0,5, 0,0,0.7,0,-10, 0,0,0,1,0], Colors.deepPurple),
    _FilterPreset('Emerald', <double>[0.7,0,0,0,0, 0,1.3,0,0,10, 0,0,0.9,0,0, 0,0,0,1,0], Colors.teal),
    _FilterPreset('Cinematic', <double>[1.1,0,0,0,-5, 0,1,0,0,0, 0,0.1,1.2,0,10, 0,0,0,1,0], const Color(0xFF1A237E)),
    _FilterPreset('Peachy', <double>[1.2,0.1,0,0,15, 0,0.95,0.05,0,5, 0,0,0.85,0,0, 0,0,0,1,0], const Color(0xFFFF8A65)),
    _FilterPreset('Frost', <double>[0.85,0.05,0.1,0,10, 0.05,0.9,0.15,0,15, 0,0.05,1.2,0,20, 0,0,0,1,0], const Color(0xFF81D4FA)),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
    // Pre-load video from upload screen if provided
    if (widget.videoFile != null) {
      _selectedVideo = widget.videoFile;
      _videoFileName = widget.videoFile!.name;
      _initVideoPlayer(widget.videoFile!);
    }
  }

  Future<void> _initVideoPlayer(XFile file) async {
    try {
      _videoCtrl?.dispose();
      final controller = VideoPlayerController.networkUrl(Uri.parse(file.path));
      await controller.initialize();
      controller.setLooping(true);
      if (mounted) {
        setState(() {
          _videoCtrl = controller;
          _videoReady = true;
        });
      }
    } catch (_) {
      // fallback — video cannot be initialized on this platform
      if (mounted) setState(() => _videoReady = false);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _captionTextCtrl.dispose();
    _mentionCtrl.dispose();
    _hashtagCtrl.dispose();
    _musicSearchCtrl.dispose();
    _audioPlayer.dispose();
    _videoCtrl?.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  //  AUDIO PLAYBACK
  // ──────────────────────────────────────────────────────────────
  Future<void> _playPreview(_DeezerTrack track) async {
    try {
      // If same track is playing, pause it
      if (_currentlyPlayingId == track.id && _isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
        return;
      }

      // Set up new track
      setState(() {
        _currentlyPlayingId = track.id;
        _isPlaying = true;
      });

      await _audioPlayer.setUrl(track.previewUrl);
      await _audioPlayer.setVolume(_musicVolume);
      await _audioPlayer.setLoopMode(_musicLooping ? LoopMode.one : LoopMode.off);
      _audioPlayer.play();

      // Listen for completion
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) {
            setState(() => _isPlaying = false);
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not play preview: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _currentlyPlayingId = null;
    });
  }

  // ──────────────────────────────────────────────────────────────
  //  VIDEO PICKER
  // ──────────────────────────────────────────────────────────────
  Future<void> _pickVideo() async {
    setState(() => _pickingVideo = true);
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
      if (video != null) {
        setState(() {
          _selectedVideo = video;
          _videoFileName = video.name;
          _videoReady = false;
        });
        _initVideoPlayer(video);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick video: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingVideo = false);
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Edit Video',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('✅ Changes applied'),
                backgroundColor: AppColors.success,
              ));
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('Done',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Video preview area ────────────────────────────
          Expanded(child: _buildPreview()),
          // ── Bottom tool panel ─────────────────────────────
          _buildToolPanel(),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  VIDEO PREVIEW with filters, captions, watermark
  // ──────────────────────────────────────────────────────────────
  Widget _buildPreview() {
    return Center(
      child: AspectRatio(
        aspectRatio: _getAspectRatio(),
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Video preview / picker
              Positioned.fill(
                child: ColorFiltered(
                  colorFilter: _selectedFilter > 0
                      ? ColorFilter.matrix(_getInterpolatedMatrix())
                      : const ColorFilter.mode(
                          Colors.transparent, BlendMode.multiply),
                  child: _selectedVideo == null
                      ? GestureDetector(
                          onTap: _pickingVideo ? null : _pickVideo,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.darkSurface,
                                  AppColors.primary.withValues(alpha: 0.06),
                                  AppColors.secondary.withValues(alpha: 0.06),
                                  AppColors.darkSurface,
                                ],
                              ),
                            ),
                            child: Center(
                              child: _pickingVideo
                                  ? const CircularProgressIndicator(color: AppColors.primary)
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 72,
                                          height: 72,
                                          decoration: BoxDecoration(
                                            gradient: AppColors.primaryGradient,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary.withValues(alpha: 0.3),
                                                blurRadius: 16,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(Icons.video_library_rounded,
                                              size: 36, color: Colors.white),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text('Tap to Select Video',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 6),
                                        const Text('Choose a video from your gallery',
                                            style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 12)),
                                      ],
                                    ),
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () {
                            if (_videoCtrl != null && _videoReady) {
                              setState(() {
                                _videoCtrl!.value.isPlaying
                                    ? _videoCtrl!.pause()
                                    : _videoCtrl!.play();
                              });
                            }
                          },
                          child: Stack(
                            children: [
                              // Actual video player
                              if (_videoCtrl != null && _videoReady)
                                Positioned.fill(
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: _videoCtrl!.value.size.width,
                                      height: _videoCtrl!.value.size.height,
                                      child: VideoPlayer(_videoCtrl!),
                                    ),
                                  ),
                                )
                              else
                                // Loading state
                                Container(
                                  color: AppColors.darkSurface,
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(color: AppColors.primary),
                                        SizedBox(height: 12),
                                        Text('Loading video...',
                                            style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),

                              // Play/Pause overlay
                              if (_videoCtrl != null && _videoReady)
                                Center(
                                  child: AnimatedOpacity(
                                    opacity: !_videoCtrl!.value.isPlaying ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.play_arrow_rounded,
                                          size: 44, color: Colors.white),
                                    ),
                                  ),
                                ),

                              // Filename badge
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.videocam,
                                          size: 13, color: AppColors.primary),
                                      const SizedBox(width: 5),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 160),
                                        child: Text(
                                          _videoFileName,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Change video button
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: _pickVideo,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.swap_horiz,
                                            size: 14, color: Colors.white70),
                                        SizedBox(width: 4),
                                        Text('Change',
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              // Caption overlays
              ..._captions.asMap().entries.map((e) {
                final idx = e.key;
                final cap = e.value;
                return Positioned(
                  left: cap.x,
                  top: cap.y,
                  child: GestureDetector(
                    onPanUpdate: (d) => setState(() {
                      _captions[idx] = cap.copyWith(
                        x: (cap.x + d.delta.dx).clamp(0, 300),
                        y: (cap.y + d.delta.dy).clamp(0, 500),
                      );
                    }),
                    onTap: () => setState(() => _activeCaptionIndex = idx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cap.bgColor,
                        borderRadius: BorderRadius.circular(6),
                        border: _activeCaptionIndex == idx
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Text(
                        cap.text,
                        style: GoogleFonts.getFont(
                          cap.fontFamily,
                          fontSize: cap.fontSize,
                          color: cap.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Tag badges
              if (_mentions.isNotEmpty || _hashtags.isNotEmpty)
                Positioned(
                  left: 12,
                  top: 12,
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      ..._mentions.map((m) => _tagBadge('@$m', AppColors.primary)),
                      ..._hashtags.map((h) => _tagBadge('#$h', AppColors.secondary)),
                    ],
                  ),
                ),

              // Music badge
              if (_selectedMusic != null)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.music_note, color: AppColors.primary, size: 14),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            _selectedMusic!.title,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '- ${_selectedMusic!.artist}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

              // Watermark
              if (_watermarkEnabled)
                Positioned(
                  left: _watermarkLeft(),
                  right: _watermarkRight(),
                  top: _watermarkTop(),
                  bottom: _watermarkBottom(),
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: _watermarkOpacity,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: _watermarkSize,
                            height: _watermarkSize,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius:
                                  BorderRadius.circular(_watermarkSize * 0.28),
                            ),
                            child: Center(
                              child: Text(
                                'A',
                                style: GoogleFonts.inter(
                                  fontSize: _watermarkSize * 0.52,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Artistcase',
                            style: GoogleFonts.inter(
                              fontSize: _watermarkSize * 0.7,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tagBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  BOTTOM TOOL PANEL
  // ──────────────────────────────────────────────────────────────
  Widget _buildToolPanel() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.42,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 4),
          // Tab bar
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(icon: Icon(Icons.auto_awesome, size: 18), text: 'Filters'),
              Tab(icon: Icon(Icons.content_cut, size: 18), text: 'Trim & Crop'),
              Tab(icon: Icon(Icons.text_fields, size: 18), text: 'Captions'),
              Tab(icon: Icon(Icons.alternate_email, size: 18), text: 'Tags'),
              Tab(
                  icon: Icon(Icons.branding_watermark, size: 18),
                  text: 'Watermark'),
              Tab(icon: Icon(Icons.music_note, size: 18), text: 'Music'),
            ],
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildFiltersTab(),
                _buildTrimCropTab(),
                _buildCaptionsTab(),
                _buildTagsTab(),
                _buildWatermarkTab(),
                _buildMusicTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  TAB 1 — FILTERS
  // ──────────────────────────────────────────────────────────────
  Widget _buildFiltersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter grid
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filters.length,
              itemBuilder: (_, i) {
                final sel = _selectedFilter == i;
                final f = _filters[i];
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = i),
                  child: Container(
                    width: 68,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: i == 0
                                ? AppColors.darkCard
                                : f.accent.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                            border: sel
                                ? Border.all(
                                    color: AppColors.primary, width: 2.5)
                                : Border.all(
                                    color: AppColors.darkBorder, width: 1),
                            boxShadow: sel
                                ? [
                                    BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8)
                                  ]
                                : null,
                          ),
                          child: i == 0
                              ? const Icon(Icons.block,
                                  color: Colors.white24, size: 20)
                              : Icon(Icons.auto_awesome,
                                  color: f.accent, size: 20),
                        ),
                        const SizedBox(height: 6),
                        Text(f.name,
                            style: TextStyle(
                                color:
                                    sel ? AppColors.primary : AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Intensity slider
          if (_selectedFilter > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: AppColors.textMuted, size: 16),
                  const SizedBox(width: 8),
                  const Text('Intensity',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: _filterIntensity,
                      onChanged: (v) =>
                          setState(() => _filterIntensity = v),
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.darkBorder,
                    ),
                  ),
                  Text('${(_filterIntensity * 100).toInt()}%',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  TAB 2 — TRIM & CROP
  // ──────────────────────────────────────────────────────────────
  Widget _buildTrimCropTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trim section
          Row(
            children: [
              const Icon(Icons.content_cut, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text('Trim',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                    '${(_trimStart * 60).toInt()}s — ${(_trimEnd * 60).toInt()}s',
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Visual timeline
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                // Frame thumbnails (simulated)
                Row(
                  children: List.generate(
                    10,
                    (i) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary
                                  .withValues(alpha: 0.05 + i * 0.03),
                              AppColors.secondary
                                  .withValues(alpha: 0.05 + i * 0.02),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Selection overlay
                Positioned.fill(
                  child: Row(
                    children: [
                      // Left trim area
                      Expanded(
                        flex: (_trimStart * 100).toInt().clamp(0, 99),
                        child: Container(
                            color: Colors.black54,
                            margin: const EdgeInsets.all(2)),
                      ),
                      // Active area
                      Expanded(
                        flex: ((_trimEnd - _trimStart) * 100)
                            .toInt()
                            .clamp(1, 100),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.primary, width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      // Right trim area
                      Expanded(
                        flex: ((1 - _trimEnd) * 100).toInt().clamp(0, 99),
                        child: Container(
                            color: Colors.black54,
                            margin: const EdgeInsets.all(2)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.darkBorder,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
              rangeThumbShape:
                  const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: RangeSlider(
              values: RangeValues(_trimStart, _trimEnd),
              onChanged: (v) =>
                  setState(() { _trimStart = v.start; _trimEnd = v.end; }),
            ),
          ),
          const SizedBox(height: 12),
          // Crop / Aspect ratio
          Row(
            children: [
              const Icon(Icons.crop, color: AppColors.secondary, size: 18),
              const SizedBox(width: 8),
              const Text('Aspect Ratio',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: _aspects.asMap().entries.map((e) {
              final sel = _selectedAspect == e.key;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedAspect = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: sel ? AppColors.primaryGradient : null,
                      color: sel ? null : AppColors.darkCard,
                      borderRadius: BorderRadius.circular(12),
                      border: sel
                          ? null
                          : Border.all(color: AppColors.darkBorder),
                    ),
                    child: Center(
                      child: Text(e.value,
                          style: TextStyle(
                              color: sel
                                  ? Colors.white
                                  : AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  TAB 3 — CAPTIONS
  // ──────────────────────────────────────────────────────────────
  Widget _buildCaptionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add caption input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _captionTextCtrl,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Type caption text...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: AppColors.darkCard,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addCaption,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Font picker
          const Text('Font',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _captionFonts.length,
              itemBuilder: (_, i) {
                final sel = _captionFontIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _captionFontIndex = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: sel ? AppColors.primaryGradient : null,
                      color: sel ? null : AppColors.darkCard,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          sel ? null : Border.all(color: AppColors.darkBorder),
                    ),
                    child: Text(_captionFonts[i],
                        style: GoogleFonts.getFont(_captionFonts[i],
                            fontSize: 12,
                            color: sel ? Colors.white : AppColors.textMuted,
                            fontWeight: FontWeight.w600)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Font size slider
          Row(
            children: [
              const Text('Size',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _captionFontSize,
                  min: 12,
                  max: 48,
                  onChanged: (v) => setState(() => _captionFontSize = v),
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.darkBorder,
                ),
              ),
              Text('${_captionFontSize.toInt()}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
            ],
          ),

          // Color pickers
          Row(
            children: [
              const Text('Color  ',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              ..._colorOptions.map((c) => GestureDetector(
                    onTap: () => setState(() => _captionColor = c),
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: _captionColor == c
                            ? Border.all(color: AppColors.primary, width: 2.5)
                            : Border.all(color: AppColors.darkBorder),
                      ),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Bg       ',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              ..._bgColorOptions.map((c) => GestureDetector(
                    onTap: () => setState(() => _captionBgColor = c),
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: _captionBgColor == c
                            ? Border.all(color: AppColors.primary, width: 2.5)
                            : Border.all(color: AppColors.darkBorder),
                      ),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 12),

          // Active captions list
          if (_captions.isNotEmpty) ...[
            const Text('Captions',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ..._captions.asMap().entries.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _activeCaptionIndex == e.key
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.darkCard,
                    borderRadius: BorderRadius.circular(10),
                    border: _activeCaptionIndex == e.key
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('"${e.value.text}"',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: AppColors.error),
                        onPressed: () => setState(() {
                          _captions.removeAt(e.key);
                          if (_activeCaptionIndex == e.key) {
                            _activeCaptionIndex = null;
                          }
                        }),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  void _addCaption() {
    final text = _captionTextCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _captions.add(_CaptionOverlay(
        text: text,
        fontSize: _captionFontSize,
        color: _captionColor,
        bgColor: _captionBgColor,
        fontFamily: _captionFonts[_captionFontIndex],
        x: 40 + Random().nextDouble() * 60,
        y: 80 + Random().nextDouble() * 100,
      ));
      _activeCaptionIndex = _captions.length - 1;
      _captionTextCtrl.clear();
    });
  }

  static const _colorOptions = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
  ];

  static const _bgColorOptions = [
    Colors.transparent,
    Colors.black54,
    Colors.black87,
    Colors.white24,
    Colors.red,
    Colors.blue,
  ];

  // ──────────────────────────────────────────────────────────────
  //  TAB 4 — TAGS (@mentions, #hashtags)
  // ──────────────────────────────────────────────────────────────
  Widget _buildTagsTab() {
    final suggestedUsers = MockData.users.take(6).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mentions
          Row(
            children: [
              const Icon(Icons.alternate_email,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text('Mentions',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          // Quick pick from users
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: suggestedUsers.length,
              itemBuilder: (_, i) {
                final u = suggestedUsers[i];
                final added = _mentions.contains(u.username);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (added) {
                      _mentions.remove(u.username);
                    } else {
                      _mentions.add(u.username);
                    }
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: added ? AppColors.primaryGradient : null,
                      color: added ? null : AppColors.darkCard,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          added ? null : Border.all(color: AppColors.darkBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                            radius: 12,
                            backgroundImage:
                                NetworkImage(u.photoUrl)),
                        const SizedBox(width: 6),
                        Text('@${u.username}',
                            style: TextStyle(
                                color:
                                    added ? Colors.white : AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        if (added) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle,
                              size: 14, color: Colors.white),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _mentionCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Add @username',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.alternate_email,
                        size: 18, color: AppColors.textMuted),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    filled: true,
                    fillColor: AppColors.darkCard,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final t = _mentionCtrl.text.trim().replaceAll('@', '');
                  if (t.isNotEmpty && !_mentions.contains(t)) {
                    setState(() => _mentions.add(t));
                    _mentionCtrl.clear();
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          if (_mentions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _mentions
                  .map((m) => Chip(
                        label: Text('@$m',
                            style: const TextStyle(fontSize: 12)),
                        deleteIcon:
                            const Icon(Icons.close, size: 16),
                        onDeleted: () =>
                            setState(() => _mentions.remove(m)),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 20),

          // Hashtags
          Row(
            children: [
              const Icon(Icons.tag, color: AppColors.secondary, size: 18),
              const SizedBox(width: 8),
              const Text('Hashtags',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          // Trending suggestions
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['trending', 'artistcase', 'creative', 'music', 'dance',
                        'viral', 'fyp']
                .map((tag) {
              final added = _hashtags.contains(tag);
              return GestureDetector(
                onTap: () => setState(() {
                  if (added) {
                    _hashtags.remove(tag);
                  } else {
                    _hashtags.add(tag);
                  }
                }),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: added ? LinearGradient(colors: [AppColors.secondary, AppColors.accent]) : null,
                    color: added ? null : AppColors.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        added ? null : Border.all(color: AppColors.darkBorder),
                  ),
                  child: Text('#$tag',
                      style: TextStyle(
                          color: added ? Colors.white : AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hashtagCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Add #hashtag',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.tag,
                        size: 18, color: AppColors.textMuted),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    filled: true,
                    fillColor: AppColors.darkCard,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final t = _hashtagCtrl.text.trim().replaceAll('#', '');
                  if (t.isNotEmpty && !_hashtags.contains(t)) {
                    setState(() => _hashtags.add(t));
                    _hashtagCtrl.clear();
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  TAB 5 — WATERMARK CONTROL
  // ──────────────────────────────────────────────────────────────
  Widget _buildWatermarkTab() {
    final positions = [
      {'icon': Icons.north_west, 'label': 'Top Left'},
      {'icon': Icons.north_east, 'label': 'Top Right'},
      {'icon': Icons.south_west, 'label': 'Bottom Left'},
      {'icon': Icons.south_east, 'label': 'Bottom Right'},
      {'icon': Icons.center_focus_strong, 'label': 'Center'},
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enable/disable
          Row(
            children: [
              const Icon(Icons.branding_watermark,
                  color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              const Text('Show Watermark',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              Switch(
                value: _watermarkEnabled,
                onChanged: (v) => setState(() => _watermarkEnabled = v),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (_watermarkEnabled) ...[
            const SizedBox(height: 12),
            // Position picker
            const Text('Position',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: positions.asMap().entries.map((e) {
                final sel = _watermarkPosition == e.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _watermarkPosition = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: sel ? AppColors.primaryGradient : null,
                        color: sel ? null : AppColors.darkCard,
                        borderRadius: BorderRadius.circular(10),
                        border: sel
                            ? null
                            : Border.all(color: AppColors.darkBorder),
                      ),
                      child: Column(
                        children: [
                          Icon(e.value['icon'] as IconData,
                              size: 18,
                              color:
                                  sel ? Colors.white : AppColors.textMuted),
                          const SizedBox(height: 2),
                          Text(e.value['label'] as String,
                              style: TextStyle(
                                  fontSize: 8,
                                  color: sel
                                      ? Colors.white
                                      : AppColors.textMuted,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Size slider
            Row(
              children: [
                const Icon(Icons.format_size,
                    color: AppColors.textMuted, size: 16),
                const SizedBox(width: 8),
                const Text('Size',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _watermarkSize,
                    min: 10,
                    max: 32,
                    onChanged: (v) => setState(() => _watermarkSize = v),
                    activeColor: AppColors.accent,
                    inactiveColor: AppColors.darkBorder,
                  ),
                ),
                Text('${_watermarkSize.toInt()}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
            // Opacity slider
            Row(
              children: [
                const Icon(Icons.opacity,
                    color: AppColors.textMuted, size: 16),
                const SizedBox(width: 8),
                const Text('Opacity',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _watermarkOpacity,
                    min: 0.1,
                    max: 1.0,
                    onChanged: (v) => setState(() => _watermarkOpacity = v),
                    activeColor: AppColors.accent,
                    inactiveColor: AppColors.darkBorder,
                  ),
                ),
                Text('${(_watermarkOpacity * 100).toInt()}%',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  TAB 6 — MUSIC (Deezer API search)
  // ──────────────────────────────────────────────────────────────
  Future<void> _searchMusic(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _musicSearching = true);
    try {
      // Use backend proxy to avoid CORS issues on web
      final uri = Uri.parse(
          '${ApiService.baseUrl}/music/search?q=${Uri.encodeComponent(query.trim())}');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List items = data['data'] ?? [];
        setState(() {
          _musicSearchResults = items.map((item) {
            return _DeezerTrack(
              id: item['id']?.toString() ?? '',
              title: item['title'] ?? '',
              artist: item['artist']?['name'] ?? '',
              albumCover: item['album']?['cover_medium'] ?? item['album']?['cover'] ?? '',
              previewUrl: item['preview'] ?? '',
              duration: Duration(seconds: item['duration'] ?? 0),
            );
          }).toList();
        });
      }
    } catch (_) {
      // silently fail
    } finally {
      if (mounted) setState(() => _musicSearching = false);
    }
  }

  Widget _buildMusicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _musicSearchCtrl,
                  style: const TextStyle(fontSize: 14),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _searchMusic,
                  decoration: InputDecoration(
                    hintText: 'Search songs, artists...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: AppColors.darkCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _searchMusic(_musicSearchCtrl.text),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _musicSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.search, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Selected music card
          if (_selectedMusic != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _selectedMusic!.albumCover,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            color: AppColors.darkCard,
                            child: const Icon(Icons.music_note, color: AppColors.textMuted),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ShaderMask(
                                  shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                                  child: const Icon(Icons.music_note, size: 14, color: Colors.white),
                                ),
                                const SizedBox(width: 4),
                                const Text('Background Music',
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(_selectedMusic!.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(_selectedMusic!.artist,
                                style: const TextStyle(
                                    color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                        onPressed: () {
                          _stopPlayback();
                          setState(() => _selectedMusic = null);
                        },
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Play/Pause preview button
                  GestureDetector(
                    onTap: () => _playPreview(_selectedMusic!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            (_currentlyPlayingId == _selectedMusic!.id && _isPlaying)
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (_currentlyPlayingId == _selectedMusic!.id && _isPlaying)
                                ? 'Pause Preview'
                                : 'Play Preview',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Volume slider
                  Row(
                    children: [
                      Icon(_musicVolume == 0 ? Icons.volume_off : Icons.volume_up,
                          color: AppColors.textMuted, size: 16),
                      const SizedBox(width: 6),
                      const Text('Volume',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: _musicVolume,
                          onChanged: (v) {
                            setState(() => _musicVolume = v);
                            _audioPlayer.setVolume(v);
                          },
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.darkBorder,
                        ),
                      ),
                      Text('${(_musicVolume * 100).toInt()}%',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                  // Start offset slider
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: AppColors.textMuted, size: 16),
                      const SizedBox(width: 6),
                      const Text('Start at',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: _musicStartOffset,
                          onChanged: (v) => setState(() => _musicStartOffset = v),
                          activeColor: AppColors.secondary,
                          inactiveColor: AppColors.darkBorder,
                        ),
                      ),
                      Text(
                        _formatDuration(Duration(
                            seconds: (_musicStartOffset * _selectedMusic!.duration.inSeconds).toInt())),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  // Loop toggle
                  Row(
                    children: [
                      const Icon(Icons.loop, color: AppColors.textMuted, size: 16),
                      const SizedBox(width: 6),
                      const Text('Loop music',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const Spacer(),
                      Switch(
                        value: _musicLooping,
                        onChanged: (v) {
                          setState(() => _musicLooping = v);
                          _audioPlayer.setLoopMode(v ? LoopMode.one : LoopMode.off);
                        },
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Search results
          if (_musicSearching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 12),
                    Text('Searching music...',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            )
          else if (_musicSearchResults.isEmpty && _musicSearchCtrl.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.music_off, color: AppColors.textMuted, size: 40),
                    const SizedBox(height: 8),
                    const Text('No results found',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('Try a different search term',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            )
          else if (_musicSearchResults.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                      child: const Icon(Icons.library_music, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text('Add Background Music',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('Search for any song to add as background',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            ..._musicSearchResults.map((track) {
              final isSelected = _selectedMusic?.id == track.id;
              final isThisPlaying = _currentlyPlayingId == track.id && _isPlaying;
              return GestureDetector(
                onTap: () {
                  final wasAlreadySelected = _selectedMusic?.id == track.id;
                  setState(() {
                    _selectedMusic = track;
                    _musicStartOffset = 0.0;
                  });
                  _playPreview(track);
                  if (!wasAlreadySelected) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.music_note, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '\"${track.title}\" added as video background music',
                                style: const TextStyle(fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
                        : Border.all(color: AppColors.darkBorder.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          track.albumCover,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.darkBorder,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.music_note,
                                color: AppColors.textMuted, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(track.title,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(track.artist,
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Text(_formatDuration(track.duration),
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                      const SizedBox(width: 6),
                      // Play/pause per track
                      GestureDetector(
                        onTap: () => _playPreview(track),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isThisPlaying
                                ? AppColors.primary
                                : AppColors.darkBorder.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isThisPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.primaryGradient : null,
                          color: isSelected ? null : AppColors.darkBorder,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSelected ? Icons.check : Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ──────────────────────────────────────────────────────────────
  //  HELPERS
  // ──────────────────────────────────────────────────────────────
  double _getAspectRatio() {
    switch (_selectedAspect) {
      case 0: return 9 / 16;
      case 1: return 1;
      case 2: return 16 / 9;
      case 3: return 4 / 5;
      default: return 9 / 16;
    }
  }

  List<double> _getInterpolatedMatrix() {
    if (_selectedFilter == 0) return List<double>.from(_identity);
    final target = _filters[_selectedFilter].values!;
    return List.generate(20, (i) {
      return _identity[i] + (target[i] - _identity[i]) * _filterIntensity;
    });
  }

  double? _watermarkLeft() {
    if (_watermarkPosition == 0 || _watermarkPosition == 2) return 12;
    if (_watermarkPosition == 4) return null;
    return null;
  }

  double? _watermarkRight() {
    if (_watermarkPosition == 1 || _watermarkPosition == 3) return 12;
    if (_watermarkPosition == 4) return null;
    return null;
  }

  double? _watermarkTop() {
    if (_watermarkPosition == 0 || _watermarkPosition == 1) return 12;
    if (_watermarkPosition == 4) return null;
    return null;
  }

  double? _watermarkBottom() {
    if (_watermarkPosition == 2 || _watermarkPosition == 3) return 12;
    if (_watermarkPosition == 4) return null;
    return null;
  }
}

// ──────────────────────────────────────────────────────────────
//  Data classes
// ──────────────────────────────────────────────────────────────

class _FilterPreset {
  final String name;
  final List<double>? values;
  final Color accent;
  const _FilterPreset(this.name, this.values, this.accent);
}

class _CaptionOverlay {
  final String text;
  final double fontSize;
  final Color color;
  final Color bgColor;
  final String fontFamily;
  final double x;
  final double y;

  const _CaptionOverlay({
    required this.text,
    required this.fontSize,
    required this.color,
    required this.bgColor,
    required this.fontFamily,
    required this.x,
    required this.y,
  });

  _CaptionOverlay copyWith({double? x, double? y}) {
    return _CaptionOverlay(
      text: text,
      fontSize: fontSize,
      color: color,
      bgColor: bgColor,
      fontFamily: fontFamily,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

class _DeezerTrack {
  final String id;
  final String title;
  final String artist;
  final String albumCover;
  final String previewUrl;
  final Duration duration;

  const _DeezerTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumCover,
    required this.previewUrl,
    required this.duration,
  });
}


