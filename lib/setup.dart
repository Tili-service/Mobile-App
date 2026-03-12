import 'package:flutter/material.dart';
import 'login.dart';
import 'package:http/http.dart' as http; // Le package pour les requêtes
import 'dart:convert';
import 'services/token_service.dart';

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

class _SetupPageState extends State<SetupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final pinController = TextEditingController();

  Future<void> _continuer() async {
    final email = emailController.text;
    final password = passwordController.text;
    final pin = pinController.text;

    print("Email entré : $email");
    print("Password entré : $password");
    print("PIN entré : $pin");

    final url = Uri.parse('http://10.0.2.2:8080/users/login');
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json", // Optionnel mais bonne pratique
        },
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await TokenService.saveToken(TokenType.shop, data['token']);
          await TokenService.saveToken(TokenType.pinAdmin, pin);
        } else {
          print("Le token n'est pas présent dans la réponse.");
        }
        print("Connexion réussie ! Réponse : $data");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LoginPage(
              isFullScreen: widget.isFullScreen,
              onToggleFullScreen: widget.onToggleFullScreen,
            ),
          ),
        );
      } else {
        // Le serveur a répondu une erreur (ex: 401 Mauvais mot de passe, 404 Non trouvé)
        print("Erreur de connexion. Code serveur : ${response.statusCode}");
      }
      
    } catch (e) {
      // S'il y a un problème de réseau (pas d'internet, serveur éteint...)
      print("Erreur réseau : $e");
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/tiliLogo.png', height: 250),
              const SizedBox(height: 25),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: emailController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: passwordController,
                  textAlign: TextAlign.center,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: pinController,
                  textAlign: TextAlign.center,
                  obscureText: true,
                  maxLength: 6,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Definir un code PIN (6 chiffres)',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: _continuer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF548687),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Continuer',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        width: 50,
        height: 50,
        child: IconButton(
          onPressed: widget.onToggleFullScreen,
          icon: Icon(
            widget.isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
            color: Colors.grey,
            size: 24,
          ),
        ),
      ),
    );
  }
}
