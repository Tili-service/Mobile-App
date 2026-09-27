import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';

import '../pages/credentials_page.dart';
import '../theme/theme.dart';

/* App root: owns the fullscreen state (passed down to every page for the
toggle button) and always starts on the merchant login screen. */
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
    if (!mounted) return;
    setState(() => isFullScreen = FullScreen.isFullScreen);
  }

  void toggleFullScreen() {
    FullScreen.setFullScreen(!isFullScreen);
  }

  @override
  void onFullScreenChanged(bool enabled, SystemUiMode? systemUiMode) {
    if (!mounted) return;
    setState(() => isFullScreen = enabled);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: TiliTheme.light(),
      home: CredentialsPage(
        isFullScreen: isFullScreen,
        onToggleFullScreen: toggleFullScreen,
      ),
    );
  }
}
