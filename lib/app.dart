import 'package:flutter/material.dart';
import 'login.dart';
import 'services/token_service.dart';

class AppPage extends StatefulWidget {
  const AppPage({
    super.key,
    required this.isFullScreen,
    required this.onToggleFullScreen,
  });

  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  // --- 1. Variables d'état pour l'interface ---
  final List<String> categories = [
    'Bière', 'Vin', 'Soda', 'Jus', 'Boisson Chaude', 'Alimentaire'
  ];
  int selectedCategoryIndex = 3; // "Jus" sélectionné par défaut

  // --- 2. Ta fonction de déconnexion ---
  void _logout() {
    TokenService.deleteToken(TokenType.user);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginPage(
          isFullScreen: widget.isFullScreen,
          onToggleFullScreen: widget.onToggleFullScreen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      // --- Ton bouton de déconnexion ---
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          SizedBox(
            width: 50,
            height: 50,
            child: IconButton(
              onPressed: _logout,
              icon: const Icon(
                Icons.logout,
                color: Colors.grey,
                size: 24,
              ),
            ),
          ),
        ],
      ),
      // On le place en bas à gauche pour ne pas gêner la liste de droite
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,

      // --- L'interface de la caisse (Le corps de la page) ---
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
              // L'EN-TÊTE (Catégories + Tris)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryBar(),
                    const SizedBox(width: 40),
                    _buildSortButtons(),
                  ],
                ),
              ),

              // LA LISTE DES ARTICLES
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: 6, // Nombre de lignes provisoires
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end, // Aligne à droite
                        children: [
                          _buildQuantityStepper(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // WIDGETS DE COMPOSITION (Pour garder le build() propre)
  // =========================================================

  // WIDGET : La barre des catégories
  Widget _buildCategoryBar() {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(categories.length, (index) {
            bool isSelected = index == selectedCategoryIndex;
            return Row(
              children: [
                InkWell(
                  onTap: () {
                    setState(() => selectedCategoryIndex = index);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      categories[index],
                      style: TextStyle(
                        color: isSelected ? Colors.red.shade400 : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (index < categories.length - 1)
                  Container(width: 1, height: 15, color: Colors.grey.shade300),
              ],
            );
          }),
          Container(width: 1, height: 15, color: Colors.grey.shade300),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.black87),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  // WIDGET : Les boutons de tri
  Widget _buildSortButtons() {
    return Row(
      children: [
        _sortButton("Prix"),
        const SizedBox(width: 30),
        _sortButton("Nom"),
      ],
    );
  }

  Widget _sortButton(String title) {
    return InkWell(
      onTap: () {},
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF5A8B8C), // Ton vert d'eau
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.unfold_more,
            color: Color(0xFF5A8B8C),
            size: 20,
          ),
        ],
      ),
    );
  }

  // WIDGET : Le bouton + / -
  Widget _buildQuantityStepper() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              print("Moins");
            },
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Icon(Icons.remove, size: 20, color: Colors.black87),
            ),
          ),
          Container(width: 1, height: 15, color: Colors.grey.shade400),
          InkWell(
            onTap: () {
              print("Plus");
            },
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Icon(Icons.add, size: 20, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}