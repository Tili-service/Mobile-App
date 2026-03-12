import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'login.dart';
import 'setup.dart';
import 'services/token_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FullScreen.ensureInitialized();
  FullScreen.setFullScreen(true);
  runApp(const TiliRoot());
}

class TiliRoot extends StatefulWidget {
  const TiliRoot({super.key});

  @override
  State<TiliRoot> createState() => _TiliRootState();
}

class _TiliRootState extends State<TiliRoot> with FullScreenListener {
  bool isFullScreen = false;

  @override
  void initState() {
    super.initState();
    FullScreen.addListener(this);
    _initializeFullScreenState();
  }

  @override
  void dispose() {
    FullScreen.removeListener(this);
    super.dispose();
  }

  Future<void> _initializeFullScreenState() async {
    await FullScreen.ensureInitialized();

    if (!mounted) {
      return;
    }

    setState(() {
      isFullScreen = FullScreen.isFullScreen;
    });
  }

  void toggleFullScreen() {
    FullScreen.setFullScreen(!isFullScreen);
  }

  @override
  void onFullScreenChanged(bool enabled, SystemUiMode? systemUiMode) {
    if (!mounted) {
      return;
    }

    setState(() {
      isFullScreen = enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:  FutureBuilder<List<String?>>(
          future: Future.wait([
            TokenService.getToken(TokenType.shop),
            TokenService.getToken(TokenType.pinAdmin)
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final shopToken = snapshot.data?[0];
            final pinAdminToken = snapshot.data?[1];

            if (shopToken == null || pinAdminToken == null) {
              return SetupPage(
                isFullScreen: isFullScreen,
                onToggleFullScreen: toggleFullScreen,
              );
            } else {
              return LoginPage(
                isFullScreen: isFullScreen,
                onToggleFullScreen: toggleFullScreen,
              );
            }
          },
        ), 
    );
  }
}