import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Artistcase branded logo widget used in bottom nav and branding.
class ArtistcaseLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool animated;

  const ArtistcaseLogo({
    super.key,
    this.size = 32,
    this.showText = false,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    final logo = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'A',
          style: GoogleFonts.inter(
            fontSize: size * 0.52,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );

    if (!showText) return logo;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        const SizedBox(width: 8),
        ShaderMask(
          shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
          child: Text(
            'Artistcase',
            style: GoogleFonts.inter(
              fontSize: size * 0.56,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Semi-transparent watermark overlay for videos and livestreams.
class ArtistcaseWatermark extends StatelessWidget {
  final Alignment alignment;
  final double opacity;
  final double size;

  const ArtistcaseWatermark({
    super.key,
    this.alignment = Alignment.bottomRight,
    this.opacity = 0.35,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: alignment == Alignment.bottomRight ? 12 : null,
      left: alignment == Alignment.bottomLeft ? 12 : null,
      bottom: 12,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(size * 0.28),
                ),
                child: Center(
                  child: Text(
                    'A',
                    style: GoogleFonts.inter(
                      fontSize: size * 0.52,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Artistcase',
                style: GoogleFonts.inter(
                  fontSize: size * 0.7,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
