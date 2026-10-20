/// Environment configuration for Eduvora Prep.
///
/// Credentials are injected at build time so no secret is ever committed:
///
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=sb_publishable_...
/// ```
///
/// Unlike Eduvora, Eduvora Prep has no offline fallback — the portal (news,
/// scholarships, forum, marketplace) only makes sense against a shared
/// backend, so every build of this app is expected to carry both values.
class AppConfig {
  const AppConfig._();

  static const String appName = 'Eduvora Prep';
  static const String tagline = 'Past questions. Real results.';
  static const String supportEmail = 'hello@eduvora.ng';

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// Deep link registered in the Supabase dashboard for OAuth callbacks on
  /// mobile. Web uses the browser's own origin instead.
  static const String oauthRedirect =
      'com.eduvora.eduvora_prep://login-callback';

  /// True when a Supabase project has been wired up for this build.
  static bool get hasBackend =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  /// Storage bucket holding marketplace listing photos.
  static const String marketplaceImagesBucket = 'marketplace-images';

  /// A marketplace photo above this size is refused client-side.
  static const int maxImageBytes = 8 * 1024 * 1024;
}
