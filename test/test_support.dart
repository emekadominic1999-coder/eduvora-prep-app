import 'package:eduvora_prep/core/state/app_state.dart';
import 'package:eduvora_prep/core/state/session_controller.dart';

/// A fresh [AppState] for the current test. Reassigned by [resetTestState]
/// so each test starts with an empty attempt/bookmark history.
late AppState testAppState;

/// Call from `setUp` in any widget test that touches [testAppState] or
/// [sessionController] — there is no backend in a test run, so both would
/// otherwise carry state over from whichever test ran previously.
Future<void> resetTestState() async {
  testAppState = await AppState.create();
  sessionController.resetForTest();
}
