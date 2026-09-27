import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/stat_card.dart';

class ProfilesSection extends StatefulWidget {
  const ProfilesSection({
    super.key,
    required this.token,
    required this.storeId,
    required this.currentProfileId,
  });

  final String token;
  final String storeId;
  final String? currentProfileId;

  @override
  State<ProfilesSection> createState() => _ProfilesSectionState();
}

enum _StatusFilter { all, active, inactive }

class _ProfilesSectionState extends State<ProfilesSection> {
  List<dynamic>? _profiles;
  String? _error;
  String _search = '';
  int? _roleFilter;
  _StatusFilter _statusFilter = _StatusFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profiles = await ProfileService.getProfiles(widget.token, widget.storeId);
      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profiles ??= [];
        _error = e.toString();
      });
    }
  }

  List<dynamic> get _filtered {
    final q = _search.trim().toLowerCase();
    final rows = (_profiles ?? []).where((p) {
      if (q.isNotEmpty && !p['name'].toString().toLowerCase().contains(q)) return false;
      if (_roleFilter != null && p['level_access'] != _roleFilter) return false;
      if (_statusFilter == _StatusFilter.active && p['is_active'] != true) return false;
      if (_statusFilter == _StatusFilter.inactive && p['is_active'] == true) return false;
      return true;
    }).toList();
    rows.sort((a, b) => a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase()));
    return rows;
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      if (mounted) showMessage(context, success);
      await _load();
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    }
  }

  Future<void> _create() async {
    final result = await showDialog<_ProfileFormResult>(
      context: context,
      builder: (_) => const _ProfileFormDialog(title: 'Nouveau profil'),
    );
    if (result == null || !mounted) return;
    try {
      final created = await ProfileService.createProfile(widget.token, result.name, result.level);
      await _load();
      if (!mounted) return;
      await showPinOnceDialog(context, title: 'Profil créé', name: result.name, pin: created['pin'].toString());
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    }
  }

  Future<void> _edit(Map<String, dynamic> profile) async {
    final result = await showDialog<_ProfileFormResult>(
      context: context,
      builder: (_) => _ProfileFormDialog(
        title: 'Modifier le profil',
        initialName: profile['name']?.toString() ?? '',
        initialLevel: profile['level_access'] as int? ?? 4,
        initialActive: profile['is_active'] == true,
        showActive: true,
      ),
    );
    if (result == null) return;
    await _run(
      () => ProfileService.updateProfile(
        widget.token,
        profile['profile_id'].toString(),
        widget.storeId,
        name: result.name,
        level: result.level,
        isActive: result.active,
      ),
      'Profil mis à jour',
    );
  }

  Future<void> _resetPin(Map<String, dynamic> profile) async {
    final name = profile['name']?.toString() ?? 'Profil';
    final confirmed = await confirmDialog(
      context,
      title: 'Régénérer le PIN',
      message: "L'ancien PIN de $name ne fonctionnera plus. Continuer ?",
      confirmLabel: 'Régénérer',
      destructive: false,
    );
    if (!confirmed || !mounted) return;
    try {
      final pin = await ProfileService.resetPin(widget.token, profile['profile_id'].toString(), widget.storeId);
      if (!mounted) return;
      await showPinOnceDialog(context, title: 'PIN régénéré', name: name, pin: pin);
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> profile) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Supprimer le profil',
      message: 'Supprimer ${profile['name']} ? Cette action est irréversible.',
    );
    if (!confirmed) return;
    await _run(() => ProfileService.deleteProfile(widget.token, profile['profile_id'].toString()), 'Profil supprimé');
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length >= 2) return (parts.first[0] + parts.last[0]).toUpperCase();
    return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
  }

  Widget _profileTile(Map<String, dynamic> p) {
    final isSelf = p['profile_id']?.toString() == widget.currentProfileId;
    final active = p['is_active'] == true;
    final level = p['level_access'] as int? ?? 4;
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(_initials(p['name']?.toString() ?? ''))),
        title: Text('${p['name']}${isSelf ? ' (vous)' : ''}'),
        subtitle: Wrap(
          spacing: 8,
          children: [
            Text(ProfileService.levelNames[level] ?? 'Inconnu'),
            Text(active ? '● Actif' : '● Inactif', style: TextStyle(color: active ? Colors.green : Colors.grey)),
          ],
        ),
        onTap: () => _edit(p),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(tooltip: 'Modifier', onPressed: () => _edit(p), icon: const Icon(Icons.edit)),
            IconButton(tooltip: 'Régénérer le PIN', onPressed: () => _resetPin(p), icon: const Icon(Icons.pin)),
            IconButton(
              tooltip: isSelf ? 'Impossible de supprimer votre propre profil' : 'Supprimer',
              onPressed: isSelf ? null : () => _delete(p),
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = _profiles;
    if (profiles == null) return const Center(child: CircularProgressIndicator());
    final filtered = _filtered;
    final activeCount = profiles.where((p) => p['is_active'] == true).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Profils (${profiles.length})', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Spacer(),
            FilledButton.icon(onPressed: _create, icon: const Icon(Icons.person_add), label: const Text('Ajouter un profil')),
          ],
        ),
        const SizedBox(height: 8),
        if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
        Row(
          children: [
            StatCard(label: 'Total', value: profiles.length),
            StatCard(label: 'Actifs', value: activeCount, color: Colors.green),
            StatCard(label: 'Inactifs', value: profiles.length - activeCount, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Rechercher un profil…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<int?>(
              value: _roleFilter,
              items: [
                const DropdownMenuItem(value: null, child: Text('Tous les rôles')),
                ...ProfileService.assignableLevels.map(
                  (l) => DropdownMenuItem(value: l, child: Text(ProfileService.levelNames[l]!)),
                ),
              ],
              onChanged: (v) => setState(() => _roleFilter = v),
            ),
            const SizedBox(width: 8),
            DropdownButton<_StatusFilter>(
              value: _statusFilter,
              items: const [
                DropdownMenuItem(value: _StatusFilter.all, child: Text('Tous les statuts')),
                DropdownMenuItem(value: _StatusFilter.active, child: Text('Actif')),
                DropdownMenuItem(value: _StatusFilter.inactive, child: Text('Inactif')),
              ],
              onChanged: (v) => setState(() => _statusFilter = v ?? _StatusFilter.all),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: profiles.isEmpty
              ? const Center(child: Text('Aucun profil. Créez des profils pour chacun de vos employés.'))
              : filtered.isEmpty
                  ? const Center(child: Text('Aucun résultat.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        children: filtered.map((p) => _profileTile((p as Map).cast<String, dynamic>())).toList(),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _ProfileFormResult {
  const _ProfileFormResult(this.name, this.level, this.active);

  final String name;
  final int level;
  final bool active;
}

class _ProfileFormDialog extends StatefulWidget {
  const _ProfileFormDialog({
    required this.title,
    this.initialName = '',
    this.initialLevel = 4,
    this.initialActive = true,
    this.showActive = false,
  });

  final String title;
  final String initialName;
  final int initialLevel;
  final bool initialActive;
  final bool showActive;

  @override
  State<_ProfileFormDialog> createState() => _ProfileFormDialogState();
}

class _ProfileFormDialogState extends State<_ProfileFormDialog> {
  late final TextEditingController _nameController = TextEditingController(text: widget.initialName);
  late int _level = ProfileService.assignableLevels.contains(widget.initialLevel) ? widget.initialLevel : 4;
  late bool _active = widget.initialActive;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(_ProfileFormResult(name, _level, _active));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nom du profil', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text('Rôle'),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: ProfileService.assignableLevels
                  .map((l) => ButtonSegment(value: l, label: Text(ProfileService.levelNames[l]!)))
                  .toList(),
              selected: {_level},
              onSelectionChanged: (s) => setState(() => _level = s.first),
            ),
            if (widget.showActive) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Profil actif'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        FilledButton(onPressed: _submit, child: const Text('Enregistrer')),
      ],
    );
  }
}
