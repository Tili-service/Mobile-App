import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/token_service.dart';
import '../services/auth_service.dart';

class CreateCatalogDialog extends StatefulWidget {
  const CreateCatalogDialog({super.key});

  @override
  State<CreateCatalogDialog> createState() => _CreateCatalogDialogState();
}

class _CreateCatalogDialogState extends State<CreateCatalogDialog> {
  final TextEditingController catalogNameController = TextEditingController();
  final TextEditingController catalogDescriptionController = TextEditingController();

  @override
  void dispose() {
    catalogNameController.dispose();
    catalogDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: Dialog(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
          width: 500,
          height: 450,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Nouveau Catalogue',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: catalogNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du catalogue',
                  hintText: 'Entrez le nom de votre catalogue',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: catalogDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description du catalogue',
                  hintText: 'Entrez une description pour votre catalogue',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                style: const TextStyle(fontSize: 16),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Annuler',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final catalogName = catalogNameController.text.trim();
                      final catalogDescription = catalogDescriptionController.text.trim();
                      if (catalogName.isNotEmpty) {
                        final token = await TokenService.getToken(TokenType.user);
                        if (token != null) {
                          final success = await AuthService.createCatalog(token, catalogName, catalogDescription);
                          if (success) {
                            Navigator.of(context).pop(true);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Erreur lors de la création du catalogue'),
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Token non disponible'),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez entrer un nom pour le catalogue'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'Créer',
                      style: TextStyle(fontSize: 16),
                    ),
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