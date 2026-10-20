import 'package:eduvora_prep/core/models/student.dart';
import 'package:eduvora_prep/core/state/app_state.dart';
import 'package:eduvora_prep/core/state/session_controller.dart';
import 'package:eduvora_prep/core/theme/app_theme.dart';
import 'package:eduvora_prep/features/home/home_shell.dart';
import 'package:eduvora_prep/features/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

/// Exercises the onboarding screen and the portal shell directly, seeded via
/// [SessionController.setProfileForTest] — these screens do not need a live
/// Supabase project to render correctly. The sign-in screen and the real
/// auth calls are out of scope for an offline widget test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetTestState();
  });

  testWidgets('onboarding screen collects a name and subjects', (
    WidgetTester tester,
  ) async {
    sessionController.setProfileForTest(
      StudentProfile.empty('test-user', 'student@example.com', ''),
    );

    await tester.pumpWidget(wrapWithAppScope(const OnboardingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Eduvora Prep'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('onboarding leads to a completed profile', (
    WidgetTester tester,
  ) async {
    sessionController.setProfileForTest(
      StudentProfile.empty('test-user', 'student@example.com', ''),
    );

    await tester.pumpWidget(wrapWithAppScope(const OnboardingScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Ada');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Which exam are you writing?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Pick your subjects'), findsOneWidget);
    await tester.tap(find.text('Start practising'));
    await tester.pumpAndSettle();

    expect(sessionController.profile?.name, 'Ada');
    expect(sessionController.status, AuthStatus.ready);
  });

  testWidgets('the portal shell renders the dashboard for a ready profile', (
    WidgetTester tester,
  ) async {
    sessionController.setProfileForTest(
      const StudentProfile(
        id: 'test-user',
        email: 'student@example.com',
        name: 'Ada',
        subjectIds: <String>['english', 'mathematics'],
        onboarded: true,
      ),
    );

    await tester.pumpWidget(wrapWithAppScope(const HomeShell()));
    await tester.pumpAndSettle();

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Your subjects'), findsOneWidget);

    // The portal section sits below the fold in the test viewport.
    await tester.scrollUntilVisible(
      find.text('Explore the portal'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Explore the portal'), findsOneWidget);
  });
}

Widget wrapWithAppScope(Widget child) {
  return AppScope(
    state: testAppState,
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}
