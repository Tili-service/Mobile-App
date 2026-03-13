import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';
import 'login_page.dart';

/* The SetupPage is a stateful widget that serves as the initial setup screen
for the application. It allows users to enter their email, password, and a PIN
to configure the application for the first time. The page includes input fields
for these credentials and a button to continue. When the user taps the "Continuer
button, it attempts to log in using the provided email and password. If the login
is successful, it saves the authentication token and PIN using the TokenService
and navigates to the LoginPage. If the login fails, it displays an error message
using a SnackBar. The page also includes a floating action button to toggle
full-screen mode. */
class SetupPage extends StatefulWidget {
  const SetupPage({
    super.key,
    required this.isFullScreen,
    required this.onToggleFullScreen,
  });

  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;

  @override
  State<SetupPage> createState() => _SetupPageState();
}



/* The _SetupPageState class manages the state of the SetupPage widget. It includes
text controllers for the email, password, and PIN input fields. The _continuer
method handles the login process by calling the AuthService's login method with the
provided email and password. If the login is successful, it saves the authentication
token and PIN using the TokenService and navigates to the LoginPage. If the login
fails, it shows a SnackBar with an error message. The build method constructs the UI
of the page, including the input fields and the continue button. The _buildInput
method is a helper function to create styled input fields for the email, password, and PIN. */
class _SetupPageState extends State<SetupPage> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final pinController = TextEditingController();

  /* The _continuer method is responsible for handling the login process when the user
  taps the "Continuer" button. It retrieves the email, password, and PIN from the
  respective text controllers, then calls the AuthService's login method with the email
  and password. If the login is successful and a token is returned, it saves the token
  and PIN using the TokenService and navigates to the LoginPage. If the login fails,
  it displays a SnackBar with an error message indicating that the connection failed. */
  Future<void> _continuer() async {
    final email = emailController.text;
    final password = passwordController.text;
    final pin = pinController.text;

    final token = await AuthService.login(email, password);
    if (token != null) {
      await TokenService.saveToken(TokenType.shop, token);
      await TokenService.saveToken(TokenType.pinAdmin, pin);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LoginPage(
            isFullScreen: widget.isFullScreen,
            onToggleFullScreen: widget.onToggleFullScreen,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur de connexion")),
      );
    }
  }

  /* The dispose method is overridden to clean up the text controllers when the widget
  is removed from the widget tree. This is important to prevent memory leaks and ensure
  that the controllers are properly disposed of when they are no longer needed. */
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    pinController.dispose();
    super.dispose();
  }

  /* The build method constructs the UI of the SetupPage. It uses a Scaffold to provide
  the basic structure of the page, including a background color and a body that centers
  the content. The content consists of a SingleChildScrollView that allows for scrolling
  if the content exceeds the screen height. Inside the scroll view, a Column is used to
  arrange the elements vertically, including an image, input fields for email, password,
  and PIN, and a continue button. The floating action button is included to allow users
  to toggle full-screen mode. The _buildInput method is called to create styled input fields
  for the email, password, and PIN. */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              _buildInput(emailController, "Email"),
              const SizedBox(height: 12),
              _buildInput(passwordController, "Password", obscure: true),
              const SizedBox(height: 12),
              _buildInput(pinController, "Définir un PIN (6 chiffres)", obscure: true),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: _continuer,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("Continuer"),
                ),
              )
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

  /* The _buildInput method is a helper function that creates a styled input field for the
  email, password, or PIN. It takes a TextEditingController, a hint text, and an optional
  obscure parameter to determine if the input should be obscured (for passwords). The method
  returns a SizedBox containing a TextField with the specified controller, hint text, and styling.
  The TextField is centered and has an outlined border with rounded corners. */
  Widget _buildInput(TextEditingController controller, String hint, {bool obscure = false}) {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
