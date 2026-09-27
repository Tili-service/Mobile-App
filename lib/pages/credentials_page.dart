import 'package:flutter/material.dart';
import '../services/account_service.dart';
import '../widgets/dialogs.dart';
import '../services/token_service.dart';
import 'licenses_page.dart';
import 'register_page.dart';

/* Merchant login (email + password). Entry screen of the app. */
class CredentialsPage extends StatefulWidget {
  const CredentialsPage({
    super.key,
    required this.isFullScreen,
    required this.onToggleFullScreen,
  });

  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;

  @override
  State<CredentialsPage> createState() => _CredentialsPageState();
}

class _CredentialsPageState extends State<CredentialsPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  /* Logs the merchant in with email + password, stores the AccountToken and
  opens the licences page; on failure shows the backend's error message. */
  Future<void> _continuer() async {
    final String token;
    try {
      token = await AccountService.login(emailController.text.trim(), passwordController.text);
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
      return;
    }
    await TokenService.saveToken(TokenType.shop, token);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LicensesPage(
          isFullScreen: widget.isFullScreen,
          onToggleFullScreen: widget.onToggleFullScreen,
        ),
      ),
    );
  }

  Future<void> _openRegister() async {
    final email = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
    if (email != null) {
      emailController.text = email;
      passwordController.clear();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              _buildInput(emailController, "EMAIL"),
              const SizedBox(height: 12),
              _buildInput(passwordController, "MOT DE PASSE", obscure: true),
              const SizedBox(height: 25),
              SizedBox(
                width: 200,
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: _continuer,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("CONTINUER"),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _openRegister,
                child: const Text("Pas encore de compte ? Créer un compte"),
              ),
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Réinitialisation du mot de passe bientôt disponible")),
                ),
                child: const Text("Mot de passe oublié ?"),
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

  /* The _buildInput method is a helper function that creates a styled input field for the
  email, password, or PIN. It takes a TextEditingController, a hint text, and an optional
  obscure parameter to determine if the input should be obscured (for passwords). The method
  returns a SizedBox containing a TextField with the specified controller, hint text, and styling.
  The TextField is centered and has an outlined border with rounded corners. */
  Widget _buildInput(TextEditingController controller, String hint, {bool obscure = false}) {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
