import 'package:flutter/material.dart';
import '../services/token_service.dart';
import '../services/auth_service.dart';
import 'create_catalog_page.dart';
import 'catalog_edit_page.dart';

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
  final List<String> _menuItems = ['Compte', 'Analytiques', 'Profils', 'Catalogues', 'TPE', 'Informations'];
  List<dynamic>? _catalogs;
  bool _isLoadingCatalogs = true;
  int? _currentCatalogId;
  List<dynamic>? _sessions;
  bool _isLoadingSessions = true;
  final Map<int, String> _levelNames = {
    1: 'Super Administrateur',
    2: 'Administrateur',
    3: 'Manager',
    4: 'Salarié',
  };

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
      try {
        final storeId = widget.license['store']['store_id'] as int;
        final sessions = await AuthService.getSessions(token, storeId);
        setState(() {
          _sessions = sessions;
          _isLoadingSessions = false;
        });
      } catch (e) {
        print('Error loading sessions: $e');
        setState(() {
          _isLoadingSessions = false;
        });
      }
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
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations du compte',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.business, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Nom du commerce: ${widget.license['store']['name'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.confirmation_number, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Numéro de licence: ${widget.license['id'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Accès aux sections',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: List.generate(_menuItems.length, (index) {
                  return ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _menuItems[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              const Text(
                'Filtres d\'accessibilité',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Options d\'accessibilité à venir...',
                        style: TextStyle(fontSize: 16),
                      ),
                      // Add actual toggles here if needed
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      case 1:
        return const Text('Contenu pour Analytiques');
      case 2:
        return Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: _isLoadingSessions
                  ? const Center(child: CircularProgressIndicator())
                  : _sessions != null
                    ? GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _sessions!.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return GestureDetector(
                              onTap: () {
                                final nameController = TextEditingController();
                                const Map<String, int> levels = {'Salarié': 4, 'Manager': 3, 'Admin': 2};
                                String selectedLevel = 'Salarié';
                                showDialog(
                                  context: context,
                                  builder: (context) => StatefulBuilder(
                                    builder: (context, setState) => AlertDialog(
                                      title: const Text('Créer un profil'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: nameController,
                                            decoration: const InputDecoration(labelText: 'Nom du profil'),
                                          ),
                                          const SizedBox(height: 16),
                                          const Text('Niveau d\'accès:'),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: levels.keys.map((level) => Expanded(
                                              child: RadioListTile<String>(
                                                title: Text(level),
                                                value: level,
                                                groupValue: selectedLevel,
                                                onChanged: (value) {
                                                  setState(() {
                                                    selectedLevel = value!;
                                                  });
                                                },
                                              ),
                                            )).toList(),
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
                                              await AuthService.createSession(token, nameController.text, levels[selectedLevel]!);
                                              _loadSessions();
                                            }
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Créer'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(Icons.add, size: 48),
                                ),
                              ),
                            );
                          } else {
                            final session = _sessions![index - 1];
                            return GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
                                    title: Text(
                                      session['name'] ?? 'Profil',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.security, size: 32),
                                          title: const Text('Niveau d\'accès', style: TextStyle(fontSize: 20)),
                                          subtitle: Text(_levelNames[session['level_access']] ?? 'Inconnu', style: TextStyle(fontSize: 18)),
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.pin),
                                          title: const Text('PIN'),
                                          subtitle: Text(session['pin'] ?? 'N/A'),
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.check_circle),
                                          title: const Text('Actif'),
                                          subtitle: Text(session['is_active'] ? 'Oui' : 'Non'),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Fermer', style: TextStyle(fontSize: 18)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(session['name'] ?? 'Profil'),
                                ),
                              ),
                            );
                          }
                        },
                      )
                    : const Center(child: Text('Aucune session')),
              ),
            ),
          ],
        );
      case 3:
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
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CatalogEditPage(catalog: catalog),
                                    ),
                                  ).then((result) {
                                    if (result == true) {
                                      _loadCatalogs();
                                    }
                                  });
                                },
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
      case 4:
        return const Text('Contenu pour TPE');
      case 5:
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