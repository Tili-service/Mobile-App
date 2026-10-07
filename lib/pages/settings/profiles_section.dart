import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

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

  Widget _profileCard(Map<String, dynamic> p) {
    final palette = context.palette;
    final isSelf = p['profile_id']?.toString() == widget.currentProfileId;
    final active = p['is_active'] == true;
    final level = p['level_access'] as int? ?? 4;
    final name = p['name']?.toString() ?? '';
    return TiliCard(
      onTap: () => _edit(p),
      padding: const EdgeInsets.all(TiliSpace.lg + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Avatar(name: name, size: 44, tone: active ? TiliTone.accent : TiliTone.neutral),
              const SizedBox(width: TiliSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name${isSelf ? ' (vous)' : ''}',
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                    const SizedBox(height: TiliSpace.xxs),
                    Text(ProfileService.levelNames[level] ?? 'Inconnu', style: context.text.bodySmall?.copyWith(color: palette.textSubtle)),
                  ],
                ),
              ),
              StatusBadge(label: active ? 'Actif' : 'Inactif', tone: active ? TiliTone.success : TiliTone.neutral, dot: true),
            ],
          ),
          const SizedBox(height: TiliSpace.md),
          Divider(color: palette.borderSubtle),
          const SizedBox(height: TiliSpace.xs),
          Row(
            children: [
              TiliButton(label: 'Modifier', icon: Icons.edit_outlined, size: TiliButtonSize.sm, variant: TiliButtonVariant.ghost, onPressed: () => _edit(p)),
              TiliButton(label: 'PIN', icon: Icons.pin_outlined, size: TiliButtonSize.sm, variant: TiliButtonVariant.ghost, onPressed: () => _resetPin(p)),
              const Spacer(),
              TiliIconButton(
                tooltip: isSelf ? 'Impossible de supprimer votre propre profil' : 'Supprimer',
                onPressed: isSelf ? null : () => _delete(p),
                icon: Icons.delete_outline,
                tone: TiliTone.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profiles = _profiles;
    if (profiles == null) return const Center(child: CircularProgressIndicator());
    final filtered = _filtered;
    final activeCount = profiles.where((p) => p['is_active'] == true).length;

    Widget body;
    if (profiles.isEmpty) {
      body = EmptyState(
        icon: Icons.people_outline,
        title: 'Aucun profil',
        message: 'Créez des profils pour chacun de vos employés.',
        action: TiliButton(label: 'Ajouter un profil', icon: Icons.person_add_alt, variant: TiliButtonVariant.accent, onPressed: _create),
      );
    } else if (filtered.isEmpty) {
      body = const EmptyState(icon: Icons.search_off, title: 'Aucun résultat', tone: TiliTone.neutral);
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, c) {
            const gap = TiliSpace.gutter;
            final cols = (c.maxWidth / 320).floor().clamp(1, 4);
            final w = (c.maxWidth - gap * (cols - 1)) / cols;
            return ListView(
              children: [
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final p in filtered) SizedBox(width: w, child: _profileCard((p as Map).cast<String, dynamic>())),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Profils',
          subtitle: '${profiles.length} profil${profiles.length > 1 ? 's' : ''} dans ce commerce',
          actions: [TiliButton(label: 'Ajouter un profil', icon: Icons.person_add_alt, onPressed: _create)],
        ),
        const SizedBox(height: TiliSpace.xl),
        if (_error != null) ...[Notice(message: _error!, tone: TiliTone.danger), const SizedBox(height: TiliSpace.md)],
        StatRow(
          children: [
            StatCard(label: 'Total', value: profiles.length, icon: Icons.people_outline, tone: TiliTone.brand),
            StatCard(label: 'Actifs', value: activeCount, icon: Icons.check_circle_outline, tone: TiliTone.success),
            StatCard(label: 'Inactifs', value: profiles.length - activeCount, icon: Icons.pause_circle_outline),
          ],
        ),
        const SizedBox(height: TiliSpace.lg),
        Row(
          children: [
            Expanded(child: SearchField(hint: 'Rechercher un profil…', onChanged: (v) => setState(() => _search = v))),
            const SizedBox(width: TiliSpace.sm),
            TiliSelect<int?>(
              value: _roleFilter,
              icon: Icons.shield_outlined,
              items: [
                (null, 'Tous les rôles'),
                for (final l in ProfileService.assignableLevels) (l, ProfileService.levelNames[l]!),
              ],
              onChanged: (v) => setState(() => _roleFilter = v),
            ),
            const SizedBox(width: TiliSpace.sm),
            TiliSelect<_StatusFilter>(
              value: _statusFilter,
              items: const [
                (_StatusFilter.all, 'Tous les statuts'),
                (_StatusFilter.active, 'Actif'),
                (_StatusFilter.inactive, 'Inactif'),
              ],
              onChanged: (v) => setState(() => _statusFilter = v ?? _StatusFilter.all),
            ),
          ],
        ),
        const SizedBox(height: TiliSpace.lg),
        Expanded(child: body),
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
    return TiliDialog(
      title: widget.title,
      icon: Icons.person_outline,
      actions: [
        TiliButton(label: 'Annuler', variant: TiliButtonVariant.outline, onPressed: () => Navigator.of(context).pop()),
        TiliButton(label: 'Enregistrer', onPressed: _submit),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TiliField(controller: _nameController, label: 'Nom du profil', autofocus: true, onSubmitted: (_) => _submit()),
          const SizedBox(height: TiliSpace.lg),
          const SectionLabel('Rôle'),
          const SizedBox(height: TiliSpace.sm),
          SegmentedButton<int>(
            segments: ProfileService.assignableLevels
                .map((l) => ButtonSegment(value: l, label: Text(ProfileService.levelNames[l]!)))
                .toList(),
            selected: {_level},
            onSelectionChanged: (s) => setState(() => _level = s.first),
          ),
          if (widget.showActive) ...[
            const SizedBox(height: TiliSpace.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Profil actif', style: context.text.titleSmall),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
          ],
        ],
      ),
    );
  }
}
