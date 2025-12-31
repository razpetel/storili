import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storili/app/router.dart';
import 'package:storili/app/theme.dart';

class StoriliApp extends StatelessWidget {
  const StoriliApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Lock to portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp.router(
      title: 'Storili',
      theme: StoriliTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
