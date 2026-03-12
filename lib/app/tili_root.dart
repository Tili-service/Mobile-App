import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';

import '../pages/login_page.dart';
import '../pages/setup_page.dart';
import '../services/token_service.dart';

/* This widget serves as the root of the application, managing the initial
setup and login flow based on token presence. */
class TiliRoot extends StatefulWidget {
  /* The constructor for TiliRoot, which takes a key as an optional parameter. */
  const TiliRoot({super.key});

  /* The createState method creates the mutable state for this widget. It
  returns an instance of _TiliRootState, which contains the logic for managing
  the fullscreen state and determining which page to show based on token presence. */
  @override
  State<TiliRoot> createState() => _TiliRootState();
}


/* The state of TiliRoot manages the fullscreen state and determines which
page to show based on the presence of tokens. It listens for fullscreen changes
and updates the UI accordingly. */
class _TiliRootState extends State<TiliRoot> with FullScreenListener {
  /* This variable tracks whether the app is currently in fullscreen mode. It
  is initialized in the initState method and updated whenever the fullscreen
  state changes. */
  bool isFullScreen = false;

  /* When the state is initialized, we set up the fullscreen listener and check
  the initial fullscreen state. This ensures that the app starts in the correct
  mode and can respond to changes in fullscreen status. */
  @override
  void initState() {
    super.initState();
    FullScreen.addListener(this);
    _initializeFullScreenState();
  }

  /* When the widget is disposed, we remove the fullscreen listener to prevent
  memory leaks. This is important to ensure that the app remains efficient and
  does not consume unnecessary resources when the widget is no longer in use. */
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

  /* This method is called whenever the fullscreen state changes. It updates
  the isFullScreen variable to reflect the new state. If the widget is not
  mounted when the fullscreen state changes, we simply return to avoid trying
  to update the state of an unmounted widget. */
  @override
  void onFullScreenChanged(bool enabled, SystemUiMode? systemUiMode) {
    if (!mounted) {
      return;
    }

    setState(() {
      isFullScreen = enabled;
    });
  }

  /* The build method determines which page to show based on the presence of
  tokens. It uses a FutureBuilder to asynchronously check for the shop and
  admin PIN tokens. If either token is missing, it shows the SetupPage; if
  both tokens are present, it shows the LoginPage. The MaterialApp widget is
  used to provide the app's theme and navigation structure. */
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
