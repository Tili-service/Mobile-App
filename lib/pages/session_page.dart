import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/token_service.dart';
import '../services/profile_service.dart';
import '../widgets/dialogs.dart';
import 'main_page.dart';

/* PIN entry for the selected shop: opens the POS as the matching profile. */
class SessionPage extends StatefulWidget {
  const SessionPage({
    super.key,
    required this.license,
    required this.isFullScreen,
    required this.onToggleFullScreen,
  });

  final Map<String, dynamic> license;
  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  final pinController = TextEditingController();

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  /* Checks the 6-digit PIN against the backend for the selected store, saves
  the returned ProfileToken and opens the POS; clears the field on failure. */
  void _checkPin() async {
    if (pinController.text.length != 6) {
      showMessage(context, 'Le PIN doit contenir 6 chiffres', error: true);
      return;
    }
    final storeId = await TokenService.getToken(TokenType.license);
    if (storeId == null) return;
    final Map<String, dynamic> result;
    try {
      result = await ProfileService.loginWithPin(storeId, pinController.text);
    } catch (_) {
      if (mounted) showMessage(context, 'PIN incorrect', error: true);
      pinController.clear();
      return;
    }
    await TokenService.saveToken(TokenType.user, result['token'].toString());
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainPage(
          isFullScreen: widget.isFullScreen,
          onToggleFullScreen: widget.onToggleFullScreen,
          license: widget.license,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.license['store']?['name'] ?? 'Session'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/tiliLogo.png',
                height: 250,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Entrez le PIN (6 chiffres)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                height: 45,
                child: ElevatedButton(
                  onPressed: _checkPin,
                  child: const Text('Continuer'),
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
