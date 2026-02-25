import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../models/story_model.dart';
import 'create_story_screen.dart';

// ── Story Bar (horizontal list at top of feed) ───────────────────

class StoryBar extends ConsumerWidget {
  const StoryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesProvider);

    return SizedBox(
      height: 100,
      child: storiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const SizedBox(),
        data: (stories) {
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: stories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              if (i == 0) return _AddStoryButton(onTap: () => _openCreateStory(context));
              final story = stories[i - 1];
              return _StoryCircle(
                story: story,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoryViewerScreen(stories: stories, initialIndex: i - 1),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openCreateStory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
    );
  }
}

class _AddStoryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddStoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66, height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.darkBorder, width: 2),
            ),
            child: const Center(
              child: Icon(Icons.add_rounded, size: 28, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 4),
          const Text('Your Story', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _StoryCircle extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onTap;

  const _StoryCircle({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66, height: 66,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.storyGradient,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.darkBg, width: 2),
              ),
              child: CircleAvatar(
                radius: 27,
                backgroundImage: NetworkImage(story.userPhotoUrl),
                backgroundColor: AppColors.darkCard,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 66,
            child: Text(
              story.username,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Enhanced Story Viewer ────────────────────────────────────────

class StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;

  const StoryViewerScreen({super.key, required this.stories, required this.initialIndex});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;
  final TextEditingController _replyCtrl = TextEditingController();

  static const List<Map<String, dynamic>> _filterMap = [
    {'name': 'normal', 'matrix': null},
    {'name': 'vivid', 'matrix': [1.3, 0, 0, 0, -30, 0, 1.3, 0, 0, -30, 0, 0, 1.3, 0, -30, 0, 0, 0, 1, 0]},
    {'name': 'mono', 'matrix': [0.33, 0.59, 0.11, 0, 0, 0.33, 0.59, 0.11, 0, 0, 0.33, 0.59, 0.11, 0, 0, 0, 0, 0, 1, 0]},
    {'name': 'sepia', 'matrix': [0.39, 0.77, 0.19, 0, 0, 0.35, 0.69, 0.17, 0, 0, 0.27, 0.53, 0.13, 0, 0, 0, 0, 0, 1, 0]},
    {'name': 'cool', 'matrix': [0.9, 0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 0, 1.2, 0, 20, 0, 0, 0, 1, 0]},
    {'name': 'warm', 'matrix': [1.2, 0, 0, 0, 20, 0, 1.0, 0, 0, 0, 0, 0, 0.8, 0, 0, 0, 0, 0, 1, 0]},
    {'name': 'vintage', 'matrix': [0.6, 0.3, 0.1, 0, 40, 0.2, 0.7, 0.1, 0, 20, 0.1, 0.2, 0.5, 0, 10, 0, 0, 0, 1, 0]},
    {'name': 'fade', 'matrix': [1, 0, 0, 0, 40, 0, 1, 0, 0, 40, 0, 0, 1, 0, 40, 0, 0, 0, 0.9, 0]},
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _nextStory();
    });
    _progressController.forward();
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _currentIndex++);
      _progressController.reset();
      _progressController.forward();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _progressController.reset();
      _progressController.forward();
    }
  }

  ColorFilter? _getColorFilter(String filterName) {
    final f = _filterMap.firstWhere((f) => f['name'] == filterName, orElse: () => _filterMap[0]);
    if (f['matrix'] == null) return null;
    final List<double> m = (f['matrix'] as List).map((e) => (e as num).toDouble()).toList();
    return ColorFilter.matrix(m);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _prevStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story image with filter
            ColorFiltered(
              colorFilter: _getColorFilter(story.filter) ??
                  const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
              child: Image.network(
                story.mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.darkCard,
                  child: const Icon(Icons.broken_image, color: AppColors.textMuted, size: 64),
                ),
              ),
            ),

            // Gradient overlays
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                  ),
                ),
              ),
            ),

            // Progress bars
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: Row(
                children: List.generate(widget.stories.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: i < _currentIndex
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : i == _currentIndex
                              ? AnimatedBuilder(
                                  animation: _progressController,
                                  builder: (_, __) => ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: _progressController.value,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      minHeight: 3,
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                    ),
                  );
                }),
              ),
            ),

            // Header: user info + close
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(story.userPhotoUrl),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(story.username,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                        if (story.caption.isNotEmpty)
                          Text(story.caption,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Music info bar
            if (story.musicTitle != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 72,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.music_note, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${story.musicTitle} • ${story.musicArtist ?? ''}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

            // Mentions & hashtags at bottom
            Positioned(
              bottom: 80,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (story.mentions.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: story.mentions.map((m) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('@$m', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      )).toList(),
                    ),
                  if (story.hashtags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        children: story.hashtags.map((h) => Text(
                          '#$h',
                          style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600),
                        )).toList(),
                      ),
                    ),
                ],
              ),
            ),

            // Reply text field
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 12,
              left: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Reply to story...',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppColors.primary, size: 20),
                      onPressed: () {
                        if (_replyCtrl.text.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reply sent! 💬'), backgroundColor: AppColors.success),
                          );
                          _replyCtrl.clear();
                        }
                      },
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
