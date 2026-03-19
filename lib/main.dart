import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:start_hack_2026/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const App());
}
