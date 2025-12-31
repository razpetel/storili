import 'package:flutter_test/flutter_test.dart';
import 'package:storili/services/permission_service.dart';

void main() {
  group('MicPermissionStatus', () {
    test('has all expected values', () {
      expect(MicPermissionStatus.values, containsAll([
        MicPermissionStatus.granted,
        MicPermissionStatus.denied,
        MicPermissionStatus.permanentlyDenied,
        MicPermissionStatus.restricted,
      ]));
    });
  });

  group('MockPermissionService', () {
    test('returns configured status for check', () async {
      final service = MockPermissionService(
        checkResult: MicPermissionStatus.granted,
        requestResult: MicPermissionStatus.granted,
      );

      final status = await service.checkMicrophone();
      expect(status, MicPermissionStatus.granted);
    });

    test('returns configured status for request', () async {
      final service = MockPermissionService(
        checkResult: MicPermissionStatus.denied,
        requestResult: MicPermissionStatus.granted,
      );

      final checkStatus = await service.checkMicrophone();
      expect(checkStatus, MicPermissionStatus.denied);

      final requestStatus = await service.requestMicrophone();
      expect(requestStatus, MicPermissionStatus.granted);
    });

    test('tracks openSettings calls', () async {
      final service = MockPermissionService(
        checkResult: MicPermissionStatus.permanentlyDenied,
        requestResult: MicPermissionStatus.permanentlyDenied,
      );

      expect(service.openSettingsCallCount, 0);
      await service.openSettings();
      expect(service.openSettingsCallCount, 1);
    });
  });
}
