import 'package:eduvora_prep/core/state/app_state.dart';
import 'package:eduvora_prep/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boots the real app the way main() does and walks the onboarding flow into
/// the dashboard, so a regression in either path fails here first.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('app boots into onboarding', (WidgetTester tester) async {
    final AppState state = await AppState.create();
    await tester.pumpWidget(EduvoraPrepApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Eduvora Prep'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('onboarding leads to the dashboard', (WidgetTester tester) async {
    final AppState state = await AppState.create();
    await tester.pumpWidget(EduvoraPrepApp(state: state));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Ada');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step two: exam body.
    expect(find.text('Which exam are you writing?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step three: subjects.
    expect(find.text('Pick your subjects'), findsOneWidget);
    await tester.tap(find.text('Start practising'));
    await tester.pumpAndSettle();

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Your subjects'), findsOneWidget);
    expect(state.isOnboarded, isTrue);
  });
}
