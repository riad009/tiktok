import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/providers.dart';
import 'core/services/auth_persistence.dart';
import 'core/widgets/artistcase_logo.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/reels/presentation/reels_screen.dart';
import 'features/upload/presentation/upload_screen.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/notifications/presentation/notifications_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/livestream/presentation/livestream_screen.dart';
import 'features/music/presentation/music_screen.dart';

class ArtistcaseApp extends StatelessWidget {
  const ArtistcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Artistcase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

/// Gate: restores persisted session, then watches auth state
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final savedUser = await AuthPersistence.loadUser();
      if (savedUser != null) {
        ref.read(authUserProvider.notifier).state = savedUser;
      }
    } catch (_) {
      // Silently fail — user will see login screen
    }
    if (mounted) setState(() => _initializing = false);
  }

  @override
  Widget build(BuildContext context) {
    // Show splash while restoring session
    if (_initializing) {
      return Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ArtistcaseLogo(size: 64, showText: true),
              const SizedBox(height: 24),
              const CupertinoActivityIndicator(
                  radius: 14, color: AppColors.primary),
            ],
          ),
        ),
      );
    }

    final loggedIn = ref.watch(mockLoggedInProvider);
    if (loggedIn) {
      return const MainShell();
    }
    // Show onboarding flow first
    return const OnboardingScreen();
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  // 4 screens matching bottom nav: Reels (Home), Notifications, Chat, Profile
  final List<Widget> _screens = const [
    ReelsScreen(),           // Home — full-screen reels
    NotificationsScreen(),   // Notifications
    ConversationsScreen(),   // Chat/Messages
    ProfileScreen(),         // Profile
  ];

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  void _showCreateActions() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const ArtistcaseLogo(size: 36, showText: true),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context,
                  CupertinoPageRoute(builder: (_) => const UploadScreen()));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(CupertinoIcons.add,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Text('Upload Content',
                    style: TextStyle(fontSize: 17)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context,
                  CupertinoPageRoute(builder: (_) => const MusicScreen()));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(CupertinoIcons.music_note,
                      color: AppColors.secondary, size: 18),
                ),
                const SizedBox(width: 12),
                const Text('Music', style: TextStyle(fontSize: 17)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (_) => const LivestreamScreen()));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.liveRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(CupertinoIcons.video_camera_solid,
                      color: AppColors.liveRed, size: 18),
                ),
                const SizedBox(width: 12),
                const Text('Go Live', style: TextStyle(fontSize: 17)),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _ArtistcaseBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        onFabTap: _showCreateActions,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Bottom Navigation Bar — white bar with center notch + purple FAB
// Now uses ConsumerWidget so it can show the user's profile photo
// ══════════════════════════════════════════════════════════════════
class _ArtistcaseBottomNav extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;

  const _ArtistcaseBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final currentUser = ref.watch(authUserProvider);

    return SizedBox(
      height: 70 + bottomPad,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── White bar with notch ──────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 70 + bottomPad),
              painter: _NavBarPainter(),
              child: SizedBox(
                height: 70 + bottomPad,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomPad),
                  child: Row(
                    children: [
                      // Home
                      _buildNavItem(
                        index: 0,
                        icon: CupertinoIcons.house,
                        activeIcon: CupertinoIcons.house_fill,
                      ),
                      // Notifications
                      _buildNavItem(
                        index: 1,
                        icon: CupertinoIcons.bell,
                        activeIcon: CupertinoIcons.bell_fill,
                      ),
                      // Center gap for FAB
                      const SizedBox(width: 72),
                      // Chat
                      _buildNavItem(
                        index: 2,
                        icon: CupertinoIcons.chat_bubble,
                        activeIcon: CupertinoIcons.chat_bubble_fill,
                      ),
                      // Profile avatar (replaces gear icon)
                      _buildProfileNavItem(
                        index: 3,
                        currentUser: currentUser,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Center FAB ────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            top: -4,
            child: Center(
              child: GestureDetector(
                onTap: onFabTap,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: SizedBox(
          height: 56,
          child: Icon(
            isActive ? activeIcon : icon,
            size: 24,
            color: isActive
                ? AppColors.primary
                : const Color(0xFFB0B0B0),
          ),
        ),
      ),
    );
  }

  /// Profile avatar nav item — shows user's photo instead of gear icon
  Widget _buildProfileNavItem({
    required int index,
    required dynamic currentUser,
  }) {
    final isActive = currentIndex == index;
    final photoUrl = currentUser?.photoUrl ?? '';
    final username = currentUser?.username ?? 'default';
    final avatarUrl = photoUrl.isNotEmpty
        ? photoUrl
        : 'https://i.pravatar.cc/150?u=$username';

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: SizedBox(
          height: 56,
          child: Center(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFB0B0B0),
                    child: const Icon(Icons.person,
                        size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the white nav bar with a center circular notch
class _NavBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final w = size.width;
    final h = size.height;
    final mid = w / 2;
    const notchRadius = 38.0;
    const curveDepth = 10.0;

    final path = Path();
    path.moveTo(0, 0);
    // Left side straight to notch
    path.lineTo(mid - notchRadius - 8, 0);
    // Curve into the notch
    path.quadraticBezierTo(
      mid - notchRadius, 0,
      mid - notchRadius + 4, curveDepth,
    );
    // Arc across the notch circle
    path.arcToPoint(
      Offset(mid + notchRadius - 4, curveDepth),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    // Curve out of notch
    path.quadraticBezierTo(
      mid + notchRadius, 0,
      mid + notchRadius + 8, 0,
    );
    // Right side
    path.lineTo(w, 0);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    // Shadow
    canvas.drawPath(path.shift(const Offset(0, -2)), shadowPaint);
    // White fill
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
