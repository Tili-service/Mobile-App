import 'package:flutter/material.dart';
import '../services/token_service.dart';

/* The showSecurityDialog function displays a dialog that prompts the user to
enter an administrator PIN code to confirm a secure logout action. It uses a
StatefulBuilder to manage the state of the dialog, allowing it to display error
messages if the entered PIN code is incorrect. The function returns a Future<bool>
that indicates whether the user successfully entered the correct PIN code (true)
or canceled the action (false). The dialog includes a TextField for PIN input and
two buttons: "Annuler" to cancel the action and "Déconnecter" to attempt the logout.
If the entered PIN code matches the stored administrator PIN, the dialog returns
true; otherwise, it displays an error message and allows the user to try again. */
Future<bool> showSecurityDialog(BuildContext context) async {
  final securityCodeController = TextEditingController();
  String errorMessage = '';
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Déconnexion sécurisée'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Veuillez entrer le code administrateur pour déconnecter la boutique :",
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: securityCodeController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: "Code PIN",
                    errorText:
                        errorMessage.isNotEmpty ? errorMessage : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () async {
                  String? pinCode =
                      await TokenService.getToken(TokenType.pinAdmin);

                  if (securityCodeController.text == pinCode) {
                    Navigator.pop(context, true);
                  } else {
                    setDialogState(() {
                      errorMessage =
                          "Code incorrect, veuillez réessayer.";
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
  return result ?? false;
}
