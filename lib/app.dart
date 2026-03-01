import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/providers.dart';
import 'core/services/auth_persistence.dart';
import 'core/widgets/artistcase_logo.dart';
import 'features/feed/presentation/feed_screen.dart';
import 'features/upload/presentation/upload_screen.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/liked/presentation/liked_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/livestream/presentation/livestream_screen.dart';
import 'features/music/presentation/music_screen.dart';
import 'features/splash/presentation/splash_screen.dart';

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
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ArtistcaseLogo(size: 64, showText: true),
              SizedBox(height: 24),
              CupertinoActivityIndicator(radius: 14, color: AppColors.primary),
            ],
          ),
        ),
      );
    }

    final loggedIn = ref.watch(mockLoggedInProvider);
    if (loggedIn) {
      return const MainShell();
    }
    return const LoginScreen();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // 5 screens: Home(0), Chat(1), [logo placeholder](2), Liked(3), Profile(4)
  final List<Widget> _screens = const [
    FeedScreen(),
    ConversationsScreen(),
    SizedBox(), // placeholder — logo tap shows action sheet
    LikedScreen(),
    ProfileScreen(),
  ];

  void _onNavTap(int index) {
    if (index == 2) {
      // Center logo — show action sheet
      _showLogoActions();
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _showLogoActions() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const ArtistcaseLogo(size: 36, showText: true),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, CupertinoPageRoute(builder: (_) => const UploadScreen()));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(CupertinoIcons.add, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Text('Upload Content', style: TextStyle(fontSize: 17)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, CupertinoPageRoute(builder: (_) => const MusicScreen()));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(CupertinoIcons.music_note, color: AppColors.secondary, size: 18),
                ),
                const SizedBox(width: 12),
                const Text('Music', style: TextStyle(fontSize: 17)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, CupertinoPageRoute(builder: (_) => const LivestreamScreen()));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.liveRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(CupertinoIcons.video_camera_solid, color: AppColors.liveRed, size: 18),
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex > 2 ? _currentIndex - 1 : _currentIndex,
        children: [
          _screens[0], // Home
          _screens[1], // Chat
          _screens[3], // Liked
          _screens[4], // Profile
        ],
      ),
      bottomNavigationBar: _ArtistcaseBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        bottomPadding: bottomPadding,
      ),
    );
  }
}

// ── iOS-style Bottom Navigation Bar ──────────────────────────────
class _ArtistcaseBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final double bottomPadding;

  const _ArtistcaseBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.navBarBg.withValues(alpha: 0.92),
            border: const Border(
              top: BorderSide(color: Color(0xFF38383A), width: 0.33),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 50,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: CupertinoIcons.house,
                        activeIcon: CupertinoIcons.house_fill,
                        label: 'Home',
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: CupertinoIcons.chat_bubble,
                        activeIcon: CupertinoIcons.chat_bubble_fill,
                        label: 'Chat',
                      ),
                      // Center gap for logo
                      const Expanded(child: SizedBox()),
                      _buildNavItem(
                        index: 3,
                        icon: CupertinoIcons.heart,
                        activeIcon: CupertinoIcons.heart_fill,
                        label: 'Liked',
                      ),
                      _buildNavItem(
                        index: 4,
                        icon: CupertinoIcons.person,
                        activeIcon: CupertinoIcons.person_fill,
                        label: 'Profile',
                      ),
                    ],
                  ),
                  // Raised center logo button
                  Positioned(
                    left: 0,
                    right: 0,
                    top: -20,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => onTap(2),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.navLogoGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 1,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(2.5),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                            ),
                            padding: const EdgeInsets.all(2.5),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                              ),
                              child: const Center(
                                child: ArtistcaseLogo(size: 26),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textMuted,
                letterSpacing: -0.24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
