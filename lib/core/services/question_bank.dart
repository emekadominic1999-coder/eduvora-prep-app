import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../data/subjects.dart';
import '../models/exam.dart';

/// Loads the bundled past-question bank from `assets/question_bank/`.
///
/// Everything is offline: the student can practise on a bus, in a village with
/// no data, or in a school hall with the Wi-Fi off. Each subject is one JSON
/// file so a single subject can be updated without touching the rest.
class QuestionBank {
  QuestionBank._();

  static final QuestionBank instance = QuestionBank._();

  final Map<String, List<PastPaper>> _bySubject = <String, List<PastPaper>>{};
  final Map<String, PastPaper> _byId = <String, PastPaper>{};
  final Map<String, Question> _questionsById = <String, Question>{};

  bool _loaded = false;

  bool get isLoaded => _loaded;

  List<PastPaper> get papers => _byId.values.toList(growable: false);

  Future<void> load() async {
    if (_loaded) return;

    for (final Subject subject in Subjects.all) {
      final List<PastPaper> papers = await _loadSubject(subject.id);
      if (papers.isEmpty) continue;
      papers.sort((PastPaper a, PastPaper b) {
        final int byYear = b.year.compareTo(a.year);
        if (byYear != 0) return byYear;
        return a.body.index.compareTo(b.body.index);
      });
      _bySubject[subject.id] = papers;
      for (final PastPaper paper in papers) {
        _byId[paper.id] = paper;
        for (final Question question in paper.questions) {
          _questionsById[question.id] = question;
        }
      }
    }

    _loaded = true;
  }

  Future<List<PastPaper>> _loadSubject(String subjectId) async {
    final String path = 'assets/question_bank/$subjectId.json';
    late final String raw;
    try {
      raw = await rootBundle.loadString(path);
    } catch (_) {
      // Subject not yet stocked — it simply shows as "coming soon".
      return const <PastPaper>[];
    }

    final Map<String, dynamic> json =
        jsonDecode(raw) as Map<String, dynamic>;
    final List<dynamic> papers = json['papers'] as List<dynamic>? ?? const [];

    return papers.map((dynamic entry) {
      final Map<String, dynamic> paper = entry as Map<String, dynamic>;
      final ExamBody body = ExamBody.fromCode(paper['body'] as String);
      final int year = paper['year'] as int;
      final String diet = paper['diet'] as String? ?? '';
      final List<Question> questions =
          (paper['questions'] as List<dynamic>)
              .map((dynamic q) => Question.fromJson(q as Map<String, dynamic>))
              .toList(growable: false);

      return PastPaper(
        id: _paperId(body, subjectId, year, diet),
        body: body,
        subjectId: subjectId,
        year: year,
        diet: diet,
        durationMinutes: paper['duration'] as int? ??
            (body == ExamBody.jamb
                ? JambRules.minutesFor(subjectId)
                : _defaultDuration(questions.length)),
        questions: questions,
      );
    }).toList(growable: false);
  }

  static String _paperId(
    ExamBody body,
    String subjectId,
    int year,
    String diet,
  ) {
    final String slug = diet
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return <String>[
      body.code.toLowerCase(),
      subjectId,
      '$year',
      if (slug.isNotEmpty) slug,
    ].join('-');
  }

  /// WAEC and NECO allow roughly a minute and a half per objective question.
  static int _defaultDuration(int questionCount) {
    return (questionCount * 1.5).ceil().clamp(10, 180);
  }

  // ---------------------------------------------------------------- queries

  List<PastPaper> forSubject(String subjectId) =>
      _bySubject[subjectId] ?? const <PastPaper>[];

  List<PastPaper> forBody(ExamBody body) => _byId.values
      .where((PastPaper paper) => paper.body == body)
      .toList(growable: false);

  List<PastPaper> forSubjectAndBody(String subjectId, ExamBody body) =>
      forSubject(subjectId)
          .where((PastPaper paper) => paper.body == body)
          .toList(growable: false);

  /// Subjects that carry at least one paper for [body].
  List<Subject> subjectsFor(ExamBody body) => Subjects.all
      .where((Subject subject) =>
          forSubjectAndBody(subject.id, body).isNotEmpty)
      .toList(growable: false);

  bool hasContent(String subjectId) => forSubject(subjectId).isNotEmpty;

  PastPaper? paperById(String id) => _byId[id];

  Question? questionById(String id) => _questionsById[id];

  int questionCountFor(String subjectId) => forSubject(subjectId).fold<int>(
        0,
        (int sum, PastPaper paper) => sum + paper.questionCount,
      );

  int get totalQuestions => _questionsById.length;

  /// Every question in the bank for a subject, used by the "mixed drill" that
  /// pulls across years the way a revision class would.
  List<Question> allQuestionsFor(String subjectId, {ExamBody? body}) {
    final List<PastPaper> source =
        body == null ? forSubject(subjectId) : forSubjectAndBody(subjectId, body);
    return <Question>[
      for (final PastPaper paper in source) ...paper.questions,
    ];
  }

  /// Years available for a subject under an exam body, newest first.
  List<int> yearsFor(String subjectId, ExamBody body) {
    final Set<int> years = <int>{
      for (final PastPaper paper in forSubjectAndBody(subjectId, body))
        paper.year,
    };
    final List<int> sorted = years.toList()..sort((int a, int b) => b - a);
    return sorted;
  }
}
