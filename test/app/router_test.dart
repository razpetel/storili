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
      // Verify the initial location via the route information provider
      expect(router.routeInformationProvider.value.uri.path, equals('/'));
    });
  });
}
