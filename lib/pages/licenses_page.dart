import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/license_service.dart';
import '../services/token_service.dart';
import '../widgets/dialogs.dart';
import 'account_page.dart';
import 'credentials_page.dart';
import 'session_page.dart';
import 'shop_forms_page.dart';

enum _LicenseStatus { active, expired, inactive }

/* Home screen after account login: the merchant's licences and the shop each
one is linked to. Tapping a linked licence opens the shop's PIN screen; an
active unlinked licence opens the shop creation form. Buying a licence is
done on the web app on purpose. */
class LicensesPage extends StatefulWidget {
  const LicensesPage({
    super.key,
    required this.isFullScreen,
    required this.onToggleFullScreen,
  });

  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;

  @override
  State<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends State<LicensesPage> {
  List<dynamic>? _licenses;
  Map<String, dynamic> _storesById = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  Future<void> _loadLicenses() async {
    final token = await TokenService.getToken(TokenType.shop);
    if (token == null) {
      _goToLogin();
      return;
    }
    try {
      final results = await Future.wait([
        LicenseService.getLicenses(token),
        LicenseService.getMyStores(token).catchError((_) => <dynamic>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _licenses = results[0];
        _storesById = {
          for (final s in results[1]) s['licence_id']?.toString() ?? '': s,
        };
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _licenses ??= [];
        _error = e.toString();
      });
    }
  }

  _LicenseStatus _statusOf(dynamic license) {
    if (license['is_active'] != true) return _LicenseStatus.inactive;
    final expiration = DateTime.tryParse(license['expiration']?.toString() ?? '');
    if (expiration != null && expiration.isBefore(DateTime.now())) return _LicenseStatus.expired;
    return _LicenseStatus.active;
  }

  bool _hasStore(dynamic license) {
    final name = license['store']?['name'];
    return name != null && name.toString().isNotEmpty;
  }

  String _formatDate(String? raw) {
    final date = DateTime.tryParse(raw ?? '');
    return date == null ? 'N/A' : DateFormat('dd/MM/yyyy').format(date);
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => CredentialsPage(
          isFullScreen: widget.isFullScreen,
          onToggleFullScreen: widget.onToggleFullScreen,
        ),
      ),
      (_) => false,
    );
  }

  Future<void> _logout() async {
    await TokenService.deleteToken(TokenType.shop);
    await TokenService.deleteToken(TokenType.user);
    await TokenService.deleteToken(TokenType.license);
    if (mounted) _goToLogin();
  }

  Future<void> _openAccount() async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AccountPage()),
    );
    if (deleted == true && mounted) _goToLogin();
  }

  Future<void> _openLicense(Map<String, dynamic> license) async {
    if (_hasStore(license)) {
      final storeId = license['store']?['store_id']?.toString() ??
          _storesById[license['licence_id']?.toString()]?['store_id']?.toString();
      if (storeId != null) await TokenService.saveToken(TokenType.license, storeId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SessionPage(
            license: license,
            isFullScreen: widget.isFullScreen,
            onToggleFullScreen: widget.onToggleFullScreen,
          ),
        ),
      );
      return;
    }
    if (_statusOf(license) != _LicenseStatus.active) {
      showMessage(context, 'Cette licence n\'est pas active : impossible d\'y associer un commerce', error: true);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShopFormsPage(
          license: license,
          isFullScreen: widget.isFullScreen,
          onToggleFullScreen: widget.onToggleFullScreen,
        ),
      ),
    );
    _loadLicenses();
  }

  Future<void> _refund(Map<String, dynamic> license) async {
    final id = license['licence_id']?.toString() ?? '';
    final confirmed = await confirmDialog(
      context,
      title: 'Rembourser la licence',
      message: 'Rembourser la licence ${_shortId(id)} ?\n\n'
          'Cette action est irréversible. La licence sera désactivée et le paiement remboursé.',
      confirmLabel: 'Rembourser',
    );
    if (!confirmed || !mounted) return;
    final token = await TokenService.getToken(TokenType.shop);
    if (token == null) return;
    try {
      await LicenseService.refund(token, id);
      if (mounted) showMessage(context, 'Licence remboursée');
      _loadLicenses();
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    }
  }

  void _showBuyInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acheter une licence'),
        content: const Text(
          "L'achat de licence se fait depuis le site web Tili, rubrique « Licences ».\n\n"
          'Une fois le paiement validé, la licence apparaîtra ici et vous pourrez y associer votre commerce.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  String _shortId(String id) => id.length > 8 ? '${id.substring(0, 8).toUpperCase()}…' : id.toUpperCase();

  Widget _stat(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(label, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(_LicenseStatus status) {
    final (label, color) = switch (status) {
      _LicenseStatus.active => ('Active', Colors.green),
      _LicenseStatus.expired => ('Expirée', Colors.amber.shade800),
      _LicenseStatus.inactive => ('Inactive', Colors.grey),
    };
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _licenseCard(Map<String, dynamic> license) {
    final status = _statusOf(license);
    final hasStore = _hasStore(license);
    final store = _storesById[license['licence_id']?.toString()];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: hasStore ? Colors.orange.shade50 : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openLicense(license),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(hasStore ? Icons.store : Icons.add_business, size: 36, color: hasStore ? Colors.orange : Colors.red),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            hasStore ? license['store']['name'].toString() : 'ASSOCIER UN COMMERCE',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: hasStore ? null : Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusChip(status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 16,
                      children: [
                        Text('Licence ${_shortId(license['licence_id']?.toString() ?? '')}'),
                        Text('Expire le ${_formatDate(license['expiration']?.toString())}'),
                        if (store != null) ...[
                          Text('SIRET ${store['siret'] ?? 'N/A'}'),
                          Text('TVA ${store['numero_tva'] ?? 'N/A'}'),
                          Text('Créée le ${_formatDate(store['date_creation']?.toString())}'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _refund(license),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Rembourser'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final licenses = _licenses;
    return Scaffold(
      appBar: AppBar(
        title: const Text('VOS LICENCES / COMMERCES'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(tooltip: 'Acheter une licence', onPressed: _showBuyInfo, icon: const Icon(Icons.add_card)),
          IconButton(tooltip: 'Mon compte', onPressed: _openAccount, icon: const Icon(Icons.account_circle)),
          IconButton(tooltip: 'Se déconnecter', onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: licenses == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLicenses,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
                    ),
                  if (licenses.isEmpty) ...[
                    const SizedBox(height: 40),
                    Center(child: Image.asset('assets/tiliLogo.png', height: 150)),
                    const SizedBox(height: 16),
                    const Center(child: Text('Aucune licence trouvée')),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(onPressed: _showBuyInfo, child: const Text('Comment obtenir une licence ?')),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        _stat('Total', licenses.length, Icons.credit_card, Colors.grey),
                        _stat('Actives', licenses.where((l) => _statusOf(l) == _LicenseStatus.active).length,
                            Icons.check_circle, Colors.green),
                        _stat('Associées', licenses.where(_hasStore).length, Icons.store, Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...licenses.map((l) => _licenseCard((l as Map).cast<String, dynamic>())),
                  ],
                ],
              ),
            ),
      floatingActionButton: IconButton(
        onPressed: widget.onToggleFullScreen,
        icon: Icon(widget.isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
      ),
    );
  }
}
