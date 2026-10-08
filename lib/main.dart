import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/tili_root.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await FullScreen.ensureInitialized();
  try {
    await dotenv.load();
  } catch (e) {
    debugPrint('Error loading .env file: $e');
  }
  FullScreen.setFullScreen(true);

  runApp(const TiliRoot());
}
