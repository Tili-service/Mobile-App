import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/license_service.dart';
import '../services/token_service.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
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
    await TokenService.clearAll();
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
      builder: (context) => TiliDialog(
        title: 'Acheter une licence',
        icon: Icons.add_card,
        actions: [TiliButton(label: 'Compris', onPressed: () => Navigator.of(context).pop())],
        child: const Text(
          "L'achat de licence se fait depuis le site web Tili, rubrique « Licences ».\n\n"
          'Une fois le paiement validé, la licence apparaîtra ici et vous pourrez y associer votre commerce.',
        ),
      ),
    );
  }

  String _shortId(String id) => id.length > 8 ? '${id.substring(0, 8).toUpperCase()}…' : id.toUpperCase();

  Widget _statusBadge(_LicenseStatus status) {
    final (label, tone) = switch (status) {
      _LicenseStatus.active => ('Active', TiliTone.success),
      _LicenseStatus.expired => ('Expirée', TiliTone.warning),
      _LicenseStatus.inactive => ('Inactive', TiliTone.neutral),
    };
    return StatusBadge(label: label, tone: tone, dot: true);
  }

  Widget _metaRow(IconData icon, String label, String value) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: TiliSpace.sm),
      child: Row(
        children: [
          Icon(icon, size: 14, color: p.border),
          const SizedBox(width: TiliSpace.sm),
          Text(label, style: context.text.bodySmall?.copyWith(color: p.textSubtle)),
          const SizedBox(width: TiliSpace.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(color: p.textMuted, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _licenseCard(Map<String, dynamic> license) {
    final p = context.palette;
    final status = _statusOf(license);
    final hasStore = _hasStore(license);
    final store = _storesById[license['licence_id']?.toString()];
    return TiliCard(
      onTap: () => _openLicense(license),
      highlight: hasStore,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(
                icon: hasStore ? Icons.storefront_outlined : Icons.add_business_outlined,
                tone: hasStore ? TiliTone.accent : TiliTone.neutral,
                size: 44,
              ),
              const Spacer(),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: TiliSpace.lg),
          Text(
            hasStore ? license['store']['name'].toString() : 'Associer un commerce',
            overflow: TextOverflow.ellipsis,
            style: context.text.titleMedium?.copyWith(
              fontFamily: TiliFonts.display,
              fontWeight: FontWeight.w700,
              color: hasStore ? null : p.accentStrong,
            ),
          ),
          const SizedBox(height: TiliSpace.xxs),
          Text(
            hasStore ? 'Touchez pour ouvrir la caisse' : 'Licence disponible — créez votre commerce',
            style: context.text.bodySmall?.copyWith(color: p.textSubtle),
          ),
          const SizedBox(height: TiliSpace.md),
          Divider(color: p.borderSubtle),
          _metaRow(Icons.confirmation_number_outlined, 'Licence', _shortId(license['licence_id']?.toString() ?? '')),
          _metaRow(Icons.event_outlined, 'Expire le', _formatDate(license['expiration']?.toString())),
          if (store != null) ...[
            _metaRow(Icons.badge_outlined, 'SIRET', store['siret']?.toString() ?? 'N/A'),
            _metaRow(Icons.receipt_long_outlined, 'TVA', store['numero_tva']?.toString() ?? 'N/A'),
            _metaRow(Icons.calendar_today_outlined, 'Créé le', _formatDate(store['date_creation']?.toString())),
          ],
          const SizedBox(height: TiliSpace.md),
          Align(
            alignment: Alignment.centerRight,
            child: TiliButton(
              label: 'Rembourser',
              icon: Icons.undo,
              size: TiliButtonSize.sm,
              variant: TiliButtonVariant.dangerGhost,
              onPressed: () => _refund(license),
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(List<dynamic> licenses) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = TiliSpace.gutter;
        final columns = (constraints.maxWidth / 340).floor().clamp(1, 4);
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final l in licenses) SizedBox(width: width, child: _licenseCard((l as Map).cast<String, dynamic>())),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final licenses = _licenses;
    return Scaffold(
      appBar: TiliAppBar(
        title: 'Mes commerces',
        showBack: false,
        leading: const Padding(
          padding: EdgeInsets.only(left: TiliSpace.lg),
          child: Center(child: BrandMark(onDark: false, size: 36, showName: false)),
        ),
        actions: [
          TiliButton(label: 'Acheter une licence', icon: Icons.add, variant: TiliButtonVariant.soft, size: TiliButtonSize.sm, onPressed: _showBuyInfo),
          const SizedBox(width: TiliSpace.sm),
          TiliIconButton(tooltip: 'Mon compte', onPressed: _openAccount, icon: Icons.person_outline),
          TiliIconButton(tooltip: 'Se déconnecter', onPressed: _logout, icon: Icons.logout),
        ],
      ),
      floatingActionButton: FullscreenButton(isFullScreen: widget.isFullScreen, onToggle: widget.onToggleFullScreen),
      body: licenses == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLicenses,
              child: licenses.isEmpty
                  ? ListView(
                      children: [
                        if (_error != null) Padding(padding: const EdgeInsets.all(TiliSpace.page), child: Notice(message: _error!, tone: TiliTone.danger)),
                        SizedBox(
                          height: 420,
                          child: EmptyState(
                            icon: Icons.storefront_outlined,
                            title: 'Aucune licence',
                            message: 'Achetez une licence sur le site web Tili pour créer votre premier commerce.',
                            action: TiliButton(label: 'Comment obtenir une licence ?', variant: TiliButtonVariant.accent, onPressed: _showBuyInfo),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(TiliSpace.page),
                      children: [
                        const PageHeader(title: 'Licences & commerces', subtitle: 'Sélectionnez un commerce pour ouvrir la caisse.'),
                        const SizedBox(height: TiliSpace.xl),
                        if (_error != null) ...[Notice(message: _error!, tone: TiliTone.danger), const SizedBox(height: TiliSpace.lg)],
                        StatRow(
                          children: [
                            StatCard(label: 'Licences', value: licenses.length, icon: Icons.credit_card, tone: TiliTone.brand),
                            StatCard(
                              label: 'Actives',
                              value: licenses.where((l) => _statusOf(l) == _LicenseStatus.active).length,
                              icon: Icons.check_circle_outline,
                              tone: TiliTone.success,
                            ),
                            StatCard(label: 'Commerces', value: licenses.where(_hasStore).length, icon: Icons.storefront_outlined, tone: TiliTone.accent),
                          ],
                        ),
                        const SizedBox(height: TiliSpace.xl),
                        _grid(licenses),
                      ],
                    ),
            ),
    );
  }
}
