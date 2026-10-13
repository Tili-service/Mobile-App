import 'package:flutter/material.dart';
import 'session_page.dart';
import '../services/token_service.dart';
import '../services/catalog_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/active_catalog_service.dart';
import '../services/profile_service.dart';
import '../utils/pricing.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import 'settings_pages.dart';

/* POS screen of the logged-in cashier: products of the active catalogue
(filterable by category), cart with quantity keypad, payment buttons, and
the admin PIN gate to the settings. Several orders can be open at once and
are switched from the bottom bar; paying an order closes it. */
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
  final List<_Order> _orders = [_Order(1)];
  int _activeOrderIndex = 0;
  int _nextOrderNumber = 2;

  _Order get _order => _orders[_activeOrderIndex];
  List<Map<String, dynamic>> get _cartItems => _order.cartItems;
  dynamic get _selectedProduct => _order.selectedProduct;
  set _selectedProduct(dynamic product) => _order.selectedProduct = product;
  String get _quantityInput => _order.quantityInput;
  set _quantityInput(String input) => _order.quantityInput = input;

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
        debugPrint('Error decoding user token: $e');
      }
    }
    setState(() {
      _storeName = widget.license['store']?['name'] ?? 'Commerce';
    });
  }

  Future<void> _loadCatalog() async {
    final token = await TokenService.getToken(TokenType.user);
    final storeId = await TokenService.getToken(TokenType.license);
    if (token == null || storeId == null) {
      setState(() => _isLoadingCatalog = false);
      return;
    }
    try {
      final catalog = await CatalogService.getCatalogs(token, storeId);
      final activeCatalogId = await ActiveCatalogService.get(storeId);
      final catalogIds = catalog.map((c) => c['catalog_id']?.toString()).toList();
      final catalogId = catalogIds.contains(activeCatalogId)
          ? activeCatalogId
          : (catalogIds.isEmpty ? null : catalogIds.first);
      final categories = catalogId == null
          ? <dynamic>[]
          : await CatalogService.getCategories(token, catalogId);
      final items = await CatalogService.getCatalogItems(token, categories);
      if (!mounted) return;
      setState(() {
        if (catalogId != _currentCatalogId) _selectedCategory = 'Tous';
        _catalog = catalog;
        _categories = categories;
        _items = items;
        _currentCatalogId = catalogId;
      });
    } catch (e) {
      if (mounted) _showSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingCatalog = false);
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

  double _itemPrice(dynamic item) => itemPriceTTC(item);

  String? get _currentCatalogName => _catalog
      ?.cast<Map<String, dynamic>?>()
      .firstWhere((c) => c?['catalog_id']?.toString() == _currentCatalogId, orElse: () => null)?['name']
      ?.toString();


  double _orderTotal(_Order order) {
    return order.cartItems.fold(0, (total, item) {
      return total + (_itemPrice(item['product']) * (item['quantity'] as int));
    });
  }

  double get _cartTotal => _orderTotal(_order);

  void _newOrder() {
    setState(() {
      _orders.add(_Order(_nextOrderNumber++));
      _activeOrderIndex = _orders.length - 1;
    });
  }

  void _selectOrder(int index) {
    setState(() => _activeOrderIndex = index);
  }

  /* Removes an order from the bar; there is always at least one open order,
  so closing the last one replaces it with a fresh one. */
  void _closeOrder(int index) {
    setState(() {
      _orders.removeAt(index);
      if (_orders.isEmpty) {
        _orders.add(_Order(_nextOrderNumber++));
      }
      if (_activeOrderIndex >= index && _activeOrderIndex > 0) {
        _activeOrderIndex--;
      }
    });
  }

  // TODO: record the payment on the backend once the sales API exists.
  void _pay(String method) {
    if (_cartItems.isEmpty) {
      _showSnackBar('Le panier est vide');
      return;
    }
    final number = _order.number;
    final total = _cartTotal;
    _closeOrder(_activeOrderIndex);
    _showSnackBar('Commande $number réglée ($method) : ${formatEuro(total)}', error: false);
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

  void _showSnackBar(String message, {bool error = true}) => showMessage(context, message, error: error);

  Future<String?> _showSettingsPinDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => const _SettingsPinDialog(),
    );
  }

  /* The PIN is checked against the backend and must belong to an Admin or
  Super admin of this store (same rule as the web back-office). The admin's
  own ProfileToken is then used for every call made from the settings. */
  Future<void> _openSettings() async {
    final pin = await _showSettingsPinDialog();
    if (pin == null) {
      return;
    }
    if (pin.length != 6) {
      _showSnackBar('Le PIN doit contenir 6 chiffres');
      return;
    }
    final storeId = await TokenService.getToken(TokenType.license);
    if (storeId == null) return;

    final Map<String, dynamic> result;
    try {
      result = await ProfileService.loginWithPin(storeId, pin);
    } catch (e) {
      _showSnackBar(e.toString());
      return;
    }
    final profile = (result['profile'] as Map?)?.cast<String, dynamic>() ?? {};
    final level = profile['level_access'] as int? ?? 99;
    if (level > 2) {
      _showSnackBar('Droits administrateur requis pour accéder aux paramètres');
      return;
    }
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          license: widget.license,
          isFullScreen: widget.isFullScreen,
          onToggleFullScreen: widget.onToggleFullScreen,
          storeId: storeId,
          adminToken: result['token'].toString(),
          adminProfile: profile,
          currentCatalogId: _currentCatalogId,
        ),
      ),
    );
    if (mounted) _loadCatalog();
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

  static const _keypad = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'X', '0', '='];

  PreferredSizeWidget _appBar() {
    final p = context.palette;
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: TiliSpace.lg,
      title: Row(
        children: [
          const BrandMark(onDark: false, size: 36, showName: false),
          const SizedBox(width: TiliSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Caisse', style: context.text.bodySmall?.copyWith(color: p.textSubtle)),
                Text(_storeName, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          padding: const EdgeInsets.fromLTRB(TiliSpace.xs, TiliSpace.xs, TiliSpace.md, TiliSpace.xs),
          decoration: BoxDecoration(
            color: p.surfaceMuted,
            borderRadius: TiliRadius.all(TiliRadius.md),
            border: Border.all(color: p.borderSubtle),
          ),
          child: Row(
            children: [
              Avatar(name: _userName, size: 30),
              const SizedBox(width: TiliSpace.sm),
              Text(_userName, style: context.text.labelLarge),
            ],
          ),
        ),
        const SizedBox(width: TiliSpace.md),
        TiliIconButton(tooltip: 'Paramètres', onPressed: _openSettings, icon: Icons.settings_outlined, bordered: true),
        const SizedBox(width: TiliSpace.sm),
        TiliIconButton(tooltip: 'Changer de caissier', onPressed: _logout, icon: Icons.logout, bordered: true),
        const SizedBox(width: TiliSpace.lg),
      ],
    );
  }

  Widget _categoryBar() {
    return SizedBox(
      height: TiliSizes.buttonMd,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterPill(
            label: 'Tous',
            icon: Icons.grid_view_rounded,
            selected: _selectedCategory == 'Tous',
            onTap: () => setState(() => _selectedCategory = 'Tous'),
          ),
          for (final category in _categories ?? [])
            Padding(
              padding: const EdgeInsets.only(left: TiliSpace.sm),
              child: FilterPill(
                label: category['type'] ?? 'Inconnue',
                selected: category['type'] == _selectedCategory,
                onTap: () => setState(() => _selectedCategory = category['type'] ?? 'Tous'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _productTile(dynamic item) {
    final p = context.palette;
    final selected = _selectedProduct != null && _selectedProduct['item_id'] == item['item_id'];
    return TiliCard(
      padding: const EdgeInsets.all(TiliSpace.md + 2),
      highlight: selected,
      borderColor: selected ? p.accent : null,
      onTap: () {
        setState(() => _selectedProduct = item);
        _addToCart(item);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['name'] ?? 'Produit',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleSmall,
          ),
          const SizedBox(height: TiliSpace.xxs),
          Text(
            item['categorie']?['type'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(color: p.textSubtle),
          ),
          const Spacer(),
          Text(formatEuro(_itemPrice(item)), style: context.text.titleLarge?.copyWith(color: p.accentStrong)),
        ],
      ),
    );
  }

  Widget _catalogPanel() {
    final p = context.palette;
    Widget content;
    if (_isLoadingCatalog) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_catalog == null || _catalog!.isEmpty) {
      content = EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Aucun catalogue',
        message: 'Créez un catalogue dans les paramètres pour commencer à vendre.',
        action: TiliButton(label: 'Ouvrir les paramètres', icon: Icons.settings_outlined, variant: TiliButtonVariant.accent, onPressed: _openSettings),
      );
    } else if (_visibleItems.isEmpty) {
      content = const EmptyState(icon: Icons.search_off, title: 'Aucun produit', tone: TiliTone.neutral);
    } else {
      content = GridView.builder(
        padding: const EdgeInsets.only(top: TiliSpace.xs),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          mainAxisExtent: 116,
          crossAxisSpacing: TiliSpace.md,
          mainAxisSpacing: TiliSpace.md,
        ),
        itemCount: _visibleItems.length,
        itemBuilder: (context, index) => _productTile(_visibleItems[index]),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_catalog != null && _catalog!.isNotEmpty) ...[
          _categoryBar(),
          const SizedBox(height: TiliSpace.sm),
          Row(
            children: [
              SectionLabel('${_visibleItems.length} produit${_visibleItems.length > 1 ? 's' : ''}'),
              const Spacer(),
              if (_currentCatalogName != null) ...[
                Icon(Icons.star_rounded, size: 14, color: p.accent),
                const SizedBox(width: TiliSpace.xs),
                Text(_currentCatalogName!, style: context.text.bodySmall?.copyWith(color: p.textSubtle)),
              ],
            ],
          ),
          const SizedBox(height: TiliSpace.sm),
        ],
        Expanded(child: content),
      ],
    );
  }

  Widget _cartPanel() {
    final p = context.palette;
    final count = _cartItems.fold<int>(0, (n, i) => n + (i['quantity'] as int));
    return TiliCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(TiliSpace.lg + 2, TiliSpace.md, TiliSpace.sm, TiliSpace.md),
            child: Row(
              children: [
                Text('Panier', style: context.text.titleLarge),
                const SizedBox(width: TiliSpace.sm),
                if (count > 0) StatusBadge(label: '$count', tone: TiliTone.accent),
                const Spacer(),
                TiliIconButton(
                  tooltip: 'Vider le panier',
                  onPressed: _cartItems.isEmpty ? null : _clearCart,
                  icon: Icons.delete_sweep_outlined,
                  tone: TiliTone.danger,
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _cartItems.isEmpty
                ? const EmptyState(icon: Icons.shopping_basket_outlined, title: 'Panier vide', message: 'Touchez un produit pour l\'ajouter.', tone: TiliTone.neutral)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: TiliSpace.xs),
                    itemCount: _cartItems.length,
                    separatorBuilder: (_, _) => const Divider(indent: TiliSpace.lg, endIndent: TiliSpace.lg),
                    itemBuilder: (context, index) {
                      final cartItem = _cartItems[index];
                      final product = cartItem['product'];
                      final quantity = cartItem['quantity'] as int;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(TiliSpace.lg, TiliSpace.sm, TiliSpace.xs, TiliSpace.sm),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: p.surfaceMuted, borderRadius: TiliRadius.all(TiliRadius.sm)),
                              child: Text('$quantity', style: context.text.labelLarge),
                            ),
                            const SizedBox(width: TiliSpace.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product['name'] ?? 'Produit', overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                                  Text(formatEuro(_itemPrice(product)), style: context.text.bodySmall?.copyWith(color: p.textSubtle)),
                                ],
                              ),
                            ),
                            Text(formatEuro(_itemPrice(product) * quantity), style: context.text.titleSmall),
                            TiliIconButton(tooltip: 'Retirer du panier', onPressed: () => _removeCartItem(index), icon: Icons.close),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(TiliSpace.lg + 2),
            decoration: BoxDecoration(
              color: p.ink,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(TiliRadius.lg - 1)),
            ),
            child: Row(
              children: [
                Text('TOTAL TTC', style: context.text.labelSmall?.copyWith(color: p.onInkMuted, letterSpacing: 1.5)),
                const Spacer(),
                Text(formatEuro(_cartTotal), style: context.text.headlineMedium?.copyWith(color: p.onInk)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _keypadKey(String label) {
    final p = context.palette;
    final (bg, fg) = switch (label) {
      'X' => (p.dangerTint, p.danger),
      '=' => (p.accent, p.onInk),
      _ => (p.surfaceMuted, p.foreground),
    };
    return Material(
      color: bg,
      borderRadius: TiliRadius.all(TiliRadius.md),
      child: InkWell(
        borderRadius: TiliRadius.all(TiliRadius.md),
        onTap: () => _handleCalculatorButton(label),
        child: Center(
          child: label == 'X'
              ? Icon(Icons.clear_rounded, color: fg, size: TiliSizes.iconLg)
              : Text(label, style: context.text.headlineSmall?.copyWith(color: fg)),
        ),
      ),
    );
  }

  Widget _actionPanel() {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: TiliCard(
            padding: const EdgeInsets.all(TiliSpace.md + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: TiliSpace.md, vertical: TiliSpace.sm),
                  decoration: BoxDecoration(
                    color: p.surfaceMuted,
                    borderRadius: TiliRadius.all(TiliRadius.md),
                    border: Border.all(color: p.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedProduct?['name'] ?? 'Quantité',
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall?.copyWith(color: p.textSubtle),
                        ),
                      ),
                      Text(
                        _quantityInput.isEmpty ? '0' : '×$_quantityInput',
                        style: context.text.headlineSmall?.copyWith(color: _quantityInput.isEmpty ? p.border : p.foreground),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TiliSpace.md),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      const gap = TiliSpace.sm;
                      final keyW = (c.maxWidth - gap * 2) / 3;
                      final keyH = (c.maxHeight - gap * 3) / 4;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [for (final k in _keypad) SizedBox(width: keyW, height: keyH, child: _keypadKey(k))],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: TiliSpace.md),
        TiliButton(label: 'Carte', icon: Icons.credit_card, size: TiliButtonSize.lg, expand: true, onPressed: () => _pay('Carte')),
        const SizedBox(height: TiliSpace.sm),
        Row(
          children: [
            Expanded(
              child: TiliButton(label: 'Espèces', icon: Icons.payments_outlined, variant: TiliButtonVariant.outline, size: TiliButtonSize.lg, onPressed: () => _pay('Espèces')),
            ),
            const SizedBox(width: TiliSpace.sm),
            Expanded(
              child: TiliButton(label: 'Multiple', icon: Icons.call_split, variant: TiliButtonVariant.outline, size: TiliButtonSize.lg, onPressed: () => _pay('Multiple')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _orderTab(int index) {
    final p = context.palette;
    final order = _orders[index];
    final selected = index == _activeOrderIndex;
    final mutedColor = selected ? p.onInkMuted : p.textSubtle;
    return FilterPill(
      label: 'Commande ${order.number}',
      icon: Icons.receipt_long_outlined,
      selected: selected,
      onTap: () => _selectOrder(index),
      trailing: order.cartItems.isNotEmpty
          ? Text(formatEuro(_orderTotal(order)), style: context.text.labelLarge?.copyWith(color: selected ? p.accentSoft : p.accentStrong))
          : _orders.length > 1
              ? InkWell(
                  onTap: () => _closeOrder(index),
                  borderRadius: TiliRadius.all(TiliRadius.pill),
                  child: Tooltip(message: 'Fermer la commande', child: Icon(Icons.close, size: TiliSizes.iconSm, color: mutedColor)),
                )
              : null,
    );
  }

  Widget _orderBar() {
    return SizedBox(
      height: TiliSizes.buttonMd,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _orders.length,
              separatorBuilder: (_, _) => const SizedBox(width: TiliSpace.sm),
              itemBuilder: (context, index) => _orderTab(index),
            ),
          ),
          const SizedBox(width: TiliSpace.sm),
          TiliButton(label: 'Nouvelle commande', icon: Icons.add, variant: TiliButtonVariant.soft, onPressed: _newOrder),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TiliSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 5, child: _catalogPanel()),
                    const SizedBox(width: TiliSpace.lg),
                    Expanded(flex: 3, child: _cartPanel()),
                    const SizedBox(width: TiliSpace.lg),
                    Expanded(flex: 3, child: _actionPanel()),
                  ],
                ),
              ),
              const SizedBox(height: TiliSpace.md),
              _orderBar(),
            ],
          ),
        ),
      ),
    );
  }
}

/* One open order of the till: its cart and the keypad state tied to it, so
switching orders restores exactly what the cashier was typing. */
class _Order {
  _Order(this.number);

  final int number;
  final List<Map<String, dynamic>> cartItems = [];
  dynamic selectedProduct;
  String quantityInput = '';
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
    return TiliDialog(
      title: 'PIN administrateur',
      subtitle: 'Réservé aux administrateurs du commerce',
      icon: Icons.admin_panel_settings_outlined,
      width: 400,
      actions: [
        TiliButton(label: 'Annuler', variant: TiliButtonVariant.outline, onPressed: () => Navigator.of(context).pop()),
        TiliButton(label: 'Valider', onPressed: _submitPin),
      ],
      child: PinField(controller: _pinController, onSubmitted: (_) => _submitPin()),
    );
  }
}
