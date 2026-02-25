import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MiniLineChart extends StatelessWidget {
  final List<double> data;
  final Color? lineColor;
  final double height;
  final bool showFill;

  const MiniLineChart({
    super.key,
    required this.data,
    this.lineColor,
    this.height = 120,
    this.showFill = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _LineChartPainter(
          data: data,
          lineColor: lineColor ?? AppColors.primary,
          showFill: showFill,
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final bool showFill;

  _LineChartPainter({
    required this.data,
    required this.lineColor,
    required this.showFill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minVal) / range) * (size.height * 0.85);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = ((i - 1) / (data.length - 1)) * size.width;
        final prevY = size.height -
            ((data[i - 1] - minVal) / range) * (size.height * 0.85);
        final cp1x = prevX + (x - prevX) / 2;
        path.cubicTo(cp1x, prevY, cp1x, y, x, y);
        fillPath.cubicTo(cp1x, prevY, cp1x, y, x, y);
      }
    }

    if (showFill) {
      fillPath.lineTo(size.width, size.height);
      fillPath.close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.3),
            lineColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);
    }

    canvas.drawPath(path, linePaint);

    // Draw last point dot
    if (data.isNotEmpty) {
      final lastX = size.width;
      final lastY = size.height -
          ((data.last - minVal) / range) * (size.height * 0.85);
      canvas.drawCircle(
        Offset(lastX, lastY),
        4,
        Paint()..color = lineColor,
      );
      canvas.drawCircle(
        Offset(lastX, lastY),
        6,
        Paint()
          ..color = lineColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MiniBarChart extends StatelessWidget {
  final List<double> data;
  final List<String>? labels;
  final Color? barColor;
  final double height;

  const MiniBarChart({
    super.key,
    required this.data,
    this.labels,
    this.barColor,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _BarChartPainter(
          data: data,
          barColor: barColor ?? AppColors.secondary,
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> data;
  final Color barColor;

  _BarChartPainter({required this.data, required this.barColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    final barWidth = (size.width / data.length) * 0.6;
    final gap = (size.width / data.length) * 0.4;

    for (int i = 0; i < data.length; i++) {
      final barHeight = (data[i] / maxVal) * (size.height * 0.9);
      final x = i * (barWidth + gap) + gap / 2;
      final y = size.height - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      );

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            barColor,
            barColor.withValues(alpha: 0.5),
          ],
        ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight));

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
