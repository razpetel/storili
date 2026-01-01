class AppConfig {
  AppConfig._();

  static const tokenEndpoint = String.fromEnvironment(
    'TOKEN_ENDPOINT',
    defaultValue: 'https://storili-token-dev.razpetel.workers.dev',
  );

  static const maxSessionDuration = Duration(minutes: 45);
  static const idleWarningDuration = Duration(minutes: 5);
  static const idleGracePeriod = Duration(seconds: 30);
  static const backgroundGracePeriod = Duration(seconds: 30);
  static const tokenTimeout = Duration(seconds: 10);
  static const connectTimeout = Duration(seconds: 15);
}
