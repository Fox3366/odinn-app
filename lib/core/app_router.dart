import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/main_screen.dart';

abstract class AppRouter {
  static const String splash = '/';
  static const String main   = '/main';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    main:   (_) => const MainScreen(),
  };
}