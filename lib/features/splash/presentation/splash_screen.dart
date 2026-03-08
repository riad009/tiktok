import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../app.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Phase 1: Logo scale + fade
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  // Phase 2: Ring pulse
  late AnimationController _ringController;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;

  // Phase 3: Particles
  late AnimationController _particleController;

  // Phase 4: Text reveal
  late AnimationController _textController;
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;

  // Phase 5: Tagline
  late AnimationController _taglineController;
  late Animation<double> _taglineOpacity;

  // Phase 6: Shimmer sweep on logo
  late AnimationController _shimmerController;
  late Animation<double> _shimmerPosition;

  // Phase 7: Exit fade
  late AnimationController _exitController;
  late Animation<double> _exitOpacity;

  // Particles data
  final List<_Particle> _particles = [];
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _generateParticles();

    // 1. Logo scale-in with bounce
    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _logoController,
            curve: const Interval(0, 0.3, curve: Curves.easeIn)));

    // 2. Ring pulse
    _ringController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _ringScale = Tween<double>(begin: 0.6, end: 1.6).animate(
        CurvedAnimation(parent: _ringController, curve: Curves.easeOut));
    _ringOpacity = Tween<double>(begin: 0.8, end: 0.0).animate(
        CurvedAnimation(parent: _ringController, curve: Curves.easeOut));

    // 3. Particles float
    _particleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..addListener(() => setState(() {}));

    // 4. Text slide up
    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _textSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    // 5. Tagline fade
    _taglineController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _taglineController, curve: Curves.easeIn));

    // 6. Shimmer
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _shimmerPosition = Tween<double>(begin: -1.0, end: 2.0).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));

    // 7. Exit
    _exitController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _exitController, curve: Curves.easeIn));

    _runSequence();
  }

  void _generateParticles() {
    for (int i = 0; i < 40; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: _rng.nextDouble() * 4 + 1,
        speed: _rng.nextDouble() * 0.3 + 0.1,
        opacity: _rng.nextDouble() * 0.6 + 0.2,
        color: [
          const Color(0xFF8B5CF6),
          const Color(0xFFEC4899),
          const Color(0xFFA855F7),
          const Color(0xFFD8B4FE),
          Colors.white,
        ][_rng.nextInt(5)],
      ));
    }
  }

  void _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _particleController.forward();
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _ringController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _taglineController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _shimmerController.forward();

    // Wait then exit
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuthGate(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _ringController.dispose();
    _particleController.dispose();
    _textController.dispose();
    _taglineController.dispose();
    _shimmerController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D0019),
              Color(0xFF140228),
              Color(0xFF1A0533),
              Color(0xFF0D0019),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Floating Particles ───────────────────
            ...List.generate(_particles.length, (i) {
              final p = _particles[i];
              final progress = _particleController.value;
              final y = (p.y - progress * p.speed) % 1.0;
              final wave = sin(progress * pi * 2 + i) * 20;
              return Positioned(
                left: p.x * size.width + wave,
                top: y * size.height,
                child: Opacity(
                  opacity: p.opacity * (0.3 + 0.7 * progress),
                  child: Container(
                    width: p.size,
                    height: p.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.color,
                      boxShadow: [
                        BoxShadow(
                          color: p.color.withOpacity(0.6),
                          blurRadius: p.size * 3,
                          spreadRadius: p.size * 0.5,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // ── Center Content ──────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ring pulse (behind logo)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing ring
                      AnimatedBuilder(
                        animation: _ringController,
                        builder: (_, __) => Transform.scale(
                          scale: _ringScale.value,
                          child: Opacity(
                            opacity: _ringOpacity.value.clamp(0.0, 1.0),
                            child: Container(
                              width: 180,
                              height: 190,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Second ring (delayed)
                      AnimatedBuilder(
                        animation: _ringController,
                        builder: (_, __) {
                          final delayed =
                              (_ringController.value - 0.2).clamp(0.0, 1.0);
                          return Transform.scale(
                            scale: 0.6 + delayed * 1.0,
                            child: Opacity(
                              opacity:
                                  (0.6 - delayed * 0.6).clamp(0.0, 1.0),
                              child: Container(
                                width: 180,
                                height: 190,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        AppColors.secondary.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Logo
                      AnimatedBuilder(
                        animation: Listenable.merge(
                            [_logoController, _shimmerController]),
                        builder: (_, __) => Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: SizedBox(
                              width: 160,
                              height: 170,
                              child: CustomPaint(
                                painter: _LogoPainter(
                                  shimmerPosition:
                                      _shimmerController.isAnimating
                                          ? _shimmerPosition.value
                                          : -1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // App Name
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: Opacity(
                        opacity: _textOpacity.value,
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFFD8B4FE),
                              Colors.white,
                              Color(0xFFD8B4FE),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'Artistcase',
                            style: GoogleFonts.inter(
                              fontSize: 42,
                              fontWeight: FontWeight.w200,
                              letterSpacing: 4,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tagline
                  AnimatedBuilder(
                    animation: _taglineController,
                    builder: (_, __) => Opacity(
                      opacity: _taglineOpacity.value,
                      child: Text(
                        'Create  •  Share  •  Inspire',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 3,
                          color:
                              AppColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom loading bar ──────────────────
            Positioned(
              bottom: 60,
              left: size.width * 0.3,
              right: size.width * 0.3,
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (_, __) => Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _particleController.value,
                        backgroundColor:
                            AppColors.primary.withOpacity(0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Particle data class
// ══════════════════════════════════════════════════════════════════
class _Particle {
  final double x, y, size, speed, opacity;
  final Color color;
  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.color,
  });
}

// ══════════════════════════════════════════════════════════════════
// Logo Painter — bag + handle + play triangle
// ══════════════════════════════════════════════════════════════════
class _LogoPainter extends CustomPainter {
  final double shimmerPosition;

  _LogoPainter({required this.shimmerPosition});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Outer glow ──
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35)
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF9B6DFF).withOpacity(0.5),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromCenter(
          center: Offset(w / 2, h / 2 + 10),
          width: w * 1.5,
          height: h * 1.5));
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w / 2, h / 2 + 10),
            width: w * 1.3,
            height: h * 1.3),
        glowPaint);

    // ── Bag body ──
    final bagRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 34, w - 20, h - 44),
      const Radius.circular(22),
    );

    final bagPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFB06DFF), Color(0xFF8B5CF6), Color(0xFFA855F7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bagRect.outerRect);
    canvas.drawRRect(bagRect, bagPaint);

    // Inner shadow
    final innerShadow = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.15),
          Colors.transparent,
          Colors.black.withOpacity(0.18),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bagRect.outerRect);
    canvas.drawRRect(bagRect, innerShadow);

    // Border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bagRect.outerRect);
    canvas.drawRRect(bagRect, borderPaint);

    // ── Handle ──
    final handlePath = Path();
    final handleW = w * 0.38;
    final handleStartX = (w - handleW) / 2;
    final handleEndX = handleStartX + handleW;
    const handleTop = 8.0;

    handlePath.moveTo(handleStartX, 38);
    handlePath.cubicTo(
      handleStartX - 4, handleTop,
      handleEndX + 4, handleTop,
      handleEndX, 38,
    );

    final handlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0xFFC084FC), Color(0xFFD8B4FE), Color(0xFFC084FC)],
      ).createShader(Rect.fromLTWH(handleStartX, handleTop, handleW, 30));
    canvas.drawPath(handlePath, handlePaint);

    // Handle highlight
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.25);
    final pathMetrics = handlePath.computeMetrics().first;
    final highlightPath = pathMetrics.extractPath(
        pathMetrics.length * 0.2, pathMetrics.length * 0.5);
    canvas.drawPath(highlightPath, highlightPaint);

    // ── White play triangle ──
    final cx = w / 2;
    final cy = h / 2 + 14;
    const triH = 52.0;
    const triW = 56.0;

    final topPt = Offset(cx, cy - triH / 2);
    final leftPt = Offset(cx - triW / 2, cy + triH / 2);
    final rightPt = Offset(cx + triW / 2, cy + triH / 2);

    final triPath = Path()
      ..moveTo(topPt.dx, topPt.dy)
      ..lineTo(rightPt.dx, rightPt.dy)
      ..lineTo(leftPt.dx, leftPt.dy)
      ..close();

    canvas.drawPath(triPath, Paint()..color = Colors.white);

    // Inner pink triangle
    const innerH = triH * 0.58;
    const innerW = triW * 0.58;
    final innerTop = Offset(cx, cy - innerH / 2 + 4);
    final innerLeft = Offset(cx - innerW / 2, cy + innerH / 2 + 4);
    final innerRight = Offset(cx + innerW / 2, cy + innerH / 2 + 4);

    final innerPath = Path()
      ..moveTo(innerTop.dx, innerTop.dy)
      ..lineTo(innerRight.dx, innerRight.dy)
      ..lineTo(innerLeft.dx, innerLeft.dy)
      ..close();

    canvas.drawPath(
      innerPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFEC4899)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(
            cx - innerW / 2, cy - innerH / 2 + 4, innerW, innerH)),
    );

    // ── Shimmer sweep ──
    if (shimmerPosition >= 0) {
      canvas.save();
      canvas.clipRRect(bagRect);
      final shimmerPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.22),
            Colors.white.withOpacity(0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(
          Rect.fromLTWH(w * shimmerPosition - 40, 34, 80, h - 44),
        );
      canvas.drawRect(Rect.fromLTWH(0, 34, w, h - 44), shimmerPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) => true;
}
