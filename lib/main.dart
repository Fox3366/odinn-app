import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_theme.dart';
import 'core/app_router.dart';
import 'services/mavlink_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MavlinkService().init();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light),
  );
  runApp(const OdinApp());
}

class OdinApp extends StatelessWidget {
  const OdinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ODİN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: AppRouter.splash,
      routes: AppRouter.routes,
    );
  }
}