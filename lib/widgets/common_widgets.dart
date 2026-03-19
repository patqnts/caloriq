// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import '../theme.dart';

class CCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const CCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface_(isDark),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: card);
    return card;
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: AppTheme.textMuted_(isDark),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class CaloriePill extends StatelessWidget {
  final double value;
  final String label;
  final Color color;

  const CaloriePill({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(value.round().toString(),
            style: TextStyle(
                color: color, fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: AppTheme.textMuted_(isDark), fontSize: 12)),
      ],
    );
  }
}

class MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;

  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: AppTheme.textSecondary_(isDark), fontSize: 15)),
            Text('${value.round()}g',
                style: TextStyle(
                    color: AppTheme.textPrimary_(isDark),
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.bg_(isDark),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

class RingProgress extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  final double strokeWidth;

  RingProgress({
    required this.progress,
    required this.color,
    required this.bgColor,
    this.strokeWidth = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    paint.color = bgColor;
    canvas.drawCircle(center, radius, paint);

    paint.color = color;
    final sweepAngle = progress.clamp(0.0, 1.0) * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant RingProgress old) =>
      old.progress != progress || old.color != color;
}
