import 'package:flutter/material.dart';
import '../../services/active_catalog_service.dart';
import '../../services/catalog_service.dart';
import '../../utils/pricing.dart';
import '../../widgets/dialogs.dart';

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
      builder: (context) => SimpleDialog(
        title: Text('Déplacer ${item['name']} vers :'),
        children: _categories
            .map((c) => SimpleDialogOption(
                  onPressed: c['categorie_id'].toString() == current
                      ? null
                      : () => Navigator.of(context).pop(c['categorie_id'].toString()),
                  child: Row(
                    children: [
                      const Icon(Icons.label_outline),
                      const SizedBox(width: 12),
                      Text(c['type'].toString(),
                          style: TextStyle(color: c['categorie_id'].toString() == current ? Colors.grey : null)),
                      if (c['categorie_id'].toString() == current) const Text('  (actuelle)', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ))
            .toList(),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _catalogs!
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              avatar: c['catalog_id'].toString() == _activeCatalogId
                                  ? const Icon(Icons.star, color: Colors.orange)
                                  : null,
                              tooltip: c['catalog_id'].toString() == _activeCatalogId ? 'Catalogue actif en caisse' : null,
                              label: Text(c['name']?.toString() ?? 'Catalogue'),
                              selected: c['catalog_id'].toString() == _catalogId,
                              onSelected: (_) {
                                setState(() {
                                  _catalogId = c['catalog_id'].toString();
                                  _drillCategoryId = null;
                                  _itemCategoryFilter = null;
                                });
                                _loadContent();
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            if (_catalogId == _activeCatalogId)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Chip(
                  avatar: Icon(Icons.star, color: Colors.orange, size: 18),
                  label: Text('Actif en caisse'),
                  visualDensity: VisualDensity.compact,
                ),
              )
            else
              TextButton.icon(
                onPressed: _setActiveCatalog,
                icon: const Icon(Icons.star_border),
                label: const Text('Définir comme actif'),
              ),
            IconButton(tooltip: 'Nouveau catalogue', onPressed: _createCatalog, icon: const Icon(Icons.create_new_folder)),
            IconButton(tooltip: 'Modifier', onPressed: _editCatalog, icon: const Icon(Icons.edit)),
            IconButton(
                tooltip: 'Supprimer', onPressed: _deleteCatalog, icon: const Icon(Icons.delete_outline), color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _emptyCatalogPrompt() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.create_new_folder, size: 56, color: Colors.orange),
          const SizedBox(height: 12),
          const Text('Aucun catalogue', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Créez-en un pour ajouter vos catégories et articles.'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _createCatalog(initialName: 'Catalogue principal'),
            icon: const Icon(Icons.add),
            label: const Text('Créer le catalogue'),
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
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search), hintText: 'Rechercher une catégorie…', border: OutlineInputBorder(), isDense: true),
                onChanged: (v) => setState(() => _categorySearch = v),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(onPressed: _createCategory, icon: const Icon(Icons.add), label: const Text('Nouvelle catégorie')),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(_categories.isEmpty ? 'Aucune catégorie. Créez-en une !' : 'Aucun résultat.'))
              : GridView.extent(
                  maxCrossAxisExtent: 320,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: filtered.map((c) {
                    final id = c['categorie_id'].toString();
                    final count = _itemCount(id);
                    return Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          Expanded(
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.label)),
                              title: Text(c['type'].toString(), overflow: TextOverflow.ellipsis),
                              subtitle: Text('$count article${count != 1 ? 's' : ''}'),
                              trailing: const Icon(Icons.folder_open),
                              onTap: () => setState(() => _drillCategoryId = id),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                    onPressed: () => _renameCategory(c), icon: const Icon(Icons.edit, size: 16), label: const Text('Modifier')),
                              ),
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () => _deleteCategory(c),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  label: const Text('Supprimer'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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
            IconButton(onPressed: () => setState(() => _drillCategoryId = null), icon: const Icon(Icons.arrow_back)),
            Text(_categoryName(id), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text('${items.length} article${items.length != 1 ? 's' : ''}', style: const TextStyle(color: Colors.grey)),
            const Spacer(),
            FilledButton.icon(
                onPressed: () => _createItem(categoryId: id), icon: const Icon(Icons.add), label: const Text('Ajouter un article')),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Aucun article dans cette catégorie.'))
              : ListView(children: items.map(_itemTile).toList()),
        ),
      ],
    );
  }

  Widget _itemTile(dynamic item) {
    final ht = itemPriceHT(item);
    final rate = itemTaxRate(item);
    return Card(
      child: ListTile(
        title: Text(item['name'].toString()),
        subtitle: Text('${_categoryName(item['categorie_id'].toString())} · HT ${formatEuro(ht)} · TVA ${(rate * 100).toStringAsFixed(rate * 100 % 1 == 0 ? 0 : 1)}%'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(formatEuro(itemPriceTTC(item)), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 8),
            IconButton(tooltip: 'Modifier', onPressed: () => _editItem(item), icon: const Icon(Icons.edit)),
            IconButton(tooltip: 'Déplacer', onPressed: () => _moveItem(item), icon: const Icon(Icons.drive_file_move_outline)),
            IconButton(
                tooltip: 'Supprimer',
                onPressed: () => _deleteItem(item),
                icon: const Icon(Icons.delete_outline),
                color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _sortChip(_SortKey key, String label) {
    final selected = _sortKey == key;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (selected) Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward, size: 14),
        ],
      ),
      selected: selected,
      onSelected: (_) => setState(() {
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
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search), hintText: 'Rechercher un article…', border: OutlineInputBorder(), isDense: true),
                onChanged: (v) => setState(() => _itemSearch = v),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String?>(
              value: _itemCategoryFilter,
              items: [
                const DropdownMenuItem(value: null, child: Text('Toutes les catégories')),
                ..._categories.map((c) =>
                    DropdownMenuItem(value: c['categorie_id'].toString(), child: Text(c['type'].toString()))),
              ],
              onChanged: (v) => setState(() => _itemCategoryFilter = v),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _categories.isEmpty ? null : () => _createItem(categoryId: _itemCategoryFilter),
              icon: const Icon(Icons.add),
              label: const Text('Nouvel article'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('${rows.length} article${rows.length != 1 ? 's' : ''} · Trier par :'),
            _sortChip(_SortKey.name, 'Nom'),
            _sortChip(_SortKey.category, 'Catégorie'),
            _sortChip(_SortKey.price, 'Prix'),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: rows.isEmpty
              ? Center(child: Text(_items.isEmpty ? 'Aucun article.' : 'Aucun résultat.'))
              : ListView(children: rows.map(_itemTile).toList()),
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
        if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
        Expanded(child: _emptyCatalogPrompt()),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _catalogBar(),
        if ((_currentCatalog?['description']?.toString() ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Text(_currentCatalog!['description'].toString(), style: TextStyle(color: Colors.grey[700])),
          ),
        if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 8),
        Row(
          children: [
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, icon: const Icon(Icons.label), label: Text('Catégories (${_categories.length})')),
                ButtonSegment(value: 1, icon: const Icon(Icons.inventory_2), label: Text('Tous les articles (${_items.length})')),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() {
                _tab = s.first;
                _drillCategoryId = null;
              }),
            ),
            const Spacer(),
            if (_loadingContent) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        const SizedBox(height: 12),
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
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                autofocus: widget.item == null,
                decoration: const InputDecoration(labelText: "Nom de l'article", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Prix TTC (€)', border: OutlineInputBorder()),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _taxController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'TVA (%)', border: OutlineInputBorder()),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              if (ht != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Prix HT : ${formatEuro(ht)} · TVA : ${formatEuro(round2(_price - ht))}',
                      style: const TextStyle(color: Colors.grey)),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder()),
                items: widget.categories
                    .map((c) => DropdownMenuItem(value: c['categorie_id'].toString(), child: Text(c['type'].toString())))
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v ?? _categoryId),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        FilledButton(onPressed: _submit, child: const Text('Enregistrer')),
      ],
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
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nom du catalogue', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description (optionnelle)', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
