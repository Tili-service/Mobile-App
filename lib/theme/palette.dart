import 'package:flutter/material.dart';
import 'tokens.dart';

enum TiliTone { neutral, brand, accent, success, warning, danger, info }

/* Semantic colors read by widgets (`context.palette.x`). Widgets never use
TiliColors directly, so a dark/alternate palette only needs a new instance
here. */
@immutable
class TiliPalette extends ThemeExtension<TiliPalette> {
  const TiliPalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.foreground,
    required this.textStrong,
    required this.textMuted,
    required this.textSubtle,
    required this.border,
    required this.borderSubtle,
    required this.ink,
    required this.inkStrong,
    required this.inkSoft,
    required this.onInk,
    required this.onInkMuted,
    required this.accent,
    required this.accentStrong,
    required this.accentSoft,
    required this.accentTint,
    required this.focusRing,
    required this.success,
    required this.successTint,
    required this.warning,
    required this.warningTint,
    required this.warningBorder,
    required this.danger,
    required this.dangerTint,
    required this.dangerBorder,
    required this.info,
    required this.infoTint,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color foreground;
  final Color textStrong;
  final Color textMuted;
  final Color textSubtle;
  final Color border;
  final Color borderSubtle;
  final Color ink;
  final Color inkStrong;
  final Color inkSoft;
  final Color onInk;
  final Color onInkMuted;
  final Color accent;
  final Color accentStrong;
  final Color accentSoft;
  final Color accentTint;
  final Color focusRing;
  final Color success;
  final Color successTint;
  final Color warning;
  final Color warningTint;
  final Color warningBorder;
  final Color danger;
  final Color dangerTint;
  final Color dangerBorder;
  final Color info;
  final Color infoTint;

  static const light = TiliPalette(
    background: TiliColors.gray50,
    surface: TiliColors.white,
    surfaceMuted: TiliColors.gray50,
    foreground: TiliColors.gray900,
    textStrong: TiliColors.gray700,
    textMuted: TiliColors.gray500,
    textSubtle: TiliColors.gray400,
    border: TiliColors.gray200,
    borderSubtle: TiliColors.gray100,
    ink: TiliColors.ink,
    inkStrong: TiliColors.inkStrong,
    inkSoft: TiliColors.inkSoft,
    onInk: TiliColors.white,
    onInkMuted: Color(0x99FFFFFF),
    accent: TiliColors.orange,
    accentStrong: TiliColors.orangeStrong,
    accentSoft: TiliColors.orangeSoft,
    accentTint: TiliColors.orangeTint,
    focusRing: TiliColors.orangeRing,
    success: TiliColors.success,
    successTint: TiliColors.successTint,
    warning: TiliColors.warning,
    warningTint: TiliColors.warningTint,
    warningBorder: TiliColors.warningBorder,
    danger: TiliColors.danger,
    dangerTint: TiliColors.dangerTint,
    dangerBorder: TiliColors.dangerBorder,
    info: TiliColors.info,
    infoTint: TiliColors.infoTint,
  );

  /// (foreground, tinted background) for badges, icon tiles, notices.
  (Color, Color) tone(TiliTone tone) => switch (tone) {
        TiliTone.neutral => (textMuted, borderSubtle),
        TiliTone.brand => (ink, borderSubtle),
        TiliTone.accent => (accentStrong, accentTint),
        TiliTone.success => (success, successTint),
        TiliTone.warning => (warning, warningTint),
        TiliTone.danger => (danger, dangerTint),
        TiliTone.info => (info, infoTint),
      };

  @override
  TiliPalette copyWith() => this;

  @override
  TiliPalette lerp(ThemeExtension<TiliPalette>? other, double t) => t < 0.5 || other is! TiliPalette ? this : other;
}

extension TiliThemeContext on BuildContext {
  TiliPalette get palette => Theme.of(this).extension<TiliPalette>() ?? TiliPalette.light;
  TextTheme get text => Theme.of(this).textTheme;
}
