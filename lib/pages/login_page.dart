import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_page.dart';
import 'setup_page.dart';
import '../services/token_service.dart';
import '../widgets/security_dialog.dart';

/* The LoginPage is a stateful widget that serves as the login screen for the
application. It checks for an existing authentication token on initialization
and navigates to the SetupPage if no token is found. The page includes a text
field for entering an access code (PIN) and a button to log in. If the entered
PIN matches the stored administrator PIN, it navigates to the AppPage. The page
also provides a floating action button to disconnect the store, which prompts
the user with a security dialog to confirm the action before clearing tokens and
navigating back to the SetupPage. The UI is designed with a centered layout,
including an image, input field, and login button. */
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.isFullScreen,
    required this.onToggleFullScreen,
  });

  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;

  @override
  State<LoginPage> createState() => _LoginPageState();
}



/* The _LoginPageState class manages the state of the LoginPage widget. It includes
a text controller for the access code input field. In the initState method, it checks
for an existing authentication token using the TokenService. If no token is found, it
navigates to the SetupPage. The _seConnecter method handles the login process by
comparing the entered PIN with the stored administrator PIN. If they match, it navigates
to the AppPage; otherwise, it shows a SnackBar with an error message. The _disconnectStore
method prompts the user with a security dialog to confirm the logout action. If confirmed,
it clears the authentication and PIN tokens and navigates back to the SetupPage. The build
method constructs the UI of the login page, including an image, a text field for the access
code, and a login button. The floating action button allows the user to disconnect the store
or toggle full-screen mode. */
class _LoginPageState extends State<LoginPage> {
  final codeController = TextEditingController();

  /* In the initState method, it checks for an existing authentication token using the
  TokenService. If no token is found, it navigates to the SetupPage. This ensures that
  users who have not set up their credentials are directed to the setup process before
  accessing the login page. */
  @override
  void initState() {
    super.initState();
    TokenService.getToken(TokenType.shop).then((token) {
      if (token == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => SetupPage(
              isFullScreen: widget.isFullScreen,
              onToggleFullScreen: widget.onToggleFullScreen,
            ),
          ),
        );
      }
    });
  }

  /* The _seConnecter method handles the login process when the user taps the "Se connecter" button.
  It retrieves the entered PIN from the codeController and compares it with the stored administrator
  PIN retrieved from the TokenService. If the entered PIN matches the stored PIN, it navigates to
  the AppPage. If the PIN is incorrect, it displays a SnackBar with an error message indicating that
  the code is incorrect. This method ensures that only users with the correct administrator PIN can
  access the main application page. */
  Future<void> _seConnecter() async {
    final enteredPin = codeController.text;
    final storedPin = await TokenService.getToken(TokenType.pinAdmin);
    if (enteredPin == storedPin) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AppPage(
            isFullScreen: widget.isFullScreen,
            onToggleFullScreen: widget.onToggleFullScreen,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Code incorrect")),
      );
    }
  }

  /* The _disconnectStore method is responsible for handling the store disconnection
  process when the user taps the "Disconnect Store" button. It first prompts the user
  with a security dialog to confirm the logout action. If the user confirms,
  it deletes the authentication token and administrator PIN from the TokenService,
  effectively logging out the user. After clearing the tokens, it navigates back to
  the SetupPage, allowing the user to set up their credentials again if they wish to
  log in later. This method ensures that the store is securely disconnected and that
  any sensitive information is cleared from storage. */
  Future<void> _disconnectStore() async {
    final confirmed = await showSecurityDialog(context);
    if (confirmed) {
      await TokenService.deleteToken(TokenType.shop);
      await TokenService.deleteToken(TokenType.pinAdmin);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SetupPage(
            isFullScreen: widget.isFullScreen,
            onToggleFullScreen: widget.onToggleFullScreen,
          ),
        ),
      );
    }
  }

  /* The dispose method is overridden to clean up the codeController when the LoginPage
  is removed from the widget tree. This is important to prevent memory leaks by
  ensuring that the resources used by the TextEditingController are properly released
  when they are no longer needed. */
  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  /* The build method constructs the UI of the login page. It uses a Scaffold to provide
  the basic structure of the page, including a background color and a body that centers
  the content. The content consists of a Column that arranges an image, a text field
  for entering the access code, and a login button vertically. The text field is styled with
  an outlined border and centered text. The login button is an ElevatedButton with an icon and
  a label. The floating action button is a Row that includes a TextButton for disconnecting
  the store and an IconButton for toggling full-screen mode. The UI is designed to be simple
  and user-friendly, allowing users to easily log in or disconnect the store as needed. */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/tiliLogo.png', height: 250),
            const SizedBox(height: 25),
            SizedBox(
              width: 300,
              child: TextField(
                controller: codeController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                onSubmitted: (_) => _seConnecter(),
                decoration: InputDecoration(
                  hintText: "Code d'accès",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: _seConnecter,
                icon: const Icon(Icons.key),
                label: const Text('Se connecter'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _disconnectStore,
            icon: const Icon(Icons.logout),
            label: const Text("Disconnect Store"),
          ),
          IconButton(
            onPressed: widget.onToggleFullScreen,
            icon: Icon(
              widget.isFullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
            ),
          ),
        ],
      ),
    );
  }
}
