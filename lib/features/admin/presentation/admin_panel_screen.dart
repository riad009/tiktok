import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../models/user_model.dart';
import '../../../models/report_model.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> _users = [];
  bool _loadingUsers = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final users = await ref.read(adminRepositoryProvider).getAllUsers();
    if (mounted) setState(() { _users = users; _loadingUsers = false; });
  }

  Future<void> _searchUsers(String query) async {
    setState(() => _loadingUsers = true);
    final users = await ref.read(adminRepositoryProvider).searchUsersAdmin(query);
    if (mounted) setState(() { _users = users; _loadingUsers = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Control Panel',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Tabs
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
              tabs: const [
                Tab(text: 'Dashboard'),
                Tab(text: 'Users'),
                Tab(text: 'Reports'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboard(),
                _buildUsersTab(),
                _buildReportsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Dashboard Tab ──────────────────────────────────────────────
  Widget _buildDashboard() {
    return FutureBuilder<Map<String, int>>(
      future: ref.read(adminRepositoryProvider).getPlatformStats(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        final stats = snap.data ?? {};
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Platform Overview',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  StatCard(
                    icon: Icons.people,
                    value: '${stats['totalUsers'] ?? 0}',
                    label: 'Total Users',
                    iconColor: AppColors.accent,
                  ),
                  StatCard(
                    icon: Icons.video_library,
                    value: '${stats['totalVideos'] ?? 0}',
                    label: 'Total Videos',
                    iconColor: AppColors.secondary,
                  ),
                  StatCard(
                    icon: Icons.live_tv,
                    value: '${stats['totalLivestreams'] ?? 0}',
                    label: 'Livestreams',
                    iconColor: AppColors.liveRed,
                  ),
                  StatCard(
                    icon: Icons.report_problem,
                    value: '${stats['pendingReports'] ?? 0}',
                    label: 'Pending Reports',
                    iconColor: AppColors.warning,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Users Tab ──────────────────────────────────────────────────
  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search users...',
              hintStyle: TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.darkCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
            ),
            onChanged: (q) => _searchUsers(q),
          ),
        ),
        Expanded(
          child: _loadingUsers
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _users.isEmpty
                  ? Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _users.length,
                      itemBuilder: (context, i) => _UserAdminCard(
                        user: _users[i],
                        onBanToggle: () => _toggleBan(_users[i]),
                        onVerify: () => _toggleVerify(_users[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  void _toggleBan(UserModel user) async {
    final repo = ref.read(adminRepositoryProvider);
    if (user.isBanned) {
      await repo.unbanUser(user.uid);
    } else {
      await repo.banUser(user.uid);
    }
    _loadUsers();
  }

  void _toggleVerify(UserModel user) async {
    await ref.read(adminRepositoryProvider).verifyUser(user.uid, !user.isVerified);
    _loadUsers();
  }

  // ── Reports Tab ────────────────────────────────────────────────
  Widget _buildReportsTab() {
    final reports = ref.watch(reportsProvider);
    return reports.when(
      data: (reportsList) {
        if (reportsList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: AppColors.success.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  'No reports',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'All clear! No pending reports.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reportsList.length,
          itemBuilder: (context, i) => _ReportCard(
            report: reportsList[i],
            onResolve: () => _resolveReport(reportsList[i].id, 'resolved'),
            onDismiss: () => _resolveReport(reportsList[i].id, 'dismissed'),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (_, __) => const Center(child: Text('Error loading reports')),
    );
  }

  void _resolveReport(String reportId, String action) {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    ref.read(adminRepositoryProvider).resolveReport(reportId, user.uid, action);
  }
}

// ── User Admin Card ──────────────────────────────────────────────
class _UserAdminCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onBanToggle;
  final VoidCallback onVerify;

  const _UserAdminCard({
    required this.user,
    required this.onBanToggle,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: user.isBanned
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.darkBorder,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                backgroundImage: user.photoUrl.isNotEmpty
                    ? NetworkImage(user.photoUrl) : null,
                child: user.photoUrl.isEmpty
                    ? Icon(Icons.person, color: AppColors.primary) : null,
              ),
              if (user.isVerified)
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.darkCard, width: 2),
                    ),
                    child: const Icon(Icons.check, size: 10, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _roleColor(user.role).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: TextStyle(
                          color: _roleColor(user.role),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (user.isBanned) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BANNED',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username} · ${user.email}',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
            color: AppColors.darkSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              PopupMenuItem(
                onTap: onVerify,
                child: Row(
                  children: [
                    Icon(
                      user.isVerified ? Icons.verified_user : Icons.verified,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(user.isVerified ? 'Remove Verify' : 'Verify User'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: onBanToggle,
                child: Row(
                  children: [
                    Icon(
                      user.isBanned ? Icons.check_circle : Icons.block,
                      size: 18,
                      color: user.isBanned ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(user.isBanned ? 'Unban' : 'Ban User'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return AppColors.error;
      case 'creator': return AppColors.secondary;
      default: return AppColors.textMuted;
    }
  }
}

// ── Report Card ──────────────────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onResolve;
  final VoidCallback onDismiss;

  const _ReportCard({
    required this.report,
    required this.onResolve,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusBorderColor()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _typeIcon(),
                color: AppColors.warning,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${report.targetType.toUpperCase()} Report',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report.status.toUpperCase(),
                  style: TextStyle(
                    color: _statusColor(),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reason: ${report.reason}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (report.details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              report.details,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (report.status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onResolve,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Resolve',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onDismiss,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Dismiss',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _typeIcon() {
    switch (report.targetType) {
      case 'video': return Icons.videocam;
      case 'user': return Icons.person;
      case 'livestream': return Icons.live_tv;
      default: return Icons.report;
    }
  }

  Color _statusColor() {
    switch (report.status) {
      case 'resolved': return AppColors.success;
      case 'dismissed': return AppColors.textMuted;
      default: return AppColors.warning;
    }
  }

  Color _statusBorderColor() {
    switch (report.status) {
      case 'pending': return AppColors.warning.withValues(alpha: 0.3);
      default: return AppColors.darkBorder;
    }
  }
}
