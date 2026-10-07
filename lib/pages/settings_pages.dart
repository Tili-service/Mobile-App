import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import 'settings/catalog_section.dart';
import 'settings/profiles_section.dart';

/* Store back-office, reached from the POS after an admin PIN check. Every
call here uses `adminToken` (the ProfileToken of the admin who unlocked the
page), not the cashier's token, so a low-level cashier session cannot manage
the store. */
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.isFullScreen,
    required this.onToggleFullScreen,
    required this.license,
    required this.storeId,
    required this.adminToken,
    required this.adminProfile,
    this.currentCatalogId,
  });

  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;
  final Map<String, dynamic> license;
  final String storeId;
  final String adminToken;
  final Map<String, dynamic> adminProfile;
  final String? currentCatalogId;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 0;

  static const _menu = [
    SideNavItem('Boutique', Icons.storefront_outlined),
    SideNavItem('Analytiques', Icons.bar_chart_rounded),
    SideNavItem('Profils', Icons.people_outline),
    SideNavItem('Catalogue', Icons.inventory_2_outlined),
    SideNavItem('TPE', Icons.point_of_sale_outlined),
    SideNavItem('Informations', Icons.info_outline),
  ];

  Widget _infoRow(IconData icon, String label, String value) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TiliSpace.sm),
      child: Row(
        children: [
          IconTile(icon: icon, size: 36),
          const SizedBox(width: TiliSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.text.bodySmall?.copyWith(color: p.textSubtle)),
                Text(value, style: context.text.titleSmall, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(String title, String text) {
    return EmptyState(icon: Icons.construction_outlined, title: title, message: text, tone: TiliTone.neutral);
  }

  Widget _shortcut(int index) {
    final item = _menu[index];
    return TiliCard(
      onTap: () => setState(() => _selectedIndex = index),
      padding: const EdgeInsets.all(TiliSpace.lg),
      child: Row(
        children: [
          IconTile(icon: item.icon, tone: TiliTone.accent),
          const SizedBox(width: TiliSpace.md),
          Expanded(child: Text(item.label, style: context.text.titleSmall)),
          Icon(Icons.chevron_right, color: context.palette.border),
        ],
      ),
    );
  }

  Widget _storeOverview() {
    final store = widget.license['store'] ?? {};
    final level = widget.adminProfile['level_access'] as int?;
    return ListView(
      children: [
        const PageHeader(title: 'Boutique', subtitle: 'Vue d\'ensemble de votre commerce'),
        const SizedBox(height: TiliSpace.xl),
        TiliSection(
          title: 'Informations',
          icon: Icons.storefront_outlined,
          children: [
            _infoRow(Icons.business_outlined, 'Nom du commerce', store['name']?.toString() ?? 'N/A'),
            _infoRow(Icons.confirmation_number_outlined, 'Licence', widget.license['licence_id']?.toString() ?? 'N/A'),
            _infoRow(Icons.admin_panel_settings_outlined, 'Connecté en tant que',
                '${widget.adminProfile['name'] ?? 'Admin'} (${ProfileService.levelNames[level] ?? 'Inconnu'})'),
          ],
        ),
        const SizedBox(height: TiliSpace.xl),
        const SectionLabel('Accès rapide'),
        const SizedBox(height: TiliSpace.md),
        LayoutBuilder(
          builder: (context, c) {
            const gap = TiliSpace.md;
            final cols = (c.maxWidth / 260).floor().clamp(1, 3);
            final w = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [for (var i = 1; i < _menu.length; i++) SizedBox(width: w, child: _shortcut(i))],
            );
          },
        ),
        const SizedBox(height: TiliSpace.xl),
        const TiliSection(
          title: "Filtres d'accessibilité",
          icon: Icons.accessibility_new_outlined,
          children: [Notice(message: "Options d'accessibilité à venir…", tone: TiliTone.info)],
        ),
      ],
    );
  }

  Widget _buildContent() {
    return switch (_selectedIndex) {
      0 => _storeOverview(),
      1 => _placeholder('Analytiques', 'Les statistiques de ventes arrivent bientôt.'),
      2 => ProfilesSection(
          token: widget.adminToken,
          storeId: widget.storeId,
          currentProfileId: widget.adminProfile['profile_id']?.toString(),
        ),
      3 => CatalogSection(
          token: widget.adminToken,
          storeId: widget.storeId,
          initialCatalogId: widget.currentCatalogId,
        ),
      4 => _placeholder('Configuration TPE', 'La connexion aux terminaux de paiement arrive bientôt.'),
      _ => _placeholder('Informations', 'Bientôt disponible.'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final adminName = widget.adminProfile['name']?.toString() ?? 'Admin';
    return Scaffold(
      body: Row(
        children: [
          SideNav(
            items: _menu,
            selected: _selectedIndex,
            onSelect: (i) => setState(() => _selectedIndex = i),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Avatar(name: adminName, size: 34),
                    const SizedBox(width: TiliSpace.sm + 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(adminName, overflow: TextOverflow.ellipsis, style: context.text.labelLarge?.copyWith(color: p.onInk)),
                          Text(
                            ProfileService.levelNames[widget.adminProfile['level_access']] ?? '',
                            style: context.text.bodySmall?.copyWith(color: p.onInkMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TiliSpace.md),
                TiliButton(
                  label: 'Retour à la caisse',
                  icon: Icons.arrow_back,
                  variant: TiliButtonVariant.accent,
                  size: TiliButtonSize.sm,
                  expand: true,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                TiliAppBar(
                  showBack: false,
                  breadcrumb: 'Paramètres',
                  title: widget.license['store']?['name']?.toString() ?? '',
                  actions: [
                    FullscreenButton(isFullScreen: widget.isFullScreen, onToggle: widget.onToggleFullScreen),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(TiliSpace.page),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
