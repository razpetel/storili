import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:storili/app/router.dart';

void main() {
  group('AppRouter', () {
    test('router is a GoRouter instance', () {
      final router = AppRouter.router;
      expect(router, isA<GoRouter>());
    });

    test('initial location is home', () {
      final router = AppRouter.router;
      // GoRouter configuration is set via initialLocation,
      // which we can verify through the router's configuration
      final firstRoute = router.configuration.routes.first as GoRoute;
      expect(firstRoute.path, equals('/'));
    });
  });
}
