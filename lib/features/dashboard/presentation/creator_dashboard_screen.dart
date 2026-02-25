import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/mini_chart.dart';
import 'dart:math';

class CreatorDashboardScreen extends ConsumerStatefulWidget {
  const CreatorDashboardScreen({super.key});

  @override
  ConsumerState<CreatorDashboardScreen> createState() =>
      _CreatorDashboardScreenState();
}

class _CreatorDashboardScreenState
    extends ConsumerState<CreatorDashboardScreen> {
  final _random = Random(42);

  // Generate mock analytics data for charts
  List<double> _generateMockData(int count, double base, double variance) {
    return List.generate(count, (i) {
      return base + (i * variance / count) + _random.nextDouble() * variance * 0.3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final videos = ref.watch(userVideosProvider(user?.uid ?? ''));

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: const Text(
          'Creator Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Overview Stats ────────────────────────────────────
            _sectionTitle('Overview'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  icon: Icons.visibility,
                  value: _formatNumber((user?.postsCount ?? 0) * 847),
                  label: 'Total Views',
                  trend: 12.5,
                  iconColor: AppColors.accent,
                ),
                StatCard(
                  icon: Icons.people,
                  value: _formatNumber(user?.followersCount ?? 0),
                  label: 'Followers',
                  trend: 8.3,
                  iconColor: AppColors.secondary,
                ),
                StatCard(
                  icon: Icons.favorite,
                  value: '${((user?.followersCount ?? 1) * 3.2).toInt()}',
                  label: 'Total Likes',
                  trend: 15.2,
                  iconColor: AppColors.primary,
                ),
                StatCard(
                  icon: Icons.attach_money,
                  value: '\$${(user?.totalTips ?? 0).toStringAsFixed(2)}',
                  label: 'Earnings',
                  trend: 23.1,
                  iconColor: AppColors.goldBadge,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Followers Growth ─────────────────────────────────
            _sectionTitle('Followers Growth'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatNumber(user?.followersCount ?? 0),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.trending_up, size: 14, color: AppColors.success),
                            SizedBox(width: 4),
                            Text(
                              '+8.3% this week',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MiniLineChart(
                    data: _generateMockData(14, 100, 200),
                    lineColor: AppColors.secondary,
                    height: 140,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Content Performance ──────────────────────────────
            _sectionTitle('Content Performance'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: videos.when(
                data: (vids) {
                  if (vids.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No content yet. Upload your first video!',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text('Post',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                            Expanded(
                              child: Text('Views',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                            Expanded(
                              child: Text('Likes',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: AppColors.darkBorder, height: 1),
                      ...vids.take(10).map((v) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    v.caption.isNotEmpty ? v.caption : 'Untitled',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    _formatNumber(v.viewsCount),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    _formatNumber(v.likesCount),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (_, __) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Error loading content')),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Engagement Chart ─────────────────────────────────
            _sectionTitle('Engagement by Day'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                children: [
                  MiniBarChart(
                    data: _generateMockData(7, 50, 150),
                    barColor: AppColors.primary,
                    height: 120,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                        .map((d) => Text(
                              d,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Activity Heatmap ─────────────────────────────────
            _sectionTitle('Activity Heatmap'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                children: [
                  // Hour labels
                  Row(
                    children: [
                      const SizedBox(width: 32),
                      ...['6AM', '12PM', '6PM', '12AM'].map((h) => Expanded(
                            child: Text(
                              h,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(7, (dayIndex) {
                    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text(
                              days[dayIndex],
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          ...List.generate(24, (hourIndex) {
                            final val = _random.nextDouble();
                            return Expanded(
                              child: Container(
                                height: 14,
                                margin: const EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: AppColors.primary.withValues(
                                    alpha: val < 0.2 ? 0.05 : val < 0.5 ? 0.2 : val < 0.8 ? 0.4 : 0.7,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
