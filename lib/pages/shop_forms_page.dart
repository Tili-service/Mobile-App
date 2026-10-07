import 'package:flutter/material.dart';
import '../services/token_service.dart';
import '../services/store_service.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import 'session_page.dart';

/* Creates the shop linked to an active licence, then opens its PIN screen. */
class ShopFormsPage extends StatefulWidget {
  const ShopFormsPage({
    super.key,
    required this.license,
    required this.isFullScreen,
    required this.onToggleFullScreen,
  });

  final Map<String, dynamic> license;
  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;

  @override
  State<ShopFormsPage> createState() => _ShopFormsPageState();
}

class _ShopFormsPageState extends State<ShopFormsPage> {
  final nameController = TextEditingController();
  final siretController = TextEditingController();
  final tvaController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    nameController.dispose();
    siretController.dispose();
    tvaController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (nameController.text.trim().isEmpty ||
        siretController.text.trim().isEmpty ||
        tvaController.text.trim().isEmpty) {
      showMessage(context, 'Nom, SIRET et numéro de TVA sont requis', error: true);
      return;
    }
    final token = await TokenService.getToken(TokenType.shop);
    if (token == null) return;
    setState(() => _loading = true);
    final Map<String, dynamic> store;
    try {
      store = await StoreService.createStore(
        token,
        widget.license['licence_id'],
        nameController.text.trim(),
        tvaController.text.trim(),
        siretController.text.trim(),
      );
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
      return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    final storeId = store['store_id']?.toString();
    if (storeId != null) {
      await TokenService.saveToken(TokenType.license, storeId);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SessionPage(
          license: {...widget.license, 'store': store},
          isFullScreen: widget.isFullScreen,
          onToggleFullScreen: widget.onToggleFullScreen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TiliAppBar(breadcrumb: 'Mes commerces', title: 'Nouveau commerce'),
      floatingActionButton: FullscreenButton(isFullScreen: widget.isFullScreen, onToggle: widget.onToggleFullScreen),
      body: SingleChildScrollView(
        child: PageBody(
          maxWidth: TiliSizes.contentMaxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                title: 'Associer un commerce',
                subtitle: 'Renseignez les informations légales de votre établissement.',
              ),
              const SizedBox(height: TiliSpace.xl),
              TiliSection(
                title: 'Informations du commerce',
                icon: Icons.storefront_outlined,
                children: [
                  TiliField(controller: nameController, label: 'Nom du commerce', hint: 'Ma boutique', icon: Icons.store_outlined),
                  const SizedBox(height: TiliSpace.lg),
                  Row(
                    children: [
                      Expanded(
                        child: TiliField(
                          controller: siretController,
                          label: 'Numéro SIRET',
                          hint: '12345678901234',
                          icon: Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: TiliSpace.md),
                      Expanded(
                        child: TiliField(
                          controller: tvaController,
                          label: 'Numéro de TVA',
                          hint: 'FR12345678901',
                          icon: Icons.receipt_long_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TiliSpace.xl),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TiliButton(label: 'Créer le commerce', icon: Icons.check, loading: _loading, onPressed: _submit),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
