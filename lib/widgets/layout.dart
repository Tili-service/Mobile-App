import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'brand.dart';

class AuthFeature {
  const AuthFeature(this.icon, this.title, this.text);

  final IconData icon;
  final String title;
  final String text;
}

/* Tablet-first split-screen auth shell (web login/register): ink brand panel
on the left, form column on the right. The Scaffold does not resize for the
keyboard — only the form column gets bottom padding — so the brand panel stays
put and the focused field scrolls into view. Panel hides on narrow screens. */
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.onBack,
    this.footer,
    this.topAction,
    this.headline = 'Gérez vos\ncommerces\nsimplement.',
    this.tagline = 'La caisse tout-en-un pour vos points de vente.',
    this.features = defaultFeatures,
  });

  static const defaultFeatures = [
    AuthFeature(Icons.point_of_sale_outlined, 'Caisse rapide', 'Encaissez en quelques touches, même aux heures de pointe.'),
    AuthFeature(Icons.inventory_2_outlined, 'Catalogue centralisé', 'Catégories, articles et prix TTC toujours à jour.'),
    AuthFeature(Icons.pin_outlined, 'Accès par PIN', 'Chaque employé a son profil et ses droits.'),
  ];

  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? footer;
  final Widget? topAction;
  final String headline;
  final String tagline;
  final List<AuthFeature> features;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      backgroundColor: p.surface,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide) Expanded(child: _BrandPanel(headline: headline, tagline: tagline, features: features)),
                Expanded(
                  child: SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(TiliSpace.lg, TiliSpace.lg, TiliSpace.lg, 0),
                          child: SizedBox(
                            height: TiliSizes.buttonMd,
                            child: Row(
                              children: [
                                if (onBack != null)
                                  TextButton.icon(
                                    onPressed: onBack,
                                    icon: const Icon(Icons.arrow_back, size: TiliSizes.icon),
                                    label: const Text('Retour'),
                                    style: TextButton.styleFrom(foregroundColor: p.textMuted, minimumSize: const Size(0, TiliSizes.buttonMd)),
                                  ),
                                const Spacer(),
                                ?topAction,
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(TiliSpace.xxxl, TiliSpace.lg, TiliSpace.xxxl, TiliSpace.xxl + keyboard),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: TiliSizes.formMaxWidth),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (!wide) ...[
                                      const Center(child: BrandMark(onDark: false, size: 56, showName: false)),
                                      const SizedBox(height: TiliSpace.xl),
                                    ],
                                    Text(title, style: context.text.displaySmall),
                                    if (subtitle != null) ...[
                                      const SizedBox(height: TiliSpace.sm),
                                      Text(subtitle!, style: context.text.bodyLarge?.copyWith(color: p.textMuted)),
                                    ],
                                    const SizedBox(height: TiliSpace.xxl + TiliSpace.sm),
                                    child,
                                    if (footer != null) ...[const SizedBox(height: TiliSpace.xl), footer!],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.headline, required this.tagline, required this.features});

  final String headline;
  final String tagline;
  final List<AuthFeature> features;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkPanel(
      child: SafeArea(
        right: false,
        child: LayoutBuilder(
          builder: (context, c) {
            final roomy = c.maxHeight >= 600;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandMark(size: 48),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: p.accentSoft),
                    const SizedBox(width: TiliSpace.sm),
                    Text('LOGICIEL DE CAISSE', style: context.text.labelSmall?.copyWith(color: p.accentSoft, letterSpacing: 2)),
                  ],
                ),
                const SizedBox(height: TiliSpace.lg + 4),
                Text(
                  headline,
                  style: (roomy ? context.text.displayMedium : context.text.displaySmall)?.copyWith(color: p.onInk, height: 1.05),
                ),
                const SizedBox(height: TiliSpace.lg),
                Text(tagline, style: context.text.bodyLarge?.copyWith(color: p.onInkMuted, fontSize: 17)),
                if (roomy && features.isNotEmpty) ...[
                  const SizedBox(height: TiliSpace.xxl + TiliSpace.sm),
                  for (final f in features) _FeatureRow(feature: f),
                ],
                const Spacer(),
                Text('© ${DateTime.now().year} Tili — Logiciel de caisse',
                    style: context.text.bodySmall?.copyWith(color: p.onInk.withValues(alpha: 0.3))),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});

  final AuthFeature feature;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: TiliSpace.lg + 2),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: p.onInk.withValues(alpha: 0.08),
              borderRadius: TiliRadius.all(TiliRadius.md),
              border: Border.all(color: p.onInk.withValues(alpha: 0.06)),
            ),
            child: Icon(feature.icon, color: p.accentSoft, size: TiliSizes.icon),
          ),
          const SizedBox(width: TiliSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feature.title, style: context.text.titleSmall?.copyWith(color: p.onInk)),
                const SizedBox(height: 2),
                Text(feature.text, style: context.text.bodySmall?.copyWith(color: p.onInkMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* White top bar with bottom border (web AdminHeader). `breadcrumb` renders
the "Parent / Current" line above the title. */
class TiliAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TiliAppBar({super.key, required this.title, this.breadcrumb, this.actions = const [], this.leading, this.showBack = true});

  final String title;
  final String? breadcrumb;
  final List<Widget> actions;
  final Widget? leading;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(TiliSizes.appBar);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasBack = showBack && (ModalRoute.of(context)?.canPop ?? false);
    return AppBar(
      automaticallyImplyLeading: showBack,
      leading: leading,
      titleSpacing: leading == null && !hasBack ? TiliSpace.xl : TiliSpace.sm,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (breadcrumb != null)
            Text(breadcrumb!, style: context.text.bodySmall?.copyWith(color: p.textSubtle)),
          Text(title, overflow: TextOverflow.ellipsis),
        ],
      ),
      actions: [...actions, const SizedBox(width: TiliSpace.md)],
    );
  }
}

class FullscreenButton extends StatelessWidget {
  const FullscreenButton({super.key, required this.isFullScreen, required this.onToggle});

  final bool isFullScreen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: null,
      tooltip: isFullScreen ? 'Quitter le plein écran' : 'Plein écran',
      onPressed: onToggle,
      child: Icon(isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
    );
  }
}

/* Centered, width-capped, padded page body. */
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.maxWidth, this.padding = const EdgeInsets.all(TiliSpace.page)});

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class SideNavItem {
  const SideNavItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

/* Dark sidebar (web Sidebar + NavLinks): brand header, items, optional footer. */
class SideNav extends StatelessWidget {
  const SideNav({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
    this.header,
    this.footer,
  });

  final List<SideNavItem> items;
  final int selected;
  final ValueChanged<int> onSelect;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: TiliSizes.sideNav,
      color: p.ink,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: TiliSizes.appBar,
              padding: const EdgeInsets.symmetric(horizontal: TiliSpace.lg + 4),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.inkSoft))),
              child: header ?? const BrandMark(size: 32, badge: 'Admin'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: TiliSpace.md, vertical: TiliSpace.lg),
                children: [
                  for (final (i, item) in items.indexed) _NavTile(item: item, active: i == selected, onTap: () => onSelect(i)),
                ],
              ),
            ),
            if (footer != null)
              Container(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: p.inkSoft))),
                padding: const EdgeInsets.all(TiliSpace.md),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.active, required this.onTap});

  final SideNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = active ? p.accentSoft : p.onInkMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: TiliSpace.xxs),
      child: Material(
        color: active ? p.accentSoft.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: TiliRadius.all(TiliRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: TiliRadius.all(TiliRadius.sm),
          hoverColor: p.inkSoft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: TiliSpace.md, vertical: TiliSpace.sm + 3),
            child: Row(
              children: [
                Icon(item.icon, size: TiliSizes.iconSm + 2, color: fg),
                const SizedBox(width: TiliSpace.md),
                Text(item.label, style: context.text.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
