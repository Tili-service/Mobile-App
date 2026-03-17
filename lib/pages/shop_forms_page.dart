import 'package:flutter/material.dart';
import '../services/token_service.dart';
import '../services/store_service.dart';
import 'session_page.dart';

/* The ShopFormsPage is a stateful widget that represents the form for
creating a new store. It includes input fields for the store name, SIRET number,
and TVA number, as well as a submit button to create the store. The page also
includes a floating action button to toggle full-screen mode. */
class ShopFormsPage extends StatefulWidget {
  const ShopFormsPage({
    super.key,
    required this.license,
    required this.isFullScreen,
    required this.onToggleFullScreen,
  });

  final Map<String, dynamic> license;
  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;

  @override
  State<ShopFormsPage> createState() => _ShopFormsPageState();
}



/* The _ShopFormsPageState class manages the state of the ShopFormsPage widget. It includes
text controllers for the store name, SIRET number, and TVA number input fields. The
_submit method handles the submission of the form by retrieving the authentication token,
calling the StoreService's createStore method with the provided information, and navigating
to the SessionPage if the store is successfully created. If there is an error during store
creation, it shows a SnackBar with an error message. The build method constructs the UI of the
page, including the input fields and the submit button. The floating action button allows the
user to toggle full-screen mode. */
class _ShopFormsPageState extends State<ShopFormsPage> {
  final nameController = TextEditingController();
  final siretController = TextEditingController();
  final tvaController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    siretController.dispose();
    tvaController.dispose();
    super.dispose();
  }

  /* The _submit method is responsible for handling the form submission when the user
  taps the "CONFIRMER" button. It retrieves the authentication token from the TokenService
  and calls the StoreService's createStore method with the token, license ID, store name,
  SIRET number, and TVA number. If the store is successfully created and a store ID is returned,
  it saves the store ID as a token and navigates to the SessionPage. If there is an error
  during store creation, it shows a SnackBar with an error message indicating that there
  was an issue creating the store. This method ensures that the user can only proceed to
  the next step if the store is successfully created, providing feedback in case of errors. */
  void _submit() async {
    final token = await TokenService.getToken(TokenType.shop);
    if (token != null) {
      final result = await StoreService.createStore(
        token,
        widget.license['licence_id'],
        nameController.text,
        tvaController.text,
        siretController.text,
      );
      if (result != null) {
        final storeId = result['store_id']?.toString();
        if (storeId != null) {
          await TokenService.saveToken(TokenType.license, storeId);
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SessionPage(
              license: widget.license,
              isFullScreen: widget.isFullScreen,
              onToggleFullScreen: widget.onToggleFullScreen,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création du commerce')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOUVEAU COMMERCE'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/tiliLogo.png',
                height: 150,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: 500,
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'NOM DU COMMERCE',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 500,
                child: TextField(
                  controller: siretController,
                  decoration: const InputDecoration(
                    labelText: 'NUMÉROS SIRET (ex: 12345678901234)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 500,
                child: TextField(
                  controller: tvaController,
                  decoration: const InputDecoration(
                    labelText: 'NUMÉROS TVA (ex: FR12345678901)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 250,
                height: 45,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('CONFIRMER'),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: IconButton(
        onPressed: widget.onToggleFullScreen,
        icon: Icon(
          widget.isFullScreen
              ? Icons.fullscreen_exit
              : Icons.fullscreen,
        ),
      ),
    );
  }
}
