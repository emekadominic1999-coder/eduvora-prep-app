import 'package:flutter/material.dart';

import '../models/exam.dart';
import '../services/question_bank.dart';
import '../services/supabase_service.dart';
import 'session_controller.dart';

/// Owns everything about the signed-in student's CBT activity: attempt
/// history, bookmarks and the practice streak derived from them.
///
/// Unlike the profile (held by [SessionController]), this data lives
/// entirely in Supabase — there is no local-only mode, because progress is
/// meant to follow the student between devices once they have an account.
/// A small in-memory cache keeps the UI responsive between network round
/// trips; it is never the source of truth.
class AppState extends ChangeNotifier {
  AppState._();

  /// Attempts are capped client-side so a single student's history cannot
  /// grow the in-memory list without bound.
  static const int _maxAttempts = 300;

  List<AttemptRecord> _attempts = <AttemptRecord>[];
  Set<String> _bookmarks = <String>{};
  bool _loaded = false;
  bool _loading = false;

  static Future<AppState> create() async {
    final AppState state = AppState._();
    await QuestionBank.instance.load();
    return state;
  }

  bool get isLoaded => _loaded;

  String? get _userId => sessionController.profile?.id;

  /// Loads attempts and bookmarks for the currently signed-in student. Safe
  /// to call repeatedly — it is a no-op once loaded, unless [force].
  Future<void> loadForCurrentUser({bool force = false}) async {
    final String? userId = _userId;
    if (userId == null || userId.isEmpty) return;
    if (_loaded && !force) return;
    if (_loading) return;
    _loading = true;
    try {
      final List<Map<String, dynamic>> attemptRows =
          await SupabaseService.client
              .from('attempts')
              .select()
              .eq('user_id', userId)
              .order('taken_at', ascending: false)
              .limit(_maxAttempts);
      _attempts = attemptRows
          .map((Map<String, dynamic> row) => AttemptRecord.fromRow(row))
          .toList();

      final List<Map<String, dynamic>> bookmarkRows =
          await SupabaseService.client
              .from('bookmarks')
              .select('question_id')
              .eq('user_id', userId);
      _bookmarks = bookmarkRows
          .map((Map<String, dynamic> row) => row['question_id'] as String)
          .toSet();

      _loaded = true;
    } catch (error) {
      debugPrint('[Eduvora Prep] failed to load student data: $error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Clears everything when the student signs out, so the next sign-in
  /// starts from a clean slate rather than showing a stale cache.
  void resetForSignOut() {
    _attempts = <AttemptRecord>[];
    _bookmarks = <String>{};
    _loaded = false;
    notifyListeners();
  }

  // --------------------------------------------------------------- attempts

  List<AttemptRecord> get attempts => List<AttemptRecord>.unmodifiable(_attempts);

  List<AttemptRecord> attemptsForSubject(String subjectId) => _attempts
      .where((AttemptRecord a) => a.subjectId == subjectId)
      .toList(growable: false);

  AttemptRecord? get lastAttempt => _attempts.isEmpty ? null : _attempts.first;

  int get questionsAnswered =>
      _attempts.fold<int>(0, (int sum, AttemptRecord a) => sum + a.total);

  int get totalCorrect =>
      _attempts.fold<int>(0, (int sum, AttemptRecord a) => sum + a.correct);

  double get overallAccuracy {
    final int answered = questionsAnswered;
    if (answered == 0) return 0;
    return (totalCorrect / answered) * 100;
  }

  double recentAverage({int count = 5}) {
    final List<AttemptRecord> recent = _attempts.take(count).toList();
    if (recent.isEmpty) return 0;
    final double sum = recent.fold<double>(
      0,
      (double s, AttemptRecord a) => s + a.percentage,
    );
    return sum / recent.length;
  }

  List<MapEntry<String, double>> subjectRanking() {
    final Map<String, List<int>> tally = <String, List<int>>{};
    for (final AttemptRecord attempt in _attempts) {
      final List<int> entry =
          tally.putIfAbsent(attempt.subjectId, () => <int>[0, 0]);
      entry[0] += attempt.correct;
      entry[1] += attempt.total;
    }
    final List<MapEntry<String, double>> ranked = tally.entries
        .where((MapEntry<String, List<int>> e) => e.value[1] > 0)
        .map((MapEntry<String, List<int>> e) =>
            MapEntry<String, double>(e.key, (e.value[0] / e.value[1]) * 100))
        .toList();
    ranked.sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
        b.value.compareTo(a.value));
    return ranked;
  }

  List<MapEntry<String, double>> weakTopics({int limit = 6}) {
    final Map<String, List<int>> tally = <String, List<int>>{};
    for (final AttemptRecord attempt in _attempts) {
      attempt.topicScores.forEach((String topic, List<int> score) {
        final List<int> entry = tally.putIfAbsent(topic, () => <int>[0, 0]);
        entry[0] += score[0];
        entry[1] += score[1];
      });
    }
    final List<MapEntry<String, double>> ranked = tally.entries
        .where((MapEntry<String, List<int>> e) => e.value[1] >= 2)
        .map((MapEntry<String, List<int>> e) =>
            MapEntry<String, double>(e.key, (e.value[0] / e.value[1]) * 100))
        .toList();
    ranked.sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
        a.value.compareTo(b.value));
    return ranked.take(limit).toList();
  }

  Future<void> recordAttempt(AttemptRecord attempt) async {
    // Local state updates unconditionally — a slow or absent connection must
    // never cost the student their result screen, and this also means the
    // app's own widget tests do not need a live backend.
    _attempts = <AttemptRecord>[attempt, ..._attempts];
    if (_attempts.length > _maxAttempts) {
      _attempts = _attempts.sublist(0, _maxAttempts);
    }
    notifyListeners();

    final String? userId = _userId;
    if (userId == null || userId.isEmpty) return;
    try {
      await SupabaseService.client.from('attempts').insert(
            attempt.toRow(userId),
          );
    } catch (error) {
      debugPrint('[Eduvora Prep] failed to save attempt: $error');
    }
  }

  Future<void> clearHistory() async {
    final String? userId = _userId;
    _attempts = <AttemptRecord>[];
    notifyListeners();
    if (userId == null || userId.isEmpty) return;
    try {
      await SupabaseService.client
          .from('attempts')
          .delete()
          .eq('user_id', userId);
    } catch (error) {
      debugPrint('[Eduvora Prep] failed to clear history: $error');
    }
  }

  // -------------------------------------------------------------- bookmarks

  Set<String> get bookmarks => Set<String>.unmodifiable(_bookmarks);

  bool isBookmarked(String questionId) => _bookmarks.contains(questionId);

  Future<void> toggleBookmark(String questionId) async {
    final bool wasBookmarked = _bookmarks.contains(questionId);
    if (wasBookmarked) {
      _bookmarks.remove(questionId);
    } else {
      _bookmarks.add(questionId);
    }
    notifyListeners();

    final String? userId = _userId;
    if (userId == null || userId.isEmpty) return;
    try {
      if (wasBookmarked) {
        await SupabaseService.client
            .from('bookmarks')
            .delete()
            .eq('user_id', userId)
            .eq('question_id', questionId);
      } else {
        await SupabaseService.client.from('bookmarks').upsert(<String, dynamic>{
          'user_id': userId,
          'question_id': questionId,
        });
      }
    } catch (error) {
      debugPrint('[Eduvora Prep] failed to sync bookmark: $error');
    }
  }

  List<Question> bookmarkedQuestions() {
    final QuestionBank bank = QuestionBank.instance;
    return _bookmarks
        .map(bank.questionById)
        .whereType<Question>()
        .toList(growable: false);
  }

  // ------------------------------------------------------------------ streak

  /// Derived from the dates attempts were taken — no separate counter to
  /// keep in sync. Counts consecutive days ending today or yesterday; any
  /// earlier gap resets the count to zero.
  int get streak {
    if (_attempts.isEmpty) return 0;
    final Set<DateTime> days = _attempts
        .map((AttemptRecord a) => _dateOnly(a.takenAt))
        .toSet();
    final DateTime today = _dateOnly(DateTime.now());

    DateTime cursor;
    if (days.contains(today)) {
      cursor = today;
    } else if (days.contains(today.subtract(const Duration(days: 1)))) {
      cursor = today.subtract(const Duration(days: 1));
    } else {
      return 0;
    }

    int count = 0;
    while (days.contains(cursor)) {
      count += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  DateTime? get lastPractice =>
      _attempts.isEmpty ? null : _attempts.first.takenAt;

  bool get practisedToday {
    final DateTime? last = lastPractice;
    if (last == null) return false;
    return _dateOnly(last) == _dateOnly(DateTime.now());
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Exposes [AppState] to the widget tree without a third-party package.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final AppScope? scope =
        context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing from the widget tree');
    return scope!.notifier!;
  }

  /// Reads the state without subscribing — for callbacks and one-off writes.
  static AppState read(BuildContext context) {
    final AppScope? scope =
        context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing from the widget tree');
    return scope!.notifier!;
  }
}
