import 'package:flutter/material.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'app/tili_root.dart';

void main() async {
  /* Initialize Flutter and the fullscreen plugin before running the app */
  WidgetsFlutterBinding.ensureInitialized();
  await FullScreen.ensureInitialized();
  FullScreen.setFullScreen(true);

  /* Run the main app widget */
  runApp(const TiliRoot());
}
