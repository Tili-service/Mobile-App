import 'package:flutter/material.dart';
import '../services/token_service.dart';
import '../services/store_service.dart';
import '../widgets/dialogs.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom, SIRET et numéro de TVA sont requis')),
      );
      return;
    }
    final token = await TokenService.getToken(TokenType.shop);
    if (token == null) return;
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
      appBar: AppBar(
        title: const Text('NOUVEAU COMMERCE'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/tiliLogo.png',
                height: 150,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: 500,
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'NOM DU COMMERCE',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 500,
                child: TextField(
                  controller: siretController,
                  decoration: const InputDecoration(
                    labelText: 'NUMÉROS SIRET (ex: 12345678901234)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 500,
                child: TextField(
                  controller: tvaController,
                  decoration: const InputDecoration(
                    labelText: 'NUMÉROS TVA (ex: FR12345678901)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 250,
                height: 45,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('CONFIRMER'),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: IconButton(
        onPressed: widget.onToggleFullScreen,
        icon: Icon(
          widget.isFullScreen
              ? Icons.fullscreen_exit
              : Icons.fullscreen,
        ),
      ),
    );
  }
}
