import 'package:flutter/material.dart';
import '../services/token_service.dart';
import '../services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.catalog['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.catalog['description'] ?? '');
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
      final success = await AuthService.updateCatalog(token, widget.catalog['id'], {
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
        final success = await AuthService.deleteCatalog(token, widget.catalog['id']);

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
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du catalogue',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => _CreateCategoryDialog(catalogId: widget.catalog['id']),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.category, size: 32),
                          SizedBox(height: 8),
                          Text('Nouvelle\nCatégorie', textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement create product
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Créer un nouveau produit - À implémenter')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_box, size: 32),
                          SizedBox(height: 8),
                          Text('Nouveau\nProduit', textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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

  final int? catalogId;

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
        Navigator.of(context).pop();
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