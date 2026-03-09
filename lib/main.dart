import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tili App',
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),
      home: const PageConnexion(),
    );
  }
}

class PageConnexion extends StatefulWidget {
  const PageConnexion({super.key});

  @override
  State<PageConnexion> createState() => _PageConnexionState();
}

class _PageConnexionState extends State<PageConnexion> {
  final codeController = TextEditingController();

  void _seConnecter() {
    print("Code entré : ${codeController.text}");
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
                  onSubmitted: (valeur) {
                    _seConnecter();
                  },

                  decoration: InputDecoration(
                    hintText: "Code d'accès",
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
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
    );
  }
}