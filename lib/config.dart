/// App-wide configuration. Secrets are injected at build time with
/// `--dart-define`, never committed to source control.
class AppConfig {
  static const openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const openAiModel =
      String.fromEnvironment('OPENAI_MODEL', defaultValue: 'gpt-4o-mini');

  /// Default dial code prepended to the phone number typed on the login screen.
  static const defaultDialCode = '+91';

  static const departments = ['MCA', 'MBA', 'CSE', 'IT', 'ECE', 'MECH', 'CIVIL'];
  static const years = [1, 2, 3, 4];

  /// Fallback map centre (Mumbai) when no bus has reported a position yet.
  static const defaultMapLat = 19.0760;
  static const defaultMapLng = 72.8777;

  /// A bus that has not reported for this long is shown as "offline".
  static const busStaleAfter = Duration(minutes: 2);
}
