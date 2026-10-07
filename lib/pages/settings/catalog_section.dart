import 'package:flutter/material.dart';
import '../../services/active_catalog_service.dart';
import '../../services/catalog_service.dart';
import '../../utils/pricing.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class CatalogSection extends StatefulWidget {
  const CatalogSection({
    super.key,
    required this.token,
    required this.storeId,
    this.initialCatalogId,
  });

  final String token;
  final String storeId;
  final String? initialCatalogId;

  @override
  State<CatalogSection> createState() => _CatalogSectionState();
}

enum _SortKey { name, price, category }

class _CatalogSectionState extends State<CatalogSection> {
  List<dynamic>? _catalogs;
  String? _catalogId;
  String? _activeCatalogId;
  List<dynamic> _categories = [];
  List<dynamic> _items = [];
  String? _error;
  bool _loadingContent = false;

  int _tab = 0;
  String? _drillCategoryId;
  String _categorySearch = '';
  String _itemSearch = '';
  String? _itemCategoryFilter;
  _SortKey _sortKey = _SortKey.name;
  bool _sortAsc = true;

  String get _token => widget.token;

  @override
  void initState() {
    super.initState();
    _catalogId = widget.initialCatalogId;
    _loadCatalogs();
  }

  Future<void> _loadCatalogs() async {
    try {
      final catalogs = await CatalogService.getCatalogs(_token, widget.storeId);
      final storedActive = await ActiveCatalogService.get(widget.storeId);
      if (!mounted) return;
      final ids = catalogs.map((c) => c['catalog_id'].toString()).toList();
      setState(() {
        _catalogs = catalogs;
        _activeCatalogId = ids.contains(storedActive) ? storedActive : (ids.isEmpty ? null : ids.first);
        _catalogId = ids.contains(_catalogId) ? _catalogId : _activeCatalogId;
        _error = null;
      });
      await _loadContent();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _catalogs ??= [];
        _error = e.toString();
      });
    }
  }

  Future<void> _loadContent() async {
    final catalogId = _catalogId;
    if (catalogId == null) {
      setState(() {
        _categories = [];
        _items = [];
      });
      return;
    }
    setState(() => _loadingContent = true);
    try {
      final categories = await CatalogService.getCategories(_token, catalogId);
      final items = await CatalogService.getCatalogItems(_token, categories);
      if (!mounted || catalogId != _catalogId) return;
      setState(() {
        _categories = categories;
        _items = items;
        _error = null;
        if (_drillCategoryId != null && !categories.any((c) => c['categorie_id'].toString() == _drillCategoryId)) {
          _drillCategoryId = null;
        }
        if (_itemCategoryFilter != null && !categories.any((c) => c['categorie_id'].toString() == _itemCategoryFilter)) {
          _itemCategoryFilter = null;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingContent = false);
    }
  }

  Future<void> _run(Future<void> Function() action, String success, {bool reloadCatalogs = false}) async {
    try {
      await action();
      if (mounted) showMessage(context, success);
      reloadCatalogs ? await _loadCatalogs() : await _loadContent();
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    }
  }

  // ---- Catalogues ---------------------------------------------------------

  Map<String, dynamic>? get _currentCatalog =>
      _catalogs?.cast<Map<String, dynamic>?>().firstWhere((c) => c?['catalog_id'].toString() == _catalogId, orElse: () => null);

  Future<void> _createCatalog({String initialName = ''}) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _CatalogFormDialog(title: 'Nouveau catalogue', initialName: initialName, confirmLabel: 'Créer'),
    );
    if (result == null) return;
    await _run(() async {
      final created = await CatalogService.createCatalog(_token, widget.storeId, result.$1, result.$2);
      _catalogId = created['catalog_id']?.toString();
    }, 'Catalogue créé', reloadCatalogs: true);
  }

  Future<void> _setActiveCatalog() async {
    final id = _catalogId;
    if (id == null) return;
    await ActiveCatalogService.set(widget.storeId, id);
    if (!mounted) return;
    setState(() => _activeCatalogId = id);
    showMessage(context, '${_currentCatalog?['name'] ?? 'Catalogue'} est maintenant le catalogue actif en caisse');
  }

  Future<void> _editCatalog() async {
    final current = _currentCatalog;
    if (current == null) return;
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _CatalogFormDialog(
        title: 'Modifier le catalogue',
        initialName: current['name']?.toString() ?? '',
        initialDescription: current['description']?.toString() ?? '',
      ),
    );
    if (result == null) return;
    await _run(
      () => CatalogService.updateCatalog(_token, widget.storeId, _catalogId!, result.$1, result.$2),
      'Catalogue modifié',
      reloadCatalogs: true,
    );
  }

  Future<void> _deleteCatalog() async {
    final current = _currentCatalog;
    if (current == null) return;
    final confirmed = await confirmDialog(context,
        title: 'Supprimer le catalogue',
        message: 'Supprimer ${current['name']} ? Ses catégories et articles seront perdus.');
    if (!confirmed) return;
    await _run(() async {
      await CatalogService.deleteCatalog(_token, widget.storeId, _catalogId!);
      _catalogId = null;
    }, 'Catalogue supprimé', reloadCatalogs: true);
  }

  // ---- Categories ---------------------------------------------------------

  int _itemCount(String categoryId) => _items.where((i) => i['categorie_id'].toString() == categoryId).length;

  String _categoryName(String? id) =>
      _categories.firstWhere((c) => c['categorie_id'].toString() == id, orElse: () => {'type': '—'})['type'].toString();

  Future<void> _createCategory() async {
    final name = await textInputDialog(context,
        title: 'Nouvelle catégorie', label: 'Nom de la catégorie (ex : Boissons)', confirmLabel: 'Créer');
    if (name == null) return;
    await _run(() => CatalogService.createCategory(_token, _catalogId!, name), 'Catégorie créée');
  }

  Future<void> _renameCategory(dynamic category) async {
    final name = await textInputDialog(context,
        title: 'Modifier la catégorie', label: 'Nom de la catégorie', initialValue: category['type'].toString());
    if (name == null) return;
    await _run(() => CatalogService.renameCategory(_token, _catalogId!, category['categorie_id'].toString(), name),
        'Catégorie mise à jour');
  }

  Future<void> _deleteCategory(dynamic category) async {
    final count = _itemCount(category['categorie_id'].toString());
    final confirmed = await confirmDialog(context,
        title: 'Supprimer la catégorie',
        message: count == 0
            ? 'Supprimer ${category['type']} ?'
            : 'Supprimer ${category['type']} ?\n\n'
                '⚠️ Les $count article${count > 1 ? 's' : ''} de cette catégorie seront aussi supprimé${count > 1 ? 's' : ''}. '
                'Cette action est irréversible.');
    if (!confirmed) return;
    await _run(() => CatalogService.deleteCategory(_token, _catalogId!, category['categorie_id'].toString()),
        'Catégorie supprimée');
  }

  // ---- Items --------------------------------------------------------------

  Future<void> _createItem({String? categoryId}) async {
    if (_categories.isEmpty) {
      showMessage(context, "Créez d'abord une catégorie", error: true);
      return;
    }
    final result = await showDialog<_ItemFormResult>(
      context: context,
      builder: (_) => _ItemFormDialog(title: 'Nouvel article', categories: _categories, initialCategoryId: categoryId),
    );
    if (result == null) return;
    await _run(
      () => CatalogService.createItem(_token,
          name: result.name, priceTTC: result.priceTTC, taxRate: result.taxRate, categoryId: result.categoryId),
      'Article créé',
    );
  }

  Future<void> _editItem(dynamic item) async {
    final result = await showDialog<_ItemFormResult>(
      context: context,
      builder: (_) => _ItemFormDialog(title: "Modifier l'article", categories: _categories, item: item),
    );
    if (result == null) return;
    await _run(
      () => CatalogService.updateItem(_token, item['item_id'].toString(),
          name: result.name, priceTTC: result.priceTTC, taxRate: result.taxRate, categoryId: result.categoryId),
      'Article mis à jour',
    );
  }

  Future<void> _moveItem(dynamic item) async {
    final current = item['categorie_id'].toString();
    final target = await showDialog<String>(
      context: context,
      builder: (context) => TiliDialog(
        title: 'Déplacer ${item['name']}',
        subtitle: 'Choisissez la catégorie de destination',
        icon: Icons.drive_file_move_outline,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in _categories)
              Padding(
                padding: const EdgeInsets.only(bottom: TiliSpace.sm),
                child: TiliCard(
                  padding: const EdgeInsets.symmetric(horizontal: TiliSpace.lg, vertical: TiliSpace.md),
                  color: c['categorie_id'].toString() == current ? context.palette.surfaceMuted : null,
                  onTap: c['categorie_id'].toString() == current
                      ? null
                      : () => Navigator.of(context).pop(c['categorie_id'].toString()),
                  child: Row(
                    children: [
                      Icon(Icons.label_outline, size: TiliSizes.icon, color: context.palette.textSubtle),
                      const SizedBox(width: TiliSpace.md),
                      Expanded(child: Text(c['type'].toString(), style: context.text.titleSmall)),
                      if (c['categorie_id'].toString() == current) const StatusBadge(label: 'Actuelle'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (target == null) return;
    await _run(() => CatalogService.moveItem(_token, item['item_id'].toString(), target), 'Article déplacé');
  }

  Future<void> _deleteItem(dynamic item) async {
    final confirmed = await confirmDialog(context, title: "Supprimer l'article", message: 'Supprimer ${item['name']} ?');
    if (!confirmed) return;
    await _run(() => CatalogService.deleteItem(_token, item['item_id'].toString()), 'Article supprimé');
  }

  List<dynamic> _sortedItems(List<dynamic> items) {
    final q = _itemSearch.trim().toLowerCase();
    final rows = items.where((i) {
      if (q.isNotEmpty && !i['name'].toString().toLowerCase().contains(q)) return false;
      if (_itemCategoryFilter != null && i['categorie_id'].toString() != _itemCategoryFilter) return false;
      return true;
    }).toList();
    rows.sort((a, b) {
      final cmp = switch (_sortKey) {
        _SortKey.name => a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase()),
        _SortKey.price => itemPriceTTC(a).compareTo(itemPriceTTC(b)),
        _SortKey.category => _categoryName(a['categorie_id'].toString())
            .toLowerCase()
            .compareTo(_categoryName(b['categorie_id'].toString()).toLowerCase()),
      };
      return _sortAsc ? cmp : -cmp;
    });
    return rows;
  }

  // ---- UI -----------------------------------------------------------------

  Widget _catalogBar() {
    final p = context.palette;
    return TiliCard(
      padding: const EdgeInsets.symmetric(horizontal: TiliSpace.md, vertical: TiliSpace.sm + 2),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: TiliSizes.buttonMd,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final c in _catalogs!)
                    Padding(
                      padding: const EdgeInsets.only(right: TiliSpace.sm),
                      child: FilterPill(
                        label: c['name']?.toString() ?? 'Catalogue',
                        icon: c['catalog_id'].toString() == _activeCatalogId ? Icons.star_rounded : Icons.folder_outlined,
                        selected: c['catalog_id'].toString() == _catalogId,
                        onTap: () {
                          setState(() {
                            _catalogId = c['catalog_id'].toString();
                            _drillCategoryId = null;
                            _itemCategoryFilter = null;
                          });
                          _loadContent();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: TiliSpace.sm),
          if (_catalogId == _activeCatalogId)
            const StatusBadge(label: 'Actif en caisse', tone: TiliTone.accent, icon: Icons.star_rounded)
          else
            TiliButton(
              label: 'Définir comme actif',
              icon: Icons.star_border_rounded,
              size: TiliButtonSize.sm,
              variant: TiliButtonVariant.soft,
              onPressed: _setActiveCatalog,
            ),
          const SizedBox(width: TiliSpace.sm),
          Container(width: 1, height: 24, color: p.borderSubtle),
          const SizedBox(width: TiliSpace.xs),
          TiliIconButton(tooltip: 'Nouveau catalogue', onPressed: _createCatalog, icon: Icons.create_new_folder_outlined),
          TiliIconButton(tooltip: 'Modifier', onPressed: _editCatalog, icon: Icons.edit_outlined),
          TiliIconButton(tooltip: 'Supprimer', onPressed: _deleteCatalog, icon: Icons.delete_outline, tone: TiliTone.danger),
        ],
      ),
    );
  }

  Widget _emptyCatalogPrompt() {
    return EmptyState(
      icon: Icons.create_new_folder_outlined,
      title: 'Aucun catalogue',
      message: 'Créez-en un pour ajouter vos catégories et articles.',
      action: TiliButton(
        label: 'Créer le catalogue',
        icon: Icons.add,
        variant: TiliButtonVariant.accent,
        onPressed: () => _createCatalog(initialName: 'Catalogue principal'),
      ),
    );
  }

  Widget _categoryCard(dynamic c) {
    final id = c['categorie_id'].toString();
    final count = _itemCount(id);
    return TiliCard(
      onTap: () => setState(() => _drillCategoryId = id),
      padding: const EdgeInsets.fromLTRB(TiliSpace.lg, TiliSpace.lg, TiliSpace.sm, TiliSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const IconTile(icon: Icons.sell_outlined, tone: TiliTone.accent),
              const SizedBox(width: TiliSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['type'].toString(), overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                    Text('$count article${count != 1 ? 's' : ''}', style: context.text.bodySmall?.copyWith(color: context.palette.textSubtle)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.palette.border),
              const SizedBox(width: TiliSpace.sm),
            ],
          ),
          const SizedBox(height: TiliSpace.sm),
          Row(
            children: [
              TiliButton(label: 'Modifier', icon: Icons.edit_outlined, size: TiliButtonSize.sm, variant: TiliButtonVariant.ghost, onPressed: () => _renameCategory(c)),
              const Spacer(),
              TiliButton(label: 'Supprimer', icon: Icons.delete_outline, size: TiliButtonSize.sm, variant: TiliButtonVariant.dangerGhost, onPressed: () => _deleteCategory(c)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoriesTab() {
    if (_drillCategoryId != null) return _drillDown();
    final q = _categorySearch.trim().toLowerCase();
    final filtered = _categories.where((c) => q.isEmpty || c['type'].toString().toLowerCase().contains(q)).toList();
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: SearchField(hint: 'Rechercher une catégorie…', onChanged: (v) => setState(() => _categorySearch = v))),
            const SizedBox(width: TiliSpace.sm),
            TiliButton(label: 'Nouvelle catégorie', icon: Icons.add, onPressed: _createCategory),
          ],
        ),
        const SizedBox(height: TiliSpace.lg),
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  icon: _categories.isEmpty ? Icons.sell_outlined : Icons.search_off,
                  title: _categories.isEmpty ? 'Aucune catégorie' : 'Aucun résultat',
                  message: _categories.isEmpty ? 'Créez une catégorie (ex : Boissons) pour y ranger vos articles.' : null,
                  tone: _categories.isEmpty ? TiliTone.accent : TiliTone.neutral,
                )
              : LayoutBuilder(
                  builder: (context, c) {
                    const gap = TiliSpace.md;
                    final cols = (c.maxWidth / 300).floor().clamp(1, 4);
                    final w = (c.maxWidth - gap * (cols - 1)) / cols;
                    return ListView(
                      children: [
                        Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [for (final cat in filtered) SizedBox(width: w, child: _categoryCard(cat))],
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _drillDown() {
    final id = _drillCategoryId!;
    final items = _items.where((i) => i['categorie_id'].toString() == id).toList()
      ..sort((a, b) => a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase()));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            TiliIconButton(icon: Icons.arrow_back, tooltip: 'Retour', bordered: true, onPressed: () => setState(() => _drillCategoryId = null)),
            const SizedBox(width: TiliSpace.md),
            Text(_categoryName(id), style: context.text.titleLarge),
            const SizedBox(width: TiliSpace.sm),
            StatusBadge(label: '${items.length} article${items.length != 1 ? 's' : ''}'),
            const Spacer(),
            TiliButton(label: 'Ajouter un article', icon: Icons.add, onPressed: () => _createItem(categoryId: id)),
          ],
        ),
        const SizedBox(height: TiliSpace.lg),
        Expanded(
          child: items.isEmpty
              ? const EmptyState(icon: Icons.inventory_2_outlined, title: 'Aucun article dans cette catégorie', tone: TiliTone.neutral)
              : _itemList(items),
        ),
      ],
    );
  }

  Widget _itemList(List<dynamic> items) {
    return TiliCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (_, i) => _itemTile(items[i]),
      ),
    );
  }

  Widget _itemTile(dynamic item) {
    final p = context.palette;
    final ht = itemPriceHT(item);
    final rate = itemTaxRate(item);
    return Padding(
      padding: const EdgeInsets.fromLTRB(TiliSpace.lg, TiliSpace.md, TiliSpace.sm, TiliSpace.md),
      child: Row(
        children: [
          const IconTile(icon: Icons.inventory_2_outlined, size: 36),
          const SizedBox(width: TiliSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'].toString(), style: context.text.titleSmall, overflow: TextOverflow.ellipsis),
                Text(
                  '${_categoryName(item['categorie_id'].toString())} · HT ${formatEuro(ht)} · TVA ${(rate * 100).toStringAsFixed(rate * 100 % 1 == 0 ? 0 : 1)}%',
                  style: context.text.bodySmall?.copyWith(color: p.textSubtle),
                ),
              ],
            ),
          ),
          Text(formatEuro(itemPriceTTC(item)), style: context.text.titleMedium?.copyWith(fontFamily: TiliFonts.display, fontWeight: FontWeight.w700)),
          const SizedBox(width: TiliSpace.md),
          TiliIconButton(tooltip: 'Modifier', onPressed: () => _editItem(item), icon: Icons.edit_outlined),
          TiliIconButton(tooltip: 'Déplacer', onPressed: () => _moveItem(item), icon: Icons.drive_file_move_outline),
          TiliIconButton(tooltip: 'Supprimer', onPressed: () => _deleteItem(item), icon: Icons.delete_outline, tone: TiliTone.danger),
        ],
      ),
    );
  }

  Widget _sortPill(_SortKey key, String label) {
    final selected = _sortKey == key;
    return FilterPill(
      label: label,
      selected: selected,
      trailing: selected
          ? Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: context.palette.onInk)
          : null,
      onTap: () => setState(() {
        if (selected) {
          _sortAsc = !_sortAsc;
        } else {
          _sortKey = key;
          _sortAsc = true;
        }
      }),
    );
  }

  Widget _itemsTab() {
    final rows = _sortedItems(_items);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: SearchField(hint: 'Rechercher un article…', onChanged: (v) => setState(() => _itemSearch = v))),
            const SizedBox(width: TiliSpace.sm),
            TiliSelect<String?>(
              value: _itemCategoryFilter,
              icon: Icons.sell_outlined,
              items: [
                (null, 'Toutes les catégories'),
                for (final c in _categories) (c['categorie_id'].toString(), c['type'].toString()),
              ],
              onChanged: (v) => setState(() => _itemCategoryFilter = v),
            ),
            const SizedBox(width: TiliSpace.sm),
            TiliButton(
              label: 'Nouvel article',
              icon: Icons.add,
              onPressed: _categories.isEmpty ? null : () => _createItem(categoryId: _itemCategoryFilter),
            ),
          ],
        ),
        const SizedBox(height: TiliSpace.md),
        Row(
          children: [
            SectionLabel('${rows.length} article${rows.length != 1 ? 's' : ''}'),
            const Spacer(),
            Text('Trier par', style: context.text.bodySmall),
            const SizedBox(width: TiliSpace.sm),
            _sortPill(_SortKey.name, 'Nom'),
            const SizedBox(width: TiliSpace.xs + 2),
            _sortPill(_SortKey.category, 'Catégorie'),
            const SizedBox(width: TiliSpace.xs + 2),
            _sortPill(_SortKey.price, 'Prix'),
          ],
        ),
        const SizedBox(height: TiliSpace.md),
        Expanded(
          child: rows.isEmpty
              ? EmptyState(
                  icon: _items.isEmpty ? Icons.inventory_2_outlined : Icons.search_off,
                  title: _items.isEmpty ? 'Aucun article' : 'Aucun résultat',
                  tone: TiliTone.neutral,
                )
              : _itemList(rows),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogs = _catalogs;
    if (catalogs == null) return const Center(child: CircularProgressIndicator());
    if (catalogs.isEmpty) {
      return Column(children: [
        if (_error != null) Notice(message: _error!, tone: TiliTone.danger),
        Expanded(child: _emptyCatalogPrompt()),
      ]);
    }

    final description = _currentCatalog?['description']?.toString() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Catalogue',
          subtitle: description.isNotEmpty ? description : 'Catégories et articles vendus en caisse',
          actions: [
            if (_loadingContent) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        const SizedBox(height: TiliSpace.lg),
        _catalogBar(),
        if (_error != null) ...[const SizedBox(height: TiliSpace.md), Notice(message: _error!, tone: TiliTone.danger)],
        const SizedBox(height: TiliSpace.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, icon: const Icon(Icons.sell_outlined, size: TiliSizes.iconSm), label: Text('Catégories (${_categories.length})')),
              ButtonSegment(value: 1, icon: const Icon(Icons.inventory_2_outlined, size: TiliSizes.iconSm), label: Text('Tous les articles (${_items.length})')),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() {
              _tab = s.first;
              _drillCategoryId = null;
            }),
          ),
        ),
        const SizedBox(height: TiliSpace.lg),
        Expanded(child: _tab == 0 ? _categoriesTab() : _itemsTab()),
      ],
    );
  }
}

class _ItemFormResult {
  const _ItemFormResult(this.name, this.priceTTC, this.taxRate, this.categoryId);

  final String name;
  final double priceTTC;
  final double taxRate;
  final String categoryId;
}

/* Prices are typed TTC with a VAT percentage, like on the web app; the
service converts to the HT price the backend stores. */
class _ItemFormDialog extends StatefulWidget {
  const _ItemFormDialog({required this.title, required this.categories, this.item, this.initialCategoryId});

  final String title;
  final List<dynamic> categories;
  final dynamic item;
  final String? initialCategoryId;

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _taxController;
  late String _categoryId;
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?['name']?.toString() ?? '');
    _priceController = TextEditingController(text: item == null ? '' : itemPriceTTC(item).toStringAsFixed(2));
    final taxPercent = item == null ? defaultTaxRate * 100 : itemTaxRate(item) * 100;
    _taxController = TextEditingController(text: taxPercent.toStringAsFixed(taxPercent % 1 == 0 ? 0 : 1));
    _categoryId = item?['categorie_id']?.toString() ??
        widget.initialCategoryId ??
        widget.categories.first['categorie_id'].toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  double get _price => parseInput(_priceController.text);
  double get _taxPercent => parseInput(_taxController.text);

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return setState(() => _error = 'Le nom est requis');
    if (_price.isNaN || _price < 0) return setState(() => _error = 'Prix invalide');
    if (_taxPercent.isNaN || _taxPercent < 0 || _taxPercent > 100) {
      return setState(() => _error = 'TVA invalide (0 à 100 %)');
    }
    Navigator.of(context).pop(_ItemFormResult(name, round2(_price), _taxPercent / 100, _categoryId));
  }

  @override
  Widget build(BuildContext context) {
    final validPrice = !_price.isNaN && !_taxPercent.isNaN;
    final ht = validPrice ? round2(_price / (1 + _taxPercent / 100)) : null;
    return TiliDialog(
      title: widget.title,
      icon: Icons.inventory_2_outlined,
      actions: [
        TiliButton(label: 'Annuler', variant: TiliButtonVariant.outline, onPressed: () => Navigator.of(context).pop()),
        TiliButton(label: 'Enregistrer', onPressed: _submit),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TiliField(controller: _nameController, label: "Nom de l'article", autofocus: widget.item == null),
          const SizedBox(height: TiliSpace.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TiliField(
                  controller: _priceController,
                  label: 'Prix TTC (€)',
                  icon: Icons.euro,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: TiliSpace.md),
              SizedBox(
                width: 120,
                child: TiliField(
                  controller: _taxController,
                  label: 'TVA (%)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          if (ht != null) ...[
            const SizedBox(height: TiliSpace.sm),
            Text('Prix HT : ${formatEuro(ht)} · TVA : ${formatEuro(round2(_price - ht))}', style: context.text.bodySmall),
          ],
          const SizedBox(height: TiliSpace.lg),
          const SectionLabel('Catégorie'),
          const SizedBox(height: TiliSpace.xs + 2),
          DropdownButtonFormField<String>(
            initialValue: _categoryId,
            borderRadius: TiliRadius.all(TiliRadius.md),
            items: widget.categories
                .map((c) => DropdownMenuItem(value: c['categorie_id'].toString(), child: Text(c['type'].toString())))
                .toList(),
            onChanged: (v) => setState(() => _categoryId = v ?? _categoryId),
          ),
          if (_error != null) ...[
            const SizedBox(height: TiliSpace.md),
            Notice(message: _error!, tone: TiliTone.danger),
          ],
        ],
      ),
    );
  }
}

class _CatalogFormDialog extends StatefulWidget {
  const _CatalogFormDialog({
    required this.title,
    this.initialName = '',
    this.initialDescription = '',
    this.confirmLabel = 'Enregistrer',
  });

  final String title;
  final String initialName;
  final String initialDescription;
  final String confirmLabel;

  @override
  State<_CatalogFormDialog> createState() => _CatalogFormDialogState();
}

class _CatalogFormDialogState extends State<_CatalogFormDialog> {
  late final TextEditingController _nameController = TextEditingController(text: widget.initialName);
  late final TextEditingController _descriptionController = TextEditingController(text: widget.initialDescription);

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name, _descriptionController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return TiliDialog(
      title: widget.title,
      icon: Icons.folder_outlined,
      actions: [
        TiliButton(label: 'Annuler', variant: TiliButtonVariant.outline, onPressed: () => Navigator.of(context).pop()),
        TiliButton(label: widget.confirmLabel, onPressed: _submit),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TiliField(controller: _nameController, label: 'Nom du catalogue', autofocus: true),
          const SizedBox(height: TiliSpace.lg),
          TiliField(controller: _descriptionController, label: 'Description (optionnelle)', maxLines: 3),
        ],
      ),
    );
  }
}
