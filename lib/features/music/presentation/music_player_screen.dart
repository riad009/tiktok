import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/music_model.dart';

class MusicPlayerScreen extends StatefulWidget {
  final MusicTrack track;

  const MusicPlayerScreen({super.key, required this.track});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  double _currentPosition = 0;
  late AnimationController _rotationController;
  String? _localCoverPath;
  late List<String> _taggedUsers;

  @override
  void initState() {
    super.initState();
    _taggedUsers = List<String>.from(widget.track.taggedUsers);
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });
  }

  void _skip(int seconds) {
    setState(() {
      _currentPosition = (_currentPosition + seconds)
          .clamp(0, widget.track.duration.inSeconds.toDouble());
    });
  }

  String _formatDuration(double seconds) {
    final mins = seconds ~/ 60;
    final secs = (seconds % 60).toInt();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _localCoverPath = picked.path);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cover updated! 🎨'), backgroundColor: AppColors.success),
      );
    }
  }

  void _showTagArtistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Tag Artist / User',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '@username',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.darkSurface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                prefixIcon: Icon(Icons.alternate_email, color: AppColors.accent),
              ),
            ),
            if (_taggedUsers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _taggedUsers.map((u) => Chip(
                  label: Text('@$u', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                  backgroundColor: AppColors.accent.withAlpha(30),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() => _taggedUsers.remove(u));
                    Navigator.pop(ctx);
                    _showTagArtistDialog();
                  },
                )).toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final username = controller.text.trim().replaceAll('@', '');
              if (username.isNotEmpty && !_taggedUsers.contains(username)) {
                setState(() => _taggedUsers.add(username));
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Tagged @$username! 🏷️'),
                    backgroundColor: AppColors.success),
              );
            },
            child: const Text('Add Tag', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const Spacer(flex: 1),

            // Rotating album cover
            AnimatedBuilder(
              animation: _rotationController,
              builder: (_, child) => Transform.rotate(
                angle: _rotationController.value * 2 * pi,
                child: child,
              ),
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _localCoverPath != null
                          ? (kIsWeb
                              ? Image.network(_localCoverPath!, fit: BoxFit.cover, width: 260, height: 260)
                              : Image.file(File(_localCoverPath!), fit: BoxFit.cover, width: 260, height: 260))
                          : Image.network(
                        track.coverUrl,
                        fit: BoxFit.cover,
                        width: 260,
                        height: 260,
                        errorBuilder: (_, __, ___) => Container(
                          width: 260, height: 260,
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                          ),
                          child: const Icon(Icons.music_note, size: 80, color: Colors.white),
                        ),
                      ),
                      // Center hole (vinyl look)
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.darkBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.darkBorder, width: 3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(flex: 1),

            // Track info
            Text(track.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                // Navigate to artist profile
              },
              child: Text(track.artistName,
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            ),

            // Tagged users
            if (_taggedUsers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: _taggedUsers.map((u) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('@$u', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                )).toList(),
              ),
            ],

            const SizedBox(height: 32),

            // Seek bar
            Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.darkBorder,
                    thumbColor: AppColors.primary,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 3,
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: _currentPosition,
                    min: 0,
                    max: track.duration.inSeconds.toDouble(),
                    onChanged: (v) => setState(() => _currentPosition = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_currentPosition),
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      Text(_formatDuration(track.duration.inSeconds.toDouble()),
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Rewind 10s
                _ControlButton(
                  icon: Icons.replay_10_rounded,
                  size: 32,
                  onTap: () => _skip(-10),
                ),
                // Skip previous
                _ControlButton(
                  icon: Icons.skip_previous_rounded,
                  size: 40,
                  onTap: () => setState(() => _currentPosition = 0),
                ),
                // Play/Pause
                GestureDetector(
                  onTap: _togglePlay,
                  child: Container(
                    width: 72, height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                // Skip next
                _ControlButton(
                  icon: Icons.skip_next_rounded,
                  size: 40,
                  onTap: () => setState(
                    () => _currentPosition = track.duration.inSeconds.toDouble()),
                ),
                // Fast forward 10s
                _ControlButton(
                  icon: Icons.forward_10_rounded,
                  size: 32,
                  onTap: () => _skip(10),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionBtn(icon: Icons.camera_alt_outlined, label: 'Use in Story', onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select this track when creating a story! 🎵'), backgroundColor: AppColors.success),
                  );
                }),
                _ActionBtn(icon: Icons.upload_rounded, label: 'Upload Cover', onTap: _pickCover),
                _ActionBtn(icon: Icons.person_add_alt_1_rounded, label: 'Tag Artist', onTap: _showTagArtistDialog),
                _ActionBtn(icon: Icons.share_rounded, label: 'Share', onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shared! 🔗'), backgroundColor: AppColors.success),
                  );
                }),
              ],
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _ControlButton({required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: AppColors.textPrimary, size: size),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
