import 'package:flutter/material.dart';
import '../theme/theme.dart';

enum TiliButtonVariant { brand, accent, outline, ghost, danger, dangerGhost, soft }

enum TiliButtonSize { sm, md, lg }

/* Mirrors the web `<Button variant=…>`: pick a variant, never pass colors. */
class TiliButton extends StatelessWidget {
  const TiliButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = TiliButtonVariant.brand,
    this.size = TiliButtonSize.md,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final TiliButtonVariant variant;
  final TiliButtonSize size;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, fg, border, overlay) = switch (variant) {
      TiliButtonVariant.brand => (p.ink, p.onInk, null, p.inkStrong),
      TiliButtonVariant.accent => (p.accent, p.onInk, null, p.accentStrong),
      TiliButtonVariant.outline => (p.surface, p.foreground, p.border, p.surfaceMuted),
      TiliButtonVariant.ghost => (Colors.transparent, p.textMuted, null, p.borderSubtle),
      TiliButtonVariant.danger => (p.danger, p.onInk, null, p.danger),
      TiliButtonVariant.dangerGhost => (Colors.transparent, p.danger, null, p.dangerTint),
      TiliButtonVariant.soft => (p.accentTint, p.accentStrong, null, p.focusRing),
    };
    final (height, hPad, fontSize, iconSize) = switch (size) {
      TiliButtonSize.sm => (TiliSizes.buttonSm, TiliSpace.md, 13.0, TiliSizes.iconSm),
      TiliButtonSize.md => (TiliSizes.buttonMd, TiliSpace.lg + 2, 14.0, TiliSizes.iconSm + 1),
      TiliButtonSize.lg => (TiliSizes.buttonLg, TiliSpace.xl, 15.0, TiliSizes.icon),
    };
    final disabled = onPressed == null || loading;

    final style = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(disabled && bg != Colors.transparent ? bg.withValues(alpha: 0.5) : bg),
      foregroundColor: WidgetStatePropertyAll(disabled ? fg.withValues(alpha: 0.6) : fg),
      overlayColor: WidgetStatePropertyAll(overlay.withValues(alpha: 0.35)),
      minimumSize: WidgetStatePropertyAll(Size(0, height)),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: hPad)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: TiliRadius.all(TiliRadius.md))),
      side: WidgetStatePropertyAll(border == null ? BorderSide.none : BorderSide(color: border)),
      textStyle: WidgetStatePropertyAll(context.text.labelLarge?.copyWith(fontSize: fontSize)),
      elevation: const WidgetStatePropertyAll(0),
    );

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: loading
          ? [
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              ),
            ]
          : [
              if (icon != null) ...[Icon(icon, size: iconSize, color: fg), const SizedBox(width: TiliSpace.sm)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              if (trailingIcon != null) ...[
                const SizedBox(width: TiliSpace.sm),
                Icon(trailingIcon, size: iconSize, color: fg),
              ],
            ],
    );

    final button = TextButton(onPressed: disabled ? null : onPressed, style: style, child: content);
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/* Square icon-only button (web: `p-1.5 rounded-lg hover:bg-gray-100`). */
class TiliIconButton extends StatelessWidget {
  const TiliIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.tone = TiliTone.neutral,
    this.bordered = false,
    this.size = TiliSizes.buttonSm,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final TiliTone tone;
  final bool bordered;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (fg, tint) = p.tone(tone);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: TiliSizes.icon - 2),
      style: IconButton.styleFrom(
        foregroundColor: tone == TiliTone.neutral ? p.textMuted : fg,
        hoverColor: tint,
        highlightColor: tint,
        disabledForegroundColor: p.border,
        backgroundColor: bordered ? p.surface : null,
        fixedSize: Size.square(size),
        minimumSize: Size.square(size),
        padding: EdgeInsets.zero,
        side: bordered ? BorderSide(color: p.border) : null,
        shape: RoundedRectangleBorder(borderRadius: TiliRadius.all(TiliRadius.sm + 2)),
      ),
    );
  }
}
