import 'package:flutter/material.dart';
import 'palette.dart';
import 'tokens.dart';

/* Builds the Material theme from the tokens: every stock Material widget
(TextField, FilledButton, Card, Dialog, Chip…) is styled here so pages can use
them plain and still look like the web app. */
abstract final class TiliTheme {
  static ThemeData light() => _build(TiliPalette.light);

  static TextTheme _textTheme(TiliPalette p) {
    TextStyle display(double size, [FontWeight weight = FontWeight.w700]) =>
        TextStyle(fontFamily: TiliFonts.display, fontSize: size, fontWeight: weight, color: p.foreground, height: 1.2);
    TextStyle body(double size, [FontWeight weight = FontWeight.w400, Color? color]) =>
        TextStyle(fontFamily: TiliFonts.body, fontSize: size, fontWeight: weight, color: color ?? p.foreground, height: 1.4);

    return TextTheme(
      displayLarge: display(48),
      displayMedium: display(40),
      displaySmall: display(32),
      headlineLarge: display(30),
      headlineMedium: display(26),
      headlineSmall: display(22),
      titleLarge: display(18),
      titleMedium: body(16, FontWeight.w600),
      titleSmall: body(14, FontWeight.w600),
      bodyLarge: body(16),
      bodyMedium: body(14),
      bodySmall: body(12, FontWeight.w400, p.textMuted),
      labelLarge: body(14, FontWeight.w600),
      labelMedium: body(13, FontWeight.w500, p.textMuted),
      labelSmall: body(11, FontWeight.w600, p.textSubtle).copyWith(letterSpacing: 0.8),
    );
  }

  static ThemeData _build(TiliPalette p) {
    final text = _textTheme(p);
    final buttonShape = RoundedRectangleBorder(borderRadius: TiliRadius.all(TiliRadius.md));
    const buttonPadding = EdgeInsets.symmetric(horizontal: TiliSpace.xl - 4, vertical: TiliSpace.md);
    const buttonMinSize = Size(0, TiliSizes.buttonMd);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: TiliRadius.all(TiliRadius.md),
          borderSide: BorderSide(color: color, width: width),
        );

    final colorScheme = ColorScheme.fromSeed(seedColor: p.ink).copyWith(
      primary: p.ink,
      onPrimary: p.onInk,
      secondary: p.accent,
      onSecondary: p.onInk,
      tertiary: p.info,
      surface: p.surface,
      onSurface: p.foreground,
      onSurfaceVariant: p.textMuted,
      surfaceContainerHighest: p.surfaceMuted,
      error: p.danger,
      outline: p.border,
      outlineVariant: p.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: TiliFonts.body,
      textTheme: text,
      scaffoldBackgroundColor: p.background,
      extensions: [p],
      splashFactory: InkRipple.splashFactory,
      dividerTheme: DividerThemeData(color: p.borderSubtle, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: p.textMuted, size: TiliSizes.icon),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.accent.withValues(alpha: 0.25),
        selectionHandleColor: p.accent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: TiliSizes.appBar,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: p.textMuted),
        actionsIconTheme: IconThemeData(color: p.textMuted),
        shape: Border(bottom: BorderSide(color: p.borderSubtle)),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: TiliRadius.all(TiliRadius.lg),
          side: BorderSide(color: p.borderSubtle),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: TiliSpace.lg, vertical: 14),
        hintStyle: text.bodyMedium?.copyWith(color: p.textSubtle),
        labelStyle: text.bodyMedium?.copyWith(color: p.textMuted),
        floatingLabelStyle: text.bodyMedium?.copyWith(color: p.accentStrong),
        prefixIconColor: p.textSubtle,
        suffixIconColor: p.textSubtle,
        counterStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: p.danger),
        border: inputBorder(p.border),
        enabledBorder: inputBorder(p.border),
        disabledBorder: inputBorder(p.borderSubtle),
        focusedBorder: inputBorder(p.accent, 1.5),
        errorBorder: inputBorder(p.danger),
        focusedErrorBorder: inputBorder(p.danger, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.ink,
          foregroundColor: p.onInk,
          disabledBackgroundColor: p.ink.withValues(alpha: 0.5),
          disabledForegroundColor: p.onInk.withValues(alpha: 0.8),
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
          elevation: 0,
        ).copyWith(overlayColor: WidgetStatePropertyAll(p.inkStrong.withValues(alpha: 0.4))),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.ink,
          foregroundColor: p.onInk,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.foreground,
          backgroundColor: p.surface,
          side: BorderSide(color: p.border),
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accentStrong,
          shape: RoundedRectangleBorder(borderRadius: TiliRadius.all(TiliRadius.sm)),
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.textMuted,
          shape: RoundedRectangleBorder(borderRadius: TiliRadius.all(TiliRadius.sm)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.surface,
        foregroundColor: p.textMuted,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: TiliRadius.all(TiliRadius.md),
          side: BorderSide(color: p.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.accentTint,
        disabledColor: p.borderSubtle,
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(borderRadius: TiliRadius.all(TiliRadius.md)),
        labelStyle: text.labelLarge?.copyWith(color: p.foreground, fontWeight: FontWeight.w500),
        secondaryLabelStyle: text.labelLarge?.copyWith(color: p.accentStrong),
        iconTheme: IconThemeData(color: p.textMuted, size: TiliSizes.iconSm + 2),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: TiliSpace.sm, vertical: TiliSpace.xs),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.ink : p.surface),
          foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.onInk : p.textMuted),
          iconColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.onInk : p.textMuted),
          side: WidgetStatePropertyAll(BorderSide(color: p.border)),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          minimumSize: const WidgetStatePropertyAll(Size(0, TiliSizes.buttonSm + 4)),
        ),
        selectedIcon: const SizedBox.shrink(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.accent : p.border),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.accent : Colors.transparent),
        side: BorderSide(color: p.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: TiliRadius.all(4)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textMuted,
        textColor: p.foreground,
        selectedColor: p.accentStrong,
        selectedTileColor: p.accentTint,
        shape: RoundedRectangleBorder(borderRadius: TiliRadius.all(TiliRadius.md)),
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: TiliRadius.all(TiliRadius.xl)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.textMuted),
        actionsPadding: const EdgeInsets.fromLTRB(TiliSpace.xl, 0, TiliSpace.xl, TiliSpace.xl),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.onInk),
        actionTextColor: p.accentSoft,
        shape: RoundedRectangleBorder(borderRadius: TiliRadius.all(TiliRadius.md)),
        width: 420,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: p.ink, borderRadius: TiliRadius.all(TiliRadius.sm)),
        textStyle: text.bodySmall?.copyWith(color: p.onInk),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: TiliRadius.all(TiliRadius.md),
          side: BorderSide(color: p.borderSubtle),
        ),
        textStyle: text.bodyMedium,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(textStyle: text.bodyMedium),
      canvasColor: p.surface,
    );
  }
}
