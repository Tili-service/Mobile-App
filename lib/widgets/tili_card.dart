import 'package:flutter/material.dart';
import '../theme/theme.dart';

/* White rounded card with the soft web border (`bg-white border-gray-100
rounded-2xl`). Tappable when `onTap` is set; `highlight` gives the orange
hover look of the web shop cards. */
class TiliCard extends StatelessWidget {
  const TiliCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(TiliSpace.card),
    this.onTap,
    this.highlight = false,
    this.shadow = false,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool highlight;
  final bool shadow;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = TiliRadius.all(TiliRadius.lg);
    return AnimatedContainer(
      duration: TiliMotion.normal,
      curve: TiliMotion.curve,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? (highlight ? p.focusRing : p.borderSubtle)),
        boxShadow: shadow || highlight ? TiliShadows.card : TiliShadows.none,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          hoverColor: p.accentTint.withValues(alpha: 0.5),
          splashColor: p.accentTint,
          highlightColor: p.accentTint.withValues(alpha: 0.6),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/* Titled card block (settings sections, "Zone de danger"). */
class TiliSection extends StatelessWidget {
  const TiliSection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.icon,
    this.tone = TiliTone.neutral,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final TiliTone tone;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final danger = tone == TiliTone.danger;
    return TiliCard(
      borderColor: danger ? p.dangerBorder : null,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(TiliSpace.xl, TiliSpace.lg + 2, TiliSpace.xl, TiliSpace.lg),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: TiliSizes.icon, color: danger ? p.danger : p.textSubtle),
                  const SizedBox(width: TiliSpace.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.text.titleMedium?.copyWith(color: danger ? p.danger : null)),
                      if (subtitle != null) ...[
                        const SizedBox(height: TiliSpace.xxs),
                        Text(subtitle!, style: context.text.bodySmall),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: danger ? p.dangerBorder : p.borderSubtle),
          Padding(
            padding: const EdgeInsets.all(TiliSpace.xl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ],
      ),
    );
  }
}
