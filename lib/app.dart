import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/providers.dart';
import 'core/widgets/artistcase_logo.dart';
import 'features/feed/presentation/feed_screen.dart';
import 'features/search/presentation/search_screen.dart';
import 'features/upload/presentation/upload_screen.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/auth/presentation/login_screen.dart';
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
      home: const AuthGate(),
    );
  }
}

/// Gate: awaits session restore from SharedPreferences, then routes
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the session restore future — this reads SharedPreferences once
    final session = ref.watch(sessionProvider);

    return session.when(
      // Brief splash while localStorage is read (usually <100ms on web)
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0a0a0a),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF2D55)),
        ),
      ),
      // If restore fails, still check the in-memory state
      error: (_, __) {
        final loggedIn = ref.watch(mockLoggedInProvider);
        return loggedIn ? const MainShell() : const LoginScreen();
      },
      // Session resolved — route based on auth state
      data: (_) {
        final loggedIn = ref.watch(mockLoggedInProvider);
        return loggedIn ? const MainShell() : const LoginScreen();
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    FeedScreen(),
    SearchScreen(),
    LivestreamScreen(),
    UploadScreen(), // Shown when logo is tapped
    ConversationsScreen(),
    ProfileScreen(),
  ];

  void _onNavTap(int index) {
    if (index == 3) {
      // Logo tap — show action sheet with Upload / Music
      _showLogoActions();
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _showLogoActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const ArtistcaseLogo(size: 48, showText: true),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                ),
                title: const Text('Upload Content', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Post a video, reel, or image', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _currentIndex = 3);
                },
              ),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.music_note_rounded, color: AppColors.secondary, size: 24),
                ),
                title: const Text('Music', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Browse trending tracks', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MusicScreen()));
                },
              ),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.liveRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.live_tv_rounded, color: AppColors.liveRed, size: 24),
                ),
                title: const Text('Go Live', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Start a livestream', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _currentIndex = 2);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.darkBorder, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.search_rounded),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.liveRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.live_tv, color: AppColors.liveRed, size: 20),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.liveRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.live_tv, color: Colors.white, size: 20),
              ),
              label: 'Live',
            ),
            // ── Center: Artistcase Logo ──
            BottomNavigationBarItem(
              icon: const ArtistcaseLogo(size: 34),
              activeIcon: const ArtistcaseLogo(size: 34),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Chat',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
