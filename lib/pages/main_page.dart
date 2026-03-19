import 'package:flutter/material.dart';
import 'credentials_page.dart';
import '../services/token_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/* This widget represents the main page of the application after the user has
logged in. It displays a category bar, sorting options, and a list of items with
quantity steppers. */
class MainPage extends StatefulWidget {
  const MainPage({
    super.key,
    required this.isFullScreen,
    required this.onToggleFullScreen,
  });

  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<String> _categories = [
    'Tous',
    'Boissons',
    'Snacks',
    'Desserts',
    'Couverts',
    'Sauces',
    'Autres'
  ];

  String _selectedCategory = 'Tous';

  void _logout() {
    TokenService.deleteToken(TokenType.user);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CredentialsPage(
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
              backgroundColor: isDigit ? const Color(0xFF3BB273) : const Color(0xFFE1BC29),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              print('Pressed $label');
            },
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
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
    final safeHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - kToolbarHeight;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: _logout,
          icon: const Icon(Icons.logout),
        ),
        title: const Text('Tili'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement settings
              print('Settings pressed');
            },
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
                    SizedBox(
                      height: 60, // Fixed height for the category buttons row
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((category) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: category == _selectedCategory
                                  ? const Color(0xFFE15554)
                                  : Colors.grey[300],
                                foregroundColor: category == _selectedCategory
                                  ? Colors.white
                                  : Colors.black,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = category;
                                });
                                print('Selected $category');
                              },
                              child: Text(category),
                            ),
                          )).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        // Placeholder for the catalog items list
                        color: Colors.grey[200],
                        child: const Center(
                          child: Text('Vos articles apparaîtront ici'),
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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF7768AE),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.only(top: 16, bottom: 16),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          'Votre commande',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: spacing),
                    child: SizedBox(
                      width: partWidth - spacing / 2,
                      height: safeHeight,
                      child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(8.0),
                            margin: const EdgeInsets.only(right: 16, top: 16),
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
                        SizedBox(height: spacing),
                        Expanded(
                          child: Container(
                            width: partWidth - spacing / 2,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(right: 16, bottom: 16),
                            color: Colors.white,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 100,
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    child: const Text('Carte'),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 100,
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    child: const Text('Espèces'),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 100,
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
