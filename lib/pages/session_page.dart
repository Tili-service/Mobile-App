import 'package:flutter/material.dart';
import '../services/token_service.dart';
import '../services/profile_service.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
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
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  /* Checks the 6-digit PIN against the backend for the selected store, saves
  the returned ProfileToken and opens the POS; clears the field on failure. */
  void _checkPin() async {
    if (_loading) return;
    if (pinController.text.length != 6) {
      setState(() => _error = 'Le PIN doit contenir 6 chiffres');
      return;
    }
    final storeId = await TokenService.getToken(TokenType.license);
    if (storeId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final Map<String, dynamic> result;
    try {
      result = await ProfileService.loginWithPin(storeId, pinController.text);
    } catch (_) {
      if (mounted) setState(() => _error = 'PIN incorrect');
      pinController.clear();
      return;
    } finally {
      if (mounted) setState(() => _loading = false);
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
    final p = context.palette;
    return Scaffold(
      appBar: TiliAppBar(breadcrumb: 'Mes commerces', title: widget.license['store']?['name'] ?? 'Session'),
      floatingActionButton: FullscreenButton(isFullScreen: widget.isFullScreen, onToggle: widget.onToggleFullScreen),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TiliSpace.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: TiliCard(
              shadow: true,
              padding: const EdgeInsets.all(TiliSpace.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: IconTile(icon: Icons.lock_outline, size: 64, circle: true)),
                  const SizedBox(height: TiliSpace.xl),
                  Text('Accès caisse', textAlign: TextAlign.center, style: context.text.headlineSmall),
                  const SizedBox(height: TiliSpace.sm),
                  Text(
                    'Entrez votre code PIN à 6 chiffres pour ouvrir votre session.',
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium?.copyWith(color: p.textMuted),
                  ),
                  const SizedBox(height: TiliSpace.xxl),
                  PinField(controller: pinController, onSubmitted: (_) => _checkPin()),
                  if (_error != null) ...[
                    const SizedBox(height: TiliSpace.lg),
                    Notice(message: _error!, tone: TiliTone.danger),
                  ],
                  const SizedBox(height: TiliSpace.xl),
                  TiliButton(label: 'Continuer', size: TiliButtonSize.lg, expand: true, loading: _loading, onPressed: _checkPin),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
