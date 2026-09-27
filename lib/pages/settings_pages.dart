import 'package:flutter/material.dart';
import '../services/profile_service.dart';
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

  static const _menu = <(String, IconData)>[
    ('Boutique', Icons.store),
    ('Analytiques', Icons.bar_chart),
    ('Profils', Icons.people),
    ('Catalogue', Icons.inventory_2),
    ('TPE', Icons.point_of_sale),
    ('Informations', Icons.info_outline),
  ];

  Widget _infoRow(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 18, color: Colors.black87)),
    );
  }

  Widget _placeholder(String title, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _storeOverview() {
    final store = widget.license['store'] ?? {};
    final level = widget.adminProfile['level_access'] as int?;
    return ListView(
      children: [
        const Text('Boutique', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _infoRow(Icons.business, 'Nom du commerce', store['name']?.toString() ?? 'N/A'),
              _infoRow(Icons.confirmation_number, 'Licence', widget.license['licence_id']?.toString() ?? 'N/A'),
              _infoRow(Icons.admin_panel_settings, 'Connecté en tant que',
                  '${widget.adminProfile['name'] ?? 'Admin'} (${ProfileService.levelNames[level] ?? 'Inconnu'})'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 1; i < _menu.length; i++)
              ActionChip(
                avatar: Icon(_menu[i].$2, size: 18),
                label: Text(_menu[i].$1),
                onPressed: () => setState(() => _selectedIndex = i),
              ),
          ],
        ),
        const SizedBox(height: 24),
        const Text("Filtres d'accessibilité", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text("Options d'accessibilité à venir...", style: TextStyle(fontSize: 16)),
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Paramètres — ${widget.license['store']?['name'] ?? ''}'),
      ),
      body: Row(
        children: [
          SizedBox(
            width: 200,
            child: ListView.builder(
              itemCount: _menu.length,
              itemBuilder: (context, index) => ListTile(
                leading: Icon(_menu[index].$2),
                title: Text(_menu[index].$1),
                selected: index == _selectedIndex,
                onTap: () => setState(() => _selectedIndex = index),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }
}
