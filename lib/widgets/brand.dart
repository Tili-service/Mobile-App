import 'package:flutter/material.dart';
import '../theme/theme.dart';

abstract final class TiliAssets {
  static const logo = 'assets/tiliLogo.png';
}

/* Logo in a translucent rounded square + "Tili" wordmark (web Sidebar / auth header). */
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40, this.onDark = true, this.showName = true, this.badge});

  final double size;
  final bool onDark;
  final bool showName;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.16),
          decoration: BoxDecoration(
            color: onDark ? p.onInk.withValues(alpha: 0.1) : p.surfaceMuted,
            borderRadius: TiliRadius.all(size >= 40 ? TiliRadius.md : TiliRadius.sm),
          ),
          child: Image.asset(TiliAssets.logo, fit: BoxFit.contain),
        ),
        if (showName) ...[
          const SizedBox(width: TiliSpace.md),
          Text(
            'Tili',
            style: context.text.titleLarge?.copyWith(color: onDark ? p.onInk : p.foreground, fontSize: size * 0.5),
          ),
        ],
        if (badge != null) ...[
          const SizedBox(width: TiliSpace.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: p.accentSoft.withValues(alpha: 0.2),
              borderRadius: TiliRadius.all(6),
            ),
            child: Text(
              badge!.toUpperCase(),
              style: context.text.labelSmall?.copyWith(color: p.accentSoft, fontSize: 10),
            ),
          ),
        ],
      ],
    );
  }
}

/* Dark "ink" surface with the soft decorative circles used on the web auth
panel and hero blocks. */
class InkPanel extends StatelessWidget {
  const InkPanel({super.key, required this.child, this.padding = const EdgeInsets.all(TiliSpace.xxxl)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget circle(double size, Color color) =>
        Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
    final soft = p.onInk.withValues(alpha: 0.05);
    return Container(
      color: p.ink,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(top: -128, left: -128, child: circle(384, soft)),
          Positioned(bottom: -96, right: -120, child: circle(320, soft)),
          Positioned(top: 120, right: 56, child: circle(120, p.accent.withValues(alpha: 0.12))),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
