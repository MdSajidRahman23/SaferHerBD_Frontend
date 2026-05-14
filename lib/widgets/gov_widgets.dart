import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class SafeHerLogo extends StatelessWidget {
  final double size;
  final bool light;
  final bool compact;
  const SafeHerLogo({super.key, this.size = 30, this.light = false, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final mainColor = light ? Colors.white : AppColors.g;
    final subColor  = light ? Colors.white.withValues(alpha: 0.65) : AppColors.t3;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: size, height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: light
              ? [Colors.white.withValues(alpha: 0.25), Colors.white.withValues(alpha: 0.1)]
              : [AppColors.gl, AppColors.gd],
          ),
          borderRadius: BorderRadius.circular(size * 0.25),
          border: light ? Border.all(color: Colors.white.withValues(alpha: 0.3)) : null,
        ),
        child: Center(child: Icon(Icons.shield_rounded,
            color: light ? Colors.white : AppColors.gold, size: size * 0.55)),
      ),
      if (!compact) ...[
        const SizedBox(width: 9),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          RichText(text: TextSpan(children: [
            TextSpan(text: 'SafeHer', style: GoogleFonts.dmSans(
                fontSize: size * 0.55, fontWeight: FontWeight.w800,
                color: mainColor, letterSpacing: -0.5)),
            TextSpan(text: 'BD', style: GoogleFonts.dmSans(
                fontSize: size * 0.55, fontWeight: FontWeight.w800,
                color: light ? Colors.white : AppColors.r, letterSpacing: -0.5)),
          ])),
          Text('নিরাপদ নারী', style: GoogleFonts.hindSiliguri(
              fontSize: size * 0.36, color: subColor, height: 1.2)),
        ]),
      ],
    ]);
  }
}

class HeroHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget>? children;
  const HeroHeader({super.key, required this.title, this.subtitle, this.trailing, this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.gdd, AppColors.gd, AppColors.g, AppColors.gl],
          stops: [0, 0.4, 0.75, 1],
        ),
      ),
      child: Stack(children: [
        Positioned(top: -60, right: -60, child: Container(width: 200, height: 200,
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04)))),
        Positioned(bottom: -40, left: -40, child: Container(width: 120, height: 120,
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.03)))),
        SafeArea(bottom: false, child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const SafeHerLogo(size: 32, light: true),
              const Spacer(),
              if (trailing != null) trailing!,
            ]),
            const SizedBox(height: 18),
            Text(title, style: GoogleFonts.dmSans(
                color: Colors.white, fontSize: 24,
                fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: GoogleFonts.hindSiliguri(
                  color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
            ],
            if (children != null) ...children!,
          ]),
        )),
      ]),
    );
  }
}

class GovCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  const GovCard({super.key, required this.child,
    this.padding = const EdgeInsets.all(14), this.onTap, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: card));
  }
}

class SectionTitle extends StatelessWidget {
  final String en, bn;
  final Widget? trailing;
  const SectionTitle({super.key, required this.en, required this.bn, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(en, style: GoogleFonts.dmSans(
            color: AppColors.t1, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(width: 6),
        Text('· $bn', style: GoogleFonts.hindSiliguri(
            color: AppColors.t3, fontSize: 12)),
        const Spacer(),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool light;
  const StatusPill({super.key, required this.label, required this.color,
    this.icon, this.light = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: light ? Colors.white.withValues(alpha: 0.15) : color.withValues(alpha: 0.1),
        border: Border.all(
            color: light ? Colors.white.withValues(alpha: 0.25) : color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 11, color: light ? Colors.white : color),
          const SizedBox(width: 4),
        ] else ...[
          Container(width: 5, height: 5,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: light ? Colors.white : color)),
          const SizedBox(width: 5),
        ],
        Text(label, style: GoogleFonts.hindSiliguri(
            color: light ? Colors.white : color,
            fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class GovFooter extends StatelessWidget {
  const GovFooter({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.g.withValues(alpha: 0.3), width: 1.5),
            shape: BoxShape.circle),
          child: const Icon(Icons.verified_rounded, color: AppColors.g, size: 24)),
        const SizedBox(height: 6),
        Text('Government of Bangladesh',
            style: GoogleFonts.dmSans(color: AppColors.t2, fontSize: 11,
                fontWeight: FontWeight.w600)),
        Text('গণপ্রজাতন্ত্রী বাংলাদেশ সরকার',
            style: GoogleFonts.hindSiliguri(color: AppColors.t3, fontSize: 10)),
      ]),
    );
  }
}