import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_page.dart';
import 'setup_page.dart';
import '../services/token_service.dart';

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

class _LoginPageState extends State<LoginPage> {
  final codeController = TextEditingController();

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


  void _seConnecter() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => AppPage(
          isFullScreen: widget.isFullScreen,
          onToggleFullScreen: widget.onToggleFullScreen,
        ),
      ),
    );
  }

  @override
  void dispose() {
    codeController.dispose();
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
                  controller: codeController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _seConnecter(),
                  decoration: InputDecoration(
                    hintText: "Code d'accès",
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
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: _seConnecter,
                  icon: const Icon(
                    Icons.key,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Se connecter',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB04A46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 30.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                // 1. On crée un contrôleur spécifique pour le code de sécurité
                final securityCodeController = TextEditingController();
                String errorMessage = ''; // Pour afficher "Code incorrect"

                showDialog(
                  context: context,
                  builder: (context) {
                    // 2. Le StatefulBuilder permet de mettre à jour le contenu de l'alerte
                    return StatefulBuilder(
                      builder: (context, setDialogState) {
                        return AlertDialog(
                          title: const Text('Déconnexion sécurisée'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min, // S'adapte au contenu
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                  "Veuillez entrer le code administrateur pour déconnecter la boutique :"),
                              const SizedBox(height: 15),
                              TextField(
                                controller: securityCodeController,
                                obscureText: true,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                decoration: InputDecoration(
                                  hintText: "Code PIN",
                                  errorText: errorMessage.isNotEmpty ? errorMessage : null,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () async {
                                String? pinCode = await TokenService.getToken(TokenType.pinAdmin);
                                if (securityCodeController.text ==  pinCode) {
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
                                } else {
                                  // Code faux : on affiche l'erreur dans l'alerte
                                  setDialogState(() {
                                    errorMessage = "Code incorrect, veuillez réessayer.";
                                  });
                                }
                              },
                              child: const Text(
                                'Déconnecter',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
              icon: const Icon(Icons.logout, color: Colors.grey),
              label: const Text(
                'Disconnect Store',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            SizedBox(
              width: 50,
              height: 50,
              child: IconButton(
                onPressed: widget.onToggleFullScreen,
                icon: Icon(
                  widget.isFullScreen
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen,
                  color: Colors.grey,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}