import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';

class MonetizationScreen extends ConsumerStatefulWidget {
  const MonetizationScreen({super.key});

  @override
  ConsumerState<MonetizationScreen> createState() => _MonetizationScreenState();
}

class _MonetizationScreenState extends ConsumerState<MonetizationScreen>
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
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: const Text('Monetization', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              dividerHeight: 0,
              tabs: const [Tab(text: 'Earnings'), Tab(text: 'Tips'), Tab(text: 'Subscribers')],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildEarningsTab(), _buildTipsTab(), _buildSubscribersTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsTab() {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox();
    return FutureBuilder<Map<String, double>>(
      future: ref.read(monetizationRepositoryProvider).getCreatorEarnings(user.uid),
      builder: (context, snap) {
        final e = snap.data ?? {'totalTips': 0.0, 'subscriptionRevenue': 0.0, 'totalEarnings': 0.0};
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero earnings card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [AppColors.goldBadge.withValues(alpha: 0.15), AppColors.primary.withValues(alpha: 0.1)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.goldBadge.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Text('Total Earnings', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('\$${e['totalEarnings']!.toStringAsFixed(2)}',
                      style: TextStyle(color: AppColors.goldBadge, fontSize: 40, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _pill('💎 Tips', '\$${e['totalTips']!.toStringAsFixed(2)}'),
                        const SizedBox(width: 16),
                        _pill('⭐ Subs', '\$${e['subscriptionRevenue']!.toStringAsFixed(2)}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Subscription Tiers', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _tierCard('Free', 'Basic access', 'Free', AppColors.tierFree, ['View posts', 'Like & comment']),
              const SizedBox(height: 10),
              _tierCard('Pro', 'Exclusive content', '\$4.99/mo', AppColors.tierPro, ['Subscriber badge', 'Exclusive posts', 'Priority support']),
              const SizedBox(height: 10),
              _tierCard('VIP', 'Premium + DMs', '\$14.99/mo', AppColors.tierVip, ['All Pro features', 'Direct messaging', 'VIP badge', 'Monthly shoutout']),
              const SizedBox(height: 24),
              const Text('Creator Badges', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 10, children: [
                _badge('✓ Verified', AppColors.accent),
                _badge('🔥 Top Creator', AppColors.primary),
                _badge('⭐ Rising Star', AppColors.goldBadge),
                _badge('💎 Diamond', AppColors.subscriberPurple),
              ]),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _pill(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      const SizedBox(width: 6),
      Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
    ]),
  );

  Widget _tierCard(String name, String desc, String price, Color c, List<String> feats) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.darkCard, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: c.withValues(alpha: 0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Text(name, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 13))),
        const Spacer(),
        Text(price, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 18)),
      ]),
      const SizedBox(height: 8),
      Text(desc, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      const SizedBox(height: 10),
      ...feats.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Icon(Icons.check_circle, size: 16, color: c),
          const SizedBox(width: 8),
          Text(f, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ]),
      )),
    ]),
  );

  Widget _badge(String label, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: c.withValues(alpha: 0.3)),
    ),
    child: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 13)),
  );

  Widget _buildTipsTab() {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox();
    final tips = ref.watch(creatorTipsProvider(user.uid));
    return tips.when(
      data: (list) {
        if (list.isEmpty) return _emptyState('💎', 'No tips yet', 'Tips from viewers will appear here');
        return ListView.builder(
          padding: const EdgeInsets.all(16), itemCount: list.length,
          itemBuilder: (_, i) {
            final t = list[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.darkBorder)),
              child: Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.goldBadge.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Center(child: Text('💎', style: TextStyle(fontSize: 20)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.senderUsername.isNotEmpty ? t.senderUsername : 'User', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  if (t.message.isNotEmpty) Text(t.message, style: TextStyle(color: AppColors.textMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                Text('\$${t.amount.toStringAsFixed(2)}', style: TextStyle(color: AppColors.goldBadge, fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('Error loading tips')),
    );
  }

  Widget _buildSubscribersTab() {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox();
    final subs = ref.watch(creatorSubscribersProvider(user.uid));
    return subs.when(
      data: (list) {
        if (list.isEmpty) return _emptyState('⭐', 'No subscribers yet', 'Share your profile to get subscribers!');
        return ListView.builder(
          padding: const EdgeInsets.all(16), itemCount: list.length,
          itemBuilder: (_, i) {
            final s = list[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.darkBorder)),
              child: Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(
                  color: (s.tier == 'vip' ? AppColors.tierVip : AppColors.tierPro).withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: AppColors.textSecondary)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.subscriberId, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  Text('${s.tier.toUpperCase()} · \$${s.price.toStringAsFixed(2)}/mo', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Active', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600))),
              ]),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('Error loading subscribers')),
    );
  }

  Widget _emptyState(String emoji, String title, String sub) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(emoji, style: const TextStyle(fontSize: 48)),
      const SizedBox(height: 16),
      Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
      const SizedBox(height: 8),
      Text(sub, style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
    ]),
  );
}
