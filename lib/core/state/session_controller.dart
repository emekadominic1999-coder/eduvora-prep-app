import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/student.dart';
import '../services/supabase_service.dart';

/// Where the app is in the sign-in → onboarding → dashboard journey.
enum AuthStatus {
  /// Still restoring a persisted session.
  unknown,

  /// No student is signed in; the sign-in screen is shown.
  signedOut,

  /// Signed in, but the academic identity has not been chosen yet.
  needsOnboarding,

  /// Fully set up; the portal is shown.
  ready,
}

/// Raised for any expected authentication failure so the UI can show a calm,
/// plain-English message instead of a raw exception.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Owns the authentication session and the signed-in student's profile.
///
/// Eduvora Prep requires a backend — unlike Eduvora there is no offline
/// Campus Mode fallback here, because the whole point of accounts is a
/// portal shared between students (news, forum, marketplace) and progress
/// that follows them between devices.
class SessionController extends ChangeNotifier {
  SessionController();

  AuthStatus _status = AuthStatus.unknown;
  StudentProfile? _profile;
  bool _busy = false;
  Future<void>? _bootstrapping;

  AuthStatus get status => _status;
  StudentProfile? get profile => _profile;
  bool get isBusy => _busy;
  bool get isSignedIn =>
      _status == AuthStatus.ready || _status == AuthStatus.needsOnboarding;

  // ------------------------------------------------------------- bootstrap

  Future<void> bootstrap() async {
    if (!SupabaseService.isReady) {
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    try {
      final sb.Session? session = SupabaseService.currentSession;
      if (session != null) {
        await _loadRemoteProfile(session.user);
      } else {
        _status = AuthStatus.signedOut;
      }
    } catch (error) {
      debugPrint('[Eduvora Prep] bootstrap failed: $error');
      _status = AuthStatus.signedOut;
    }
    notifyListeners();
  }

  Future<void> ensureLoaded() async {
    if (_profile != null) return;
    if (_bootstrapping != null) {
      await _bootstrapping;
      return;
    }
    _bootstrapping = bootstrap();
    try {
      await _bootstrapping;
    } finally {
      _bootstrapping = null;
    }
  }

  /// Lets widget tests drive the app past the sign-in screen without a real
  /// backend. Never call this outside a test.
  @visibleForTesting
  void setProfileForTest(StudentProfile profile) {
    _profile = profile;
    _status =
        profile.isComplete ? AuthStatus.ready : AuthStatus.needsOnboarding;
    notifyListeners();
  }

  @visibleForTesting
  void resetForTest() {
    _profile = null;
    _status = AuthStatus.unknown;
    _busy = false;
  }

  // ------------------------------------------------------- email & password

  Future<void> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _setBusy(true);
    await Future<void>.value();
    try {
      final String cleanEmail = email.trim().toLowerCase();
      final sb.AuthResponse response = await SupabaseService.auth.signUp(
        email: cleanEmail,
        password: password,
        data: <String, dynamic>{'full_name': fullName.trim()},
      );
      final sb.User? user = response.user;
      if (user == null || response.session == null) {
        throw const AuthFailure(
          'Almost done! We sent a confirmation link to your email. Open it, '
          'then come back here and sign in.',
        );
      }
      await _loadRemoteProfile(user, fallbackName: fullName.trim());
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setBusy(true);
    await Future<void>.value();
    try {
      final String cleanEmail = email.trim().toLowerCase();
      final sb.AuthResponse response = await SupabaseService.auth
          .signInWithPassword(email: cleanEmail, password: password);
      final sb.User? user = response.user;
      if (user == null) {
        throw const AuthFailure(
          'We could not sign you in. Please check your details and try '
          'again.',
        );
      }
      await _loadRemoteProfile(user);
    } finally {
      _setBusy(false);
    }
  }

  /// Starts the Google OAuth flow through Supabase. The session itself
  /// arrives asynchronously through [listenToAuthChanges].
  Future<bool> signInWithGoogle() async {
    _setBusy(true);
    await Future<void>.value();
    try {
      return await SupabaseService.auth.signInWithOAuth(
        sb.OAuthProvider.google,
        redirectTo: kIsWeb ? null : null,
        authScreenLaunchMode: kIsWeb
            ? sb.LaunchMode.platformDefault
            : sb.LaunchMode.externalApplication,
      );
    } finally {
      _setBusy(false);
    }
  }

  void listenToAuthChanges() {
    if (!SupabaseService.isReady) return;
    SupabaseService.auth.onAuthStateChange.listen(
      (sb.AuthState event) async {
        final sb.Session? session = event.session;
        if (session == null) {
          if (_status == AuthStatus.signedOut) return;
          // A settle window: a transient null during token refresh must not
          // be mistaken for a real sign-out and tear the app down.
          const Duration pollInterval = Duration(milliseconds: 1000);
          const int maxPolls = 8;
          for (int i = 0; i < maxPolls; i++) {
            await Future<void>.delayed(pollInterval);
            if (SupabaseService.currentSession != null) return;
          }
          if (_status != AuthStatus.signedOut) {
            _profile = null;
            _status = AuthStatus.signedOut;
            notifyListeners();
          }
          return;
        }
        if (_profile?.id != session.user.id) {
          await _loadRemoteProfile(session.user);
          notifyListeners();
        }
      },
      onError: (Object error) =>
          debugPrint('[Eduvora Prep] auth stream error: $error'),
    );
  }

  // --------------------------------------------------------------- profile

  Future<void> _loadRemoteProfile(
    sb.User user, {
    String fallbackName = '',
  }) async {
    Map<String, dynamic>? row;
    try {
      row = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    } catch (error) {
      debugPrint('[Eduvora Prep] profile fetch failed: $error');
    }

    if (row != null) {
      _profile = StudentProfile.fromRow(row);
    } else {
      // The handle_new_user() trigger usually wins the race, but fall back
      // to a fresh local profile so the student is never stuck.
      _profile = StudentProfile.empty(
        user.id,
        user.email ?? '',
        fallbackName.isNotEmpty
            ? fallbackName
            : (user.userMetadata?['full_name'] as String? ?? ''),
      );
    }
    _status = (_profile?.isComplete ?? false)
        ? AuthStatus.ready
        : AuthStatus.needsOnboarding;
    notifyListeners();
  }

  /// Saves the academic identity chosen during onboarding, or later edits.
  Future<void> saveProfile(StudentProfile updated) async {
    // Deferring past the first synchronous frame means a thrown error
    // (Supabase not ready) surfaces as a normal Future error rather than a
    // synchronous crash — see the matching note on the repository classes.
    await Future<void>.value();
    _setBusy(true);
    _profile = updated;
    _status =
        updated.isComplete ? AuthStatus.ready : AuthStatus.needsOnboarding;
    notifyListeners();
    try {
      await SupabaseService.client
          .from('profiles')
          .upsert(updated.toRow())
          .select()
          .maybeSingle();
    } catch (error) {
      debugPrint('[Eduvora Prep] profile upsert failed: $error');
    } finally {
      _setBusy(false);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await Future<void>.value();
    final String cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      throw const AuthFailure('Please enter your email address first.');
    }
    await SupabaseService.auth.resetPasswordForEmail(cleanEmail);
  }

  Future<void> signOut() async {
    _setBusy(true);
    await Future<void>.value();
    try {
      try {
        await SupabaseService.auth.signOut();
      } catch (error) {
        debugPrint('[Eduvora Prep] sign-out failed: $error');
      }
      _profile = null;
      _status = AuthStatus.signedOut;
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  static String describeError(Object error) {
    if (error is AuthFailure) return error.message;
    if (error is sb.AuthException) {
      final String message = error.message.toLowerCase();
      if (message.contains('invalid login')) {
        return 'That email and password combination did not work. Do check '
            'them and try once more.';
      }
      if (message.contains('already registered') ||
          message.contains('already exists') ||
          message.contains('user already registered')) {
        return 'An account already exists for this email address. Please '
            'sign in instead.';
      }
      if (message.contains('email not confirmed')) {
        return 'Please confirm your email address first — the link is in '
            'your inbox.';
      }
      if (message.contains('password')) {
        return 'Your password needs to be at least six characters long.';
      }
      return error.message;
    }
    if (error is sb.PostgrestException) {
      return 'We could not reach your records just now. Please try again in '
          'a moment.';
    }
    final String text = error.toString();
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('ClientException')) {
      return 'You appear to be offline. Please check your connection and '
          'try again.';
    }
    return 'Something did not go to plan. Please try again.';
  }
}

/// The single session used across the app.
final SessionController sessionController = SessionController();
