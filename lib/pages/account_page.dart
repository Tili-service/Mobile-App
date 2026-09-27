import 'package:flutter/material.dart';
import '../services/account_service.dart';
import '../services/token_service.dart';
import '../widgets/dialogs.dart';

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
      await TokenService.deleteToken(TokenType.shop);
      await TokenService.deleteToken(TokenType.user);
      await TokenService.deleteToken(TokenType.license);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    }
  }

  Widget _section(String title, List<Widget> children, {Color? color}) {
    return Card(
      color: color,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MON COMPTE')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 560,
                  child: Column(
                    children: [
                      _section('Informations', [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Nom complet', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _saving ? null : _saveInfo,
                          child: const Text('Enregistrer les modifications'),
                        ),
                      ]),
                      _section('Mot de passe', [
                        TextField(
                          controller: _oldPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Mot de passe actuel', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _newPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Nouveau mot de passe', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Confirmer le nouveau mot de passe', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _savingPassword ? null : _changePassword,
                          child: const Text('Changer le mot de passe'),
                        ),
                      ]),
                      _section(
                        'Zone de danger',
                        [
                          const Text("Une fois votre compte supprimé, il n'y a pas de retour en arrière."),
                          const SizedBox(height: 16),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                            onPressed: _deleteAccount,
                            child: const Text('Supprimer mon compte définitivement'),
                          ),
                        ],
                        color: Colors.red.shade50,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
