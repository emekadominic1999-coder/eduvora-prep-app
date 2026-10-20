import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/services/supabase_service.dart';
import 'core/state/app_state.dart';
import 'core/state/session_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/common.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.lightOverlay);
  await SupabaseService.initialise();
  sessionController.listenToAuthChanges();
  final AppState state = await AppState.create();
  runApp(EduvoraPrepApp(state: state));
  // Bootstrap after the first frame so the splash screen below has a chance
  // to paint instead of a blank white frame on a slow connection.
  unawaited(sessionController.bootstrap());
}

class EduvoraPrepApp extends StatelessWidget {
  const EduvoraPrepApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Eduvora Prep',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _Entry(),
      ),
    );
  }
}

/// Routes between sign-in, onboarding and the portal based on
/// [SessionController.status], and keeps [AppState] loaded for whoever is
/// currently signed in.
class _Entry extends StatefulWidget {
  const _Entry();

  @override
  State<_Entry> createState() => _EntryState();
}

class _EntryState extends State<_Entry> {
  @override
  void initState() {
    super.initState();
    sessionController.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    sessionController.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    final AuthStatus status = sessionController.status;
    if (status == AuthStatus.ready || status == AuthStatus.needsOnboarding) {
      AppScope.read(context).loadForCurrentUser();
    } else if (status == AuthStatus.signedOut) {
      AppScope.read(context).resetForSignOut();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseService.isReady) {
      return const _BackendMissing();
    }

    switch (sessionController.status) {
      case AuthStatus.unknown:
        return const PrepSplash();
      case AuthStatus.signedOut:
        return const AuthScreen();
      case AuthStatus.needsOnboarding:
        return const OnboardingScreen();
      case AuthStatus.ready:
        return const HomeShell();
    }
  }
}

/// Shown while the session is being restored.
class PrepSplash extends StatelessWidget {
  const PrepSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PrepLogo(size: 64),
            SizedBox(height: AppSpacing.lg),
            CircularProgressIndicator(strokeWidth: 2.4),
          ],
        ),
      ),
    );
  }
}

/// Shown when the app was built without Supabase credentials — a
/// configuration error rather than something a student can work around.
class _BackendMissing extends StatelessWidget {
  const _BackendMissing();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppColours.danger,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Eduvora Prep needs its backend connected',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                SupabaseService.initError ??
                    'Rebuild with --dart-define=SUPABASE_URL=... and '
                        '--dart-define=SUPABASE_ANON_KEY=...',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
