import 'package:flutter/material.dart';

import '../../../domain/dashboard/entities/daily_order_count.dart';

/// A dependency-free 7-day order bar chart (FC5). Bars are daily order counts,
/// labelled with a compact weekday initial; today's bar is the accent, earlier
/// days a lighter tint. Theme colours only — verified in light and dark. Drawn
/// with [CustomPaint] so it stays crisp and adds no package.
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    required this.data,
    required this.locale,
    this.height = 148,
  });

  /// Oldest-first; the last entry is treated as today (accent bar).
  final List<DailyOrderCount> data;
  final String locale;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarPainter(
          data: data,
          locale: locale,
          accent: scheme.primary,
          track: scheme.onSurface.withValues(alpha: 0.06),
          labelStyle: (text.bodySmall ?? const TextStyle()).copyWith(color: muted),
          valueStyle: (text.labelSmall ?? const TextStyle()).copyWith(
            color: scheme.onSurface.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
          ),
          textDirection: Directionality.of(context),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.data,
    required this.locale,
    required this.accent,
    required this.track,
    required this.labelStyle,
    required this.valueStyle,
    required this.textDirection,
  });

  final List<DailyOrderCount> data;
  final String locale;
  final Color accent;
  final Color track;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const topPad = 16.0; // room for the value above each bar
    const bottomPad = 18.0; // room for the weekday label
    final n = data.length;
    final slot = size.width / n;
    final barWidth = (slot - 10).clamp(6.0, 26.0);
    final chartTop = topPad;
    final baseline = size.height - bottomPad;
    final chartHeight = baseline - chartTop;
    final maxCount =
        data.map((d) => d.count).fold<int>(0, (a, b) => a > b ? a : b);
    final denom = maxCount == 0 ? 1 : maxCount;
    const radius = Radius.circular(4);

    final trackPaint = Paint()..color = track;
    final barPaint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < n; i++) {
      final cx = slot * (i + 0.5);
      final left = cx - barWidth / 2;
      final isToday = i == n - 1;

      // Faint full-height track so a zero day still reads as a day.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left, chartTop, left + barWidth, baseline),
          radius,
        ),
        trackPaint,
      );

      final h = chartHeight * (data[i].count / denom);
      if (h > 0) {
        barPaint.color = isToday ? accent : accent.withValues(alpha: 0.5);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(left, baseline - h, left + barWidth, baseline),
            radius,
          ),
          barPaint,
        );
      }

      if (data[i].count > 0) {
        _paintText(canvas, '${data[i].count}', valueStyle, cx, baseline - h - 2,
            anchorBottom: true, maxWidth: slot);
      }
      _paintText(canvas, _weekdayInitial(data[i].day, locale), labelStyle, cx,
          baseline + 4,
          anchorBottom: false, maxWidth: slot);
    }
  }

  void _paintText(
    Canvas canvas,
    String s,
    TextStyle style,
    double centerX,
    double y, {
    required bool anchorBottom,
    required double maxWidth,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: textDirection,
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxWidth);
    final dy = anchorBottom ? y - tp.height : y;
    tp.paint(canvas, Offset(centerX - tp.width / 2, dy));
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.data != data ||
      old.accent != accent ||
      old.track != track ||
      old.locale != locale;
}

/// Compact one-glyph weekday marker. `DateTime.weekday`: Mon=1 … Sun=7.
String _weekdayInitial(DateTime day, String locale) {
  if (locale == 'ar') {
    const ar = {1: 'ن', 2: 'ث', 3: 'ر', 4: 'خ', 5: 'ج', 6: 'س', 7: 'ح'};
    return ar[day.weekday] ?? '';
  }
  const en = {1: 'M', 2: 'T', 3: 'W', 4: 'T', 5: 'F', 6: 'S', 7: 'S'};
  return en[day.weekday] ?? '';
}
