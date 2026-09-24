import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'session_page.dart';
import '../services/token_service.dart';
import '../services/auth_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'create_catalog_page.dart';
import 'settings_pages.dart';

/* This widget represents the main page of the application after the user has
logged in. It displays a category bar, sorting options, and a list of items with
quantity steppers. */
class MainPage extends StatefulWidget {
  const MainPage({
    super.key,
    required this.isFullScreen,
    required this.onToggleFullScreen,
    required this.license,
  });

  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;
  final Map<String, dynamic> license;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _selectedCategory = 'Tous';
  String _userName = 'Utilisateur';
  String _storeName = 'Commerce';
  String? _currentCatalogId;
  List<dynamic>? _catalog;
  bool _isLoadingCatalog = true;
  List<dynamic>? _categories;
  List<dynamic> _items = [];
  final List<Map<String, dynamic>> _cartItems = [];
  dynamic _selectedProduct;
  String _quantityInput = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadCatalog();
  }

  Future<void> _loadUserInfo() async {
    final token = await TokenService.getToken(TokenType.user);
    if (token != null) {
      try {
        final decodedToken = JwtDecoder.decode(token);
        setState(() {
          _userName = decodedToken['name'] ?? 'Utilisateur';
        });
      } catch (e) {
        print('Error decoding user token: $e');
      }
    }
    setState(() {
      _storeName = widget.license['store']?['name'] ?? 'Commerce';
    });
  }

  Future<void> _loadCatalog() async {
    final token = await TokenService.getToken(TokenType.user);
    final storeId = await TokenService.getToken(TokenType.license);
    if (token != null && storeId != null) {
      final catalog = await AuthService.getCatalog(token, storeId);
      final catalogId = catalog != null && catalog.isNotEmpty
          ? catalog.first['catalog_id']?.toString()
          : null;
      if (!mounted) return;
        final categories = catalogId == null
          ? <dynamic>[]
          : await AuthService.getCategories(token, catalogId) ?? [];
        final items = await AuthService.getItems(token) ?? [];
        final catalogCategoryIds = categories
          .map((category) => category['categorie_id']?.toString())
          .whereType<String>()
          .toSet();
      setState(() {
        _catalog = catalog;
        _isLoadingCatalog = false;
        _categories = categories;
        _items = items
          .where((item) => catalogCategoryIds.contains(item['categorie_id']?.toString()))
          .toList();
        _currentCatalogId = catalogId;
      });
    } else {
      setState(() {
        _isLoadingCatalog = false;
      });
    }
  }

  List<dynamic> get _visibleItems {
    if (_selectedCategory == 'Tous') {
      return _items;
    }
    final selectedCategory = _categories?.cast<Map<String, dynamic>?>().firstWhere(
      (category) => category?['type'] == _selectedCategory,
      orElse: () => null,
    );
    final categoryId = selectedCategory?['categorie_id']?.toString();
    return _items
        .where((item) => item['categorie_id']?.toString() == categoryId)
        .toList();
  }

  double _itemPrice(dynamic item) {
    return double.tryParse(item['price']?.toString() ?? '') ?? 0;
  }

  double get _cartTotal {
    return _cartItems.fold(0, (total, item) {
      return total + (_itemPrice(item['product']) * (item['quantity'] as int));
    });
  }

  void _addToCart(dynamic product, {int quantity = 1}) {
    final productId = product['item_id']?.toString();
    final existingIndex = _cartItems.indexWhere(
      (item) => item['product']['item_id']?.toString() == productId,
    );

    setState(() {
      if (existingIndex == -1) {
        _cartItems.add({'product': product, 'quantity': quantity});
      } else {
        _cartItems[existingIndex]['quantity'] += quantity;
      }
    });
  }

  void _removeCartItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  void _clearCart() {
    if (_cartItems.isEmpty) return;
    setState(() {
      _cartItems.clear();
      _selectedProduct = null;
      _quantityInput = '';
    });
  }

  void _handleCalculatorButton(String label) {
    if (label == 'X') {
      setState(() {
        _quantityInput = '';
      });
      return;
    }

    if (label == '=') {
      final quantity = int.tryParse(_quantityInput);
      if (_selectedProduct == null || quantity == null || quantity <= 0) {
        _showSnackBar('Sélectionnez un produit et saisissez une quantité');
        return;
      }
      if (quantity > 1) {
        _addToCart(_selectedProduct, quantity: quantity - 1);
      }
      setState(() {
        _quantityInput = '';
      });
      return;
    }

    setState(() {
      _quantityInput = '$_quantityInput$label';
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _showSettingsPinDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => const _SettingsPinDialog(),
    );
  }

  Future<void> _openSettings() async {
    final pin = await _showSettingsPinDialog();
    if (pin == null) {
      return;
    }
    if (pin.length != 6) {
      _showSnackBar('Le PIN doit contenir 6 chiffres');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          license: widget.license,
          isFullScreen: widget.isFullScreen,
          onToggleFullScreen: widget.onToggleFullScreen,
          currentCatalogId: _currentCatalogId,
        ),
      ),
    );
  }

  void _logout() {
    TokenService.deleteToken(TokenType.user);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SessionPage(
          license: widget.license,
          isFullScreen: widget.isFullScreen,
          onToggleFullScreen: widget.onToggleFullScreen,
        ),
      ),
    );
  }

  Widget _calcButton(String label) {
    final isDigit = int.tryParse(label) != null;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: AspectRatio(
          aspectRatio: 1,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDigit
                  ? const Color(0xFF3BB273)
                  : const Color(0xFFE1BC29),
              foregroundColor: Colors.black,
            ),
            onPressed: () => _handleCalculatorButton(label),
            child: Text(
              label,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = 16.0;
    final totalSpacing = spacing * 2; // two spacings
    final availableWidth = screenWidth - totalSpacing;
    final partWidth = availableWidth / 4;
    final safeHeight =
        MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        kToolbarHeight;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        title: Text('$_storeName - $_userName'),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SafeArea(

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: partWidth * 2,
              height: safeHeight,
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  // border: Border.all(
                  //   color: const Color(0xFF7768AE),
                  //   width: 5,
                  // ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_catalog != null && _catalog!.isNotEmpty)
                      SizedBox(
                        height: 60, // Fixed height for the category buttons row
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _selectedCategory == 'Tous'
                                        ? const Color(0xFFE15554)
                                        : Colors.grey[300],
                                    foregroundColor: _selectedCategory == 'Tous'
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedCategory = 'Tous';
                                    });
                                  },
                                  child: const Text('TOUS'),
                                ),
                              ),
                              ...(_categories ?? []).map(
                                (category) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          category['type'] == _selectedCategory
                                          ? const Color(0xFFE15554)
                                          : Colors.grey[300],
                                      foregroundColor:
                                          category['type'] == _selectedCategory
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _selectedCategory =
                                            category['type'] ?? 'Tous';
                                      });
                                    },
                                    child: Text(category['type'] ?? 'Unknown'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        // Placeholder for the catalog items list
                        color: Colors.grey[200],
                        child: _isLoadingCatalog
                            ? GestureDetector(
                                onTap: () async {
                                  final result = await showDialog(
                                    context: context,
                                    builder: (context) =>
                                        const CreateCatalogDialog(),
                                  );
                                  if (result == true) {
                                    _loadCatalog();
                                  }
                                },
                                child: const Center(
                                  child: Text(
                                    'Créer un catalogue',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 16,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              )
                            : _catalog != null && _catalog!.isNotEmpty
                            ? _visibleItems.isEmpty
                                ? const Center(child: Text('Aucun produit'))
                                : ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: _visibleItems.length,
                                    itemBuilder: (context, index) {
                                      final item = _visibleItems[index];
                                      return Card(
                                        child: ListTile(
                                          onTap: () {
                                            setState(() {
                                              _selectedProduct = item;
                                            });
                                            _addToCart(item);
                                          },
                                          title: Text(item['name'] ?? 'Produit'),
                                          subtitle: Text(
                                            'Catégorie: ${item['categorie']?['type'] ?? 'Inconnue'}',
                                          ),
                                          trailing: Text(
                                            '${item['price'] ?? '0.00'} €',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                            : GestureDetector(
                                onTap: () async {
                                  final result = await showDialog(
                                    context: context,
                                    builder: (context) =>
                                        const CreateCatalogDialog(),
                                  );
                                  if (result == true) {
                                    _loadCatalog();
                                  }
                                },
                                child: const Center(
                                  child: Text(
                                    'Pas de catalogue',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 16,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: spacing),
            SizedBox(
              width: partWidth * 2,
              height: safeHeight,
              child: Row(
                children: [
                  SizedBox(
                    width: partWidth - spacing / 2,
                    height: safeHeight,
                    child: Container(
                      height: double.infinity,
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFF7768AE),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.all(8.0),
                              margin: const EdgeInsets.only(top: 16),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 40,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          onPressed: _cartItems.isEmpty ? null : _clearCart,
                                          icon: const Icon(Icons.delete_outline),
                                          tooltip: 'Vider le panier',
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: _cartItems.isEmpty
                                        ? const Center(child: Text('Aucun produit sélectionné'))
                                        : ListView.separated(
                                            itemCount: _cartItems.length,
                                            separatorBuilder: (_, __) => const Divider(),
                                            itemBuilder: (context, index) {
                                              final cartItem = _cartItems[index];
                                              final product = cartItem['product'];
                                              final quantity = cartItem['quantity'] as int;
                                              return ListTile(
                                                dense: true,
                                                title: Text(product['name'] ?? 'Produit'),
                                                subtitle: Text('x$quantity'),
                                                trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '${(_itemPrice(product) * quantity).toStringAsFixed(2)} €',
                                                    ),
                                                    IconButton(
                                                      onPressed: () => _removeCartItem(index),
                                                      icon: const Icon(Icons.delete_outline),
                                                      tooltip: 'Retirer du panier',
                                                    ),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${_cartTotal.toStringAsFixed(2)} €',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: spacing),
                    child: SizedBox(
                      width: partWidth - spacing / 2,
                      height: safeHeight - 8,
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(8.0),
                              margin: const EdgeInsets.only(right: 16, top: 16),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    child: null
                                  ),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              _calcButton('1'),
                                              const SizedBox(width: 4),
                                              _calcButton('2'),
                                              const SizedBox(width: 4),
                                              _calcButton('3'),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              _calcButton('4'),
                                              const SizedBox(width: 4),
                                              _calcButton('5'),
                                              const SizedBox(width: 4),
                                              _calcButton('6'),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              _calcButton('7'),
                                              const SizedBox(width: 4),
                                              _calcButton('8'),
                                              const SizedBox(width: 4),
                                              _calcButton('9'),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              _calcButton('X'),
                                              const SizedBox(width: 4),
                                              _calcButton('0'),
                                              const SizedBox(width: 4),
                                              _calcButton('='),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: spacing),
                          SizedBox(
                            height: 248,
                            child: Container(
                              width: partWidth - spacing / 2,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(
                                right: 16,
                                bottom: 16,
                              ),
                              color: Colors.white,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      child: const Text('Carte'),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      child: const Text('Espèces'),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      child: const Text('Paiement multiple'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPinDialog extends StatefulWidget {
  const _SettingsPinDialog();

  @override
  State<_SettingsPinDialog> createState() => _SettingsPinDialogState();
}

class _SettingsPinDialogState extends State<_SettingsPinDialog> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _submitPin() {
    Navigator.of(context).pop(_pinController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('PIN administrateur'),
      content: SizedBox(
        width: 280,
        child: TextField(
          controller: _pinController,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          obscureText: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            hintText: 'Entrez le PIN à 6 chiffres',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: _submitPin,
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
