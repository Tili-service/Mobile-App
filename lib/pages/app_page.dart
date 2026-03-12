import 'package:flutter/material.dart';
import '../services/token_service.dart';
import '../widgets/category_bar.dart';
import '../widgets/sort_buttons.dart';
import '../widgets/quantity_stepper.dart';
import 'login_page.dart';

/* This widget represents the main page of the application after the user has
logged in. It displays a category bar, sorting options, and a list of items with
quantity steppers. */
class AppPage extends StatefulWidget {
  /* The constructor for AppPage, which takes a key as an optional parameter, as
  well as the current fullscreen state and a callback to toggle fullscreen mode. */
  const AppPage({
    super.key,
    required this.isFullScreen,
    required this.onToggleFullScreen,
  });

  /* The isFullScreen variable indicates whether the app is currently in
  fullscreen mode. The onToggleFullScreen callback is used to toggle the
  fullscreen state when the user interacts with the UI. These parameters allow
  the AppPage to manage and respond to changes in fullscreen status. */
  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;

  /* The createState method creates the mutable state for this widget. It returns
  an instance of _AppPageState, which contains the logic for managing the
  selected category, handling logout, and building the UI. */
  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  /* This variable tracks the index of the currently selected category in the
  category bar. It is initialized to 3, which corresponds to the "Jus" category
  in the list of categories. The selectedCategoryIndex is updated whenever the
  user selects a different category from the category bar, allowing the UI to
  reflect the current selection. */
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
  the user cannot navigate back to the AppPage after logging out. The LoginPage
  is provided with the current fullscreen state and the callback to toggle
  fullscreen mode, allowing it to maintain the same functionality as the AppPage. */
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

  /* The build method constructs the UI of the AppPage. It uses a Scaffold to
  provide the basic structure of the page, including a floating action button for
  logout and a body that contains the main content. The body consists of a Column
  with a Row at the top for the category bar and sorting options, followed by an Expanded
  widget that contains a ListView.builder to display a list of items, each with a
  QuantityStepper. The UI is designed to be responsive and visually appealing, with
  padding and spacing to ensure a clean layout. The CategoryBar and SortButtons are
  custom widgets that provide interactive elements for the user to select categories and
  sorting options, while the QuantityStepper allows the user to adjust the quantity of each
  item in the list. The overall design of the AppPage is focused on providing a user-friendly
  interface for browsing and managing items in the application. */
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