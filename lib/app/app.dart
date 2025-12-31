import 'package:flutter/material.dart';
import 'package:storili/app/router.dart';
import 'package:storili/app/theme.dart';

class StoriliApp extends StatelessWidget {
  const StoriliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Storili',
      theme: StoriliTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
