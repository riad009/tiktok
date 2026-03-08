import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Renders caption text with tappable @mentions (blue) and #hashtags (purple).
class RichTextCaption extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color defaultColor;
  final int? maxLines;
  final void Function(String username)? onMentionTap;
  final void Function(String hashtag)? onHashtagTap;

  const RichTextCaption({
    super.key,
    required this.text,
    this.fontSize = 14,
    this.defaultColor = Colors.white,
    this.maxLines,
    this.onMentionTap,
    this.onHashtagTap,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      _buildSpans(),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }

  TextSpan _buildSpans() {
    final pattern = RegExp(r'(@\w+|#\w+)');
    final matches = pattern.allMatches(text);
    if (matches.isEmpty) {
      return TextSpan(
        text: text,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          color: defaultColor,
          fontWeight: FontWeight.w400,
        ),
      );
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: GoogleFonts.inter(
            fontSize: fontSize,
            color: defaultColor,
            fontWeight: FontWeight.w400,
          ),
        ));
      }

      final matched = match.group(0)!;
      final isMention = matched.startsWith('@');

      spans.add(TextSpan(
        text: matched,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          color: isMention ? AppColors.accent : AppColors.primaryLight,
          fontWeight: FontWeight.w600,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (isMention) {
              onMentionTap?.call(matched.substring(1)); // strip @
            } else {
              onHashtagTap?.call(matched.substring(1)); // strip #
            }
          },
      ));

      lastEnd = match.end;
    }

    // Remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: GoogleFonts.inter(
          fontSize: fontSize,
          color: defaultColor,
          fontWeight: FontWeight.w400,
        ),
      ));
    }

    return TextSpan(children: spans);
  }
}
