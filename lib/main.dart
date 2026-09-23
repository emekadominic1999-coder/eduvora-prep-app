import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.lightOverlay);
  final AppState state = await AppState.create();
  runApp(EduvoraPrepApp(state: state));
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

class _Entry extends StatelessWidget {
  const _Entry();

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    return state.isOnboarded ? const HomeShell() : const OnboardingScreen();
  }
}
