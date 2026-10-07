import 'package:flutter/material.dart';
import '../services/account_service.dart';
import '../services/token_service.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

/* Merchant account settings (AccountToken): edit name/email, change password,
delete the account. Pops with `true` when the account was deleted so the
caller can return to the credentials page. */
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _token;
  bool _loading = true;
  bool _saving = false;
  bool _savingPassword = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _token = await TokenService.getToken(TokenType.shop);
    if (_token == null) return;
    try {
      final account = await AccountService.getAccount(_token!);
      _nameController.text = account['name']?.toString() ?? '';
      _emailController.text = account['email']?.toString() ?? '';
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveInfo() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || !email.contains('@')) {
      showMessage(context, 'Nom et email valides requis', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await AccountService.updateAccount(_token!, name: name, email: email);
      if (mounted) showMessage(context, 'Compte mis à jour');
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text;
    if (newPassword.length < 6) {
      showMessage(context, 'Le nouveau mot de passe doit contenir 6 caractères minimum', error: true);
      return;
    }
    if (newPassword != _confirmPasswordController.text) {
      showMessage(context, 'Les mots de passe ne correspondent pas', error: true);
      return;
    }
    setState(() => _savingPassword = true);
    try {
      await AccountService.changePassword(_token!, _oldPasswordController.text, newPassword);
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      if (mounted) showMessage(context, 'Mot de passe modifié');
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await confirmDialog(
      context,
      title: 'Supprimer mon compte',
      message: 'Cette action est irréversible et supprimera toutes vos données '
          '(boutiques, profils, licences…).',
      confirmLabel: 'Supprimer définitivement',
    );
    if (!confirmed || !mounted) return;
    try {
      await AccountService.deleteAccount(_token!);
      await TokenService.clearAll();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TiliAppBar(breadcrumb: 'Tili', title: 'Mon compte'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: PageBody(
                maxWidth: TiliSizes.contentMaxWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PageHeader(title: 'Paramètres du compte', subtitle: 'Gérez vos informations personnelles et votre sécurité.'),
                    const SizedBox(height: TiliSpace.xl),
                    TiliSection(
                      title: 'Informations',
                      subtitle: 'Nom et adresse email du compte',
                      icon: Icons.person_outline,
                      children: [
                        Row(
                          children: [
                            Expanded(child: TiliField(controller: _nameController, label: 'Nom complet', icon: Icons.person_outline)),
                            const SizedBox(width: TiliSpace.md),
                            Expanded(
                              child: TiliField(
                                controller: _emailController,
                                label: 'Email',
                                icon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: TiliSpace.xl),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TiliButton(label: 'Enregistrer', icon: Icons.check, loading: _saving, onPressed: _saveInfo),
                        ),
                      ],
                    ),
                    const SizedBox(height: TiliSpace.gutter),
                    TiliSection(
                      title: 'Mot de passe',
                      subtitle: '6 caractères minimum',
                      icon: Icons.lock_outline,
                      children: [
                        TiliField(controller: _oldPasswordController, label: 'Mot de passe actuel', password: true),
                        const SizedBox(height: TiliSpace.lg),
                        Row(
                          children: [
                            Expanded(child: TiliField(controller: _newPasswordController, label: 'Nouveau mot de passe', password: true)),
                            const SizedBox(width: TiliSpace.md),
                            Expanded(child: TiliField(controller: _confirmPasswordController, label: 'Confirmation', password: true)),
                          ],
                        ),
                        const SizedBox(height: TiliSpace.xl),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TiliButton(label: 'Changer le mot de passe', loading: _savingPassword, onPressed: _changePassword),
                        ),
                      ],
                    ),
                    const SizedBox(height: TiliSpace.gutter),
                    TiliSection(
                      title: 'Zone de danger',
                      icon: Icons.warning_amber_rounded,
                      tone: TiliTone.danger,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Une fois votre compte supprimé, il n'y a pas de retour en arrière.",
                                style: context.text.bodyMedium?.copyWith(color: context.palette.textMuted),
                              ),
                            ),
                            const SizedBox(width: TiliSpace.lg),
                            TiliButton(
                              label: 'Supprimer mon compte',
                              icon: Icons.delete_outline,
                              variant: TiliButtonVariant.danger,
                              onPressed: _deleteAccount,
                            ),
                          ],
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
