import 'package:flutter/material.dart';
import '../services/token_service.dart';
import '../services/auth_service.dart';
import 'create_catalog_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.isFullScreen,
    required this.onToggleFullScreen,
    required this.license,
    this.currentCatalogId,
  });

  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;
  final Map<String, dynamic> license;
  final int? currentCatalogId;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 0;
  final List<String> _menuItems = ['Compte', 'Sessions', 'Catalogues', 'Analytiques', 'Informations'];
  List<dynamic>? _catalogs;
  bool _isLoadingCatalogs = true;
  int? _currentCatalogId;
  List<dynamic>? _sessions;
  bool _isLoadingSessions = true;

  @override
  void initState() {
    super.initState();
    _currentCatalogId = widget.currentCatalogId;
    _loadCatalogs();
    _loadSessions();
  }

  Future<void> _loadCatalogs() async {
    final token = await TokenService.getToken(TokenType.user);
    if (token != null) {
      final catalogs = await AuthService.getCatalog(token);
      setState(() {
        _catalogs = catalogs;
        _isLoadingCatalogs = false;
      });
    } else {
      setState(() {
        _isLoadingCatalogs = false;
      });
    }
  }

  Future<void> _loadSessions() async {
    final token = await TokenService.getToken(TokenType.user);
    if (token != null) {
      final sessions = await AuthService.getSessions(token);
      setState(() {
        _sessions = sessions;
        _isLoadingSessions = false;
      });
    } else {
      setState(() {
        _isLoadingSessions = false;
      });
    }
  }

  void _editCatalog(dynamic catalog) {
    final TextEditingController controller = TextEditingController(text: catalog['name'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le catalogue'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nom du catalogue'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final token = await TokenService.getToken(TokenType.user);
              if (token != null) {
                await AuthService.updateCatalog(token, catalog['id'], {'name': controller.text});
                _loadCatalogs();
              }
              Navigator.of(context).pop();
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _deleteCatalog(dynamic catalog) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le catalogue'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce catalogue ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final token = await TokenService.getToken(TokenType.user);
              if (token != null) {
                await AuthService.deleteCatalog(token, catalog['id']);
                _loadCatalogs();
              }
              Navigator.of(context).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const Text('Contenu pour Compte');
      case 1:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final nameController = TextEditingController();
                  final descController = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Créer une session'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(labelText: 'Nom de la session'),
                          ),
                          TextField(
                            controller: descController,
                            decoration: const InputDecoration(labelText: 'Description'),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final token = await TokenService.getToken(TokenType.user);
                            if (token != null) {
                              await AuthService.createSession(token, nameController.text, descController.text);
                              _loadSessions();
                            }
                            Navigator.of(context).pop();
                          },
                          child: const Text('Créer'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Créer une session'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16),
                child: _isLoadingSessions
                  ? const Center(child: CircularProgressIndicator())
                  : _sessions != null && _sessions!.isNotEmpty
                    ? GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _sessions!.length,
                        itemBuilder: (context, index) {
                          final session = _sessions![index];
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(session['name'] ?? 'Session ${index + 1}'),
                            ),
                          );
                        },
                      )
                    : const Center(child: Text('Aucune session')),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const CreateCatalogDialog(),
                  ).then((result) {
                    if (result == true) {
                      _loadCatalogs();
                    }
                  });
                },
                child: const Text('Créer un catalogue'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16),
                child: _isLoadingCatalogs
                  ? const Center(child: CircularProgressIndicator())
                  : _catalogs != null && _catalogs!.isNotEmpty
                    ? ListView.builder(
                        itemCount: _catalogs!.length,
                        itemBuilder: (context, index) {
                          final catalog = _catalogs![index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: catalog['id'] == _currentCatalogId ? Colors.orange : Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: catalog['id'] == _currentCatalogId ? Colors.orange.withOpacity(0.1) : null,
                            ),
                            child: SizedBox(
                              height: 100,
                              child: ListTile(
                                title: Text(catalog['name'] ?? 'Catalogue ${index + 1}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editCatalog(catalog),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteCatalog(catalog),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(child: Text('Aucun catalogue')),
              ),
            ),
          ],
        );
      case 3:
        return const Text('Contenu pour Analytiques');
      case 4:
        return const Text('Contenu pour Informations');
      default:
        return const Text('Sélectionnez une option');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: Row(
        children: [
          SizedBox(
            width: 200,
            child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_menuItems[index]),
                  selected: index == _selectedIndex,
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                );
              },
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }
}