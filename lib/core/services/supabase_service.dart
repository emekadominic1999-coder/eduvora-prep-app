import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Single entry point to the Supabase client.
///
/// Eduvora Prep requires a backend — there is no Campus-Mode equivalent here,
/// because the portal (news, forum, marketplace) only means anything shared
/// between students. `initialise` still fails soft rather than crashing the
/// splash screen, so a missing or wrong credential shows a clear error
/// instead of a blank page.
class SupabaseService {
  const SupabaseService._();

  static bool _ready = false;
  static String? _initError;

  static bool get isReady => _ready;
  static String? get initError => _initError;

  static SupabaseClient get client {
    if (!_ready) {
      throw StateError(
        'Supabase is not configured. Guard calls with SupabaseService.isReady.',
      );
    }
    return Supabase.instance.client;
  }

  static GoTrueClient get auth => client.auth;

  static Session? get currentSession =>
      _ready ? Supabase.instance.client.auth.currentSession : null;

  static User? get currentUser =>
      _ready ? Supabase.instance.client.auth.currentUser : null;

  static Future<void> initialise() async {
    if (!AppConfig.hasBackend) {
      _initError = 'No Supabase credentials supplied at build time.';
      debugPrint('[Eduvora Prep] $_initError');
      return;
    }

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.error,
        ),
      );
      _ready = true;
      _initError = null;
      debugPrint('[Eduvora Prep] Connected to Supabase.');
    } catch (error, stack) {
      _ready = false;
      _initError = error.toString();
      debugPrint('[Eduvora Prep] Supabase initialisation failed: $error');
      debugPrintStack(stackTrace: stack, maxFrames: 6);
    }
  }
}
