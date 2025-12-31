import 'package:flutter_test/flutter_test.dart';
import 'package:storili/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('tokenEndpoint has default value', () {
      expect(AppConfig.tokenEndpoint, isNotEmpty);
    });

    test('maxSessionDuration is 45 minutes', () {
      expect(AppConfig.maxSessionDuration, const Duration(minutes: 45));
    });

    test('idleWarningDuration is 5 minutes', () {
      expect(AppConfig.idleWarningDuration, const Duration(minutes: 5));
    });

    test('tokenTimeout is 10 seconds', () {
      expect(AppConfig.tokenTimeout, const Duration(seconds: 10));
    });

    test('connectTimeout is 15 seconds', () {
      expect(AppConfig.connectTimeout, const Duration(seconds: 15));
    });
  });
}
