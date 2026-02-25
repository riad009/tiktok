import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/api_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }
    if (!_isLogin && _usernameController.text.trim().isEmpty) {
      _showError('Username is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        final user = await ApiService.login(email: email, password: password);
        if (user != null) {
          ref.read(authUserProvider.notifier).state = user;
        }
      } else {
        final username = _usernameController.text.trim().toLowerCase();
        final displayName = _displayNameController.text.trim().isNotEmpty
            ? _displayNameController.text.trim()
            : username;
        final user = await ApiService.signup(
          username: username,
          email: email,
          password: password,
          displayName: displayName,
        );
        if (user != null) {
          ref.read(authUserProvider.notifier).state = user;
        }
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Logo
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: const Text(
                    'Artistcase',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Welcome back, creator!' : 'Join the community',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 48),

                // Email
                _buildField(
                    controller: _emailController,
                    hint: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),

                // Username & Display Name (register only)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isLogin
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            _buildField(
                                controller: _usernameController,
                                hint: 'Username',
                                icon: Icons.alternate_email_rounded),
                            const SizedBox(height: 16),
                            _buildField(
                                controller: _displayNameController,
                                hint: 'Display Name (optional)',
                                icon: Icons.person_outline_rounded),
                            const SizedBox(height: 16),
                          ],
                        ),
                ),

                // Password
                _buildField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true),
                const SizedBox(height: 28),

                // Auth button
                GradientButton(
                  text: _isLogin ? 'Sign In' : 'Create Account',
                  isLoading: _isLoading,
                  icon: _isLogin
                      ? Icons.login_rounded
                      : Icons.person_add_rounded,
                  onPressed: _handleAuth,
                ),
                const SizedBox(height: 20),

                // Toggle
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: AppColors.textSecondary),
                      children: [
                        TextSpan(
                            text: _isLogin
                                ? "Don't have an account? "
                                : 'Already have an account? '),
                        TextSpan(
                          text: _isLogin ? 'Sign up' : 'Sign in',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder)),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15),
        onSubmitted: (_) => _handleAuth(),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
