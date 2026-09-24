import 'package:flutter/material.dart';
import '../services/token_service.dart';
import '../services/auth_service.dart';
import 'category_edit_page.dart';

class CatalogEditPage extends StatefulWidget {
  const CatalogEditPage({super.key, required this.catalog});

  final Map<String, dynamic> catalog;

  @override
  State<CatalogEditPage> createState() => _CatalogEditPageState();
}

class _CatalogEditPageState extends State<CatalogEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;
  List<dynamic>? _categories;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.catalog['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.catalog['description'] ?? '');
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final token = await TokenService.getToken(TokenType.user);
    final catalogId = widget.catalog['catalog_id']?.toString();
    if (token != null && catalogId != null) {
      final categories = await AuthService.getCategories(token, catalogId);
      if (!mounted) return;
      setState(() {
        _categories = categories ?? [];
        _isLoadingCategories = false;
      });
    } else if (mounted) {
      setState(() {
        _categories = [];
        _isLoadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCatalog() async {
    setState(() {
      _isLoading = true;
    });

    final token = await TokenService.getToken(TokenType.user);
    if (token != null) {
      final success = await AuthService.updateCatalog(token, widget.catalog['catalog_id'].toString(), {
        'name': _nameController.text,
        'description': _descriptionController.text,
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catalogue mis à jour avec succès')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deleteCatalog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le catalogue'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce catalogue ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      final token = await TokenService.getToken(TokenType.user);
      if (token != null) {
        final success = await AuthService.deleteCatalog(token, widget.catalog['catalog_id'].toString());

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Catalogue supprimé avec succès')),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la suppression')),
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le catalogue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _deleteCatalog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du catalogue',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description du catalogue',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 24),
            if (!_isLoadingCategories && _categories != null && _categories!.isNotEmpty) ...[
              const Text(
                'Catégories',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: ListView.separated(
                  itemCount: _categories!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final category = _categories![index];
                    return ListTile(
                      leading: const Icon(Icons.category),
                      title: Text(category['type'] ?? 'Catégorie'),
                      trailing: const Icon(Icons.chevron_right),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () async {
                        final updated = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => CategoryEditPage(
                              category: category,
                              catalogId: widget.catalog['catalog_id'].toString(),
                            ),
                          ),
                        );
                        if (updated == true) {
                          _loadCategories();
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog<bool>(
                        context: context,
                        builder: (context) => _CreateCategoryDialog(
                          catalogId: widget.catalog['catalog_id']?.toString(),
                        ),
                      ).then((created) {
                        if (created == true) {
                          _loadCategories();
                        }
                      });
                    },
                    icon: const Icon(Icons.category),
                    label: const Text('Créer une catégorie'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _categories == null || _categories!.isEmpty
                        ? null
                        : () {
                            showDialog<bool>(
                              context: context,
                              builder: (context) => _CreateProductDialog(
                                categories: _categories!,
                              ),
                            );
                          },
                    icon: const Icon(Icons.add_box),
                    label: const Text('Créer un produit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveCatalog,
                child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Sauvegarder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateCategoryDialog extends StatefulWidget {
  const _CreateCategoryDialog({required this.catalogId});

  final String? catalogId;

  @override
  State<_CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<_CreateCategoryDialog> {
  final TextEditingController _typeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _createCategory() async {
    if (widget.catalogId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID du catalogue manquant')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final token = await TokenService.getToken(TokenType.user);
    if (token != null) {
      final success = await AuthService.createCategory(token, widget.catalogId!, _typeController.text);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catégorie créée avec succès')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer une nouvelle catégorie'),
      content: TextField(
        controller: _typeController,
        decoration: const InputDecoration(labelText: 'Type de catégorie'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _createCategory,
          child: _isLoading ? const CircularProgressIndicator() : const Text('Créer'),
        ),
      ],
    );
  }
}

class _CreateProductDialog extends StatefulWidget {
  const _CreateProductDialog({required this.categories});

  final List<dynamic> categories;

  @override
  State<_CreateProductDialog> createState() => _CreateProductDialogState();
}

class _CreateProductDialogState extends State<_CreateProductDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categories.first['categorie_id']?.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  Future<void> _createProduct() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim().replaceAll(',', '.'));
    final taxPercent = double.tryParse(_taxController.text.trim().replaceAll(',', '.'));
    final tax = taxPercent == null ? null : taxPercent / 100;

    if (name.isEmpty || price == null || price < 0 || tax == null || tax < 0 || tax > 1 || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vérifiez le nom, le prix, la TVA et la catégorie')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final token = await TokenService.getToken(TokenType.user);
    if (token != null) {
      final success = await AuthService.createItem(
        token,
        name,
        price,
        tax,
        _selectedCategoryId!,
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit créé avec succès')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création du produit')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer un produit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom du produit'),
            ),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Prix'),
            ),
            TextField(
              controller: _taxController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'TVA (%)'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: widget.categories.map((category) {
                final categoryId = category['categorie_id']?.toString();
                return DropdownMenuItem<String>(
                  value: categoryId,
                  child: Text(category['type'] ?? 'Catégorie'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createProduct,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Créer'),
        ),
      ],
    );
  }
}