import 'package:permission_handler/permission_handler.dart';

enum MicPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

abstract class PermissionService {
  Future<MicPermissionStatus> checkMicrophone();
  Future<MicPermissionStatus> requestMicrophone();
  Future<void> openSettings();
}

class PermissionServiceImpl implements PermissionService {
  @override
  Future<MicPermissionStatus> checkMicrophone() async {
    final status = await Permission.microphone.status;
    return _mapStatus(status);
  }

  @override
  Future<MicPermissionStatus> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return _mapStatus(status);
  }

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }

  MicPermissionStatus _mapStatus(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted || PermissionStatus.limited => MicPermissionStatus.granted,
      PermissionStatus.permanentlyDenied => MicPermissionStatus.permanentlyDenied,
      PermissionStatus.restricted => MicPermissionStatus.restricted,
      _ => MicPermissionStatus.denied,
    };
  }
}

class MockPermissionService implements PermissionService {
  final MicPermissionStatus checkResult;
  final MicPermissionStatus requestResult;
  int _openSettingsCallCount = 0;

  MockPermissionService({
    required this.checkResult,
    required this.requestResult,
  });

  int get openSettingsCallCount => _openSettingsCallCount;

  @override
  Future<MicPermissionStatus> checkMicrophone() async => checkResult;

  @override
  Future<MicPermissionStatus> requestMicrophone() async => requestResult;

  @override
  Future<void> openSettings() async {
    _openSettingsCallCount++;
  }
}
