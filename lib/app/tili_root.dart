import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';

import '../pages/credentials_page.dart';
import '../services/token_service.dart';

/* This widget serves as the root of the application, managing the initial
setup and login flow based on token presence. */
class TiliRoot extends StatefulWidget {
  const TiliRoot({super.key});

  @override
  State<TiliRoot> createState() => _TiliRootState();
}


/* The state of TiliRoot manages the fullscreen state and determines which
page to show based on the presence of tokens. It listens for fullscreen changes
and updates the UI accordingly. */
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

  /* This method initializes the fullscreen state by checking the current
  status of fullscreen mode. It is called during initialization to set the
  correct state of the app. If the widget is not mounted when the fullscreen
  state is checked, we simply return to avoid trying to update the state of an
  unmounted widget. */
  Future<void> _initializeFullScreenState() async {
    await FullScreen.ensureInitialized();
    if (!mounted) {
      return;
    }

    setState(() {
      isFullScreen = FullScreen.isFullScreen;
    });
  }

  /* This method toggles the fullscreen mode on or off. It is called when the
  user interacts with the UI to change the fullscreen state. The method uses
  the FullScreen.setFullScreen method to update the fullscreen status. */
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
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return CredentialsPage(
              isFullScreen: isFullScreen,
              onToggleFullScreen: toggleFullScreen,
            );
          },
        ),
    );
  }
}
