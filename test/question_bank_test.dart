import 'package:eduvora_prep/core/data/subjects.dart';
import 'package:eduvora_prep/core/models/exam.dart';
import 'package:eduvora_prep/core/services/question_bank.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the bundled question bank: every paper must parse, every question
/// must have a usable answer, and no id may be reused.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuestionBank bank;

  setUpAll(() async {
    bank = QuestionBank.instance;
    await bank.load();
  });

  test('every subject with an asset loads at least one paper', () {
    expect(bank.papers, isNotEmpty);
    for (final Subject subject in Subjects.all) {
      expect(
        bank.forSubject(subject.id),
        isNotEmpty,
        reason: '${subject.id}.json produced no papers',
      );
    }
  });

  test('question ids are unique across the whole bank', () {
    final Set<String> seen = <String>{};
    for (final PastPaper paper in bank.papers) {
      for (final Question question in paper.questions) {
        expect(
          seen.add(question.id),
          isTrue,
          reason: 'duplicate question id ${question.id}',
        );
      }
    }
  });

  test('every question has four options and a valid answer index', () {
    for (final PastPaper paper in bank.papers) {
      for (final Question question in paper.questions) {
        expect(
          question.options.length,
          greaterThanOrEqualTo(2),
          reason: '${question.id} has too few options',
        );
        expect(
          question.answerIndex,
          inInclusiveRange(0, question.options.length - 1),
          reason: '${question.id} has an out-of-range answer index',
        );
        expect(
          question.text.trim(),
          isNotEmpty,
          reason: '${question.id} has no stem',
        );
        expect(
          question.explanation.trim(),
          isNotEmpty,
          reason: '${question.id} has no explanation',
        );
      }
    }
  });

  test('no option is repeated within a question', () {
    for (final PastPaper paper in bank.papers) {
      for (final Question question in paper.questions) {
        expect(
          question.options.toSet().length,
          question.options.length,
          reason: '${question.id} repeats an option',
        );
      }
    }
  });

  test('papers carry a sensible duration', () {
    for (final PastPaper paper in bank.papers) {
      expect(paper.durationMinutes, greaterThan(0));
      expect(paper.questionCount, greaterThan(0));
    }
  });
}
