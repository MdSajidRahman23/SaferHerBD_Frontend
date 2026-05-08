// ════════════════════════════════════════════════════════════════
//  REUSABLE WIDGETS  matching the design exactly
// ════════════════════════════════════════════════════════════════
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../utils/app_theme.dart';

// ── Topo background pattern (subtle wavy lines + circles) ────────
class TopoBackground extends StatelessWidget {
  final Widget child;
  const TopoBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.bg),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _TopoPainter())),
        child,
      ]),
    );
  }
}

class _TopoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Soft radial green tint top-left
    final radial = Paint()
      ..shader = RadialGradient(
        radius: 0.7,
        colors: [AppColors.green.withOpacity(0.05), Colors.transparent],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.2, size.height * 0.1),
          radius: size.width * 0.6));
    canvas.drawRect(Offset.zero & size, radial);

    final paint = Paint()
      ..color = AppColors.green.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Wavy horizontal lines
    for (var y = 60.0; y < size.height; y += 40) {
      final path = ui.Path()..moveTo(0, y);
      for (var x = 0.0; x < size.width + 60; x += 60) {
        path.quadraticBezierTo(x + 30, y - 18, x + 60, y);
      }
      canvas.drawPath(path, paint);
    }

    // Concentric circles in middle
    final cx = size.width * 0.5, cy = size.height * 0.45;
    for (var r = 40.0; r <= 100; r += 30) {
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _) => false;
}

// ── Bilingual text helpers ───────────────────────────────────────
class BnText extends StatelessWidget {
  final String t;
  final double size;
  final FontWeight weight;
  final Color? color;
  final double? height;
  const BnText(this.t,
      {super.key,
      this.size = 13,
      this.weight = FontWeight.w500,
      this.color,
      this.height});
  @override
  Widget build(BuildContext context) => Text(t,
      style: AppText.bn(
          size: size, w: weight, color: color, height: height));
}

class EnText extends StatelessWidget {
  final String t;
  final double size;
  final FontWeight weight;
  final Color? color;
  final double? letterSpacing;
  final double? height;
  final TextAlign? align;
  const EnText(this.t,
      {super.key,
      this.size = 13,
      this.weight = FontWeight.w500,
      this.color,
      this.letterSpacing,
      this.height,
      this.align});
  @override
  Widget build(BuildContext context) => Text(t,
      textAlign: align,
      style: AppText.en(
          size: size,
          w: weight,
          color: color,
          letterSpacing: letterSpacing,
          height: height));
}

// ── White card with border ──────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? bg;
  final BoxBorder? border;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 16,
    this.bg,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg ?? AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: AppColors.line),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

// ── Square icon button ──────────────────────────────────────────
class IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final Color? bg;
  final double size;
  final double iconSize;
  final Widget? badge;
  final bool dark;
  final BorderRadius? radius;

  const IconBtn({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
    this.bg,
    this.size = 36,
    this.iconSize = 16,
    this.badge,
    this.dark = false,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius ?? BorderRadius.circular(12),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bg ??
                  (dark ? Colors.white.withOpacity(0.1) : AppColors.card),
              borderRadius: radius ?? BorderRadius.circular(12),
              border: dark
                  ? Border.all(color: Colors.white.withOpacity(0.08))
                  : Border.all(color: AppColors.line),
            ),
            child: Icon(icon,
                size: iconSize,
                color: color ?? (dark ? Colors.white : AppColors.ink)),
          ),
        ),
      ),
      if (badge != null) Positioned(top: 6, right: 6, child: badge!),
    ]);
  }
}

// ── Status chip (GPS/Synced/Guardian) ───────────────────────────
class StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final bool ok;
  final Color? tone;
  const StatusChip({
    super.key,
    required this.icon,
    required this.label,
    required this.sub,
    this.ok = false,
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final c = tone ?? (ok ? AppColors.green : AppColors.ink2);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(children: [
          Icon(icon, size: 11, color: c),
          const SizedBox(width: 6),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              EnText(label, size: 10, weight: FontWeight.w700),
              EnText(sub, size: 9, color: AppColors.ink3),
            ],
          )),
        ]),
      ),
    );
  }
}

// ── Bottom navigation bar (light + dark variants) ───────────────
class BottomNavBar extends StatelessWidget {
  final String active;
  final void Function(String) onNav;
  final bool dark;
  const BottomNavBar({
    super.key,
    required this.active,
    required this.onNav,
    this.dark = false,
  });

  static const _items = [
    _NavItem('home', 'Home', Icons.shield_outlined, Icons.shield),
    _NavItem('route', 'Route', Icons.map_outlined, Icons.map),
    _NavItem('mitra', 'Mitra', Icons.chat_bubble_outline, Icons.chat_bubble),
    _NavItem('community', 'Feed', Icons.people_outline, Icons.people),
    _NavItem('legal', 'Legal', Icons.menu_book_outlined, Icons.menu_book),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: dark ? Colors.black.withOpacity(0.55) : AppColors.card,
        border: Border(
          top: BorderSide(
              color:
                  dark ? Colors.white.withOpacity(0.08) : AppColors.line),
        ),
      ),
      child: Row(
        children: _items.map((it) {
          final on = active == it.k;
          final color = on
              ? AppColors.green
              : (dark ? Colors.white.withOpacity(0.6) : AppColors.ink3);
          return Expanded(
            child: GestureDetector(
              onTap: () => onNav(it.k),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Stack(clipBehavior: Clip.none, children: [
                    Icon(on ? it.iOn : it.i, size: 20, color: color),
                    if (on)
                      Positioned(
                        top: -8,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2.5,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 3),
                  EnText(it.l,
                      size: 10,
                      weight: on ? FontWeight.w700 : FontWeight.w500,
                      color: color),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final String k, l;
  final IconData i, iOn;
  const _NavItem(this.k, this.l, this.i, this.iOn);
}

// ── Form field for login/register ──────────────────────────────
class GovField extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? hint;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  const GovField({
    super.key,
    required this.label,
    this.icon,
    this.hint,
    this.controller,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      EnText(label.toUpperCase(),
          size: 11,
          weight: FontWeight.w600,
          color: AppColors.ink2,
          letterSpacing: 0.5),
      const SizedBox(height: 6),
      Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.ink3),
            const SizedBox(width: 10),
          ],
          if (hint != null) ...[
            EnText(hint!,
                size: 13, weight: FontWeight.w600, color: AppColors.ink3),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              onSubmitted: onSubmitted,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (suffix != null) suffix!,
        ]),
      ),
    ]);
  }
}

// ── Trust badge (used in onboarding) ────────────────────────────
class TrustBadge extends StatelessWidget {
  final String label;
  final String sub;
  const TrustBadge({super.key, required this.label, required this.sub});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        constraints: const BoxConstraints(minWidth: 76),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          EnText(label.toUpperCase(),
              size: 9.5,
              weight: FontWeight.w600,
              color: AppColors.ink3,
              letterSpacing: 0.4),
          const SizedBox(height: 2),
          EnText(sub, size: 11, weight: FontWeight.w700),
        ]),
      );
}

// ── Half-circle gauge meter (Dashboard) ─────────────────────────
class GaugeMeter extends StatelessWidget {
  final double value; // 0-100
  final double width;
  const GaugeMeter({super.key, required this.value, this.width = 92});
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: width, height: width * 56 / 92,
          child: CustomPaint(painter: _GaugePainter(value)));
}

class _GaugePainter extends CustomPainter {
  final double value;
  _GaugePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.83;
    final r = math.min(size.width, size.height * 1.5) / 2.5;

    // Background arc
    final bgPaint = Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        math.pi, math.pi, false, bgPaint);

    // Foreground gradient arc
    final shader = SweepGradient(
      startAngle: math.pi,
      endAngle: 2 * math.pi,
      colors: const [AppColors.red, AppColors.amber, AppColors.green],
    ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    final fgPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        math.pi,
        math.pi * (value / 100).clamp(0.0, 1.0),
        false,
        fgPaint);

    // Needle
    final angle = math.pi + math.pi * (value / 100);
    final nx = cx + math.cos(angle) * (r - 4);
    final ny = cy + math.sin(angle) * (r - 4);
    canvas.drawLine(
        Offset(cx, cy),
        Offset(nx, ny),
        Paint()
          ..color = AppColors.ink
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(
        Offset(cx, cy), 4, Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.value != value;
}

// ── Hexagon (used in route legend) ──────────────────────────────
class Hexagon extends StatelessWidget {
  final Color fill;
  final double size;
  const Hexagon({super.key, required this.fill, this.size = 16});
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size,
          child: CustomPaint(painter: _HexPainter(fill)));
}

class _HexPainter extends CustomPainter {
  final Color fill;
  _HexPainter(this.fill);
  @override
  void paint(Canvas canvas, Size s) {
    final path = ui.Path();
    final cx = s.width / 2, cy = s.height / 2, r = s.width / 2 - 1;
    for (int i = 0; i < 6; i++) {
      final a = -math.pi / 6 + i * math.pi / 3;
      final x = cx + math.cos(a) * r, y = cy + math.sin(a) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = fill);
  }
  @override
  bool shouldRepaint(covariant _) => false;
}

// ── Pulse ring (animated for SOS button) ────────────────────────
class PulseRing extends StatefulWidget {
  final Color color;
  final double size;
  final Duration delay;
  const PulseRing({
    super.key,
    required this.color,
    this.size = 220,
    this.delay = Duration.zero,
  });
  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    Future.delayed(widget.delay, () {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final scale = 0.95 + _c.value * 0.45;
        final opacity = (0.7 - _c.value * 0.7).clamp(0.0, 1.0);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.color.withOpacity(opacity),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}
