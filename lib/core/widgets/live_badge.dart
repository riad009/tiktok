import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LiveBadge extends StatefulWidget {
  final double size;
  final bool showPulse;

  const LiveBadge({super.key, this.size = 14, this.showPulse = true});

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.size * 0.7,
            vertical: widget.size * 0.25,
          ),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(4),
            boxShadow: widget.showPulse
                ? [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: _animation.value * 0.6),
                      blurRadius: 8 * _animation.value,
                      spreadRadius: 2 * _animation.value,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: widget.size * 0.5,
                height: widget.size * 0.5,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: widget.size * 0.3),
              Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.size,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(animation: animation, builder: builder);
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder2({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
