import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  int _selectedFilter = 0;
  double _trimStart = 0.0;
  double _trimEnd = 1.0;
  int _selectedAspect = 0;
  bool _watermark = true;

  final _filters = [
    {'name': 'Original', 'color': Colors.transparent},
    {'name': 'Vivid', 'color': Colors.deepOrange},
    {'name': 'Warm', 'color': Colors.orange},
    {'name': 'Cool', 'color': Colors.blue},
    {'name': 'Noir', 'color': Colors.grey},
    {'name': 'Retro', 'color': Colors.brown},
    {'name': 'Glow', 'color': Colors.pink},
    {'name': 'Sunset', 'color': Colors.deepPurple},
  ];

  final _aspects = ['9:16', '1:1', '16:9', '4:5'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black, elevation: 0,
        title: const Text('Edit Video', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 20), onPressed: () => Navigator.pop(context)),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Changes applied'), backgroundColor: AppColors.success));
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
              child: const Center(child: Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
            ),
          ),
        ],
      ),
      body: Column(children: [
        // Video preview area
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _getAspectRatio(),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(children: [
                  // Placeholder
                  Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.video_file, size: 64, color: Colors.white12),
                    const SizedBox(height: 8),
                    Text('Video Preview', style: TextStyle(color: Colors.white24, fontSize: 14)),
                  ])),
                  // Filter overlay
                  if (_selectedFilter > 0) Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: (_filters[_selectedFilter]['color'] as Color).withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                  // Watermark
                  if (_watermark) Positioned(
                    right: 12, bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(4)),
                      child: const Text('Artistcase', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),

        // Tool sections
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.darkBorder, borderRadius: BorderRadius.circular(2))),

            // Trim slider
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.content_cut, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  const Text('Trim', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  const Spacer(),
                  Text('${(_trimStart * 60).toInt()}s - ${(_trimEnd * 60).toInt()}s',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ]),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.primary, inactiveTrackColor: AppColors.darkBorder,
                    thumbColor: AppColors.primary, overlayColor: AppColors.primary.withValues(alpha: 0.2),
                  ),
                  child: RangeSlider(
                    values: RangeValues(_trimStart, _trimEnd),
                    onChanged: (v) => setState(() { _trimStart = v.start; _trimEnd = v.end; }),
                  ),
                ),
              ]),
            ),

            // Aspect ratio
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                const Icon(Icons.crop, color: AppColors.secondary, size: 18),
                const SizedBox(width: 8),
                const Text('Aspect', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                const Spacer(),
                ..._aspects.asMap().entries.map((e) {
                  final sel = _selectedAspect == e.key;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedAspect = e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.secondary : AppColors.darkCard,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(e.value, style: TextStyle(color: sel ? Colors.white : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                }),
              ]),
            ),

            // Watermark toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                const Icon(Icons.branding_watermark, color: AppColors.accent, size: 18),
                const SizedBox(width: 8),
                const Text('Watermark', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                const Spacer(),
                Switch(value: _watermark, onChanged: (v) => setState(() => _watermark = v),
                  activeColor: AppColors.primary),
              ]),
            ),

            // Filter carousel
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Row(children: [
                const Icon(Icons.auto_awesome, color: AppColors.goldBadge, size: 18),
                const SizedBox(width: 8),
                const Text('Filters', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _filters.length,
                itemBuilder: (_, i) {
                  final sel = _selectedFilter == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = i),
                    child: Container(
                      width: 60, margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: i == 0 ? AppColors.darkCard : (_filters[i]['color'] as Color).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: sel ? Border.all(color: AppColors.primary, width: 2) : null,
                          ),
                          child: i == 0 ? const Icon(Icons.block, color: Colors.white24, size: 20)
                            : Icon(Icons.auto_awesome, color: (_filters[i]['color'] as Color), size: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(_filters[i]['name'] as String,
                          style: TextStyle(color: sel ? AppColors.primary : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ]),
        ),
      ]),
    );
  }

  double _getAspectRatio() {
    switch (_selectedAspect) {
      case 0: return 9 / 16;
      case 1: return 1;
      case 2: return 16 / 9;
      case 3: return 4 / 5;
      default: return 9 / 16;
    }
  }
}
