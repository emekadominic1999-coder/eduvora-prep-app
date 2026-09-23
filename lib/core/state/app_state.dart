import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exam.dart';
import '../models/student.dart';
import '../services/question_bank.dart';

/// Single source of truth for the profile, attempt history, bookmarks and
/// practice streak. Everything is persisted to [SharedPreferences] so the app
/// keeps its memory offline and across restarts.
class AppState extends ChangeNotifier {
  AppState._(this._prefs);

  static const String _kProfile = 'prep.profile';
  static const String _kAttempts = 'prep.attempts';
  static const String _kBookmarks = 'prep.bookmarks';
  static const String _kStreakDays = 'prep.streak.days';
  static const String _kStreakLast = 'prep.streak.last';

  /// Attempts are capped so the store cannot grow without bound.
  static const int _maxAttempts = 300;

  final SharedPreferences _prefs;

  StudentProfile _profile = const StudentProfile();
  List<AttemptRecord> _attempts = <AttemptRecord>[];
  Set<String> _bookmarks = <String>{};
  int _streak = 0;
  DateTime? _lastPractice;

  static Future<AppState> create() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AppState state = AppState._(prefs);
    state._restore();
    await QuestionBank.instance.load();
    return state;
  }

  void _restore() {
    final String? profileRaw = _prefs.getString(_kProfile);
    if (profileRaw != null) {
      _profile = StudentProfile.fromJson(
        jsonDecode(profileRaw) as Map<String, dynamic>,
      );
    }

    final String? attemptsRaw = _prefs.getString(_kAttempts);
    if (attemptsRaw != null) {
      _attempts = (jsonDecode(attemptsRaw) as List<dynamic>)
          .map((dynamic e) =>
              AttemptRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    _bookmarks = (_prefs.getStringList(_kBookmarks) ?? const <String>[]).toSet();
    _streak = _prefs.getInt(_kStreakDays) ?? 0;
    final String? last = _prefs.getString(_kStreakLast);
    _lastPractice = last == null ? null : DateTime.tryParse(last);
  }

  // ---------------------------------------------------------------- profile

  StudentProfile get profile => _profile;

  bool get isOnboarded => _profile.onboarded;

  Future<void> saveProfile(StudentProfile profile) async {
    _profile = profile;
    await _prefs.setString(_kProfile, jsonEncode(profile.toJson()));
    notifyListeners();
  }

  Future<void> toggleSubject(String subjectId) async {
    final List<String> next = List<String>.from(_profile.subjectIds);
    if (next.contains(subjectId)) {
      if (next.length <= 1) return; // keep at least one subject
      next.remove(subjectId);
    } else {
      if (next.length >= 4) return; // JAMB allows four
      next.add(subjectId);
    }
    await saveProfile(_profile.copyWith(subjectIds: next));
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

  /// Average score across the most recent [count] attempts.
  double recentAverage({int count = 5}) {
    final List<AttemptRecord> recent = _attempts.take(count).toList();
    if (recent.isEmpty) return 0;
    final double sum = recent.fold<double>(
      0,
      (double s, AttemptRecord a) => s + a.percentage,
    );
    return sum / recent.length;
  }

  /// Per-subject accuracy, strongest first.
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

  /// Topics the student keeps losing marks on, weakest first.
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
    _attempts = <AttemptRecord>[attempt, ..._attempts];
    if (_attempts.length > _maxAttempts) {
      _attempts = _attempts.sublist(0, _maxAttempts);
    }
    await _prefs.setString(
      _kAttempts,
      jsonEncode(_attempts.map((AttemptRecord a) => a.toJson()).toList()),
    );
    await _touchStreak(attempt.takenAt);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _attempts = <AttemptRecord>[];
    await _prefs.remove(_kAttempts);
    notifyListeners();
  }

  // --------------------------------------------------------------- bookmarks

  Set<String> get bookmarks => Set<String>.unmodifiable(_bookmarks);

  bool isBookmarked(String questionId) => _bookmarks.contains(questionId);

  Future<void> toggleBookmark(String questionId) async {
    if (!_bookmarks.remove(questionId)) {
      _bookmarks.add(questionId);
    }
    await _prefs.setStringList(_kBookmarks, _bookmarks.toList());
    notifyListeners();
  }

  List<Question> bookmarkedQuestions() {
    final QuestionBank bank = QuestionBank.instance;
    return _bookmarks
        .map(bank.questionById)
        .whereType<Question>()
        .toList(growable: false);
  }

  // ------------------------------------------------------------------ streak

  int get streak => _streak;

  DateTime? get lastPractice => _lastPractice;

  /// True when the student has already practised today.
  bool get practisedToday {
    final DateTime? last = _lastPractice;
    if (last == null) return false;
    return _daysBetween(last, DateTime.now()) == 0;
  }

  Future<void> _touchStreak(DateTime when) async {
    final DateTime? last = _lastPractice;
    if (last == null) {
      _streak = 1;
    } else {
      final int gap = _daysBetween(last, when);
      if (gap == 0) {
        _streak = _streak == 0 ? 1 : _streak;
      } else if (gap == 1) {
        _streak += 1;
      } else if (gap > 1) {
        _streak = 1;
      }
    }
    _lastPractice = when;
    await _prefs.setInt(_kStreakDays, _streak);
    await _prefs.setString(_kStreakLast, when.toIso8601String());
  }

  static int _daysBetween(DateTime a, DateTime b) {
    final DateTime start = DateTime(a.year, a.month, a.day);
    final DateTime end = DateTime(b.year, b.month, b.day);
    return end.difference(start).inDays;
  }
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
