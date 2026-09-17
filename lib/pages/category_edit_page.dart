import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';

class CategoryEditPage extends StatefulWidget {
	const CategoryEditPage({
		super.key,
		required this.category,
		required this.catalogId,
	});

	final Map<String, dynamic> category;
	final String catalogId;

	@override
	State<CategoryEditPage> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
	late final TextEditingController _typeController;
	bool _isLoading = false;

	String get _categoryId => widget.category['categorie_id'].toString();

	@override
	void initState() {
		super.initState();
		_typeController = TextEditingController(
			text: widget.category['type']?.toString() ?? '',
		);
	}

	@override
	void dispose() {
		_typeController.dispose();
		super.dispose();
	}

	Future<void> _saveCategory() async {
		final type = _typeController.text.trim();
		if (type.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Le nom de la catégorie est requis')),
			);
			return;
		}

		setState(() => _isLoading = true);
		final token = await TokenService.getToken(TokenType.user);
		if (token == null) {
			if (mounted) setState(() => _isLoading = false);
			return;
		}

		final success = await AuthService.updateCategory(
			token,
			widget.catalogId,
			_categoryId,
			type,
		);
		if (!mounted) return;

		if (success) {
			Navigator.of(context).pop(true);
		} else {
			setState(() => _isLoading = false);
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Erreur lors de la modification')),
			);
		}
	}

	Future<void> _deleteCategory() async {
		final confirmed = await showDialog<bool>(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Supprimer la catégorie'),
				content: const Text('Êtes-vous sûr de vouloir supprimer cette catégorie ?'),
				actions: [
					TextButton(
						onPressed: () => Navigator.of(context).pop(false),
						child: const Text('Annuler'),
					),
					FilledButton(
						onPressed: () => Navigator.of(context).pop(true),
						child: const Text('Supprimer'),
					),
				],
			),
		);
		if (confirmed != true) return;

		setState(() => _isLoading = true);
		final token = await TokenService.getToken(TokenType.user);
		if (token == null) {
			if (mounted) setState(() => _isLoading = false);
			return;
		}

		final success = await AuthService.deleteCategory(
			token,
			widget.catalogId,
			_categoryId,
		);
		if (!mounted) return;

		if (success) {
			Navigator.of(context).pop(true);
		} else {
			setState(() => _isLoading = false);
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Erreur lors de la suppression')),
			);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Modifier la catégorie'),
				actions: [
					IconButton(
						onPressed: _isLoading ? null : _deleteCategory,
						icon: const Icon(Icons.delete),
						tooltip: 'Supprimer la catégorie',
					),
				],
			),
			body: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					children: [
						TextField(
							controller: _typeController,
							enabled: !_isLoading,
							decoration: const InputDecoration(
								labelText: 'Nom de la catégorie',
								border: OutlineInputBorder(),
							),
						),
						const Spacer(),
						SizedBox(
							width: double.infinity,
							child: FilledButton(
								onPressed: _isLoading ? null : _saveCategory,
								child: _isLoading
										? const SizedBox(
												width: 20,
												height: 20,
												child: CircularProgressIndicator(strokeWidth: 2),
											)
										: const Text('Sauvegarder'),
							),
						),
					],
				),
			),
		);
	}
}
