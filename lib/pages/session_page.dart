import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/token_service.dart';
import '../services/auth_service.dart';
import 'main_page.dart';

/* The SessionPage is a stateful widget that represents the session screen of the application.
It displays the name of the store associated with the selected license and prompts the user
to enter a 6-digit PIN to continue. The page includes an input field for the PIN and a button
to submit the PIN. When the user taps the "Continuer" button, it checks if the entered PIN
is valid by calling the AuthService's getPin method. If the PIN is correct, it
navigates to the MainPage. If the PIN is incorrect, it shows a SnackBar with an error message
and clears the input field. The page also includes a floating action button to toggle
full-screen mode. */
class SessionPage extends StatefulWidget {
  const SessionPage({
    super.key,
    required this.license,
    required this.isFullScreen,
    required this.onToggleFullScreen,
  });

  final Map<String, dynamic> license;
  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;

  @override
  State<SessionPage> createState() => _SessionPageState();
}



/* The _SessionPageState class manages the state of the SessionPage widget. It includes
a TextEditingController for the PIN input field. The _checkPin method is responsible for
validating the entered PIN by calling the AuthService's getPin method with the authentication
token, the entered PIN, and the store ID. If the PIN is correct, it navigates to the MainPage.
If the PIN is incorrect, it shows a SnackBar with an error message and clears the input field.
The build method constructs the UI of the page, including the display of the store name, the
PIN input field, and the continue button. The floating action button allows the user to toggle
full-screen mode. */
class _SessionPageState extends State<SessionPage> {
  final pinController = TextEditingController();

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  /* The _checkPin method is responsible for validating the entered PIN. It first checks if the
  length of the entered PIN is 6 digits. If it is, it retrieves the authentication token and
  store ID from the TokenService. If both the token and store ID are available, it calls the
  AuthService's getPin method with the token, entered PIN, and store ID. If the result is not null
  (indicating a successful PIN validation), it navigates to the MainPage. If the result is
  null (indicating an incorrect PIN), it shows a SnackBar with an error message and clears the
  input field. If the entered PIN does not have 6 digits, it shows a SnackBar with a message
  indicating that the PIN must contain 6 digits. */
  void _checkPin() async {
    if (pinController.text.length == 6) {
      final token = await TokenService.getToken(TokenType.shop);
      final storeId = await TokenService.getToken(TokenType.license);
      if (token != null && storeId != null) {
        final result = await AuthService.getPin(token, pinController.text, storeId);
        if (result != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MainPage(
                isFullScreen: widget.isFullScreen,
                onToggleFullScreen: widget.onToggleFullScreen,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN incorrect')),
          );
          pinController.clear();
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le PIN doit contenir 6 chiffres')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.license['store']?['name'] ?? 'Session'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/tiliLogo.png',
                height: 250,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Entrez le PIN (6 chiffres)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                height: 45,
                child: ElevatedButton(
                  onPressed: _checkPin,
                  child: const Text('Continuer'),
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
