import 'package:flutter/material.dart';
import 'credentials_page.dart';
import '../services/token_service.dart';
import '../widgets/category_bar.dart';
import '../widgets/sort_buttons.dart';
import '../widgets/quantity_stepper.dart';

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
  int selectedCategoryIndex = 3;
  final List<String> categories = [
    'Bière',
    'Vin',
    'Soda',
    'Jus',
    'Boisson Chaude',
    'Alimentaire'
  ];

  /* This method handles the logout process. It deletes the user token using the
  TokenService and then navigates the user back to the LoginPage. The pushReplacement
  method is used to replace the current page with the LoginPage, ensuring that
  the user cannot navigate back to the MainPage after logging out. The LoginPage
  is provided with the current fullscreen state and the callback to toggle
  fullscreen mode, allowing it to maintain the same functionality as the MainPage. */
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: IconButton(
        onPressed: _logout,
        icon: const Icon(Icons.logout),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CategoryBar(
                  categories: categories,
                  selectedIndex: selectedCategoryIndex,
                  onCategorySelected: (index) {
                    setState(() {
                      selectedCategoryIndex = index;
                    });
                  },
                ),
                const SizedBox(width: 40),
                const SortButtons(),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 6,
                itemBuilder: (context, index) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: QuantityStepper(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
