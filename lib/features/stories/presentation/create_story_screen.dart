import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/data/mock_data.dart';
import '../../../models/story_model.dart';
import '../../../models/music_model.dart';

/// Full-screen story creation with filters, mentions, hashtags, music.
class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  XFile? _pickedFile;
  String _selectedFilter = 'normal';
  final TextEditingController _captionCtrl = TextEditingController();
  final List<String> _mentions = [];
  final List<String> _hashtags = [];
  MusicTrack? _selectedMusic;
  bool _showMentionPicker = false;
  bool _showMusicPicker = false;
  final TextEditingController _hashtagCtrl = TextEditingController();

  static const List<Map<String, dynamic>> _filters = [
    {'name': 'normal', 'label': 'Normal', 'matrix': null},
    {'name': 'vivid', 'label': 'Vivid', 'matrix': [1.3, 0, 0, 0, -30, 0, 1.3, 0, 0, -30, 0, 0, 1.3, 0, -30, 0, 0, 0, 1, 0]},
    {'name': 'mono', 'label': 'Mono', 'matrix': [0.33, 0.59, 0.11, 0, 0, 0.33, 0.59, 0.11, 0, 0, 0.33, 0.59, 0.11, 0, 0, 0, 0, 0, 1, 0]},
    {'name': 'sepia', 'label': 'Sepia', 'matrix': [0.39, 0.77, 0.19, 0, 0, 0.35, 0.69, 0.17, 0, 0, 0.27, 0.53, 0.13, 0, 0, 0, 0, 0, 1, 0]},
    {'name': 'cool', 'label': 'Cool', 'matrix': [0.9, 0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 0, 1.2, 0, 20, 0, 0, 0, 1, 0]},
    {'name': 'warm', 'label': 'Warm', 'matrix': [1.2, 0, 0, 0, 20, 0, 1.0, 0, 0, 0, 0, 0, 0.8, 0, 0, 0, 0, 0, 1, 0]},
    {'name': 'vintage', 'label': 'Vintage', 'matrix': [0.6, 0.3, 0.1, 0, 40, 0.2, 0.7, 0.1, 0, 20, 0.1, 0.2, 0.5, 0, 10, 0, 0, 0, 1, 0]},
    {'name': 'fade', 'label': 'Fade', 'matrix': [1, 0, 0, 0, 40, 0, 1, 0, 0, 40, 0, 0, 1, 0, 40, 0, 0, 0, 0.9, 0]},
  ];

  @override
  void dispose() {
    _captionCtrl.dispose();
    _hashtagCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1080);
    if (file != null) {
      setState(() => _pickedFile = file);
    }
  }

  ColorFilter? _getColorFilter(String filterName) {
    final f = _filters.firstWhere((f) => f['name'] == filterName, orElse: () => _filters[0]);
    if (f['matrix'] == null) return null;
    final List<double> m = (f['matrix'] as List).map((e) => (e as num).toDouble()).toList();
    return ColorFilter.matrix(m);
  }

  void _addHashtag() {
    final tag = _hashtagCtrl.text.trim().replaceAll('#', '');
    if (tag.isNotEmpty && !_hashtags.contains(tag)) {
      setState(() => _hashtags.add(tag));
      _hashtagCtrl.clear();
    }
  }

  void _postStory() {
    final user = ref.read(authUserProvider);
    if (user == null) return;

    // In production: upload media, then create story via API.
    // For now: add to mock stories list and pop
    final newStory = StoryModel(
      id: 'story-new-${DateTime.now().millisecondsSinceEpoch}',
      userId: user.uid,
      username: user.username,
      userPhotoUrl: user.photoUrl,
      mediaUrl: _pickedFile != null
          ? 'https://picsum.photos/seed/new${DateTime.now().second}/400/700'
          : 'https://picsum.photos/seed/default/400/700',
      mediaType: 'image',
      caption: _captionCtrl.text,
      filter: _selectedFilter,
      mentions: _mentions,
      hashtags: _hashtags,
      musicTrackId: _selectedMusic?.id,
      musicTitle: _selectedMusic?.title,
      musicArtist: _selectedMusic?.artistName,
    );

    // Add to beginning of stories
    MockData.stories.insert(0, newStory);
    ref.invalidate(storiesProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Story posted! 🎉'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Create Story'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _postStory,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview with filter
            GestureDetector(
              onTap: _pickMedia,
              child: Container(
                height: 400,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _pickedFile != null
                      ? ColorFiltered(
                          colorFilter: _getColorFilter(_selectedFilter) ?? const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                          child: Image.network(
                            'https://picsum.photos/seed/preview${_selectedFilter.hashCode}/400/700',
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded, size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text('Tap to select photo or video', style: TextStyle(color: AppColors.textMuted)),
                          ],
                        ),
                ),
              ),
            ),

            // Filter carousel
            SizedBox(
              height: 88,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  final f = _filters[i];
                  final isSelected = f['name'] == _selectedFilter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f['name'] as String),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.darkBorder,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ColorFiltered(
                              colorFilter: _getColorFilter(f['name'] as String) ?? const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                              child: Image.network(
                                'https://picsum.photos/seed/filter${i}/56/56',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          f['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Caption
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _captionCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Add a caption...',
                  prefixIcon: const Icon(Icons.text_fields, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.darkCard,
                ),
                maxLines: 2,
              ),
            ),

            const SizedBox(height: 12),

            // Action buttons row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildActionChip(
                    icon: Icons.alternate_email,
                    label: 'Mention',
                    color: AppColors.accent,
                    onTap: () => setState(() => _showMentionPicker = !_showMentionPicker),
                  ),
                  const SizedBox(width: 8),
                  _buildActionChip(
                    icon: Icons.tag,
                    label: 'Hashtag',
                    color: AppColors.success,
                    onTap: _showHashtagInput,
                  ),
                  const SizedBox(width: 8),
                  _buildActionChip(
                    icon: Icons.music_note,
                    label: _selectedMusic?.title ?? 'Music',
                    color: AppColors.secondary,
                    onTap: () => setState(() => _showMusicPicker = !_showMusicPicker),
                  ),
                ],
              ),
            ),

            // Mentions display
            if (_mentions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 6,
                  children: _mentions.map((m) => Chip(
                    label: Text('@$m', style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _mentions.remove(m)),
                    backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                    labelStyle: TextStyle(color: AppColors.accent),
                  )).toList(),
                ),
              ),

            // Hashtags display
            if (_hashtags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Wrap(
                  spacing: 6,
                  children: _hashtags.map((h) => Chip(
                    label: Text('#$h', style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _hashtags.remove(h)),
                    backgroundColor: AppColors.success.withValues(alpha: 0.2),
                    labelStyle: TextStyle(color: AppColors.success),
                  )).toList(),
                ),
              ),

            // Mention picker
            if (_showMentionPicker) _buildMentionPicker(),

            // Music picker
            if (_showMusicPicker) _buildMusicPicker(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHashtagInput() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Add Hashtag'),
        content: TextField(
          controller: _hashtagCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter hashtag...', prefixText: '#'),
          onSubmitted: (_) {
            _addHashtag();
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { _addHashtag(); Navigator.pop(ctx); },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildMentionPicker() {
    final allUsers = MockData.users;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tag Users', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          ...allUsers.where((u) => !_mentions.contains(u.username)).map((user) =>
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(user.photoUrl),
              ),
              title: Text('@${user.username}', style: const TextStyle(fontSize: 13)),
              onTap: () {
                setState(() {
                  _mentions.add(user.username);
                  _showMentionPicker = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicPicker() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Music', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          if (_selectedMusic != null)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.close, color: AppColors.error, size: 20),
              title: const Text('Remove music', style: TextStyle(color: AppColors.error, fontSize: 13)),
              onTap: () => setState(() { _selectedMusic = null; _showMusicPicker = false; }),
            ),
          ...MockData.musicTracks.map((track) {
            final isSelected = _selectedMusic?.id == track.id;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.darkBorder,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(track.coverUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.music_note, size: 18)),
                ),
              ),
              title: Text(track.title, style: TextStyle(
                fontSize: 13,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              )),
              subtitle: Text(track.artistName, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                  : null,
              onTap: () {
                setState(() { _selectedMusic = track; _showMusicPicker = false; });
              },
            );
          }),
        ],
      ),
    );
  }
}
