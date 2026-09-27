import 'package:flutter/material.dart';

/* Single source of truth for the app's look. Values mirror the web app
(Web-App/src/app/globals.css + the Tailwind classes used by the admin pages)
so both apps stay visually aligned: change a value here and every widget
picks it up through TiliTheme / TiliPalette. */

abstract final class TiliColors {
  // Brand (globals.css --brand-*)
  static const ink = Color(0xFF3B2B2C); // 355 16% 20%
  static const inkStrong = Color(0xFF2F2223); // 355 16% 16%
  static const inkSoft = Color(0xFF533C3E); // 355 16% 28% (sidebar-accent)
  static const orange = Color(0xFFF97415); // 25 95% 53%
  static const orangeStrong = Color(0xFFE9590C); // 21 90% 48%
  static const orangeSoft = Color(0xFFFDA863); // 27 97% 69% (sidebar-primary)
  static const orangeTint = Color(0xFFFFF7ED); // orange-50
  static const orangeRing = Color(0xFFFFEDD5); // orange-100

  // Theme (globals.css :root)
  static const primary = Color(0xFFC73E29); // 8 66% 47%
  static const secondary = Color(0xFF457B7D); // 182 29% 38%
  static const secondaryDeep = Color(0xFF326567); // 182 34% 30%
  static const accent = Color(0xFFFFAB57); // 30 100% 67%

  // Neutrals (Tailwind gray-*, as used across the admin pages)
  static const white = Color(0xFFFFFFFF);
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray900 = Color(0xFF111827);

  // Status
  static const success = Color(0xFF059669); // emerald-600
  static const successTint = Color(0xFFECFDF5);
  static const warning = Color(0xFFB45309); // amber-700
  static const warningTint = Color(0xFFFFFBEB);
  static const warningBorder = Color(0xFFFEF3C7);
  static const danger = Color(0xFFDC2626); // red-600
  static const dangerTint = Color(0xFFFEF2F2);
  static const dangerBorder = Color(0xFFFEE2E2);
  static const info = secondary;
  static const infoTint = Color(0xFFEEF5F5);
}

abstract final class TiliFonts {
  static const display = 'SpaceGrotesk';
  static const body = 'DMSans';
  static const brand = 'TiliFont';
}

abstract final class TiliSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const double page = 24; // p-6
  static const double card = 20; // p-5
  static const double gutter = 16; // gap-4
}

abstract final class TiliRadius {
  static const double sm = 8; // rounded-lg
  static const double md = 12; // rounded-xl — buttons, inputs
  static const double lg = 16; // rounded-2xl — cards
  static const double xl = 24; // rounded-3xl — panels, dialogs
  static const double pill = 999;

  static BorderRadius all(double r) => BorderRadius.circular(r);
}

abstract final class TiliSizes {
  static const double buttonSm = 36;
  static const double buttonMd = 44;
  static const double buttonLg = 56; // tablet primary actions
  static const double inputLg = 56;
  static const double iconSm = 16;
  static const double icon = 20;
  static const double iconLg = 24;
  static const double appBar = 64; // h-16
  static const double sideNav = 240;
  static const double formMaxWidth = 460;
  static const double contentMaxWidth = 640;
}

abstract final class TiliShadows {
  // .shadow-card: 0 4px 20px -4px foreground/10%
  static const card = [BoxShadow(color: Color(0x1A473335), offset: Offset(0, 4), blurRadius: 20, spreadRadius: -4)];
  // .shadow-warm: 0 10px 40px -10px primary/28%
  static const warm = [BoxShadow(color: Color(0x47C73E29), offset: Offset(0, 10), blurRadius: 40, spreadRadius: -10)];
  static const none = <BoxShadow>[];
}

abstract final class TiliGradients {
  static const warm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [TiliColors.accent, TiliColors.primary],
  );
  static const teal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [TiliColors.secondary, TiliColors.secondaryDeep],
  );
}

abstract final class TiliMotion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const curve = Curves.easeOutCubic;
}
