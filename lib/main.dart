import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/tili_root.dart';

void main() async {
  /* Initialize Flutter and the fullscreen plugin before running the app */
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await FullScreen.ensureInitialized();
  try {
    await dotenv.load();
  } catch (e) {
    print('Error loading .env file: $e');
  }
  FullScreen.setFullScreen(true);

  /* Run the main app widget */
  runApp(const TiliRoot());
}
