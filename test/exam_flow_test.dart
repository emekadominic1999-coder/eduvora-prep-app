import 'package:eduvora_prep/core/models/exam.dart';
import 'package:eduvora_prep/core/services/question_bank.dart';
import 'package:eduvora_prep/core/state/app_state.dart';
import 'package:eduvora_prep/core/theme/app_theme.dart';
import 'package:eduvora_prep/features/exam/presentation/exam_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives a real paper end to end: answer, submit, score, review.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppState state;
  late PastPaper paper;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    state = await AppState.create();
    paper = QuestionBank.instance
        .forSubjectAndBody('mathematics', ExamBody.jamb)
        .first;
  });

  Widget wrap(Widget child) => AppScope(
        state: state,
        child: MaterialApp(theme: AppTheme.light, home: child),
      );

  /// Answers the first [count] questions, choosing the correct option on the
  /// first [correct] of them, then walks to the end of the paper.
  Future<void> answer(
    WidgetTester tester,
    List<Question> questions, {
    required int count,
    required int correct,
  }) async {
    for (int i = 0; i < count; i++) {
      final Question question = questions[i];
      final int choice = i < correct
          ? question.answerIndex
          : (question.answerIndex + 1) % question.options.length;
      await tester.tap(find.text(question.options[choice]));
      await tester.pumpAndSettle();
      if (i < count - 1) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
    }
  }

  testWidgets('exam mode scores the paper and records the attempt',
      (WidgetTester tester) async {
    final ExamConfig config = ExamConfig(
      paper: paper,
      mode: PracticeMode.exam,
      questionCount: 4,
      durationMinutes: 10,
      shuffleQuestions: false,
    );

    await tester.pumpWidget(wrap(ExamScreen(config: config)));
    await tester.pumpAndSettle();

    expect(find.text('Question 1 of 4'), findsOneWidget);

    final List<Question> asked = paper.questions.take(4).toList();
    await answer(tester, asked, count: 4, correct: 3);

    // Answers stay hidden in exam mode.
    expect(find.text('Why'), findsNothing);

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    // The bottom bar and the confirmation dialog both hold a Submit button,
    // so reach for the one inside the dialog specifically.
    expect(find.text('Submit this paper?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Submit'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your result'), findsOneWidget);
    expect(find.text('3/4'), findsOneWidget);
    expect(find.text('75%  ·  A1  ·  Excellent'), findsOneWidget);

    expect(state.attempts, hasLength(1));
    final AttemptRecord attempt = state.attempts.first;
    expect(attempt.correct, 3);
    expect(attempt.total, 4);
    expect(attempt.label, paper.title);
    expect(state.streak, 1);

    // The review button sits below the fold in the test viewport.
    await tester.scrollUntilVisible(
      find.text('Review answers and explanations'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Review answers and explanations'));
    await tester.pumpAndSettle();

    expect(find.text('Review'), findsOneWidget);

    // The list builds lazily, so assert on the filters rather than on how
    // many cards happen to fit the test viewport. One question was missed and
    // none were skipped.
    await tester.tap(find.text('Got wrong'));
    await tester.pumpAndSettle();
    expect(find.text('Wrong'), findsOneWidget);
    expect(find.text('Correct'), findsNothing);
    expect(find.text('your answer'), findsOneWidget);

    await tester.tap(find.text('Skipped'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing skipped'), findsOneWidget);
  });

  testWidgets('study mode reveals the answer as soon as one is chosen',
      (WidgetTester tester) async {
    final ExamConfig config = ExamConfig(
      paper: paper,
      mode: PracticeMode.study,
      questionCount: 2,
      durationMinutes: 10,
      shuffleQuestions: false,
    );

    await tester.pumpWidget(wrap(ExamScreen(config: config)));
    await tester.pumpAndSettle();

    final Question first = paper.questions.first;
    await tester.tap(find.text(first.options[first.answerIndex]));
    await tester.pumpAndSettle();

    expect(find.text('Why'), findsOneWidget);
    expect(find.text(first.explanation), findsOneWidget);
  });

  testWidgets('a synthetic drill is labelled without a year',
      (WidgetTester tester) async {
    final PastPaper drill = PastPaper(
      id: 'quick-drill-jamb',
      body: ExamBody.jamb,
      subjectId: 'mixed',
      year: DateTime.now().year,
      diet: 'Quick drill',
      synthetic: true,
      durationMinutes: 10,
      questions: paper.questions.take(3).toList(),
    );

    expect(drill.title, 'JAMB Quick drill');
    expect(paper.title, isNot(contains('drill')));

    await tester.pumpWidget(
      wrap(
        ExamScreen(
          config: ExamConfig(
            paper: drill,
            mode: PracticeMode.exam,
            questionCount: 3,
            durationMinutes: 10,
            shuffleQuestions: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mixed subjects'), findsOneWidget);
    expect(find.text('JAMB Quick drill'), findsOneWidget);
  });
}
