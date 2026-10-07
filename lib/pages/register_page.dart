import 'package:flutter/material.dart';
import '../services/account_service.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

/* Account creation. On success, pops back to the credentials page with the
email so the merchant only has to type the password again. */
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _acceptedTerms = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      showMessage(context, "Vous devez accepter les conditions d'utilisation", error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await AccountService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      showMessage(context, 'Compte créé. Connectez-vous.');
      Navigator.of(context).pop(_emailController.text.trim());
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AuthLayout(
      title: 'Créer un compte',
      subtitle: 'Quelques secondes suffisent pour démarrer avec Tili.',
      onBack: () => Navigator.of(context).maybePop(),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Déjà un compte ?', style: context.text.bodyMedium?.copyWith(color: p.textMuted)),
          TextButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Se connecter')),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TiliField(
              controller: _nameController,
              label: 'Nom complet',
              hint: 'Jean Dupont',
              icon: Icons.person_outline,
              large: true,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est requis' : null,
            ),
            const SizedBox(height: TiliSpace.lg),
            TiliField(
              controller: _emailController,
              label: 'Email',
              hint: 'vous@exemple.com',
              icon: Icons.mail_outline,
              large: true,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
            ),
            const SizedBox(height: TiliSpace.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TiliField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    large: true,
                    password: true,
                    validator: (v) => (v == null || v.length < 6) ? '6 caractères minimum' : null,
                  ),
                ),
                const SizedBox(width: TiliSpace.md),
                Expanded(
                  child: TiliField(
                    controller: _confirmController,
                    label: 'Confirmation',
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    large: true,
                    password: true,
                    validator: (v) => v != _passwordController.text ? 'Ne correspond pas' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TiliSpace.md),
            CheckboxListTile(
              value: _acceptedTerms,
              onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text("J'accepte les conditions d'utilisation", style: context.text.bodyMedium?.copyWith(color: p.textMuted)),
            ),
            const SizedBox(height: TiliSpace.lg),
            TiliButton(
              label: 'Créer mon compte',
              trailingIcon: Icons.arrow_forward,
              size: TiliButtonSize.lg,
              expand: true,
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
