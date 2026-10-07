import 'package:flutter/material.dart';
import '../services/account_service.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
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
  bool _loading = false;

  /* Logs the merchant in with email + password, stores the AccountToken and
  opens the licences page; on failure shows the backend's error message. */
  Future<void> _continuer() async {
    if (_loading) return;
    setState(() => _loading = true);
    final String token;
    try {
      token = await AccountService.login(emailController.text.trim(), passwordController.text);
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
      return;
    } finally {
      if (mounted) setState(() => _loading = false);
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
    final p = context.palette;
    return AuthLayout(
      title: 'Connexion',
      subtitle: 'Entrez vos identifiants pour accéder à vos commerces.',
      topAction: TiliIconButton(
        icon: widget.isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
        tooltip: widget.isFullScreen ? 'Quitter le plein écran' : 'Plein écran',
        bordered: true,
        size: TiliSizes.buttonMd,
        onPressed: widget.onToggleFullScreen,
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: TiliSpace.md),
                child: Text('Pas encore de compte ?', style: context.text.bodySmall?.copyWith(color: p.textSubtle)),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: TiliSpace.lg),
          TiliButton(
            label: 'Créer un compte',
            icon: Icons.person_add_alt,
            variant: TiliButtonVariant.outline,
            size: TiliButtonSize.lg,
            expand: true,
            onPressed: _openRegister,
          ),
        ],
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TiliField(
              controller: emailController,
              label: 'Email',
              hint: 'vous@exemple.com',
              icon: Icons.mail_outline,
              large: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: TiliSpace.xl),
            TiliField(
              controller: passwordController,
              label: 'Mot de passe',
              hint: '••••••••',
              icon: Icons.lock_outline,
              large: true,
              password: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _continuer(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => showMessage(context, 'Réinitialisation du mot de passe bientôt disponible'),
                style: TextButton.styleFrom(minimumSize: const Size(0, TiliSizes.buttonMd)),
                child: const Text('Mot de passe oublié ?'),
              ),
            ),
            const SizedBox(height: TiliSpace.md),
            TiliButton(
              label: 'Se connecter',
              trailingIcon: Icons.arrow_forward,
              size: TiliButtonSize.lg,
              expand: true,
              loading: _loading,
              onPressed: _continuer,
            ),
          ],
        ),
      ),
    );
  }
}
