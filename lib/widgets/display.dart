import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'tili_card.dart';

/* Small read-only building blocks shared by every page: icon tile, badge,
page header, stat card, empty state, notice. */

class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, this.tone = TiliTone.neutral, this.size = 40, this.circle = false});

  final IconData icon;
  final TiliTone tone;
  final double size;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = context.palette.tone(tone);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: circle ? null : TiliRadius.all(size >= 56 ? TiliRadius.lg : TiliRadius.md),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: Icon(icon, color: fg, size: size * 0.45),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.tone = TiliTone.neutral, this.dot = false, this.icon});

  final String label;
  final TiliTone tone;
  final bool dot;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = context.palette.tone(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TiliSpace.sm + 2, vertical: TiliSpace.xxs + 1),
      decoration: BoxDecoration(color: bg, borderRadius: TiliRadius.all(TiliRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
            const SizedBox(width: TiliSpace.xs + 2),
          ],
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: TiliSpace.xs)],
          Text(label, style: context.text.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

/* `<PageHeader>`: display title + muted subtitle, actions on the right. */
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.eyebrow, this.actions = const [], this.leading});

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: TiliSpace.sm)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrow != null) ...[
                Text(eyebrow!.toUpperCase(), style: context.text.labelSmall),
                const SizedBox(height: TiliSpace.xs),
              ],
              Text(title, style: context.text.headlineSmall, overflow: TextOverflow.ellipsis),
              if (subtitle != null) ...[
                const SizedBox(height: TiliSpace.xxs),
                Text(subtitle!, style: context.text.bodyMedium?.copyWith(color: context.palette.textSubtle)),
              ],
            ],
          ),
        ),
        for (final (i, a) in actions.indexed) ...[if (i > 0) const SizedBox(width: TiliSpace.sm), a],
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value, this.icon, this.tone = TiliTone.neutral});

  final String label;
  final Object value;
  final IconData? icon;
  final TiliTone tone;

  @override
  Widget build(BuildContext context) {
    final (fg, _) = context.palette.tone(tone);
    return TiliCard(
      padding: const EdgeInsets.all(TiliSpace.lg + 2),
      child: Row(
        children: [
          if (icon != null) ...[IconTile(icon: icon!, tone: tone), const SizedBox(width: TiliSpace.md + 2)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: context.text.headlineSmall?.copyWith(color: icon == null && tone != TiliTone.neutral ? fg : null),
                ),
                Text(label, style: context.text.labelMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* Lays out StatCards in one row with equal widths (web `grid-cols-3 gap-3`). */
class StatRow extends StatelessWidget {
  const StatRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, c) in children.indexed) ...[
          if (i > 0) const SizedBox(width: TiliSpace.md),
          Expanded(child: c),
        ],
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.tone = TiliTone.accent,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final TiliTone tone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TiliSpace.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTile(icon: icon, tone: tone, size: 64),
              const SizedBox(height: TiliSpace.lg + 4),
              Text(title, style: context.text.titleLarge, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: TiliSpace.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(color: context.palette.textSubtle),
                ),
              ],
              if (action != null) ...[const SizedBox(height: TiliSpace.xl), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/* Inline callout (web: `text-amber-700 bg-amber-50 border-amber-100 rounded-lg`). */
class Notice extends StatelessWidget {
  const Notice({super.key, required this.message, this.tone = TiliTone.warning, this.icon});

  final String message;
  final TiliTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (fg, bg) = p.tone(tone);
    final border = switch (tone) {
      TiliTone.warning => p.warningBorder,
      TiliTone.danger => p.dangerBorder,
      _ => fg.withValues(alpha: 0.15),
    };
    final defaultIcon = switch (tone) {
      TiliTone.danger => Icons.error_outline,
      TiliTone.success => Icons.check_circle_outline,
      TiliTone.warning => Icons.warning_amber_rounded,
      _ => Icons.info_outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: TiliSpace.md, vertical: TiliSpace.sm + 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: TiliRadius.all(TiliRadius.sm),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, size: TiliSizes.iconSm, color: fg),
          const SizedBox(width: TiliSpace.sm),
          Expanded(child: Text(message, style: context.text.bodySmall?.copyWith(color: fg, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

/* Uppercase gray label above a group (web: `text-xs font-semibold uppercase tracking-wide text-gray-400`). */
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: context.text.labelSmall);
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.size = 40, this.tone = TiliTone.accent});

  final String name;
  final double size;
  final TiliTone tone;

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length >= 2) return (parts.first[0] + parts.last[0]).toUpperCase();
    return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = context.palette.tone(tone);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: TiliRadius.all(TiliRadius.md)),
      child: Text(
        initials(name),
        style: context.text.labelLarge?.copyWith(color: fg, fontFamily: TiliFonts.display, fontSize: size * 0.36),
      ),
    );
  }
}
