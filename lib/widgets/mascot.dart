import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n.dart';

/// Solecito — the Somos 956 mascot.
///
/// A friendly Rio Grande Valley "citrus sun" character: an orange/gold body
/// with a leaf sprig, big cheerful eyes, rosy cheeks and a warm smile. Drawn
/// entirely with [CustomPainter] so it scales crisply and needs no assets.
enum MascotMood { happy, wave, thinking, cheer }

class Mascot extends StatefulWidget {
  final double size;
  final MascotMood mood;
  final bool animate;
  const Mascot({
    super.key,
    this.size = 96,
    this.mood = MascotMood.happy,
    this.animate = true,
  });

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Curves.easeInOut,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant Mascot old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.animate && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _MascotPainter(t: _t.value, mood: widget.mood),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final double t; // 0..1 breathing phase
  final MascotMood mood;
  _MascotPainter({required this.t, required this.mood});

  static const _body = Color(0xFFF59E0B);
  static const _bodyDark = Color(0xFFEA8A00);
  static const _leaf = Color(0xFF2E7D32);
  static const _leafDark = Color(0xFF1B5E20);
  static const _cheek = Color(0xFFFB7185);
  static const _ink = Color(0xFF4A2C00);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.56;
    final r = w * 0.34;
    final bob = math.sin(t * math.pi) * (h * 0.018);

    canvas.save();
    canvas.translate(0, bob);

    // Soft ground shadow.
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + r * 1.02), width: r * 1.7, height: r * 0.34),
      shadow,
    );

    // Citrus "rays" / sun petals.
    final rayPaint = Paint()
      ..color = _body.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final rays = 12;
    for (var i = 0; i < rays; i++) {
      final a = (i / rays) * 2 * math.pi + t * 0.06;
      final inner = Offset(cx + math.cos(a) * r * 1.12,
          cy + math.sin(a) * r * 1.12);
      final outer = Offset(cx + math.cos(a) * r * 1.42,
          cy + math.sin(a) * r * 1.42);
      final perp = Offset(-math.sin(a), math.cos(a)) * (r * 0.09);
      final path = Path()
        ..moveTo(inner.dx + perp.dx, inner.dy + perp.dy)
        ..lineTo(outer.dx, outer.dy)
        ..lineTo(inner.dx - perp.dx, inner.dy - perp.dy)
        ..close();
      canvas.drawPath(path, rayPaint);
    }

    // Main body.
    final bodyRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBBF24), _body],
        ).createShader(bodyRect),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.018
        ..color = _bodyDark,
    );

    // Highlight.
    canvas.drawCircle(
      Offset(cx - r * 0.34, cy - r * 0.38),
      r * 0.2,
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );

    // Leaf sprig on top.
    _drawLeaf(canvas, Offset(cx + r * 0.16, cy - r * 0.92), w,
        tilt: -0.5, scale: 0.9);
    _drawLeaf(canvas, Offset(cx - r * 0.12, cy - r * 1.0), w,
        tilt: 0.35, scale: 0.72);

    // Cheeks.
    final cheekPaint = Paint()..color = _cheek.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(cx - r * 0.5, cy + r * 0.24), r * 0.17, cheekPaint);
    canvas.drawCircle(Offset(cx + r * 0.5, cy + r * 0.24), r * 0.17, cheekPaint);

    // Eyes — blink occasionally and look around with the breathing phase.
    final blink = _blink();
    final look = Offset(
      (math.sin(t * math.pi * 2) * r * 0.05),
      mood == MascotMood.thinking ? -r * 0.05 : 0,
    );
    _drawEye(canvas, Offset(cx - r * 0.34, cy - r * 0.08), r, blink, look);
    _drawEye(canvas, Offset(cx + r * 0.34, cy - r * 0.08), r, blink, look);

    // Mouth.
    _drawMouth(canvas, Offset(cx, cy + r * 0.34), r);

    // Waving arm for the wave mood.
    if (mood == MascotMood.wave || mood == MascotMood.cheer) {
      _drawArm(canvas, cx + r * 0.9, cy + r * 0.05, r, t);
    }

    canvas.restore();
  }

  double _blink() {
    // Blink briefly around phase 0.85-1.0.
    if (t > 0.9) {
      return 1 - ((t - 0.9) / 0.1).clamp(0.0, 1.0);
    }
    return 1;
  }

  void _drawLeaf(Canvas canvas, Offset base, double w,
      {required double tilt, required double scale}) {
    final len = w * 0.22 * scale;
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(tilt);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(len * 0.5, -len * 0.7, len, 0)
      ..quadraticBezierTo(len * 0.5, len * 0.7, 0, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = _leaf);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012
        ..color = _leafDark,
    );
    canvas.drawLine(Offset(0, 0), Offset(len, 0),
        Paint()..color = _leafDark..strokeWidth = w * 0.008);
    canvas.restore();
  }

  void _drawEye(Canvas canvas, Offset center, double r, double blink,
      Offset look) {
    final eyeR = r * 0.15;
    if (blink <= 0.15) {
      canvas.drawLine(
        Offset(center.dx - eyeR, center.dy),
        Offset(center.dx + eyeR, center.dy),
        Paint()
          ..color = _ink
          ..strokeWidth = r * 0.05
          ..strokeCap = StrokeCap.round,
      );
      return;
    }
    canvas.drawOval(
      Rect.fromCenter(
          center: center, width: eyeR * 2, height: eyeR * 2 * blink),
      Paint()..color = Colors.white,
    );
    final pupil = center + look;
    canvas.drawCircle(pupil, eyeR * 0.62 * blink, Paint()..color = _ink);
    canvas.drawCircle(pupil + Offset(-eyeR * 0.22, -eyeR * 0.24),
        eyeR * 0.2 * blink, Paint()..color = Colors.white);
  }

  void _drawMouth(Canvas canvas, Offset center, double r) {
    final paint = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.055
      ..strokeCap = StrokeCap.round;
    final path = Path();
    if (mood == MascotMood.thinking) {
      path.moveTo(center.dx - r * 0.16, center.dy);
      path.quadraticBezierTo(
          center.dx, center.dy - r * 0.05, center.dx + r * 0.16, center.dy);
      canvas.drawPath(path, paint);
    } else if (mood == MascotMood.cheer) {
      canvas.drawCircle(center, r * 0.2, Paint()..color = _ink);
      canvas.drawCircle(center, r * 0.2, paint);
    } else {
      path.moveTo(center.dx - r * 0.24, center.dy - r * 0.02);
      path.quadraticBezierTo(
          center.dx, center.dy + r * 0.26, center.dx + r * 0.24, center.dy - r * 0.02);
      canvas.drawPath(path, paint);
    }
  }

  void _drawArm(Canvas canvas, double x, double y, double r, double t) {
    final wave = math.sin(t * math.pi * 2) * 0.5;
    final paint = Paint()
      ..color = _body
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14
      ..strokeCap = StrokeCap.round;
    final start = Offset(x - r * 0.05, y + r * 0.1);
    final end = Offset(x + r * 0.3, y - r * 0.45 + wave * r * 0.1);
    canvas.drawLine(start, end, paint);
    canvas.drawCircle(end, r * 0.12,
        Paint()..color = const Color(0xFFFBBF24));
  }

  @override
  bool shouldRepaint(covariant _MascotPainter old) =>
      old.t != t || old.mood != mood;
}

/// A speech-bubble style card that pairs the mascot with a short friendly line.
class MascotBubble extends StatelessWidget {
  final String message;
  final MascotMood mood;
  final double mascotSize;
  final Color? accent;

  const MascotBubble({
    super.key,
    required this.message,
    this.mood = MascotMood.happy,
    this.mascotSize = 84,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Theme.of(context).colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Mascot(size: mascotSize, mood: mood),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              border: Border.all(color: color.withValues(alpha: 0.3)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, height: 1.35),
            ),
          ),
        ),
      ],
    );
  }
}

/// Small mascot avatar for app bars and list headers.
class MascotAvatar extends StatelessWidget {
  final double size;
  final MascotMood mood;
  const MascotAvatar({super.key, this.size = 40, this.mood = MascotMood.happy});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
      ),
      padding: EdgeInsets.all(size * 0.06),
      child: Mascot(size: size, mood: mood),
    );
  }
}

/// Localized name of the mascot.
String mascotName(BuildContext context) =>
    S.of(context).es ? 'Solecito' : 'Solecito';
