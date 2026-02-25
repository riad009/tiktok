import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/api_service.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _captionController = TextEditingController();
  final _hashtagController = TextEditingController();
  final _imageUrlController = TextEditingController();
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isUploading = false;
  String _postType = 'text'; // 'text', 'image', 'url'

  @override
  void dispose() {
    _captionController.dispose();
    _hashtagController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _imageBytes = bytes;
        _postType = 'image';
      });
    }
  }

  Future<void> _createPost() async {
    final currentUser = ref.read(authUserProvider);
    if (currentUser == null) return;

    final caption = _captionController.text.trim();
    if (caption.isEmpty && _selectedImage == null && _imageUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a caption or an image'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final hashtags = _hashtagController.text
          .split(RegExp(r'[\s,#]+'))
          .where((h) => h.isNotEmpty)
          .map((h) => h.toLowerCase())
          .toList();

      String imageUrl = '';

      // If user selected an image file, convert to data URI for storage
      if (_imageBytes != null && _selectedImage != null) {
        final ext = _selectedImage!.name.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
        imageUrl = 'data:$mimeType;base64,${base64Encode(_imageBytes!)}';
      } else if (_imageUrlController.text.trim().isNotEmpty) {
        imageUrl = _imageUrlController.text.trim();
      }

      final post = await ApiService.createPost(
        userId: currentUser.uid,
        caption: caption,
        imageUrl: imageUrl,
        hashtags: hashtags,
      );

      if (post != null && mounted) {
        setState(() {
          _isUploading = false;
          _selectedImage = null;
          _imageBytes = null;
          _captionController.clear();
          _hashtagController.clear();
          _imageUrlController.clear();
          _postType = 'text';
        });
        // Refresh the feed
        ref.invalidate(feedVideosProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully! 🎉'),
            backgroundColor: Color(0xFF4ade80),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post type selector
            Row(
              children: [
                _TypeChip(
                  label: '✍️ Text',
                  selected: _postType == 'text',
                  onTap: () => setState(() => _postType = 'text'),
                ),
                const SizedBox(width: 10),
                _TypeChip(
                  label: '📷 Image',
                  selected: _postType == 'image',
                  onTap: () => setState(() => _postType = 'image'),
                ),
                const SizedBox(width: 10),
                _TypeChip(
                  label: '🔗 URL',
                  selected: _postType == 'url',
                  onTap: () => setState(() => _postType = 'url'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Image picker area
            if (_postType == 'image') ...[
              if (_selectedImage == null)
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.darkBorder, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.add_photo_alternate_rounded,
                              size: 40, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        const Text('Select an image',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text('JPG, PNG supported',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 14)),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_imageBytes != null)
                        Image.memory(_imageBytes!, fit: BoxFit.cover)
                      else
                        Container(color: AppColors.darkCard),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: IconButton(
                          onPressed: () => setState(() {
                            _selectedImage = null;
                            _imageBytes = null;
                          }),
                          style: IconButton.styleFrom(
                              backgroundColor: Colors.black54),
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
            ],

            // Image URL input
            if (_postType == 'url') ...[
              const Text('Image URL',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  hintText: 'https://example.com/image.jpg',
                ),
              ),
              if (_imageUrlController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _imageUrlController.text,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      color: AppColors.darkCard,
                      child: const Center(
                          child: Text('Invalid URL',
                              style: TextStyle(color: AppColors.textMuted))),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],

            // Caption
            const Text('Caption',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _captionController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
              ),
            ),
            const SizedBox(height: 16),

            // Hashtags
            const Text('Hashtags',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _hashtagController,
              decoration: const InputDecoration(
                hintText: '#art #dance #music',
              ),
            ),
            const SizedBox(height: 32),

            // Post button
            if (_isUploading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 12),
                    Text('Creating post...',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              )
            else
              GradientButton(
                text: 'Create Post',
                icon: Icons.send_rounded,
                onPressed: _createPost,
              ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : AppColors.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: AppColors.darkBorder),
        ),
        child: Text(label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: selected ? Colors.white : AppColors.textSecondary,
            )),
      ),
    );
  }
}
