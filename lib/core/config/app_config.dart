/// Build-time switches. Enable Firebase with `--dart-define=USE_FIREBASE=true`
/// after running `flutterfire configure`.
abstract final class AppConfig {
  static const useFirebase = bool.fromEnvironment('USE_FIREBASE');
  static const appName = 'Fabric2Fit';
  static const tagline = 'From Your Fabric to Your Perfect Fit';
}
